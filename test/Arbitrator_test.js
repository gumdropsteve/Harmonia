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
        arbitrator = await Arbitrator.new({from: owner})
    })

    describe('Start a dispute', () => {
        beforeEach(async () => {
            arbitrator = await Arbitrator.new({from: owner})
            await arbitrator.openDispute(100,'0x111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFFCCCC',tenant, {from: landlord});
            await arbitrator.respondToDispute(0, 3, '0x111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFFCCCC', 0, {from: tenant})
        })
        context('Dispute is live for voting', () => {
            it('voter votes guilty', async () => {
                await arbitrator.vote(0, true, {from: voter});
                var votes = await arbitrator.getVotes(0);
                assert.equal(votes.yesVotes, 1);
                assert.equal(votes.noVotes, 0);
            })
            it('votes changes vote to innocent', async () => {
                await arbitrator.vote(0, false, {from: voter});
                var votes = await arbitrator.getVotes(0);
                assert.equal(votes.yesVotes, 0);
                assert.equal(votes.noVotes, 1);
            })
        })
    })

    
})