@echo off
echo Deploying to Sepolia Testnet...
echo.

REM Check if .env file exists
if not exist .env (
    echo Error: .env file not found!
    echo Please copy .env.example to .env and fill in your API keys and private key.
    pause
    exit /b 1
)

REM Load environment variables
echo Loading environment variables...
for /f "usebackq tokens=1,* delims==" %%i in (".env") do (
    set "%%i=%%j"
)

REM Verify required environment variables
if "%PRIVATE_KEY%"=="" (
    echo Error: PRIVATE_KEY not set in .env file
    pause
    exit /b 1
)

if "%ALCHEMY_API_KEY%"=="" (
    echo Error: ALCHEMY_API_KEY not set in .env file
    pause
    exit /b 1
)

echo.
echo Building contracts...
forge build

if errorlevel 1 (
    echo Build failed! Please check for compilation errors.
    pause
    exit /b 1
)

echo.
echo Running tests before deployment...
forge test

if errorlevel 1 (
    echo Tests failed! Please fix tests before deploying.
    pause
    exit /b 1
)

echo.
echo Deploying to Sepolia testnet...
echo Please confirm deployment details:
echo - Network: Sepolia Testnet (Chain ID: 11155111)
echo - RPC URL: https://eth-sepolia.g.alchemy.com/v2/%ALCHEMY_API_KEY%
echo.
set /p confirm="Do you want to proceed with deployment? (y/N): "

if /i not "%confirm%"=="y" (
    echo Deployment cancelled.
    pause
    exit /b 0
)

echo.
echo Starting deployment...
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify -vvvv

if errorlevel 1 (
    echo Deployment failed! Please check the error messages above.
    pause
    exit /b 1
)

echo.
echo Deployment completed successfully!
echo.
echo Next steps:
echo 1. Save the contract addresses from the output above
echo 2. Fund the contracts with test ETH if needed
echo 3. Test the contracts using the provided scripts
echo.
pause