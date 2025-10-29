const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

const DB_PATH = path.join(__dirname, '../../database/tokens.db');
const SCHEMA_PATH = path.join(__dirname, '../../database/schema.sql');

// 确保数据库目录存在
const ensureDirectoryExists = (dirPath) => {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
};

// 创建数据库连接
const createConnection = () => {
  ensureDirectoryExists(path.dirname(DB_PATH));
  return new sqlite3.Database(DB_PATH, (err) => {
    if (err) {
      console.error('❌ Error opening database:', err.message);
      throw err;
    }
    console.log('📄 Connected to SQLite database at:', DB_PATH);
  });
};

// 初始化数据库
const initDatabase = async () => {
  return new Promise((resolve, reject) => {
    const db = createConnection();
    
    // 读取SQL schema文件
    const schemaSQL = fs.readFileSync(SCHEMA_PATH, 'utf8');
    
    // 执行SQL语句
    db.exec(schemaSQL, (err) => {
      if (err) {
        console.error('❌ Error initializing database:', err.message);
        db.close();
        reject(err);
      } else {
        console.log('✅ Database schema initialized successfully');
        db.close();
        resolve();
      }
    });
  });
};

// 获取数据库连接实例
const getDatabase = () => {
  return createConnection();
};

// 执行查询的通用方法
const query = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    const db = getDatabase();
    
    if (sql.trim().toLowerCase().startsWith('select')) {
      // SELECT查询
      db.all(sql, params, (err, rows) => {
        db.close();
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    } else {
      // INSERT, UPDATE, DELETE查询
      db.run(sql, params, function(err) {
        db.close();
        if (err) {
          reject(err);
        } else {
          resolve({
            lastID: this.lastID,
            changes: this.changes
          });
        }
      });
    }
  });
};

// 执行单条查询
const queryOne = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    const db = getDatabase();
    
    db.get(sql, params, (err, row) => {
      db.close();
      if (err) {
        reject(err);
      } else {
        resolve(row);
      }
    });
  });
};

// 执行事务
const transaction = async (operations) => {
  return new Promise((resolve, reject) => {
    const db = getDatabase();
    
    db.serialize(() => {
      db.run('BEGIN TRANSACTION');
      
      const results = [];
      
      const executeNext = (index) => {
        if (index >= operations.length) {
          db.run('COMMIT', (err) => {
            db.close();
            if (err) {
              reject(err);
            } else {
              resolve(results);
            }
          });
          return;
        }
        
        const { sql, params } = operations[index];
        
        if (sql.trim().toLowerCase().startsWith('select')) {
          db.all(sql, params || [], (err, rows) => {
            if (err) {
              db.run('ROLLBACK');
              db.close();
              reject(err);
            } else {
              results.push(rows);
              executeNext(index + 1);
            }
          });
        } else {
          db.run(sql, params || [], function(err) {
            if (err) {
              db.run('ROLLBACK');
              db.close();
              reject(err);
            } else {
              results.push({
                lastID: this.lastID,
                changes: this.changes
              });
              executeNext(index + 1);
            }
          });
        }
      };
      
      executeNext(0);
    });
  });
};

module.exports = {
  initDatabase,
  getDatabase,
  query,
  queryOne,
  transaction
};