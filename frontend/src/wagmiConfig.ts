// 1. Get projectId from https://cloud.walletconnect.com
const projectId = 'YOUR_PROJECT_ID' // Replace with your own project ID

// 2. Create wagmiConfig
import { createConfig, http } from 'wagmi'
import { sepolia } from 'wagmi/chains'

const metadata = {
  name: 'Web3 Transfer App',
  description: 'A simple app to transfer ETH and ERC20 tokens',
  url: 'https://web3modal.com', // origin domain
  icons: ['https://avatars.githubusercontent.com/u/37784886']
}

export const config = createConfig({
  chains: [sepolia],
  transports: {
    [sepolia.id]: http()
  },
  metadata,
})
