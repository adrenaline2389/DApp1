# Sepolia Testnet Deployment Guide

## 前置准备

### 1. 获取Sepolia测试网ETH
- 访问 [Sepolia Faucet](https://faucets.chain.link/sepolia) 获取测试ETH
- 或者使用 [Alchemy Faucet](https://sepoliafaucet.com/)
- 需要至少 0.1 ETH 用于合约部署和交互

### 2. 获取API密钥
- **Alchemy API Key**: 注册 [Alchemy](https://alchemy.com/) 获取免费API密钥
- **Etherscan API Key**: 注册 [Etherscan](https://etherscan.io/apis) 获取API密钥用于合约验证

### 3. 配置环境变量
1. 复制 `.env.example` 到 `.env`
2. 填写以下信息：
```bash
# 你的私钥 (不要包含0x前缀)
PRIVATE_KEY=your_private_key_here

# Alchemy API密钥
ALCHEMY_API_KEY=your_alchemy_api_key_here

# Etherscan API密钥 (用于合约验证)
ETHERSCAN_API_KEY=your_etherscan_api_key_here

# RPC URLs (如果使用自定义RPC)
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your_api_key
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/your_api_key
```

## 部署步骤

### 1. 安装依赖
```bash
# 运行依赖安装脚本
install-deps.bat
```

### 2. 编译合约
```bash
forge build
```

### 3. 运行测试
```bash
forge test
```

### 4. 部署到Sepolia
```bash
# 使用自动化部署脚本
deploy-sepolia.bat

# 或者手动部署
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify -vvvv
```

## 部署后验证

### 1. 检查合约地址
部署成功后，记录以下合约地址：
- TransferContract: `0x...`
- TestToken: `0x...`

### 2. 在Etherscan上验证
访问 [Sepolia Etherscan](https://sepolia.etherscan.io/) 检查：
- 合约是否成功部署
- 合约代码是否已验证
- 交易历史是否正确

### 3. 测试合约功能
```bash
# 更新 script/Interact.s.sol 中的合约地址
# 然后运行交互脚本
forge script script/Interact.s.sol --rpc-url sepolia --broadcast
```

## 网络配置详情

### Sepolia测试网信息
- **Chain ID**: 11155111
- **RPC URL**: https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
- **Block Explorer**: https://sepolia.etherscan.io/
- **Faucet**: https://faucets.chain.link/sepolia

### Gas 配置
- **Gas Price**: 自动 (建议使用 EIP-1559)
- **Gas Limit**: 
  - TestToken 部署: ~800,000
  - TransferContract 部署: ~1,500,000
  - 一般交易: ~100,000

## 常见问题

### 1. 部署失败
- 检查ETH余额是否足够
- 确认私钥格式正确（不包含0x前缀）
- 验证API密钥是否有效

### 2. 合约验证失败
- 确认Etherscan API密钥正确
- 检查网络连接
- 等待几分钟后重试

### 3. 交互失败
- 确认合约地址正确
- 检查账户ETH余额
- 验证合约状态是否正常

## 安全提醒

1. **私钥安全**: 绝不要将私钥提交到代码仓库
2. **测试网使用**: 仅在测试网使用，避免在主网意外部署
3. **资金安全**: 测试网ETH无实际价值，但私钥管理依然重要

## 后续步骤

1. 测试所有合约功能
2. 记录合约地址和ABI
3. 创建前端接口（如需要）
4. 准备主网部署计划