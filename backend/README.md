# Token Management Backend API

代币管理系统的后端API服务，基于Express.js和SQLite构建。

## 🚀 快速开始

### 1. 安装依赖
```bash
cd backend
npm install
```

### 2. 初始化数据库
```bash
npm run init-db
```

### 3. 启动服务器
```bash
# 开发环境
npm run dev

# 生产环境
npm start
```

服务器将在 `http://localhost:3001` 启动

## 📁 项目结构

```
backend/
├── database/           # 数据库相关
│   └── init.js        # 数据库初始化和连接
├── routes/            # API路由
│   ├── tokens.js      # 代币管理路由
│   └── auth.js        # 身份验证路由
├── scripts/           # 脚本工具
│   └── initDatabase.js # 数据库初始化脚本
├── server.js          # 主服务器文件
├── package.json       # 项目配置
└── .env              # 环境变量配置
```

## 🔧 API 接口文档

### 代币管理接口

#### 获取活跃代币列表 (前端使用)
```http
GET /api/tokens/active
```

响应示例：
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Ethereum",
      "symbol": "ETH",
      "contract_address": "0x0000000000000000000000000000000000000000",
      "decimals": 18,
      "isNative": true,
      "icon_url": "https://...",
      "chain_id": 1,
      "display_order": 1
    }
  ]
}
```

#### 获取所有代币列表 (管理后台使用)
```http
GET /api/tokens?active=true&page=1&limit=50
```

#### 创建新代币
```http
POST /api/tokens
Content-Type: application/json

{
  "name": "Test Token",
  "symbol": "TEST",
  "contract_address": "0x1234567890123456789012345678901234567890",
  "decimals": 18,
  "is_native": false,
  "icon_url": "https://example.com/icon.png",
  "description": "Test token description",
  "official_website": "https://example.com"
}
```

#### 更新代币信息
```http
PUT /api/tokens/:id
Content-Type: application/json

{
  "name": "Updated Token Name",
  "display_order": 5
}
```

#### 切换代币状态
```http
PATCH /api/tokens/:id/toggle
```

#### 删除代币 (软删除)
```http
DELETE /api/tokens/:id
```

### 身份验证接口

#### 管理员登录
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "admin123"
}
```

#### 获取用户信息
```http
GET /api/auth/profile
Authorization: Bearer <token>
```

## 🗄️ 数据库结构

### supported_tokens 表
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 主键 |
| name | VARCHAR(100) | 代币名称 |
| symbol | VARCHAR(20) | 代币符号 |
| contract_address | VARCHAR(42) | 合约地址 |
| decimals | INTEGER | 精度 |
| is_native | BOOLEAN | 是否为原生代币 |
| icon_url | VARCHAR(255) | 图标URL |
| chain_id | INTEGER | 链ID |
| is_active | BOOLEAN | 是否启用 |
| display_order | INTEGER | 显示顺序 |

## 🔐 默认管理员账户

- **用户名**: admin
- **密码**: admin123

⚠️ **重要**: 生产环境下请立即修改默认密码！

## 🛡️ 安全特性

- JWT身份验证
- 密码哈希加密
- 输入验证和净化
- SQL注入防护
- CORS配置
- 速率限制
- Helmet安全头

## 📊 健康检查

```http
GET /api/health
```

## 🔧 环境变量配置

主要环境变量说明：

- `PORT`: 服务器端口 (默认: 3001)
- `JWT_SECRET`: JWT密钥
- `FRONTEND_URL`: 前端URL (CORS)
- `NODE_ENV`: 环境 (development/production)

## 🐛 调试和日志

开发环境下，API会输出详细的错误信息和调试日志。

## 📝 使用示例

### 从前端获取代币列表
```javascript
// 前端代码示例
const fetchTokens = async () => {
  try {
    const response = await fetch('http://localhost:3001/api/tokens/active');
    const result = await response.json();
    if (result.success) {
      setTokens(result.data);
    }
  } catch (error) {
    console.error('Failed to fetch tokens:', error);
  }
};
```

### 管理员添加新代币
```javascript
// 管理后台代码示例
const addToken = async (tokenData) => {
  try {
    const response = await fetch('http://localhost:3001/api/tokens', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify(tokenData)
    });
    const result = await response.json();
    return result;
  } catch (error) {
    console.error('Failed to add token:', error);
  }
};
```

## 🚀 部署注意事项

1. 修改默认JWT密钥
2. 设置强密码策略
3. 配置HTTPS
4. 设置数据库备份
5. 配置日志记录
6. 设置监控和报警

## 📞 支持

如有问题，请检查：
1. 数据库是否正确初始化
2. 环境变量是否正确配置
3. 端口是否被占用
4. 前端CORS配置是否正确