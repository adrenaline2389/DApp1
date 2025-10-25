@echo off
echo ========================================
echo.
echo     MAINNET DEPLOYMENT
echo.
echo ========================================
echo.
echo This script will deploy TransferContract to the Ethereum Mainnet.
echo This will cost REAL ETH.
echo.

REM Safety Check: Ensure .env file has the mainnet key
set "found=0"
for /f "usebackq delims=" %%x in (".env") do (
    echo "%%x" | find "MAINNET_PRIVATE_KEY=" >nul
    if not errorlevel 1 set found=1
)

if %found%==0 (
    echo ERROR: MAINNET_PRIVATE_KEY not found in your .env file.
    echo Please add it before proceeding.
    pause
    exit /b 1
)

echo INFO: MAINNET_PRIVATE_KEY found.
echo.
echo FINAL WARNING: You have 10 seconds to cancel this deployment by pressing Ctrl+C.
timeout /t 10

echo.
echo Starting Mainnet Deployment...
echo.

forge script script/DeployMainnet.s.sol --rpc-url mainnet --broadcast --verify -vvvv

if %errorlevel% neq 0 (
    echo.
    echo DEPLOYMENT FAILED. Check the error messages above.
) else (
    echo.
    echo DEPLOYMENT SUCCESSFUL!
)

echo.
pause
