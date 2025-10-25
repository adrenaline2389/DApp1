import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './index.css'
import { createWeb3Modal, defaultWagmiConfig } from '@web3modal/wagmi/react'
import { WagmiProvider } from 'wagmi'
import { mainnet, sepolia } from 'wagmi/chains'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

// 0. Setup queryClient
const queryClient = new QueryClient()

// 1. Get projectId from https://cloud.walletconnect.com
const projectId = import.meta.env.VITE_PROJECT_ID
if (!projectId) {
  throw new Error('VITE_PROJECT_ID is not set. Please add it to your .env file or Vercel environment variables.')
}

// 2. Create wagmiConfig
const metadata = {
  name: 'Web3 Transfer App',
  description: 'A simple app to transfer ETH and ERC20 tokens',
  url: 'https://web3modal.com', // origin domain
  icons: ['https://avatars.githubusercontent.com/u/37784886']
}

const chains = [mainnet, sepolia] as const
const wagmiConfig = defaultWagmiConfig({
  chains,
  projectId,
  metadata
})

// 3. Create modal
createWeb3Modal({
  wagmiConfig,
  projectId,
  chains
})

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        <App />
      </QueryClientProvider>
    </WagmiProvider>
  </React.StrictMode>,
)
