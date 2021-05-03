const Token = artifacts.require('Token')

module.exports = async (deployer, network, [defaultAccount]) => {
    deployer.deploy(Token)
}
