const { ethers, network } = require("hardhat")

const fs = require("fs")

const CONTRACT_ADDRESS_FILE = "C:\\DISK W\\Blockchain Course\\Raffle Full-Stack\\frontend\\constants\\address.json"
const ABI_FILE = "C:\\DISK W\\Blockchain Course\\Raffle Full-Stack\\frontend\\constants\\abi.json"

module.exports = async function () {
    if (!process.env.UPDATE_FRONT_END)
        return
    console.log("Updating Front End")
    await updateContractAddress()
    await updateABI()
}


async function updateContractAddress( ) {
    const Raffle = await ethers.getContract("Raffle")
    const chainId = network.config.chainId.toString()
    const currentAddress = JSON.parse(fs.readFileSync(CONTRACT_ADDRESS_FILE, "utf-8"))
    
    if (chainId in currentAddress)
        if(!currentAddress[chainId].includes(Raffle.address))
            currentAddress[chainId].push(Raffle.address)
        
    currentAddress[chainId] = [Raffle.address]
    fs.writeFileSync(CONTRACT_ADDRESS_FILE, JSON.stringify(currentAddress))
}
async function updateABI() {
    const Raffle = await ethers.getContract("Raffle")
    fs.writeFileSync(ABI_FILE, Raffle.interface.format(ethers.utils.FormatTypes.json))
}

module.exports.tags = ["all", "frontend"]