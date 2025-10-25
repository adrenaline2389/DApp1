@echo off
echo Running comprehensive test suite for Transfer Contract...
echo.

echo Installing dependencies (if not already installed)...
call install-deps.bat

echo.
echo Compiling contracts...
forge build

if errorlevel 1 (
    echo Build failed! Please check for compilation errors.
    pause
    exit /b 1
)

echo.
echo Running all tests...
forge test -vv

echo.
echo Running tests with gas reporting...
forge test --gas-report

echo.
echo Running coverage report...
forge coverage

echo.
echo Test execution completed!
pause