const { initDatabase } = require('../database/init');

// 数据库初始化脚本
const runInit = async () => {
  try {
    console.log('🔄 Initializing database...');
    await initDatabase();
    console.log('✅ Database initialization completed successfully!');
    console.log('📄 Database file created at: ../database/tokens.db');
    console.log('🔑 Default admin user: admin / admin123');
    process.exit(0);
  } catch (error) {
    console.error('❌ Database initialization failed:', error);
    process.exit(1);
  }
};

runInit();