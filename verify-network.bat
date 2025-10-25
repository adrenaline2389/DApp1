@echo off
echo Verifying Sepolia Network Configuration...
echo.

REM Check if .env file exists
if not exist .env (
    echo Warning: .env file not found!
    echo Please copy .env.example to .env and fill in your API keys.
    echo.
)

REM Test Foundry installation
echo Checking Foundry installation...
forge --version >nul 2>&1
if errorlevel 1 (
    echo Error: Foundry not found! Please install Foundry first.
    echo Visit: https://book.getfoundry.sh/getting-started/installation
    pause
    exit /b 1
) else (
    forge --version
    echo Foundry installation OK!
)

echo.
echo Testing network connectivity...

REM Test Sepolia RPC connection
echo Testing Sepolia RPC connection...
cast client --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo >nul 2>&1
if errorlevel 1 (
    echo Warning: Could not connect to Sepolia RPC
    echo Please check your internet connection and API key
) else (
    echo Sepolia RPC connection OK!
)

echo.
echo Checking Foundry configuration...
if exist foundry.toml (
    echo foundry.toml found - OK!
    echo Validating configuration...
    forge config >nul 2>&1
    if errorlevel 1 (
        echo Warning: foundry.toml configuration has issues
    ) else (
        echo Configuration validation passed!
    )
) else (
    echo Error: foundry.toml not found!
)

echo.
echo Checking project structure...
if exist src (echo src/ directory - OK!) else (echo Error: src/ directory missing!)
if exist test (echo test/ directory - OK!) else (echo Error: test/ directory missing!)
if exist script (echo script/ directory - OK!) else (echo Error: script/ directory missing!)
if exist lib (echo lib/ directory - OK!) else (echo Error: lib/ directory missing!)

echo.
echo Checking dependencies...
if exist lib\forge-std (
    echo forge-std dependency - OK!
) else (
    echo Warning: forge-std dependency missing
    echo Run: forge install foundry-rs/forge-std --no-commit
)

if exist lib\openzeppelin-contracts (
    echo OpenZeppelin dependency - OK!
) else (
    echo Warning: OpenZeppelin dependency missing
    echo Run: forge install OpenZeppelin/openzeppelin-contracts --no-commit
)

echo.
echo Testing contract compilation...
forge build >nul 2>&1
if errorlevel 1 (
    echo Error: Contract compilation failed!
    echo Run 'forge build' to see detailed errors
) else (
    echo Contract compilation - OK!
)

echo.
if exist .env (
    echo Checking environment variables...
    
    REM Load and check environment variables
    for /f "usebackq tokens=1,* delims==" %%i in (".env") do (
        if "%%i"=="PRIVATE_KEY" (
            if "%%j"=="" (
                echo Error: PRIVATE_KEY not set
            ) else (
                echo PRIVATE_KEY - OK!
            )
        )
        if "%%i"=="ALCHEMY_API_KEY" (
            if "%%j"=="" (
                echo Error: ALCHEMY_API_KEY not set
            ) else (
                echo ALCHEMY_API_KEY - OK!
            )
        )
        if "%%i"=="ETHERSCAN_API_KEY" (
            if "%%j"=="" (
                echo Warning: ETHERSCAN_API_KEY not set (needed for verification)
            ) else (
                echo ETHERSCAN_API_KEY - OK!
            )
        )
    )
)

echo.
echo ===========================================
echo Network Configuration Verification Complete
echo ===========================================
echo.
echo Next steps:
echo 1. If any errors found, fix them before deployment
echo 2. Get Sepolia testnet ETH from faucet
echo 3. Run deploy-sepolia.bat to deploy contracts
echo.
pause