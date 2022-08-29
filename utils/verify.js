const { run } = require("hardhat")

const verify = async (contractAddress, args) => {
    try {
        await run("verify:verify", {
            address: contractAddress,
            constructorArguements: args
        })
    } catch (ex) {
        if(ex.message.toLowerCase().includes("already verified")){
            console.log("Already Verified");
        }else{
            console.log(ex);
        }
    }
}
module.exports = {verify};