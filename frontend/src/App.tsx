import { useState, useEffect } from 'react'
import { useAccount, useSendTransaction, useWriteContract, useWaitForTransactionReceipt, useBalance } from 'wagmi'
import { parseEther, parseUnits, formatUnits } from 'viem'
import { transferContractAddress, transferContractABI } from './contracts'

// API基础URL
const API_BASE_URL = 'http://localhost:3001/api'

// 代币数据类型定义
interface Token {
  id: number
  name: string
  symbol: string
  contract_address: string
  decimals: number
  is_native: boolean
  display_order: number
  is_active: boolean
  icon_url?: string
  description?: string
  official_website?: string
}

// 前端使用的代币类型
interface AppToken {
  name: string
  address: string
  decimals: number
  isNative: boolean
}

function App() {
  const { address, isConnected, chainId } = useAccount()

  // 代币状态
  const [supportedTokens, setSupportedTokens] = useState<AppToken[]>([])
  const [tokensLoading, setTokensLoading] = useState(true)
  const [tokensError, setTokensError] = useState<string | null>(null)

  // Unified Transfer State
  const [recipient, setRecipient] = useState('')
  const [amount, setAmount] = useState('')
  const [selectedToken, setSelectedToken] = useState<AppToken | null>(null)
  
  // wagmi hooks
  const { data: ethHash, isPending: isEthPending, sendTransaction } = useSendTransaction()
  const { data: approveHash, isPending: isApprovePending, writeContract: approve } = useWriteContract()
  const { data: transferHash, isPending: isTransferPending, writeContract: transferTokens } = useWriteContract()

  // Hook to wait for approve transaction
  const { data: approveReceipt, isLoading: isConfirmingApprove } = useWaitForTransactionReceipt({ hash: approveHash })

  // Hook to get selected token balance
  const { data: tokenBalance, refetch: refetchTokenBalance } = useBalance({
    address,
    token: selectedToken?.isNative ? undefined : selectedToken?.address as `0x${string}`,
    chainId: 1 // Balances are fetched from mainnet for these tokens
  })

  // 从API获取代币列表
  const fetchTokens = async () => {
    try {
      setTokensLoading(true)
      setTokensError(null)
      
      const response = await fetch(`${API_BASE_URL}/tokens`)
      
      if (!response.ok) {
        throw new Error(`HTTP错误: ${response.status}`)
      }
      
      const result = await response.json()
      
      if (result.success && result.data && result.data.tokens) {
        // 转换API数据为前端需要的格式
        const tokens: AppToken[] = result.data.tokens
          .filter((token: Token) => token.is_active) // 只显示启用的代币
          .sort((a: Token, b: Token) => a.display_order - b.display_order) // 按显示顺序排序
          .map((token: Token) => ({
            name: token.symbol, // 使用symbol作为显示名称
            address: token.contract_address,
            decimals: token.decimals,
            isNative: token.is_native
          }))
        
        setSupportedTokens(tokens)
        
        // 如果还没有选中代币且有可用代币，选择第一个
        if (!selectedToken && tokens.length > 0) {
          setSelectedToken(tokens[0])
        }
      } else {
        throw new Error(result.message || '获取代币列表失败')
      }
    } catch (error) {
      console.error('获取代币列表失败:', error)
      setTokensError(error instanceof Error ? error.message : '网络错误')
      
      // 如果API失败，使用默认代币列表作为后备
      const defaultTokens: AppToken[] = [
        { name: 'ETH', address: '0x0000000000000000000000000000000000000000', decimals: 18, isNative: true },
        { name: 'USDT', address: '0xdAC17F958D2ee523a2206206994597C13D831ec7', decimals: 6, isNative: false },
        { name: 'USDC', address: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', decimals: 6, isNative: false },
        { name: 'DAI', address: '0x6B175474E89094C44Da98b954EedeAC495271d0F', decimals: 18, isNative: false },
      ]
      setSupportedTokens(defaultTokens)
      if (!selectedToken && defaultTokens.length > 0) {
        setSelectedToken(defaultTokens[0])
      }
    } finally {
      setTokensLoading(false)
    }
  }
  
  // 在组件挂载时获取代币列表
  useEffect(() => {
    fetchTokens()
  }, [])
  
  // Effect to trigger transfer after approval is confirmed
  useEffect(() => {
    if (approveReceipt) {
      handleTokenTransfer()
    }
  }, [approveReceipt])

  // Refetch balance when selected token or connection status changes
  useEffect(() => {
    if (isConnected && selectedToken) {
        refetchTokenBalance();
    }
  }, [selectedToken, isConnected, refetchTokenBalance]);

  // Unified transfer handler
  async function handleTransfer() {
    if (!recipient || !amount) return alert('Please fill in both fields for transfer.');
    if (chainId !== 1) return alert('Please switch to Ethereum Mainnet to transfer tokens.');
    if (!selectedToken) return alert('Please select a token.');
    
    if (selectedToken.isNative) {
      // Handle ETH transfer
      sendTransaction({ 
        to: recipient as `0x${string}`, 
        value: parseEther(amount) 
      })
    } else {
      // Handle ERC20 transfer - start with approval
      approve({
        address: selectedToken.address as `0x${string}`,
        abi: [{ "inputs": [ { "internalType": "address", "name": "spender", "type": "address" }, { "internalType": "uint256", "name": "value", "type": "uint256" } ], "name": "approve", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" }],
        functionName: 'approve',
        args: [transferContractAddress, parseUnits(amount, selectedToken.decimals)],
      })
    }
  }

  // ERC20 transfer handler (Step 2 - triggered by useEffect)
  async function handleTokenTransfer() {
    if (!selectedToken) return;
    
    transferTokens({
      address: transferContractAddress,
      abi: transferContractABI,
      functionName: 'transferERC20',
      args: [selectedToken.address as `0x${string}`, recipient as `0x${string}`, parseUnits(amount, selectedToken.decimals)],
    }, {
      onSuccess: () => {
        setTimeout(() => refetchTokenBalance(), 2000); 
      }
    })
  }

  // Determine which hash to show and button state
  const currentHash = selectedToken?.isNative ? ethHash : (transferHash || approveHash)
  const isTransferring = selectedToken?.isNative 
    ? isEthPending 
    : (isApprovePending || isConfirmingApprove || isTransferPending)

  // Determine button text
  const getButtonText = () => {
    if (!selectedToken) return 'Loading tokens...'
    if (chainId !== 1) return 'Switch to Mainnet'
    if (selectedToken.isNative) {
      return isEthPending ? 'Sending...' : 'Send Token'
    } else {
      if (isApprovePending) return 'Approving...'
      if (isConfirmingApprove) return 'Waiting Approval...'
      if (isTransferPending) return 'Transferring...'
      return 'Approve & Transfer'
    }
  }

  return (
    <div style={{ width: '100vw', padding: '2rem', textAlign: 'center' }}>
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <h1>Web3 Transfer App</h1>
        <w3m-button />
      </header>

      <main style={{ display: 'flex', justifyContent: 'center', alignItems: 'flex-start', gap: '2rem', flexWrap: 'wrap' }}>
        {isConnected ? (
          <div style={styles.card}>
            <h2>Send Token</h2>
            
            <label htmlFor="token-select" style={styles.label}>Select Token</label>
            {tokensLoading ? (
              <div style={{...styles.input, textAlign: 'center'}}>Loading tokens...</div>
            ) : tokensError ? (
              <div style={{...styles.input, color: '#ff6b6b', textAlign: 'center'}}>
                Error: {tokensError}
                <button 
                  onClick={fetchTokens} 
                  style={{marginLeft: '10px', padding: '2px 8px', fontSize: '12px', backgroundColor: '#4F46E5', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer'}}
                >
                  Retry
                </button>
              </div>
            ) : (
              <select 
                id="token-select" 
                value={selectedToken?.address || ''}
                onChange={(e) => setSelectedToken(supportedTokens.find(t => t.address === e.target.value) || null)}
                style={styles.input}
                disabled={supportedTokens.length === 0}
              >
                {supportedTokens.length === 0 ? (
                  <option value="">No tokens available</option>
                ) : (
                  supportedTokens.map(token => (
                    <option key={token.address} value={token.address}>{token.name}</option>
                  ))
                )}
              </select>
            )}

            {/* 显示代币数据来源信息 */}
            {!tokensLoading && !tokensError && supportedTokens.length > 0 && (
              <p style={{fontSize: '0.8rem', margin: '0.25rem 0', color: '#888'}}>
                {tokensError ? 'Using default tokens (API unavailable)' : `${supportedTokens.length} tokens loaded from API`}
              </p>
            )}

            <p style={{fontSize: '0.9rem', margin: '0.5rem 0'}}>
              Your Balance: {tokenBalance && chainId === 1 
                ? `${parseFloat(formatUnits(tokenBalance.value, tokenBalance.decimals)).toFixed(4)} ${tokenBalance.symbol}` 
                : 'Switch to Mainnet'}
            </p>
            
            <label htmlFor="recipient" style={styles.label}>Recipient Address</label>
            <input 
              id="recipient" 
              type="text" 
              placeholder="0x..." 
              value={recipient} 
              onChange={(e) => setRecipient(e.target.value)} 
              style={styles.input} 
            />
            
            <label htmlFor="amount" style={styles.label}>Amount</label>
            <input 
              id="amount" 
              type="text" 
              placeholder={selectedToken?.isNative ? "0.05" : "10"} 
              value={amount} 
              onChange={(e) => setAmount(e.target.value)} 
              style={styles.input} 
            />

            <button 
              onClick={handleTransfer} 
              disabled={isTransferring || chainId !== 1 || !selectedToken} 
              style={styles.button(isTransferring || chainId !== 1 || !selectedToken)}
            >
              {getButtonText()}
            </button>

            {currentHash && <TxLink hash={currentHash} chainId={chainId} />}
            {approveHash && transferHash && (
              <TxLink hash={approveHash} label="Approve Hash:" chainId={chainId} />
            )}
          </div>
        ) : (
          <p>Please connect your wallet to start.</p>
        )}
      </main>
    </div>
  )
}

const TxLink = ({ hash, label = "Tx Hash:", chainId }: { hash: `0x${string}`, label?: string, chainId?: number | undefined }) => {
  const explorerUrl = chainId === 1 ? 'https://etherscan.io' : 'https://sepolia.etherscan.io';
  return (
    <div style={{ marginTop: '1rem', overflowWrap: 'break-word' }}>
      {label}{' '}
      <a href={`${explorerUrl}/tx/${hash}`} target="_blank" rel="noopener noreferrer" style={{ color: '#818CF8' }}>
        {hash.slice(0, 6)}...{hash.slice(-4)}
      </a>
    </div>
  );
};

const styles = {
  card: { 
    display: 'flex', 
    flexDirection: 'column' as 'column', 
    gap: '1rem', 
    padding: '2rem', 
    backgroundColor: '#333', 
    borderRadius: '1rem', 
    minWidth: '400px',
    maxWidth: '500px'
  },
  label: { textAlign: 'left' as 'left' },
  input: { 
    padding: '0.5rem', 
    borderRadius: '0.5rem', 
    border: 'none', 
    backgroundColor: '#444', 
    color: 'white' 
  },
  button: (disabled: boolean) => ({ 
    padding: '0.75rem', 
    borderRadius: '0.5rem', 
    border: 'none', 
    backgroundColor: disabled ? '#555' : '#4F46E5', 
    color: 'white', 
    cursor: disabled ? 'not-allowed' : 'pointer', 
    marginTop: '1rem' 
  }),
};

export default App