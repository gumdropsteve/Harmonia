// contracts/Arbitrator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/utils/Address.sol';
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Token.sol";

contract Arbitrator {
    using Address for address payable;
    using SafeMath for uint256;
    address payable private owner;

    uint256 yeeCount;
    uint256 nayCount;

    mapping(address => uint) public balances;

    event Deposit(address sender, uint amount);
    event Withdrawal(address receiver, uint amount);
    event Transfer(address sender, address receiver, uint amount);
    event DisputeOpened(uint256 disputeNumber, address plantiff, address defendant);
    event DisputeResponded(uint256 disputeNumber, disputeStatus status);
    event AgreementOfferred(uint256 agreementNumber, address offeror, address offeree);
    event AgreementResponded(uint256 agreementNumber, address offeror, address offeree, agreementStatus status);
    event VoteCast(uint256 disputeNumber, address voter);

    struct Agreement {
        // the person providing the offer
        address offeror;
        // the person the offer is made for
        address offeree;
        // deposit amount
        uint amount;
        // agreement expirey date
        uint expireyDate;
        // file hashes of files pertaining to the agreement
        bytes32[] documents;
        // the agreement status
        agreementStatus status;
    }
    Agreement[] public agreements;

    struct Dispute {
        // the person opening the dispute
        address plantiff;
        // the defendant of the dispute
        address defendant;
        // the amount in $$ that the plantiff is requesting in damages
        uint256 amount;
        // response to dispute
        uint256 response;
        // file hash (stored on ipfs) on plantiff evidence related to the case
        bytes32 plantiffEvidence;
        // file hash (stored on ipfs) on defendant evidence related to the case
        bytes32 defendantEvidence;
        // status of the current dispute
        disputeStatus status;
        // status of the current dispute
        disputeRulings ruling;
        // addresses of users that voted
        mapping(address => bool) voters;
        // mapping from address of voters to yes or no
        mapping(address => bool) votedYesOrNo;
        // mapping from voters to hashed vote
        mapping(address => uint256)  votedYesOrNoSecret;
        // number of users that voted yes
        uint yeeCount;
        // number of users that voted no
        uint nayCount;
        // date dispute was opened
        uint256 openDate;
        // deadline to vote
        uint256 voteDeadline;
        // date dispute was closed
        uint256 closeDate;
        // the original agreement
        uint256 agreement;
    }
    Dispute[] public disputes;

    enum disputeStatus {PENDING, CLOSED, VOTING, COUNTER} // to do: APPEAL
    enum disputeRulings {PENDING, NOCONTEST, GUILTY, INNOCENT}
    enum agreementStatus {OPENED, CONSENTED, DECLINED, EXPIRED, VOIDED}

    Token token;

    constructor(Token _token) public {
        owner = msg.sender;
        token = _token;
    }

    /**
    * @notice A method where an offeror can open an agreement targeted at an offeree.
    * @param _offeree The user being offered the agreement.
    * @param _amount The deposit the offeree must provide.
    * @param _expireyDate The date the agreement will expire.
    * @param _documents ipfs file hashes of documents related to the agreement.
    */
    function openAgreement(address _offeree, uint _amount, uint _expireyDate, bytes32[] memory _documents) public returns(uint agreementNumber) {
        Agreement memory agreement;
        agreement.offeror = msg.sender;
        agreement.offeree = _offeree;
        agreement.amount = _amount;
        agreement.expireyDate = _expireyDate;
        agreement.documents = _documents;
        agreements.push(agreement);
        agreementNumber = agreements.length.sub(1);
        emit AgreementOfferred(agreementNumber, msg.sender, _offeree);
        return agreementNumber;
    }

    /**
    * @notice A method where an offeree can respond to an agreement and deposit the appropriate funds
    * @param _agreementNumber the agreement.
    * @param _status The status the agreement will be updated to.
    */
    function respondToAgreement(uint256 _agreementNumber, agreementStatus _status) public payable {
        Agreement memory agreement = agreements[_agreementNumber];
        require(agreement.offeree == msg.sender, 'Must be the offeree to respond');
        if(_status == agreementStatus.CONSENTED) {
            require(agreement.amount <= msg.value, 'must provide agreement amount');
            agreements[_agreementNumber].status = agreementStatus.CONSENTED;
            deposit();
        } else {
            agreements[_agreementNumber].status = agreementStatus.DECLINED;
        }
        emit AgreementResponded(_agreementNumber, agreement.offeror, agreement.offeree, _status);
    }

    /**
    * @notice Ends an agreement, can only be done once expireyDate has passed.
    * @param _agreementNumber the agreement.
    */
    function endAgreement(uint256 _agreementNumber) public {
        require(agreements[_agreementNumber].expireyDate < block.timestamp);
        agreements[_agreementNumber].status = agreementStatus.EXPIRED;
    }
    
    /**
    * @notice open a dispute for an associated agreement.
    * @param _agreementNumber the agreement.
    * @param _compensationRequested compensation requested.
    * @param _disputeSummary ipfs file hashes of documents related to the plantiffs dispute.
    */
    function openDispute(uint256 _agreementNumber, uint256 _compensationRequested, bytes32 _disputeSummary) public returns(uint256 disputeNumber) {
        Agreement memory agreement = agreements[_agreementNumber];
        require(agreement.offeree == msg.sender || agreement.offeror == msg.sender);
        require(agreement.amount >= _compensationRequested);
        // msg.sender is always the plantiff
        // if msg sender is the offeror defendant is offeree, else defendant is offeror
        address _defendant = agreement.offeror == msg.sender ? agreement.offeree : agreement.offeror;
        uint256 today = block.timestamp;
        uint256 deadline = today + 3 minutes;
        // create new dispute
        Dispute memory dispute;
        // set parties
        dispute.plantiff = msg.sender;
        dispute.defendant = _defendant;
        // add plantiff's information
        dispute.amount = _compensationRequested;
        dispute.plantiffEvidence = _disputeSummary;
        // set status and voting details
        dispute.status = disputeStatus.PENDING;
        dispute.ruling = disputeRulings.PENDING;
        dispute.yeeCount = 0;
        dispute.nayCount = 0;
        dispute.openDate = today;
        dispute.voteDeadline = deadline;
        dispute.agreement = _agreementNumber;
        // add dispute to list of disputes
        disputes.push(dispute);
        // output this dispute's number for reference
        disputeNumber = disputes.length.sub(1);
        emit DisputeOpened(disputeNumber, dispute.plantiff, dispute.defendant);
        return disputeNumber;
    }

     /**
    * @notice allows the defendant to decline a dispute settlement. this will go to a public vote.
    * @param _disputeNumber the dispute.
    * @param _defenseSummary ipfs file hashes of documents related to the defendants evidence.
    */
    function declineDispute(uint256 _disputeNumber, bytes32 _defenseSummary) public {
        require(disputes[_disputeNumber].defendant == msg.sender);
        disputes[_disputeNumber].defendantEvidence = _defenseSummary;
        disputes[_disputeNumber].status = disputeStatus.VOTING;
        emit DisputeResponded(_disputeNumber, disputeStatus.VOTING);
    }

    /**
    * @notice allows the defendant to counte a dispute settlement and offer a different compensation amount
    * @param _disputeNumber the dispute.
    * @param _counterSummary ipfs file hashes of documents related to the defendants evidence.
    */
    function counterDispute(uint256 _disputeNumber, bytes32 _counterSummary, uint256 _compensationCounter) public {
        require(disputes[_disputeNumber].defendant == msg.sender);
        disputes[_disputeNumber].defendantEvidence = _counterSummary;
        disputes[_disputeNumber].amount = _compensationCounter;
        disputes[_disputeNumber].status = disputeStatus.COUNTER;
        emit DisputeResponded(_disputeNumber, disputeStatus.COUNTER);
    }

    /**
    * @notice allows the defendant to settle the dispute for the dispute amount. trasnfers funds to plantiff, closes the dispute and voids the original agreement.
    * @param _disputeNumber the dispute.
    */
    function settleDispute(uint256 _disputeNumber) public {
        require(disputes[_disputeNumber].defendant == msg.sender);
        disputes[_disputeNumber].status = disputeStatus.CLOSED;    
        agreements[disputes[_disputeNumber].agreement].status = agreementStatus.VOIDED;
        transfer(disputes[_disputeNumber].plantiff, disputes[_disputeNumber].amount);
        emit DisputeResponded(_disputeNumber, disputeStatus.CLOSED);
    }

     /**
    * @notice allows a user to vote on a dispute. user must have some tokens staked in order to vote
    * @param _disputeNumber the dispute.
    * @param voteCast true for yee, false for nay.
    */
    function vote(uint256 _disputeNumber, bool voteCast) public {
        require(disputes[_disputeNumber].status==disputeStatus.VOTING, "voting not live :)");
        require(!disputes[_disputeNumber].voters[msg.sender], "already voted :)");
        require(block.timestamp < disputes[_disputeNumber].voteDeadline, "voting deadline passed :)");
        require(token.stakeOf(msg.sender) > 0, "must have some Token staked in order to vote");
        // if voting is live and address hasn't voted yet, count vote  
        if(voteCast) {disputes[_disputeNumber].yeeCount = disputes[_disputeNumber].yeeCount.add(1);}
        if(!voteCast) {disputes[_disputeNumber].nayCount = disputes[_disputeNumber].nayCount.add(1);}
        // address has voted, mark them as such
        disputes[_disputeNumber].voters[msg.sender] = true;
        emit VoteCast(_disputeNumber, msg.sender);
        // as an example, lets emit a single Token as a reward for voting
        token.assignRewards(1, msg.sender);
    }

    /**
    * @notice allows current vote count for a given dispute
    * @param _disputeNumber the dispute.
    */
    function getVotes(uint256 _disputeNumber) public view returns (uint yees, uint nays) {
        return(disputes[_disputeNumber].yeeCount, disputes[_disputeNumber].nayCount);
    }

    /**
    * @notice A method to complete the voting process. Only the plantiff should be able to complete the voting process.
    * @param _disputeNumber The dispute number.
    */
    function votingComplete(uint256 _disputeNumber) public {
        Dispute memory dispute = disputes[_disputeNumber];
        // require(dispute.deadline < block.timestamp);
        require(dispute.status == disputeStatus.VOTING);
        require(dispute.plantiff == msg.sender);
        disputes[_disputeNumber].status = disputeStatus.CLOSED;
        // simple majority vote
        if(dispute.yeeCount > dispute.nayCount) {    
            emit Transfer(dispute.defendant, dispute.plantiff, dispute.amount);
            balances[dispute.defendant] = balances[dispute.defendant].sub(dispute.amount);
            balances[dispute.plantiff] = balances[dispute.plantiff].add(dispute.amount);         
            // void agreement
            agreements[disputes[_disputeNumber].agreement].status = agreementStatus.VOIDED;      
        }
         emit DisputeResponded(_disputeNumber, disputeStatus.CLOSED);
    }

     // deposit funds
    // in eth (to do: make match with everything else)
    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
    }

    // withdraw funds
    // in wei (limited to int values)
    function withdraw(uint256 weiAmount) public {
        require(balances[msg.sender] >= weiAmount, "Insufficient funds");
        // send funds to requester
        msg.sender.sendValue(weiAmount);
        // adjust balance & tag event
        balances[msg.sender] = balances[msg.sender].sub(weiAmount);
        emit Withdrawal(msg.sender, weiAmount);
    }

    // transfer funds
    // in wei (limited to int values)
    function transfer(address receiver, uint256 weiAmount) public {
        require(balances[msg.sender] >= weiAmount, "Insufficient funds");
        emit Transfer(msg.sender, receiver, weiAmount);
        balances[msg.sender] = balances[msg.sender].sub(weiAmount);
        balances[receiver] =  balances[receiver].add(weiAmount);
    }

    // // lets user know if their vote has been counted
    // // status: WIP
    // function haveYouVoted(uint256 disputeNumber) public view returns (bool) {
    //     return disputes[disputeNumber].voters[msg.sender];
    // }
}
