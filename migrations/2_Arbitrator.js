const Arbitrator = artifacts.require('Arbitrator')
const Token = artifacts.require('Token')
module.exports = async (deployer, network, [defaultAccount]) => {

    const totalSupply = 1000000;
    deployer.deploy(Token, defaultAccount, totalSupply).then(() => { 
        deployer.deploy(Arbitrator, Token.address)
    })
}
