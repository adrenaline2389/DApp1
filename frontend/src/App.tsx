import { useState, useEffect } from 'react'
import { useAccount, useSendTransaction, useWriteContract, useWaitForTransactionReceipt, useBalance } from 'wagmi'
import { parseEther, parseUnits, formatUnits } from 'viem'
import { transferContractAddress, transferContractABI } from './contracts'

// Define supported tokens for the dropdown - including ETH
const supportedTokens = [
  { name: 'ETH', address: '0x0000000000000000000000000000000000000000', decimals: 18, isNative: true },
  { name: 'USDT', address: '0xdAC17F958D2ee523a2206206994597C13D831ec7', decimals: 6, isNative: false },
  { name: 'USDC', address: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', decimals: 6, isNative: false },
  { name: 'DAI', address: '0x6B175474E89094C44Da98b954EedeAC495271d0F', decimals: 18, isNative: false },
];

function App() {
  const { address, isConnected, chainId } = useAccount()

  // Unified Transfer State
  const [recipient, setRecipient] = useState('')
  const [amount, setAmount] = useState('')
  const [selectedToken, setSelectedToken] = useState(supportedTokens[0]);
  
  // wagmi hooks
  const { data: ethHash, isPending: isEthPending, sendTransaction } = useSendTransaction()
  const { data: approveHash, isPending: isApprovePending, writeContract: approve } = useWriteContract()
  const { data: transferHash, isPending: isTransferPending, writeContract: transferTokens } = useWriteContract()

  // Hook to wait for approve transaction
  const { data: approveReceipt, isLoading: isConfirmingApprove } = useWaitForTransactionReceipt({ hash: approveHash })

  // Hook to get selected token balance
  const { data: tokenBalance, refetch: refetchTokenBalance } = useBalance({
    address,
    token: selectedToken.isNative ? undefined : selectedToken.address as `0x${string}`,
    chainId: 1 // Balances are fetched from mainnet for these tokens
  })
  
  // Effect to trigger transfer after approval is confirmed
  useEffect(() => {
    if (approveReceipt) {
      handleTokenTransfer()
    }
  }, [approveReceipt])

  // Refetch balance when selected token or connection status changes
  useEffect(() => {
    if (isConnected) {
        refetchTokenBalance();
    }
  }, [selectedToken, isConnected, refetchTokenBalance]);

  // Unified transfer handler
  async function handleTransfer() {
    if (!recipient || !amount) return alert('Please fill in both fields for transfer.');
    if (chainId !== 1) return alert('Please switch to Ethereum Mainnet to transfer tokens.');
    
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
  const currentHash = selectedToken.isNative ? ethHash : (transferHash || approveHash)
  const isTransferring = selectedToken.isNative 
    ? isEthPending 
    : (isApprovePending || isConfirmingApprove || isTransferPending)

  // Determine button text
  const getButtonText = () => {
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
            <select 
              id="token-select" 
              value={selectedToken.address}
              onChange={(e) => setSelectedToken(supportedTokens.find(t => t.address === e.target.value)!)}
              style={styles.input}
            >
              {supportedTokens.map(token => (
                <option key={token.address} value={token.address}>{token.name}</option>
              ))}
            </select>

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
              placeholder={selectedToken.isNative ? "0.05" : "10"} 
              value={amount} 
              onChange={(e) => setAmount(e.target.value)} 
              style={styles.input} 
            />

            <button 
              onClick={handleTransfer} 
              disabled={isTransferring || chainId !== 1} 
              style={styles.button(isTransferring || chainId !== 1)}
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