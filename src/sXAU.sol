// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {OracleLib, AggregatorV3Interface} from "./libraries/OracleLib.sol";

/*
 * @dev the codebase will mint sXAU based on the collateral 
 * deposited into this contract. In our example, ETH is the
 * collateral that we will use to mint sXAU.
 * 
 * This codebase is NOT COMPLETE
 * 
 * As far as the incentives to do this, people who want to 
 * short tesla and long eth would have the incentive to do this. 
 */
contract sXAU is ERC20 {
    using OracleLib for AggregatorV3Interface;

    error sXAU_feeds__InsufficientCollateral();

    // These both have 8 decimal places for Polygon
    // https://docs.chain.link/data-feeds/price-feeds/addresses?network=polygon
    address private i_xauFeed;
    address private i_ethUsdFeed;
    uint256 public constant DECIMALS = 8;
    uint256 public constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 public constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // This means you need to be 200% over-collateralized
    uint256 private constant LIQUIDATION_BONUS = 10; // This means you get assets at a 10% discount when liquidating
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;

    mapping(address user => uint256 xauMinted) public s_xauMintedPerUser;
    mapping(address user => uint256 ethCollateral) public s_ethCollateralPerUser;

    constructor(address xauFeed, address ethUsdFeed) ERC20("Synthetic Tesla (Feeds)", "sXAU") {
        i_xauFeed = xauFeed;
        i_ethUsdFeed = ethUsdFeed;
    }

    /* 
     * @dev User must deposit at least 200% of the value of the sXAU they want to mint
     */
    function depositAndmint(uint256 amountToMint) external payable {
        // Checks / Effects
        s_ethCollateralPerUser[msg.sender] += msg.value;
        s_xauMintedPerUser[msg.sender] += amountToMint;
        uint256 healthFactor = getHealthFactor(msg.sender);
        if (healthFactor < MIN_HEALTH_FACTOR) {
            revert sXAU_feeds__InsufficientCollateral();
        }
        _mint(msg.sender, amountToMint);
        // No external interactions
    }

    function redeemAndBurn(uint256 amountToRedeem) external {
        // Checks / Effects
        uint256 valueRedeemed = getUsdAmountFromXau(amountToRedeem);
        uint256 ethToReturn = getEthAmountFromUsd(valueRedeemed);
        s_xauMintedPerUser[msg.sender] -= amountToRedeem;
        s_ethCollateralPerUser[msg.sender] -= ethToReturn;
        uint256 healthFactor = getHealthFactor(msg.sender);
        if (healthFactor < MIN_HEALTH_FACTOR) {
            revert sXAU_feeds__InsufficientCollateral();
        }
        _burn(msg.sender, amountToRedeem);
        // External
        (bool success,) = msg.sender.call{value: ethToReturn}("");
        if (!success) {
            revert("sXAU_feeds: transfer failed");
        }
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW AND PURE
    //////////////////////////////////////////////////////////////*/
    function getHealthFactor(address user) public view returns (uint256) {
        (uint256 totalXauMintedValueInUsd, uint256 totalCollateralEthValueInUsd) = getAccountInformationValue(user);
        return _calculateHealthFactor(totalXauMintedValueInUsd, totalCollateralEthValueInUsd);
    }

    function getUsdAmountFromXau(uint256 amountXauInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(i_xauFeed);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        return (amountXauInWei * (uint256(price) * ADDITIONAL_FEED_PRECISION)) / PRECISION;
    }

    function getUsdAmountFromEth(uint256 ethAmountInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(i_ethUsdFeed);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        return (ethAmountInWei * (uint256(price) * ADDITIONAL_FEED_PRECISION)) / PRECISION;
    }

    function getEthAmountFromUsd(uint256 usdAmountInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(i_ethUsdFeed);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        return (usdAmountInWei * PRECISION) / ((uint256(price) * ADDITIONAL_FEED_PRECISION) * PRECISION);
    }

    function getAccountInformationValue(address user)
        public
        view
        returns (uint256 totalXauMintedValueUsd, uint256 totalCollateralValueUsd)
    {
        (uint256 totalXauMinted, uint256 totalCollateralEth) = _getAccountInformation(user);
        totalXauMintedValueUsd = getUsdAmountFromXau(totalXauMinted);
        totalCollateralValueUsd = getUsdAmountFromEth(totalCollateralEth);
    }

    function _calculateHealthFactor(uint256 xauMintedValueUsd, uint256 collateralValueUsd)
        internal
        pure
        returns (uint256)
    {
        if (xauMintedValueUsd == 0) return type(uint256).max;
        uint256 collateralAdjustedForThreshold = (collateralValueUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / xauMintedValueUsd;
    }

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalXauMinted, uint256 totalCollateralEth)
    {
        totalXauMinted = s_xauMintedPerUser[user];
        totalCollateralEth = s_ethCollateralPerUser[user];
    }
}
