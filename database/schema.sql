-- 代币管理数据库表结构设计
-- 用于管理DApp中支持的代币列表

-- 创建代币表
CREATE TABLE IF NOT EXISTS supported_tokens (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL,          -- 代币全名
    symbol VARCHAR(20) NOT NULL,         -- 代币符号  
    contract_address VARCHAR(42) NOT NULL, -- 合约地址，ETH使用0x0000...作为标识
    decimals INTEGER NOT NULL DEFAULT 18, -- 代币精度
    is_native BOOLEAN NOT NULL DEFAULT FALSE, -- 是否为原生代币(ETH)
    icon_url VARCHAR(255) DEFAULT NULL,   -- 代币图标URL
    chain_id INTEGER NOT NULL DEFAULT 1, -- 链ID，1为以太坊主网
    is_active BOOLEAN NOT NULL DEFAULT TRUE, -- 是否启用
    display_order INTEGER DEFAULT 0,     -- 显示顺序
    description TEXT DEFAULT NULL,       -- 代币描述
    official_website VARCHAR(255) DEFAULT NULL, -- 官方网站
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP, -- 创建时间
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP, -- 更新时间
    
    -- 添加唯一约束
    UNIQUE(contract_address, chain_id),
    UNIQUE(symbol, chain_id)
);

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_tokens_active ON supported_tokens(is_active);
CREATE INDEX IF NOT EXISTS idx_tokens_chain ON supported_tokens(chain_id);
CREATE INDEX IF NOT EXISTS idx_tokens_symbol ON supported_tokens(symbol);
CREATE INDEX IF NOT EXISTS idx_tokens_order ON supported_tokens(display_order);

-- 创建更新时间触发器
CREATE TRIGGER IF NOT EXISTS update_tokens_timestamp 
    AFTER UPDATE ON supported_tokens
    FOR EACH ROW
BEGIN
    UPDATE supported_tokens SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- 插入初始代币数据（ETH、USDT、USDC、DAI）
INSERT OR IGNORE INTO supported_tokens (
    name, symbol, contract_address, decimals, is_native, icon_url, 
    chain_id, is_active, display_order, description, official_website
) VALUES 
(
    'Ethereum',
    'ETH',
    '0x0000000000000000000000000000000000000000',
    18,
    TRUE,
    'https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/info/logo.png',
    1,
    TRUE,
    1,
    'Ethereum is a decentralized platform for smart contracts',
    'https://ethereum.org'
),
(
    'Tether USD',
    'USDT',
    '0xdAC17F958D2ee523a2206206994597C13D831ec7',
    6,
    FALSE,
    'https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0xdAC17F958D2ee523a2206206994597C13D831ec7/logo.png',
    1,
    TRUE,
    2,
    'Tether USD is a stablecoin pegged to the US Dollar',
    'https://tether.to'
),
(
    'USD Coin',
    'USDC',
    '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
    6,
    FALSE,
    'https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48/logo.png',
    1,
    TRUE,
    3,
    'USD Coin is a fully-backed US dollar stablecoin',
    'https://www.centre.io'
),
(
    'Dai Stablecoin',
    'DAI',
    '0x6B175474E89094C44Da98b954EedeAC495271d0F',
    18,
    FALSE,
    'https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0x6B175474E89094C44Da98b954EedeAC495271d0F/logo.png',
    1,
    TRUE,
    4,
    'Dai is a decentralized stablecoin maintained by MakerDAO',
    'https://makerdao.com'
);

-- 创建代币操作日志表（可选，用于审计）
CREATE TABLE IF NOT EXISTS token_operation_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    token_id INTEGER NOT NULL,
    operation_type VARCHAR(20) NOT NULL, -- 操作类型: CREATE, UPDATE, DELETE, ENABLE, DISABLE
    old_data TEXT DEFAULT NULL,          -- 修改前的数据(JSON格式)
    new_data TEXT DEFAULT NULL,          -- 修改后的数据(JSON格式)
    operator_id VARCHAR(100) DEFAULT NULL, -- 操作者ID
    operation_time DATETIME DEFAULT CURRENT_TIMESTAMP, -- 操作时间
    remark TEXT DEFAULT NULL,            -- 备注
    
    FOREIGN KEY (token_id) REFERENCES supported_tokens(id)
);

-- 创建管理员用户表（简单实现）
CREATE TABLE IF NOT EXISTS admin_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL, -- 密码哈希
    email VARCHAR(100) DEFAULT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login DATETIME DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 插入默认管理员用户（密码: admin123）
INSERT OR IGNORE INTO admin_users (username, password_hash, email) VALUES 
('admin', '$2a$10$ZsB2KgcHw6boD503jOvNtez1xnc5joTRl6d1JNUv5wfF.EOAlDrA2', 'admin@example.com');

-- 查询所有活跃代币的视图
CREATE VIEW IF NOT EXISTS active_tokens_view AS
SELECT 
    id,
    name,
    symbol,
    contract_address,
    decimals,
    is_native,
    icon_url,
    chain_id,
    display_order,
    description,
    official_website
FROM supported_tokens 
WHERE is_active = TRUE 
ORDER BY display_order ASC, created_at ASC;

-- 代币统计视图
CREATE VIEW IF NOT EXISTS token_stats_view AS
SELECT 
    COUNT(*) as total_tokens,
    COUNT(CASE WHEN is_active = TRUE THEN 1 END) as active_tokens,
    COUNT(CASE WHEN is_native = TRUE THEN 1 END) as native_tokens,
    COUNT(CASE WHEN is_native = FALSE THEN 1 END) as erc20_tokens
FROM supported_tokens;