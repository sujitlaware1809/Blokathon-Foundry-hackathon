// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*###############################################################################

    @title UniswapV3SwapStorage
    @author BLOK Capital DAO
    @notice Storage library for Uniswap V3 swap facet using Diamond Storage pattern
    @dev Uses namespaced storage to prevent collisions with other facets

    ▗▄▄▖ ▗▖    ▗▄▖ ▗▖ ▗▖     ▗▄▄▖ ▗▄▖ ▗▄▄▖▗▄▄▄▖▗▄▄▄▖▗▄▖ ▗▖       ▗▄▄▄  ▗▄▖  ▗▄▖ 
    ▐▌ ▐▌▐▌   ▐▌ ▐▌▐▌▗▞▘    ▐▌   ▐▌ ▐▌▐▌ ▐▌ █    █ ▐▌ ▐▌▐▌       ▐▌  █▐▌ ▐▌▐▌ ▐▌
    ▐▛▀▚▖▐▌   ▐▌ ▐▌▐▛▚▖     ▐▌   ▐▛▀▜▌▐▛▀▘  █    █ ▐▛▀▜▌▐▌       ▐▌  █▐▛▀▜▌▐▌ ▐▌
    ▐▙▄▞▘▐▙▄▄▖▝▚▄▞▘▐▌ ▐▌    ▝▚▄▄▖▐▌ ▐▌▐▌  ▗▄█▄▖  █ ▐▌ ▐▌▐▙▄▄▖    ▐▙▄▄▀▐▌ ▐▌▝▚▄▞▘


################################################################################*/

library UniswapV3SwapStorage {
    /// @notice Storage position using EIP-1967 style storage slot
    bytes32 constant STORAGE_POSITION = keccak256("blokcapital.uniswapv3swap.storage");

    /// @notice Storage layout for Uniswap V3 swap functionality
    struct Layout {
        /// @notice Uniswap V3 SwapRouter address
        address swapRouter;
        /// @notice Mapping to track allowed tokens for swapping
        mapping(address => bool) allowedTokens;
        /// @notice Total number of swaps executed
        uint256 totalSwaps;
        /// @notice Total volume in USD (18 decimals)
        uint256 totalVolumeUsd;
    }

    /// @notice Returns the storage layout
    /// @return l Storage layout struct
    function layout() internal pure returns (Layout storage l) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            l.slot := position
        }
    }
}
