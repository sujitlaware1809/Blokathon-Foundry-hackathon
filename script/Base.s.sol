// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

contract BaseScript is Script {
    address internal deployer;
    bytes32 internal salt;

    modifier broadcaster() {
        vm.startBroadcast(deployer);
        _;
        vm.stopBroadcast();
    }

    function setUp() public virtual {
        uint256 privateKey;
        if (block.chainid == 31337) {
            privateKey = uint256(vm.envBytes32("PRIVATE_KEY_ANVIL"));
        } else {
            privateKey = vm.envUint("PRIVATE_KEY");
        }
        deployer = vm.rememberKey(privateKey);
        salt = vm.envBytes32("SALT");
    }
}
