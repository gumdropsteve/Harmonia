const { expectRevert, time } = require('@openzeppelin/test-helpers')
const { assert } = require('chai')


contract('Arbitrator', accounts => {
    const Arbitrator = artifacts.require('Arbitrator')
    const Token = artifacts.require('Token')
    const owner = accounts[0];
    const landlord = accounts[1];
    const tenant = accounts[2];
    const voter = accounts[3];
    const totalSupply = 1000000;

    beforeEach(async () => {
        token = await Token.new(owner, totalSupply);   
        arbitrator = await Arbitrator.new(token.address);

        // transfer token ownership to arbitrator so only it can emit rewards
        token.transferOwnership(arbitrator.address, {from: owner});
        
        await token.transfer(voter, 100, {from: owner})
        await token.createStake(10, {from: voter})
    })

    describe('Start a dispute', () => {
        beforeEach(async () => {
            await arbitrator.openDispute(100,'0x111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFFCCCC',tenant, {from: landlord});
            await arbitrator.respondToDispute(0, 3, '0x111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFFCCCC', 0, {from: tenant})
        })
        context('Dispute is live for voting', () => {
            it('voter votes guilty', async () => {
                await arbitrator.vote(0, true, {from: voter});
                var votes = await arbitrator.getVotes(0);
                assert.equal(votes.yesVotes, 1);
                assert.equal(votes.noVotes, 0);

                // should have received a reward
                assert.equal(await token.rewardOf(voter), 1);
            })
            it('votes changes vote to innocent', async () => {
                await arbitrator.vote(0, false, {from: voter});
                var votes = await arbitrator.getVotes(0);
                assert.equal(votes.yesVotes, 0);
                assert.equal(votes.noVotes, 1);

                // should have received a reward
                assert.equal(await token.rewardOf(voter), 1);
            })
        })
    })

    
})