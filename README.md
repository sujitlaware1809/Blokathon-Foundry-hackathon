# Yield Harvester

## 1. Executive Summary
The **Yield Harvester** is a next-generation DeFi wealth-optimization protocol built for the **Blok-a-Thon Hackathon**. It leverages the **Diamond Standard (EIP-2535)** for modularity and upgradeability, combined with an **off-chain AI agent** powered by **Google Gemini** to dynamically optimize yield strategies.

Unlike traditional static yield aggregators, this protocol continuously monitors market conditions and automatically reallocates user funds across supported strategies (Aave V3, Compound V3, Yearn) to achieve the best possible APY.

## 2. System Architecture
The platform consists of two major layers: **On-Chain Smart Contracts** and an **Off-Chain AI Agent**.

### A. On-Chain: Diamond Proxy (EIP-2535)
The Diamond Pattern enables modular features and bypasses contract size limits.

**Components:**
*   **Diamond Contract**: Main entry point delegating calls to facets.
*   **YieldHarvesterFacet**: Core business logic containing:
    *   `deposit()` / `withdraw()`: User funds management
    *   `harvest()`: Yield claiming
    *   `autoRebalance()`: AI-authorized capital reallocation
    *   `updateStrategyApr()`: Demo APR updater
*   **YieldHarvesterStorage**: Diamond Storage library tracking:
    *   User balances and positions
    *   Active yield strategies (Aave, Compound, Yearn)
    *   Authorized AI agent address

### B. Off-Chain: AI Agent
A Python-driven autonomous agent acting as the protocol’s decision-maker.

**Responsibilities:**
*   **Market Analysis**: Uses Gemini 2.0 Flash to analyze sentiment and forecast APR trends.
*   **Decision Engine**: Compares projected returns across strategies.
*   **Execution Pipeline**:
    *   Updates APRs on-chain
    *   Detects users in sub-optimal strategies
    *   Triggers `autoRebalance` via secure signer

## 3. Key Features

### 🤖 AI-Driven Optimization
*   **Predictive modeling** forecasts APR trends instead of reacting only to current data.
*   **Automatic rebalancing** handles withdraw–swap–redeposit flow without user involvement.

### 💎 Modular Architecture (Diamond Standard)
*   **Upgradable and extensible**: New strategies can be added as facets.
*   **Gas-efficient** due to modularized logic and shared storage.

### 🛡️ Security
*   **Role-based access** ensures only the AI agent can update APRs or trigger rebalancing.
*   **Non-Reentrant**: All external functions include reentrancy protection.

## 4. Technical Stack
*   **Smart Contracts**: Solidity 0.8.20, Foundry
*   **Architecture**: EIP-2535 Diamond Standard
*   **AI Engine**: Python + Google Generative AI (Gemini 2.0 Flash)
*   **Blockchain Interface**: Web3.py
*   **Target Network**: Arbitrum

## 5. Project Structure
```
Blokathon-Foundry-hackathon/
├── src/
│   ├── Diamond.sol
│   └── facets/
│       └── utilityFacets/
│           └── YieldHarvester/
│               ├── YieldHarvesterFacet.sol
│               ├── YieldHarvesterStorage.sol
│               └── IYieldHarvester.sol
├── script/
│   ├── Deploy.s.sol
│   └── DeployYieldHarvester.s.sol
├── ai_agent/
│   ├── ai_yield_optimizer.py
│   └── requirements.txt
└── test/
    └── YieldHarvester.t.sol
```

---

## 📚 Understanding Diamond Proxy (EIP-2535)

The **Diamond Proxy** pattern allows a single contract to use multiple implementation contracts (facets) through delegatecall. This enables:

- **Modularity**: Add, replace, or remove functionality without redeploying everything
- **Unlimited Contract Size**: Bypass the 24KB contract size limit
- **Shared State**: All facets share the same storage
- **Upgradeability**: Upgrade parts of your system independently

### Key Concepts

- **Diamond**: The main proxy contract that delegates calls to facets
- **Facets**: Implementation contracts containing specific functionality
- **Function Selectors**: 4-byte identifiers mapping functions to their respective facets
- **DiamondCut**: The mechanism for adding/replacing/removing facets

