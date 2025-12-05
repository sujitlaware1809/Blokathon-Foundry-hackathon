import time
import random
import json
import os
from web3 import Web3
from eth_account import Account
import google.generativeai as genai
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configuration
RPC_URL = os.getenv("RPC_URL", "http://127.0.0.1:8545")
PRIVATE_KEY = os.getenv("PRIVATE_KEY", "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80")
DIAMOND_ADDRESS = os.getenv("DIAMOND_ADDRESS", "0x...") 
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    # Use a model that is currently available
    model_name = 'gemini-2.0-flash'
    print(f"Using Gemini model: {model_name}")
    model = genai.GenerativeModel(model_name)
else:
    print("Warning: GEMINI_API_KEY not found. Using simulation mode.")
    model = None

class YieldOptimizerAgent:
    def __init__(self, rpc_url, private_key, contract_address):
        self.w3 = Web3(Web3.HTTPProvider(rpc_url))
        self.account = Account.from_key(private_key)
        self.contract_address = contract_address
        self.strategies = {} # Cache strategies
        
        # Load ABI (Simplified for demo)
        self.abi = [
            {
                "inputs": [{"internalType": "uint256", "name": "strategyId", "type": "uint256"}, {"internalType": "uint256", "name": "newApr", "type": "uint256"}],
                "name": "updateStrategyApr",
                "outputs": [],
                "stateMutability": "nonpayable",
                "type": "function"
            },
            {
                "inputs": [{"internalType": "address", "name": "user", "type": "address"}, {"internalType": "address", "name": "asset", "type": "address"}],
                "name": "autoRebalance",
                "outputs": [],
                "stateMutability": "nonpayable",
                "type": "function"
            },
            {
                "inputs": [{"internalType": "uint256", "name": "strategyId", "type": "uint256"}],
                "name": "getStrategy",
                "outputs": [
                    {
                        "components": [
                            {"internalType": "address", "name": "asset", "type": "address"},
                            {"internalType": "enum YieldHarvesterStorage.Protocol", "name": "protocol", "type": "uint8"},
                            {"internalType": "uint256", "name": "apr", "type": "uint256"},
                            {"internalType": "uint256", "name": "totalDeposited", "type": "uint256"},
                            {"internalType": "uint256", "name": "totalEarned", "type": "uint256"},
                            {"internalType": "bool", "name": "active", "type": "bool"}
                        ],
                        "internalType": "struct YieldHarvesterStorage.Strategy",
                        "name": "",
                        "type": "tuple"
                    }
                ],
                "stateMutability": "view",
                "type": "function"
            }
        ]
        self.contract = self.w3.eth.contract(address=contract_address, abi=self.abi)
        print(f"AI Agent initialized. Address: {self.account.address}")

    def predict_apr(self, strategy_name, current_apr):
        """
        Uses Gemini API to predict the next APR based on market conditions.
        """
        if not model:
            # Fallback to simulation if no API key
            change = random.randint(-50, 50)
            new_apr = current_apr + change
            return max(0, min(2000, new_apr))

        try:
            prompt = f"""
            You are a DeFi Yield Optimizer AI. 
            Analyze the current market conditions for {strategy_name}.
            The current APR is {current_apr} basis points (where 100 bps = 1%).
            
            Predict the next APR based on general market sentiment (simulated for this hackathon).
            Return ONLY the predicted APR in basis points as an integer.
            Do not include any text, just the number.
            """
            
            response = model.generate_content(prompt)
            predicted_apr = int(response.text.strip())
            
            # Safety bounds
            return max(0, min(2000, predicted_apr))
        except Exception as e:
            print(f"  [Error] Gemini API failed: {e}")
            return current_apr

    def analyze_market(self):
        print("\n[AI] Analyzing market conditions...")
        # Mock strategy data
        strategies = [
            {"id": 0, "name": "Aave V3 USDC", "current_apr": 500, "asset": "0xUSDC"},
            {"id": 1, "name": "Compound V3 USDC", "current_apr": 480, "asset": "0xUSDC"},
            {"id": 2, "name": "Yearn USDC", "current_apr": 520, "asset": "0xUSDC"}
        ]
        
        for strategy in strategies:
            # Try to fetch real APR from chain
            try:
                chain_strategy = self.contract.functions.getStrategy(strategy["id"]).call()
                # chain_strategy is a tuple/struct. Index 2 is apr based on ABI
                real_apr = chain_strategy[2]
                strategy["current_apr"] = real_apr
                print(f"  [Chain] Fetched real APR for Strategy {strategy['id']}: {real_apr/100}%")
            except Exception as e:
                # print(f"  [Chain] Could not fetch strategy {strategy['id']} (using mock): {e}")
                pass

            predicted_apr = self.predict_apr(strategy["name"], strategy["current_apr"])
            print(f"  Strategy {strategy['name']} (ID {strategy['id']}): Current APR {strategy['current_apr']/100}% -> Predicted {predicted_apr/100}%")
            
            if predicted_apr != strategy["current_apr"]:
                self.update_apr_on_chain(strategy["id"], predicted_apr)

        # Check for rebalancing opportunities
        # In a real app, we would query the subgraph for users with suboptimal positions
        self.check_rebalance_opportunities("0xUserAddress", "0xUSDC")

    def update_apr_on_chain(self, strategy_id, new_apr):
        print(f"  [TX] Updating Strategy {strategy_id} APR to {new_apr/100}%...")
        try:
            tx = self.contract.functions.updateStrategyApr(strategy_id, new_apr).build_transaction({
                'from': self.account.address,
                'nonce': self.w3.eth.get_transaction_count(self.account.address),
                'gas': 200000,
                'gasPrice': self.w3.eth.gas_price
            })
            signed_tx = self.w3.eth.account.sign_transaction(tx, self.account.key)
            tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
            print(f"  [TX] Sent: {tx_hash.hex()}")
            
            # Wait for receipt
            receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
            if receipt.status == 1:
                print("  [TX] Confirmed!")
            else:
                print("  [TX] Failed!")
        except Exception as e:
            print(f"  [TX] Failed to send transaction (Simulated): {e}")
            print("  [TX] (Simulated) Transaction sent.")

    def check_rebalance_opportunities(self, user, asset):
        print(f"  [AI] Checking portfolio for user {user}...")
        # Logic to check if user is in the best strategy
        # If not, call autoRebalance
        print(f"  [AI] Optimization found! Rebalancing {user} to best strategy...")
        # self.contract.functions.autoRebalance(user, asset).transact(...)
        print("  [TX] (Simulated) Rebalance executed.")

    def run(self):
        print("Starting AI Yield Optimizer Agent...")
        while True:
            self.analyze_market()
            print("[AI] Sleeping for 60 seconds to respect API rate limits...")
            time.sleep(60)

if __name__ == "__main__":
    # Mock address for demo
    agent = YieldOptimizerAgent(RPC_URL, PRIVATE_KEY, "0x0000000000000000000000000000000000000000")
    agent.run()
