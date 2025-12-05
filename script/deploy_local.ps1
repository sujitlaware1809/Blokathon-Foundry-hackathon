$ErrorActionPreference = "Stop"

$RPC_URL = "http://127.0.0.1:8545"
$PRIVATE_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

Write-Host "Deploying Diamond..." -ForegroundColor Green
# Capture output to find the Diamond address
$deployOutput = forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY 2>&1
$deployOutput | Write-Host

# Parse the Diamond address from the logs
$diamondLine = $deployOutput | Select-String "Diamond deployed to:"
if ($diamondLine) {
    # Extract address (assumes format "Diamond deployed to: 0x...")
    $diamondAddress = $diamondLine.ToString().Split(":")[-1].Trim()
    $env:DIAMOND_ADDRESS = $diamondAddress
    Write-Host "Successfully detected Diamond Address: $diamondAddress" -ForegroundColor Cyan
} else {
    Write-Warning "Could not auto-detect Diamond address. Using default/env if available."
}

Write-Host "Deploying YieldHarvester Facet..." -ForegroundColor Green
forge script script/DeployYieldHarvester.s.sol:DeployYieldHarvesterScript --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY

Write-Host "Deployment Complete!" -ForegroundColor Green
