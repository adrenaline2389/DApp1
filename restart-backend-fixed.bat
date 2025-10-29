@echo off
echo Stopping Node.js processes...
taskkill /F /IM node.exe 2>nul
echo Waiting for processes to stop...
timeout /t 3 /nobreak >nul

echo Starting backend server with new configuration...
cd backend
start "Backend Server" node server.js

echo Backend server is starting...
echo Rate limit has been increased to 1000 requests per minute
echo You can now access:
echo - Main DApp: http://localhost:5173
echo - Admin Panel: http://localhost:3001/admin
echo - API Health: http://localhost:3001/api/health
pause