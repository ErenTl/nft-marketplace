const NftMarketPlace = artifacts.require("../contracts/NftMarketPlace.sol");

module.exports = function (deployer) {
  deployer.deploy(NftMarketPlace);
};
