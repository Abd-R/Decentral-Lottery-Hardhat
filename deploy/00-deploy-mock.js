const { ethers } = require("ethers");
const { network } = require("hardhat");
// const {developmentChains} = require("../helper-hardhat.config");
/**
 * BASE FEE : Minimum Fee per request. As we are the only ones to requesting the random number
 *            unlike the DATA FEED, which are sponsored, here Only We are requesting the
 *            random number for ourself,
 *            in this case, 0.25 = fee per request
 */           
const BASE_FEE = ethers.utils.parseEther("0.25");

/**
 * Calculated value. Depends on the Gas Price of the Chain.
 * Link per Gas
 * So our nodes dont go bankrupt 
 */
const GAS_PRICE_LINK = 1e9;

module.exports = async ({ getNamedAccounts, deployments }) => {

    const {deploy, log} = deployments;
    const {deployer} = await getNamedAccounts();
    const chainId = network.config.chainId;
    const args = [BASE_FEE, GAS_PRICE_LINK];
    
    if(chainId == "31337"){
        log("Deploying Mock Coordinator")
        await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            args: args,
            log: true
        })
        log("Mock Deployed")
        log("---------------------------------------------------------------------------------------")
    }   
}

module.exports.tags = ["all", "mock"];