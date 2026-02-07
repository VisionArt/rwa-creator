// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.sol";
import { dXAU } from "../src/dXAU.sol";
import { IGetXauReturnTypes } from "../src/interfaces/IGetXauReturnTypes.sol";

contract DeployDXau is Script {
    string constant alpacaMintSource = "./functions/sources/alpacaBalance.js";
    string constant alpacaRedeemSource = "./functions/sources/alpacaBalance.js";

    function run() external {
        // Get params
        IGetXauReturnTypes.GetXauReturnType memory xauReturnType = getdXauRequirements();

        // Actually deploy
        vm.startBroadcast();
        deployDTSLA(
            xauReturnType.subId,
            xauReturnType.mintSource,
            xauReturnType.redeemSource,
            xauReturnType.functionsRouter,
            xauReturnType.donId,
            xauReturnType.xauFeed,
            xauReturnType.usdcFeed,
            xauReturnType.redemptionCoin,
            xauReturnType.secretVersion,
            xauReturnType.secretSlot
        );
        vm.stopBroadcast();
    }

    function getdXauRequirements() public returns (IGetXauReturnTypes.GetXauReturnType memory) {
        HelperConfig helperConfig = new HelperConfig();
        (
            address xauFeed,
            address usdcFeed, /*address ethFeed*/
            ,
            address functionsRouter,
            bytes32 donId,
            uint64 subId,
            address redemptionCoin,
            ,
            ,
            ,
            uint64 secretVersion,
            uint8 secretSlot
        ) = helperConfig.activeNetworkConfig();

        if (
            xauFeed == address(0) || usdcFeed == address(0) || functionsRouter == address(0) || donId == bytes32(0)
                || subId == 0
        ) {
            revert("something is wrong");
        }
        string memory mintSource = vm.readFile(alpacaMintSource);
        string memory redeemSource = vm.readFile(alpacaRedeemSource);
        return IGetXauReturnTypes.GetXauReturnType(
            subId,
            mintSource,
            redeemSource,
            functionsRouter,
            donId,
            xauFeed,
            usdcFeed,
            redemptionCoin,
            secretVersion,
            secretSlot
        );
    }

    function deployDTSLA(
        uint64 subId,
        string memory mintSource,
        string memory redeemSource,
        address functionsRouter,
        bytes32 donId,
        address xauFeed,
        address usdcFeed,
        address redemptionCoin,
        uint64 secretVersion,
        uint8 secretSlot
    )
        public
        returns (dXAU)
    {
        dXAU dXau = new dXAU(
            subId,
            mintSource,
            redeemSource,
            functionsRouter,
            donId,
            xauFeed,
            usdcFeed,
            redemptionCoin,
            secretVersion,
            secretSlot
        );
        return dXau;
    }
}
