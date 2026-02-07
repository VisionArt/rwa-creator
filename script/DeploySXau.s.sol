// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.sol";
import { sXAU } from "../src/sXAU.sol";

contract DeploySXau is Script {
    function run() external {
        // Get params
        (address xauFeed, address ethFeed) = getdXauRequirements();

        // Actually deploy
        vm.startBroadcast();
        deploySXAU(xauFeed, ethFeed);
        vm.stopBroadcast();
    }

    function getdXauRequirements() public returns (address, address) {
        HelperConfig helperConfig = new HelperConfig();
        (address xauFeed,, address ethFeed,,,,,,,,,) = helperConfig.activeNetworkConfig();

        if (xauFeed == address(0) || ethFeed == address(0)) {
            revert("something is wrong");
        }
        return (xauFeed, ethFeed);
    }

    function deploySXAU(address xauFeed, address ethFeed) public returns (sXAU) {
        return new sXAU(xauFeed, ethFeed);
    }
}