**Resources:**
- [EIP-2535 Specification](https://eips.ethereum.org/EIPS/eip-2535)
- [Diamond Standard Documentation](https://eip2535diamonds.substack.com/)

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Basic understanding of Solidity
- Git installed

### 1. Fork and Clone the Repository

```bash
# Fork this repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/Blokathon-Foundry.git
cd Blokathon-Foundry

# Install dependencies
forge install
```

### 2. Set Up Environment Variables

```bash
# Copy the example environment file
cp .envExample .env

# Edit .env with your credentials
nano .env  # or use your preferred editor
```

**`.env` file structure:**
```bash
PRIVATE_KEY_ANVIL=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
RPC_URL_ANVIL=http://127.0.0.1:8545

# For deploying to real networks
PRIVATE_KEY=your_private_key_here
RPC_URL_ARBITRUM=https://arb1.arbitrum.io/rpc
RPC_URL_POLYGON=https://polygon-rpc.com
RPC_URL_AVALANCHE=https://api.avax.network/ext/bc/C/rpc
RPC_URL_BASE=https://mainnet.base.org
RPC_URL_BSC=https://bsc-dataseed.binance.org

# Etherscan API keys for verification
API_KEY_ETHERSCAN=your_etherscan_api_key
API_KEY_ARBISCAN=your_arbiscan_api_key
API_KEY_POLYGONSCAN=your_polygonscan_api_key
API_KEY_SNOWTRACE=your_snowtrace_api_key
API_KEY_BASESCAN=your_basescan_api_key
API_KEY_BSCSCAN=your_bscscan_api_key
```

### 3. Load Environment Variables

```bash
source .env
```

---

## 🛠️ Foundry Commands

### Build Contracts

```bash
forge build
```

### Run Tests

```bash
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test testFunctionName
```

### Format Code

```bash
forge fmt
```

### Gas Snapshots

```bash
forge snapshot
```

### Clean Build Artifacts

```bash
forge clean
```

---

## 🌐 Deployment

### Deploy to Local Anvil (for testing)

**Terminal 1 - Start Anvil:**
```bash
anvil
```

**Terminal 2 - Deploy Diamond:**
```bash
source .env

forge script script/Deploy.s.sol \
  --rpc-url $RPC_URL_ANVIL \
  --private-key $PRIVATE_KEY_ANVIL \
  --broadcast
```

**Important:** If you use a different private key variable name in your `.env`, update the corresponding line in `script/Deploy.s.sol`:

```solidity
bytes32 privateKey = vm.envBytes32("YOUR_PRIVATE_KEY_NAME");
```

### Deploy to Mainnet/Testnet

```bash
source .env

forge script script/Deploy.s.sol \
  --rpc-url $RPC_URL_ARBITRUM \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --slow \
  --etherscan-api-key $API_KEY_ARBISCAN
```

Replace `$RPC_URL_ARBITRUM` and `$API_KEY_ARBISCAN` with the appropriate variables for your target chain:
- Polygon: `$RPC_URL_POLYGON`, `$API_KEY_POLYGONSCAN`
- Avalanche: `$RPC_URL_AVALANCHE`, `$API_KEY_SNOWTRACE`
- Base: `$RPC_URL_BASE`, `$API_KEY_BASESCAN`
- BSC: `$RPC_URL_BSC`, `$API_KEY_BSCSCAN`

### Verification Failed? Resume Verification

If deployment succeeds but Etherscan verification fails:

```bash
forge script script/Deploy.s.sol \
  --rpc-url $RPC_URL_ARBITRUM \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --slow \
  --resume \
  --etherscan-api-key $API_KEY_ARBISCAN
```

### Deploy Additional Facets

After the Diamond is deployed, you can add new facets:

```bash
forge script script/DeployFacet.s.sol \
  --rpc-url $RPC_URL_ANVIL \
  --private-key $PRIVATE_KEY_ANVIL \
  --broadcast
```

---

## 📁 Repository Structure

```
Blokathon-Foundry/
├── src/
│   ├── Diamond.sol                # Main Diamond proxy contract
│   ├── facets/
│   │   ├── Facet.sol              # Base facet contract
│   │   ├── baseFacets/            # Core Diamond facets
│   │   │   ├── cut/               # DiamondCut functionality
│   │   │   ├── loupe/             # DiamondLoupe for introspection
│   │   │   └── ownership/         # Ownership management
│   │   └── utilityFacets/         # Your custom facets go here!
│   ├── interfaces/                # Interface definitions
│   └── libraries/                 # Shared libraries
├── script/
│   ├── Deploy.s.sol               # Diamond deployment script
│   ├── DeployFacet.s.sol          # Facet deployment script
│   └── Base.s.sol                 # Base script utilities
├── test/                          # Test files
├── .envExample                    # Example environment variables
└── README.md                      # This file
```

---

## 💡 Building Your Facet

### Step 1: Create Your Facet Files

Create four files in `src/facets/utilityFacets/`:

1. **`YourFacetStorage.sol`** - Storage struct
2. **`IYourFacet.sol`** - Interface
3. **`YourFacetBase.sol`** - Internal logic
4. **`YourFacet.sol`** - Public-facing facet

### Step 2: Example Facet Structure

**YourFacetStorage.sol:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library YourFacetStorage {
    bytes32 constant STORAGE_POSITION = keccak256("your.facet.storage");
    
    struct Layout {
        mapping(address => uint256) balances;
        uint256 totalSupply;
    }
    
    function layout() internal pure returns (Layout storage l) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            l.slot := position
        }
    }
}
```

**IYourFacet.sol:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IYourFacet {
    function yourFunction() external returns (uint256);
}
```

