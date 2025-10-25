import { useState, useEffect } from 'react'
import { useAccount, useSendTransaction, useWriteContract, useWaitForTransactionReceipt, useBalance } from 'wagmi'
import { parseEther, parseUnits, formatUnits } from 'viem'
import { transferContractAddress, transferContractABI } from './contracts'

// Define supported tokens for the dropdown
const supportedTokens = [
  { name: 'USDT', address: '0xdAC17F958D2ee523a2206206994597C13D831ec7', decimals: 6 },
  { name: 'USDC', address: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', decimals: 6 },
  { name: 'DAI', address: '0x6B175474E89094C44Da98b954EedeAC495271d0F', decimals: 18 },
];

function App() {
  const { address, isConnected, chainId } = useAccount()

  // ETH Transfer State
  const [ethRecipient, setEthRecipient] = useState('')
  const [ethAmount, setEthAmount] = useState('')

  // ERC20 Transfer State
  const [tokenRecipient, setTokenRecipient] = useState('')
  const [tokenAmount, setTokenAmount] = useState('')
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
    token: selectedToken.address as `0x${string}`,
    chainId: 1 // Balances are fetched from mainnet for these real tokens
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


  // ETH send handler
  async function handleEthSend() {
    if (!ethRecipient || !ethAmount) return alert('Please fill in both fields for ETH transfer.');
    sendTransaction({ to: ethRecipient as `0x${string}`, value: parseEther(ethAmount) })
  }

  // ERC20 approve handler (Step 1)
  async function handleApprove() {
    if (!tokenRecipient || !tokenAmount) return alert('Please fill in both fields for token transfer.');
    if (chainId !== 1) return alert('Please switch to Ethereum Mainnet to transfer real tokens.');
    
    approve({
      address: selectedToken.address as `0x${string}`,
      abi: [{ "inputs": [ { "internalType": "address", "name": "spender", "type": "address" }, { "internalType": "uint256", "name": "value", "type": "uint256" } ], "name": "approve", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" }],
      functionName: 'approve',
      args: [transferContractAddress, parseUnits(tokenAmount, selectedToken.decimals)],
    })
  }

  // ERC20 transfer handler (Step 2 - triggered by useEffect)
  async function handleTokenTransfer() {
    transferTokens({
      address: transferContractAddress,
      abi: transferContractABI,
      functionName: 'transferERC20',
      args: [selectedToken.address as `0x${string}`, tokenRecipient as `0x${string}`, parseUnits(tokenAmount, selectedToken.decimals)],
    }, {
      onSuccess: () => {
        setTimeout(() => refetchTokenBalance(), 2000); 
      }
    })
  }

  return (
    <div style={{ width: '100vw', padding: '2rem', textAlign: 'center' }}>
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <h1>Web3 Transfer App</h1>
        <w3m-button />
      </header>

      <main style={{ display: 'flex', justifyContent: 'center', alignItems: 'flex-start', gap: '2rem', flexWrap: 'wrap' }}>
        {isConnected ? (
          <>
            {/* ETH TRANSFER COMPONENT */}
            <div style={styles.card}>
              <h2>Send ETH</h2>
              <label htmlFor="ethRecipient" style={styles.label}>Recipient Address</label>
              <input id="ethRecipient" type="text" placeholder="0x..." value={ethRecipient} onChange={(e) => setEthRecipient(e.target.value)} style={styles.input} />
              
              <label htmlFor="ethAmount" style={styles.label}>Amount (in ETH)</label>
              <input id="ethAmount" type="text" placeholder="0.05" value={ethAmount} onChange={(e) => setEthAmount(e.target.value)} style={styles.input} />

              <button onClick={handleEthSend} disabled={isEthPending} style={styles.button(isEthPending)}>
                {isEthPending ? 'Confirming...' : 'Send ETH'}
              </button>
              {ethHash && <TxLink hash={ethHash} chainId={chainId} />}
            </div>

            {/* NEW ERC20 TRANSFER COMPONENT */}
            <div style={styles.card}>
              <h2>Send ERC20 Token</h2>
              
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

              <p style={{fontSize: '0.9rem'}}>Your Balance: {tokenBalance && chainId === 1 ? `${parseFloat(formatUnits(tokenBalance.value, tokenBalance.decimals)).toFixed(4)} ${tokenBalance.symbol}` : 'Switch to Mainnet'}</p>
              
              <label htmlFor="tokenRecipient" style={styles.label}>Recipient Address</label>
              <input id="tokenRecipient" type="text" placeholder="0x..." value={tokenRecipient} onChange={(e) => setTokenRecipient(e.target.value)} style={styles.input} />
              
              <label htmlFor="tokenAmount" style={styles.label}>Amount</label>
              <input id="tokenAmount" type="text" placeholder="10" value={tokenAmount} onChange={(e) => setTokenAmount(e.target.value)} style={styles.input} />

              <button onClick={handleApprove} disabled={isApprovePending || isConfirmingApprove || isTransferPending || chainId !== 1} style={styles.button(isApprovePending || isConfirmingApprove || isTransferPending || chainId !== 1)}>
                {chainId !== 1 ? 'Switch to Mainnet' : isApprovePending ? 'Approving...' : isConfirmingApprove ? 'Waiting Approval...' : isTransferPending ? 'Transferring...' : 'Approve & Transfer'}
              </button>

              {approveHash && <TxLink hash={approveHash} label="Approve Hash:" chainId={chainId} />}
              {transferHash && <TxLink hash={transferHash} label="Transfer Hash:" chainId={chainId} />}
            </div>
          </>
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
  card: { display: 'flex', flexDirection: 'column' as 'column', gap: '1rem', padding: '2rem', backgroundColor: '#333', borderRadius: '1rem', minWidth: '400px' },
  label: { textAlign: 'left' as 'left' },
  input: { padding: '0.5rem', borderRadius: '0.5rem', border: 'none', backgroundColor: '#444', color: 'white' },
  button: (disabled: boolean) => ({ padding: '0.75rem', borderRadius: '0.5rem', border: 'none', backgroundColor: disabled ? '#555' : '#4F46E5', color: 'white', cursor: disabled ? 'not-allowed' : 'pointer', marginTop: '1rem' }),
};

export default App
