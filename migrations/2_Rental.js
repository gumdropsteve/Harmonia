const Rental = artifacts.require('Rental')

module.exports = async (deployer, network, [defaultAccount]) => {
    deployer.deploy(Rental)
}
