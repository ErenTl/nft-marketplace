const { networks } = require("../truffle-config");
const fs = require("fs");

var NftMarketPlace = artifacts.require("../contracts/NftMarketPlace.sol");

const frontEndContractsFile = "../next-js/constants/networkMapping.json";

module.exports = async function(deployer) {
    // if(!process.env.IS_FRONT_END_UP_TO_DATE) {
    if(true) {
        console.log("Updating frontend...");
        await updateContractAddresses();
        //process.env.IS_FRONT_END_UP_TO_DATE = true;
    }
}

async function updateContractAddresses() {
    const networkIds = Object.keys(NftMarketPlace.networks);
    var networkId = 0;
    console.log("deneme:: " + NftMarketPlace["networks"]["5777"]["address"]);
    for (var key in networkIds ) {
        console.log("key: " + key + "| networkId: " + networkIds[key] + " | address: " + NftMarketPlace.address);
        if(NftMarketPlace["networks"][networkIds[key]]["address"].includes(NftMarketPlace.address)){
            networkId = networkIds[key];
        }
    }
    console.log("network id: " + networkId);
    const contractAddresses = JSON.parse(fs.readFileSync(frontEndContractsFile, "utf8"));

    if(networkId in contractAddresses) {
        if(!contractAddresses[networkId]["NftMarketPlace"].includes(NftMarketPlace.address)) {
            contractAddresses[networkId]["NftMarketPlace"] = NftMarketPlace.address;
        } 
    } else {
        contractAddresses[networkId] = {NftMarketPlace: [NftMarketPlace.address]};
    }
    fs.writeFileSync(frontEndContractsFile, JSON.stringify(contractAddresses));
}

module.exports.tag = ["all", "frontend"];