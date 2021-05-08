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

    describe('Start an agreement', async () => {
        beforeEach(async () => {
            let docs = ['0x0'];
            await arbitrator.openAgreement(tenant, 100, 0, docs, {from: landlord});
        })
        it('declines agreement', async () => {
            await arbitrator.respondToAgreement(0, 2, {from: tenant});
            //declined agreement status
            assert.equal((await arbitrator.agreements(0)).status, 2);
        })
        it('accepts agreement', async() => {
            await arbitrator.respondToAgreement(0, 1, {from: tenant, value: '100'});
            assert.equal(await arbitrator.balances(tenant), 100);
            // consented agreement status
            assert.equal((await arbitrator.agreements(0)).status, 1);
        })
        describe('Start a dispute', async() => {
            beforeEach(async () => {            
                await arbitrator.respondToAgreement(0, 1, {from: tenant, value: '100'});
                await arbitrator.openDispute(0, 100,'0x0', {from: landlord});
            })
            it('tenant declines dispute, will be open to a public vote', async() => {
                await arbitrator.declineDispute(0, '0x0', {from: tenant});
                // voting status
                assert.equal((await arbitrator.disputes(0)).status, 2);
            })
            it('tenant counters dispute', async() => {
                await arbitrator.counterDispute(0, '0x0', 55, {from: tenant});
                assert.equal((await arbitrator.disputes(0)).amount, 55);
                // counter offer status
                assert.equal((await arbitrator.disputes(0)).status, 3);
            })
            it('accept dispute settlement which will incur a transfer of funds and void the agreement', async() => {
                await arbitrator.settleDispute(0, {from: tenant});               
                assert.equal(await arbitrator.balances(tenant), 0);
                assert.equal(await arbitrator.balances(landlord), 100);
                // closed dispute status
                assert.equal((await arbitrator.disputes(0)).status, 1);
                let dispute = await arbitrator.disputes(0);
                // voided agreement status
                assert.equal((await arbitrator.agreements(dispute.agreement)).status, 4)
            })
            describe('Start voting', async() => {
                beforeEach(async() => {            
                    await arbitrator.declineDispute(0, '0x0', {from: tenant});               
                })
                it('vote yee', async() => {
                    await arbitrator.vote(0, true, {from: voter})
                    let votes = await arbitrator.getVotes(0);
                    assert.equal(votes.yees, 1);
                })
                it('vote nay', async() => {
                    await arbitrator.vote(0, false, {from: voter})
                    let votes = await arbitrator.getVotes(0);
                    assert.equal(votes.nays, 1);
                })
                describe('Majority voted yee and voting deadline has expired', async() => {
                    beforeEach(async() => {            
                        await arbitrator.vote(0, true, {from: voter})
                        let votes = await arbitrator.getVotes(0);
                    })
                    it('plantiff completes the voting process, should incur a transfer of funds', async() => {
                        assert.equal(await arbitrator.balances(tenant), 100);
                        assert.equal(await arbitrator.balances(landlord), 0);
                        await arbitrator.votingComplete(0, {from: landlord})
                        assert.equal(await arbitrator.balances(tenant), 0);
                        assert.equal(await arbitrator.balances(landlord), 100); 
                        let dispute = await arbitrator.disputes(0);
                        //closed dispute status
                        assert.equal(await dispute.status, 1);
                        // voided agreement status
                        assert.equal((await arbitrator.agreements(dispute.agreement)).status, 4)
                        
                    })
                })
                describe('Majority voted nay and voting deadline has expired', async() => {
                    beforeEach(async() => {            
                        await arbitrator.vote(0, false, {from: voter})
                        let votes = await arbitrator.getVotes(0);
                    })
                    it('plantiff completes the voting process, a transfer of funds should not occur', async() => {
                        assert.equal(await arbitrator.balances(tenant), 100);
                        assert.equal(await arbitrator.balances(landlord), 0);
                        await arbitrator.votingComplete(0, {from: landlord})
                        assert.equal(await arbitrator.balances(tenant), 100);
                        assert.equal(await arbitrator.balances(landlord), 0);
                        let dispute = await arbitrator.disputes(0);
                        //closed dispute status
                        assert.equal(await dispute.status, 1);
                        // agreement status is not voided
                        assert.equal((await arbitrator.agreements(dispute.agreement)).status, 1)
                        
                    })
                })
            })
        })
    })    
})