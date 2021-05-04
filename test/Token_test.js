const { expectRevert, time } = require('@openzeppelin/test-helpers')
const { assert } = require('chai')


contract('Token', accounts => {
    const Token = artifacts.require('Token')
    const owner = accounts[0]
    const farmer = accounts[1]
    const totalSupply = 1000000;

    beforeEach(async () => {
        token = await Token.new(owner, totalSupply)
    })

    describe('Check stake balance', () => {
        context('Hasnt staked yet', () => {
            it('should equal zero', async () => {
                assert.equal(await token.stakeOf(farmer), 0);
            })
        })

        context('Has  staked', () => {
            beforeEach(async () => {
               await token.transfer(farmer, 100, {from: owner})
               await token.createStake(10, {from: farmer})
            })

            it('should equal 10', async () => {
                assert.equal(await token.stakeOf(farmer), 10);
            })

            it('should be able to unstake', async () => {
                await token.removeStake(10, {from: farmer});
                assert.equal(await token.stakeOf(farmer), 0);
            })
        })
    })

    
})