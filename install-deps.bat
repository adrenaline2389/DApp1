@echo off
echo Installing Foundry dependencies...

echo Installing OpenZeppelin contracts...
forge install OpenZeppelin/openzeppelin-contracts --no-commit

echo Installing Forge Standard Library...
forge install foundry-rs/forge-std --no-commit

echo Dependencies installed successfully!
echo Run 'forge build' to compile contracts
pause