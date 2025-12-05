-include .env

.PHONY: all test clean deploy-anvil deploy-base-sepolia deploy-arbitrum-sepolia deploy-arbitrum-diamond deploy-arbitrum-facet

all: clean remove install update build

# Clean the repo
clean :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Install the Modules
install :; forge install foundry-rs/forge-std --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit && forge install openzeppelin/openzeppelin-contracts-upgradeable --no-commit && forge install aave/aave-v3-core --no-commit && forge install aave/v3-core --no-commit && forge install aave/v3-periphery --no-commit && forge install PaulRBerg/prb-test --no-commit

# Update Dependencies
update:; forge update

# Build
build:; forge build

# Test
test :; forge test

# Deploy to Anvil (Local)
deploy-anvil:
	@echo "Deploying Diamond..."
	@forge script script/Deploy.s.sol:DeployScript --rpc-url $(RPC_URL_ANVIL) --broadcast --private-key $(PRIVATE_KEY_ANVIL)
	@echo "Deploying YieldHarvester Facet..."
	@forge script script/DeployYieldHarvester.s.sol:DeployYieldHarvesterScript --rpc-url $(RPC_URL_ANVIL) --broadcast --private-key $(PRIVATE_KEY_ANVIL)

# Deploy to Base Sepolia (Step 1: Diamond)
deploy-base-sepolia-diamond:
	@echo "Deploying Diamond to Base Sepolia..."
	@forge script script/Deploy.s.sol:DeployScript --rpc-url $(RPC_URL_BASE_SEPOLIA) --broadcast --private-key $(PRIVATE_KEY) --verify --etherscan-api-key $(BASESCAN_API_KEY)

# Deploy to Base Sepolia (Step 2: Facet - Set DIAMOND_ADDRESS in .env first!)
deploy-base-sepolia-facet:
	@echo "Deploying YieldHarvester Facet to Base Sepolia..."
	@forge script script/DeployYieldHarvester.s.sol:DeployYieldHarvesterScript --rpc-url $(RPC_URL_BASE_SEPOLIA) --broadcast --private-key $(PRIVATE_KEY) --verify --etherscan-api-key $(BASESCAN_API_KEY)

# Deploy to Arbitrum Sepolia (Step 1: Diamond)
deploy-arbitrum-sepolia-diamond:
	@echo "Deploying Diamond to Arbitrum Sepolia..."
	@forge script script/Deploy.s.sol:DeployScript --rpc-url $(RPC_URL_ARBITRUM_SEPOLIA) --broadcast --private-key $(PRIVATE_KEY) --verify --etherscan-api-key $(ARBISCAN_API_KEY)

# Deploy to Arbitrum Sepolia (Step 2: Facet - Set DIAMOND_ADDRESS in .env first!)
deploy-arbitrum-sepolia-facet:
	@echo "Deploying YieldHarvester Facet to Arbitrum Sepolia..."
	@forge script script/DeployYieldHarvester.s.sol:DeployYieldHarvesterScript --rpc-url $(RPC_URL_ARBITRUM_SEPOLIA) --broadcast --private-key $(PRIVATE_KEY) --verify --etherscan-api-key $(ARBISCAN_API_KEY)

# Deploy to Arbitrum One (Mainnet) (Step 1: Diamond)
deploy-arbitrum-diamond:
	@echo "Deploying Diamond to Arbitrum One..."
	@forge script script/Deploy.s.sol:DeployScript --rpc-url $(RPC_URL_ARBITRUM_ONE) --broadcast --private-key $(PRIVATE_KEY) --verify --etherscan-api-key $(ARBISCAN_API_KEY)

# Deploy to Arbitrum One (Mainnet) (Step 2: Facet - Set DIAMOND_ADDRESS in .env first!)
deploy-arbitrum-facet:
	@echo "Deploying YieldHarvester Facet to Arbitrum One..."
	@forge script script/DeployYieldHarvester.s.sol:DeployYieldHarvesterScript --rpc-url $(RPC_URL_ARBITRUM_ONE) --broadcast --private-key $(PRIVATE_KEY) --verify --etherscan-api-key $(ARBISCAN_API_KEY)
