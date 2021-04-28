const Arbitrator = artifacts.require('Arbitrator')

module.exports = async (deployer, network, [defaultAccount]) => {
    deployer.deploy(Arbitrator)
}
