const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { query: dbQuery, queryOne, transaction } = require('../database/init');
const router = express.Router();

// 验证中间件
const validateRequest = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'Validation Error',
      details: errors.array()
    });
  }
  next();
};

// GET /api/tokens - 获取所有代币列表
router.get('/', [
  query('active').optional().isBoolean().withMessage('active must be boolean'),
  query('chain_id').optional().isInt({ min: 1 }).withMessage('chain_id must be positive integer'),
  query('page').optional().isInt({ min: 1 }).withMessage('page must be positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit must be between 1-100')
], validateRequest, async (req, res) => {
  try {
    const { active, chain_id, page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;
    
    let sql = 'SELECT * FROM supported_tokens WHERE 1=1';
    const params = [];
    
    if (active !== undefined) {
      sql += ' AND is_active = ?';
      params.push(active === 'true' ? 1 : 0);
    }
    
    if (chain_id) {
      sql += ' AND chain_id = ?';
      params.push(chain_id);
    }
    
    sql += ' ORDER BY display_order ASC, created_at ASC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), parseInt(offset));
    
    const tokens = await dbQuery(sql, params);
    
    // 获取总数
    let countSql = 'SELECT COUNT(*) as total FROM supported_tokens WHERE 1=1';
    const countParams = [];
    
    if (active !== undefined) {
      countSql += ' AND is_active = ?';
      countParams.push(active === 'true' ? 1 : 0);
    }
    
    if (chain_id) {
      countSql += ' AND chain_id = ?';
      countParams.push(chain_id);
    }
    
    const countResult = await queryOne(countSql, countParams);
    
    res.json({
      success: true,
      data: {
        tokens: tokens.map(token => ({
          ...token,
          is_native: Boolean(token.is_native),
          is_active: Boolean(token.is_active)
        })),
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: countResult.total,
          totalPages: Math.ceil(countResult.total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Error fetching tokens:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch tokens'
    });
  }
});

// GET /api/tokens/active - 获取活跃代币列表（前端使用）
router.get('/active', async (req, res) => {
  try {
    const tokens = await dbQuery(`
      SELECT id, name, symbol, contract_address, decimals, is_native, icon_url, chain_id, display_order
      FROM supported_tokens 
      WHERE is_active = 1 
      ORDER BY display_order ASC, created_at ASC
    `);
    
    res.json({
      success: true,
      data: tokens.map(token => ({
        ...token,
        isNative: Boolean(token.is_native)
      }))
    });
  } catch (error) {
    console.error('Error fetching active tokens:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch active tokens'
    });
  }
});

// GET /api/tokens/:id - 获取单个代币详情
router.get('/:id', [
  param('id').isInt({ min: 1 }).withMessage('Token ID must be positive integer')
], validateRequest, async (req, res) => {
  try {
    const { id } = req.params;
    
    const token = await queryOne('SELECT * FROM supported_tokens WHERE id = ?', [id]);
    
    if (!token) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Token not found'
      });
    }
    
    res.json({
      success: true,
      data: {
        ...token,
        is_native: Boolean(token.is_native),
        is_active: Boolean(token.is_active)
      }
    });
  } catch (error) {
    console.error('Error fetching token:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch token'
    });
  }
});