**YourFacetBase.sol:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./YourFacetStorage.sol";

contract YourFacetBase {
    function _yourInternalLogic() internal view returns (uint256) {
        YourFacetStorage.Layout storage l = YourFacetStorage.layout();
        return l.totalSupply;
    }
}
```

**YourFacet.sol:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Facet.sol";
import "./YourFacetBase.sol";
import "./IYourFacet.sol";

contract YourFacet is Facet, YourFacetBase, IYourFacet {
    function yourFunction() external override returns (uint256) {
        return _yourInternalLogic();
    }
}
```

### Step 3: Test Your Facet

Create a test file in `test/`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Diamond.sol";
import "../src/facets/utilityFacets/YourFacet.sol";

contract YourFacetTest is Test {
    Diamond diamond;
    YourFacet yourFacet;
    
    function setUp() public {
        // Deploy and configure diamond
        diamond = new Diamond(address(this));
        yourFacet = new YourFacet();
        
        // Add facet to diamond using DiamondCut
        // ... (cut logic here)
    }
    
    function testYourFunction() public {
        // Your test logic
    }
}
```

### Step 4: Deploy Your Facet

Update `script/DeployFacet.s.sol` with your facet's deployment logic, then run:

```bash
forge script script/DeployFacet.s.sol \
  --rpc-url $RPC_URL_ANVIL \
  --private-key $PRIVATE_KEY_ANVIL \
  --broadcast
```

---

## 🧪 Interacting with Cast

### Query Diamond Functions

```bash
# Get all facets
cast call $DIAMOND_ADDRESS "facets()" --rpc-url $RPC_URL_ANVIL

# Get facet address for a function
cast call $DIAMOND_ADDRESS "facetAddress(bytes4)" $FUNCTION_SELECTOR --rpc-url $RPC_URL_ANVIL

# Call your custom function
cast call $DIAMOND_ADDRESS "yourFunction()" --rpc-url $RPC_URL_ANVIL
```

### Send Transactions

```bash
cast send $DIAMOND_ADDRESS "yourFunction(uint256)" 100 \
  --private-key $PRIVATE_KEY_ANVIL \
  --rpc-url $RPC_URL_ANVIL
```

---

## 📖 Helpful Resources

- **Foundry Book**: https://book.getfoundry.sh/
- **EIP-2535 Diamond Standard**: https://eips.ethereum.org/EIPS/eip-2535
- **Diamond Pattern Guide**: https://eip2535diamonds.substack.com/
- **Solidity Documentation**: https://docs.soliditylang.org/

---

## 🏆 Hackathon Tips

1. **Start Simple**: Begin with a basic facet and iterate
2. **Read EIP-2535**: Understanding the Diamond pattern is crucial
3. **Use Storage Properly**: Each facet should use namespaced storage to avoid collisions
4. **Test Thoroughly**: Write comprehensive tests for your facet
5. **Focus on Wealth Management**: Build tools that help users grow and preserve assets
6. **Consider Security**: Use OpenZeppelin libraries when possible
7. **Document Your Code**: Clear comments help judges understand your work

---

## 🤝 Getting Help

- Review existing facets in `src/facets/` for examples
- Check the Foundry documentation for tooling questions
- Study the Diamond proxy implementation in `src/Diamond.sol`

---
