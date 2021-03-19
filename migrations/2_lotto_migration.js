const Lotto = artifacts.require("Lotto");

module.exports = function (deployer) {
    deployer.deploy(Lotto);
};
