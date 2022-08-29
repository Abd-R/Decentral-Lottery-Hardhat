RAFFLE.

npm i --save-dev hardhat
npm hardhat init
-> empty project 

npm i --save-dev @nomiclabs/hardhat-ethers@npm:hardhat-deploy-ethers ethers @nomiclabs/hardhat-etherscan @nomiclabs/hardhat-waffle chai ethereum-waffle hardhat hardhat-contract-sizer hardhat-deploy hardhat-gas-reporter  solhint solidity-coverage dotenv --force

FUNDME

DEPLOY PRODUCTION

1. Get Subscription Id for chainlinkVRF and fund this id. ()
2. Deploy our contract. Pass this id in constructor
3. Register the contract with Chainlink VRF and its SubId
4. Register the contract with chainLink keepers
5. Run staging test

# WORKING OF CONTRACT

## KeeperCompatible Contract
We want to automate the process of selecting the Winner
So we automate this process via handing it over to the chainlink keepers
We subscribbe to chainlink keepers network by funding it with LINK TOKEN
register our keeper compatible contract. i.e. it implements checkUpkeep and performUpkeep
checkUpkeep returns boolean that fires performUpkeep

## CoordinatorVRF       Verifiably Random Func

FullFillRandomNumber called by RawFullFill returns 
1. a random number
2. a cryptographic proof to generate this random number

This Random Number is returned by a chainLink oracale

We work with chainlink contracts by Request and Recieve cycles

We make 1 Request to Oracle in 1st TX. (Need Link Token, (Oracle Cost))
We receive a response from Oracle in 2nd TX

