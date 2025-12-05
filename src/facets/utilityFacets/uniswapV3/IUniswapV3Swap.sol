// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*###############################################################################

    @title IUniswapV3Swap
    @author BLOK Capital DAO
    @notice Interface for Uniswap V3 swap functionality
    @dev Defines the external functions for swapping tokens via Uniswap V3

    ▗▄▄▖ ▗▖    ▗▄▖ ▗▖ ▗▖     ▗▄▄▖ ▗▄▖ ▗▄▄▖▗▄▄▄▖▗▄▄▄▖▗▄▖ ▗▖       ▗▄▄▄  ▗▄▖  ▗▄▖ 
    ▐▌ ▐▌▐▌   ▐▌ ▐▌▐▌▗▞▘    ▐▌   ▐▌ ▐▌▐▌ ▐▌ █    █ ▐▌ ▐▌▐▌       ▐▌  █▐▌ ▐▌▐▌ ▐▌
    ▐▛▀▚▖▐▌   ▐▌ ▐▌▐▛▚▖     ▐▌   ▐▛▀▜▌▐▛▀▘  █    █ ▐▛▀▜▌▐▌       ▐▌  █▐▛▀▜▌▐▌ ▐▌
    ▐▙▄▞▘▐▙▄▄▖▝▚▄▞▘▐▌ ▐▌    ▝▚▄▄▖▐▌ ▐▌▐▌  ▗▄█▄▖  █ ▐▌ ▐▌▐▙▄▄▖    ▐▙▄▄▀▐▌ ▐▌▝▚▄▞▘


################################################################################*/

/// @notice Swap parameters for exact input swap
struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
}

interface IUniswapV3Swap {
    // ========================================================================
    // Events
    // ========================================================================

    /// @notice Emitted when a swap is executed
    /// @param tokenIn Input token address
    /// @param tokenOut Output token address
    /// @param amountIn Amount of input tokens
    /// @param amountOut Amount of output tokens received
    /// @param fee Pool fee tier
    event SwapExecuted(
        address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut, uint24 fee
    );

    /// @notice Emitted when swap router is updated
    /// @param oldRouter Previous router address
    /// @param newRouter New router address
    event SwapRouterUpdated(address indexed oldRouter, address indexed newRouter);

    // ========================================================================
    // Functions
    // ========================================================================

    /// @notice Initialize the Uniswap V3 swap router
    /// @param swapRouter Address of Uniswap V3 SwapRouter
    function initializeSwapRouter(address swapRouter) external;

    /// @notice Execute a single-hop exact input swap
    /// @param params Swap parameters
    /// @return amountOut Amount of output tokens received
    function swapExactInputSingle(ExactInputSingleParams calldata params) external returns (uint256 amountOut);

    /// @notice Get the current swap router address
    /// @return address of the swap router
    function getSwapRouter() external view returns (address);

    /// @notice Get total swaps executed
    /// @return uint256 total number of swaps
    function getTotalSwaps() external view returns (uint256);
}
