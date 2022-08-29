

const { developmentChains, networkConfig, VERIFICATION_BLOCK_CONFIRMATIONS } = require('../helper-hardhat.config');
const { network, ethers } = require('hardhat');
const {verify} = require("../utils/verify");

const VRF_SUB_FUND_AMOUNT = ethers.utils.parseEther("2");   // LINK ETHERS

module.exports = async function ({ getNamedAccounts, deployments }) {

    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId = network.config.chainId;
    let vrfCoordinatorV2Address;
    let subscriptionId;

    if (chainId == "31337") {
        const vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock");
        vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address;
        // CREATING SUBSCRIPTION: Calling method in this contract
        const txResponse = await vrfCoordinatorV2Mock.createSubscription();
        const txReceipt = await txResponse.wait();
        subscriptionId = txReceipt.events[0].args.subId;
        // FUND THE SUBSCRIPTION
        await vrfCoordinatorV2Mock.fundSubscription(subscriptionId, VRF_SUB_FUND_AMOUNT);
    } else {
        vrfCoordinatorV2Address = networkConfig[chainId]["vrfCoordinatorV2"];
        subscriptionId = networkConfig[chainId]["subscriptionId"];
    }

    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : VERIFICATION_BLOCK_CONFIRMATIONS

    // args
    const interval = "30";  // seconds 
    const callbackGasLimit = networkConfig[chainId]["callbackGasLimit"];
    const entranceFee = networkConfig[chainId]["entranceFee"];
    const gasLane = networkConfig[chainId]["gasLane"];

    const args = [
        entranceFee,
        vrfCoordinatorV2Address,
        gasLane,
        subscriptionId,
        callbackGasLimit,
        interval
    ];
    // if (developmentChains.includes(network.name)) {
    //     await vrfCoordinatorV2Mock.addConsumer(subscriptionId.toNumber(), raffle.address)
    // }

    const raffle = await deploy("Raffle", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: waitBlockConfirmations
    })


    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying------------")

        await verify(raffle.address, args);
        log("Verified");
    }
}

module.exports.tags = ["all", "raffle"];