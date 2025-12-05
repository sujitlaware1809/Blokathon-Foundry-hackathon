# AI Yield Optimizer Agent

This module contains the off-chain AI agent responsible for optimizing yields in the YieldHarvester protocol.

## Features

1.  **Market Analysis**: Continuously monitors market conditions (simulated) to predict future APRs for supported strategies.
2.  **Dynamic Parameter Tuning**: Automatically updates the on-chain APRs of strategies based on predictions.
3.  **Auto-Rebalancing**: Identifies users in sub-optimal strategies and automatically moves their funds to the highest-yielding strategy for their asset.

## How it Works

The agent is a Python script that interacts with the `YieldHarvesterFacet` smart contract.

1.  **Predict**: Uses a stochastic model (Random Walk with Mean Reversion) to simulate APR fluctuations.
2.  **Update**: Calls `updateStrategyApr(strategyId, newApr)` on the contract.
3.  **Optimize**: Calls `autoRebalance(user, asset)` to move funds.

## Setup

1.  Install dependencies:
    ```bash
    pip install -r requirements.txt
    ```

2.  Configure the agent:
    - Copy `.env.example` to `.env`.
    - Add your `GEMINI_API_KEY` (Get one from [Google AI Studio](https://makersuite.google.com/app/apikey)).
    - Update `RPC_URL` and `DIAMOND_ADDRESS` in `.env`.

3.  Run the agent:
    ```bash
    python ai_yield_optimizer.py
    ```

## Smart Contract Integration

The `YieldHarvesterFacet` has been updated with:
- `setAiAgent(address)`: Assigns the AI agent role.
- `autoRebalance(user, asset)`: Allows the agent to rebalance user portfolios.