// POST /api/tokens - 创建新代币
router.post('/', [
  body('name').trim().isLength({ min: 1, max: 100 }).withMessage('Name is required and must be max 100 characters'),
  body('symbol').trim().isLength({ min: 1, max: 20 }).withMessage('Symbol is required and must be max 20 characters'),
  body('contract_address').isEthereumAddress().withMessage('Valid Ethereum address required'),
  body('decimals').isInt({ min: 0, max: 18 }).withMessage('Decimals must be between 0-18'),
  body('is_native').optional().isBoolean().withMessage('is_native must be boolean'),
  body('icon_url').optional().isURL().withMessage('Icon URL must be valid URL'),
  body('chain_id').optional().isInt({ min: 1 }).withMessage('Chain ID must be positive integer'),
  body('description').optional().trim().isLength({ max: 1000 }).withMessage('Description must be max 1000 characters'),
  body('official_website').optional().isURL().withMessage('Official website must be valid URL'),
  body('display_order').optional().isInt({ min: 0 }).withMessage('Display order must be non-negative integer')
], validateRequest, async (req, res) => {
  try {
    const {
      name, symbol, contract_address, decimals, is_native = false,
      icon_url, chain_id = 1, description, official_website, display_order = 0
    } = req.body;
    
    // 检查是否已存在相同合约地址或符号
    const existing = await queryOne(`
      SELECT id FROM supported_tokens 
      WHERE (contract_address = ? OR symbol = ?) AND chain_id = ?
    `, [contract_address, symbol, chain_id]);
    
    if (existing) {
      return res.status(409).json({
        error: 'Conflict',
        message: 'Token with this contract address or symbol already exists on this chain'
      });
    }
    
    const result = await dbQuery(`
      INSERT INTO supported_tokens (
        name, symbol, contract_address, decimals, is_native, 
        icon_url, chain_id, description, official_website, display_order
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [name, symbol, contract_address, decimals, is_native ? 1 : 0, 
        icon_url, chain_id, description, official_website, display_order]);
    
    const newToken = await queryOne('SELECT * FROM supported_tokens WHERE id = ?', [result.lastID]);
    
    res.status(201).json({
      success: true,
      message: 'Token created successfully',
      data: {
        ...newToken,
        is_native: Boolean(newToken.is_native),
        is_active: Boolean(newToken.is_active)
      }
    });
  } catch (error) {
    console.error('Error creating token:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to create token'
    });
  }
});

// PUT /api/tokens/:id - 更新代币信息
router.put('/:id', [
  param('id').isInt({ min: 1 }).withMessage('Token ID must be positive integer'),
  body('name').optional().trim().isLength({ min: 1, max: 100 }).withMessage('Name must be max 100 characters'),
  body('symbol').optional().trim().isLength({ min: 1, max: 20 }).withMessage('Symbol must be max 20 characters'),
  body('contract_address').optional().isEthereumAddress().withMessage('Valid Ethereum address required'),
  body('decimals').optional().isInt({ min: 0, max: 18 }).withMessage('Decimals must be between 0-18'),
  body('is_native').optional().isBoolean().withMessage('is_native must be boolean'),
  body('icon_url').optional().isURL().withMessage('Icon URL must be valid URL'),
  body('description').optional().trim().isLength({ max: 1000 }).withMessage('Description must be max 1000 characters'),
  body('official_website').optional().isURL().withMessage('Official website must be valid URL'),
  body('display_order').optional().isInt({ min: 0 }).withMessage('Display order must be non-negative integer')
], validateRequest, async (req, res) => {
  try {
    const { id } = req.params;
    
    // 检查代币是否存在
    const existingToken = await queryOne('SELECT * FROM supported_tokens WHERE id = ?', [id]);
    if (!existingToken) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Token not found'
      });
    }
    
    const updateFields = [];
    const updateValues = [];
    
    Object.keys(req.body).forEach(key => {
      if (req.body[key] !== undefined) {
        updateFields.push(`${key} = ?`);
        updateValues.push(key === 'is_native' ? (req.body[key] ? 1 : 0) : req.body[key]);
      }
    });
    
    if (updateFields.length === 0) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'No fields to update'
      });
    }
    
    updateValues.push(id);
    
    await dbQuery(`
      UPDATE supported_tokens 
      SET ${updateFields.join(', ')} 
      WHERE id = ?
    `, updateValues);
    
    const updatedToken = await queryOne('SELECT * FROM supported_tokens WHERE id = ?', [id]);
    
    res.json({
      success: true,
      message: 'Token updated successfully',
      data: {
        ...updatedToken,
        is_native: Boolean(updatedToken.is_native),
        is_active: Boolean(updatedToken.is_active)
      }
    });
  } catch (error) {
    console.error('Error updating token:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to update token'
    });
  }
});

// PATCH /api/tokens/:id/toggle - 切换代币激活状态
router.patch('/:id/toggle', [
  param('id').isInt({ min: 1 }).withMessage('Token ID must be positive integer')
], validateRequest, async (req, res) => {
  try {
    const { id } = req.params;
    
    const token = await queryOne('SELECT * FROM supported_tokens WHERE id = ?', [id]);
    if (!token) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Token not found'
      });
    }
    
    const newStatus = token.is_active ? 0 : 1;
    
    await dbQuery('UPDATE supported_tokens SET is_active = ? WHERE id = ?', [newStatus, id]);
    
    const updatedToken = await queryOne('SELECT * FROM supported_tokens WHERE id = ?', [id]);
    
    res.json({
      success: true,
      message: `Token ${newStatus ? 'activated' : 'deactivated'} successfully`,
      data: {
        ...updatedToken,
        is_native: Boolean(updatedToken.is_native),
        is_active: Boolean(updatedToken.is_active)
      }
    });
  } catch (error) {
    console.error('Error toggling token status:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to toggle token status'
    });
  }
});

// DELETE /api/tokens/:id - 删除代币（软删除，设置为不活跃）
router.delete('/:id', [
  param('id').isInt({ min: 1 }).withMessage('Token ID must be positive integer')
], validateRequest, async (req, res) => {
  try {
    const { id } = req.params;
    
    const token = await queryOne('SELECT * FROM supported_tokens WHERE id = ?', [id]);
    if (!token) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Token not found'
      });
    }
    
    // 软删除 - 设置为不活跃状态
    await dbQuery('UPDATE supported_tokens SET is_active = 0 WHERE id = ?', [id]);
    
    res.json({
      success: true,
      message: 'Token deactivated successfully'
    });
  } catch (error) {
    console.error('Error deleting token:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to delete token'
    });
  }
});

// GET /api/tokens/stats - 获取代币统计信息
router.get('/stats/overview', async (req, res) => {
  try {
    const stats = await queryOne(`
      SELECT 
        COUNT(*) as total_tokens,
        COUNT(CASE WHEN is_active = 1 THEN 1 END) as active_tokens,
        COUNT(CASE WHEN is_native = 1 THEN 1 END) as native_tokens,
        COUNT(CASE WHEN is_native = 0 THEN 1 END) as erc20_tokens
      FROM supported_tokens
    `);
    
    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Error fetching token stats:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch token statistics'
    });
  }
});

module.exports = router;