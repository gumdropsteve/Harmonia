// contracts/Arbitrator_Schain.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/utils/Address.sol';
import "./utils/Context.sol";
import "./utils/MinterRole.sol";

contract Arbitrator_Schain is Context, MinterRole {
    using Address for address payable;
    address payable private owner;

    uint256 yeeCount;
    uint256 nayCount;

    mapping(address => uint) public balances;

    event Deposit(address sender, uint amount);
    event Withdrawal(address receiver, uint amount);
    event Transfer(address sender, address receiver, uint amount);
    event DisputeOpened(uint256 disputeNumber);
    event VoteCast(uint256 disputeNumber, address voter);

    struct Dispute {
        // the person opening the dispute
        address prosecutor;
        // the defendant of the dispute
        address defendant;
        // the amount in $$ that the prosecutor is requesting in damages
        uint256 amount;
        // response to dispute
        uint256 response;
        // file hash (stored on ipfs) on prosecutor evidence related to the case
        bytes32 prosecutorEvidence;
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
    }
    Dispute[] public disputes;
    uint public totalSupply = 0; // 0 dispute tokens

    enum disputeStatus {PENDING, CLOSED, VOTING} // to do: APPEAL
    enum disputeRulings {PENDING, NOCONTEST, GUILTY, INNOCENT}

    constructor() public {
        owner = msg.sender;
        }
    
    // file a new dispute
    function openDispute(uint256 _compensationRequested, bytes32 _disputeSummary, address _defendant) 
    public returns(uint256 disputeNumber) {
        // set date info
        uint256 today = 0;
        uint256 deadline = today + 3;
        // create new dispute
        Dispute memory d;
        // set parties
        d.prosecutor = msg.sender;
        d.defendant = _defendant;
        // add prosecutor's information
        d.amount = _compensationRequested;
        d.prosecutorEvidence = _disputeSummary;
        // set status and voting details
        d.status = disputeStatus.PENDING;
        d.ruling = disputeRulings.PENDING;
        d.yeeCount = 0;
        d.nayCount = 0;
        d.openDate = today;
        d.voteDeadline = deadline;
        // add dispute to list of disputes
        disputes.push(d);
        // output this dispute's number for reference
        disputeNumber = disputes.length - 1;
        emit DisputeOpened(disputeNumber);
        return disputeNumber;
    }

    // respond to dispute
    // to do: _counterSummary & _comp optional
    function respondToDispute(uint256 disputeNumber, uint256 _response, bytes32 _counterSummary, uint256 _comp)
    public payable primaryParties(disputeNumber) {
        disputes[disputeNumber].response = _response;
        if (_response==0 || _response==1) { // plea: 0 = no contest, 1 = guilty
            settleDispute(disputeNumber, _response);
        }
        else if (_response==2) { // plea: counter
            counterDispute(disputeNumber, _counterSummary, _comp);
        }
        // start vote
        else { // plea: innocent / otherwise
            disputes[disputeNumber].status = disputeStatus.VOTING;
        }
    }

    // settle dispute
    function settleDispute(uint256 disputeNumber, uint256 _response) public payable primaryParties(disputeNumber) {
        // deposit & transfer funds
        deposit();
        transfer(disputes[disputeNumber].prosecutor, disputes[disputeNumber].amount);
        // no contest or guilty ruling
        if (_response==0) {
            disputes[disputeNumber].ruling = disputeRulings.NOCONTEST;
        }
        else {
            disputes[disputeNumber].ruling = disputeRulings.GUILTY;
        }
        // close dispute
        disputes[disputeNumber].status = disputeStatus.CLOSED;
    }

    // counter dispute
    function counterDispute(uint256 disputeNumber, bytes32 _counterSummary, uint256 _comp) public payable primaryParties(disputeNumber) {
        // defense
        disputes[disputeNumber].defendantEvidence = _counterSummary;
        disputes[disputeNumber].amount = _comp;
        // were funds deposited?
        if (msg.value>0) {
            deposit();
            // to do: logic if accepted, if not
        }
    }

    // deposit funds
    // in eth (to do: make match with everything else)
    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
        balances[msg.sender] += msg.value;
    }

    // withdraw funds
    // in wei (limited to int values)
    function withdraw(uint256 weiAmount) public {
        require(balances[msg.sender] >= weiAmount, "Insufficient funds");
        // send funds to requester
        msg.sender.sendValue(weiAmount);
        // adjust balance & tag event
        balances[msg.sender] -= weiAmount;
        emit Withdrawal(msg.sender, weiAmount);
    }

    // transfer funds
    // in wei (limited to int values)
    function transfer(address receiver, uint256 weiAmount) public {
        require(balances[msg.sender] >= weiAmount, "Insufficient funds");
        emit Transfer(msg.sender, receiver, weiAmount);
        balances[msg.sender] -= weiAmount;
        balances[receiver] += weiAmount;
    }

    // vote yee 1 or nay 0
    function vote(uint256 disputeNumber, bool voteCast) public {
        require(disputes[disputeNumber].status==disputeStatus.VOTING, "voting not live :)");
        require(!disputes[disputeNumber].voters[msg.sender], "already voted :)");
        // if voting is live and address hasn't voted yet, count vote  
        if(voteCast) {disputes[disputeNumber].yeeCount++;}
        if(!voteCast) {disputes[disputeNumber].nayCount++;}
        // address has voted, mark them as such
        disputes[disputeNumber].voters[msg.sender] = true;
        emit VoteCast(disputeNumber, msg.sender);
    }

    // outputs current vote counts
    function getVotes(uint256 disputeNumber) public view returns (uint yesVotes, uint noVotes) {
        return(disputes[disputeNumber].yeeCount, disputes[disputeNumber].nayCount);
    }

    // // lets user know if their vote has been counted
    // // status: WIP
    // function haveYouVoted(uint256 disputeNumber) public view returns (bool) {
    //     return disputes[disputeNumber].voters[msg.sender];
    // }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;
        balances[account] += uint96(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        balances[account] = uint96(accountBalance - amount);
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    // for functions that should only be called by prosecutor or defendant
    modifier primaryParties(uint256 disputeNumber) {
        require((msg.sender == disputes[disputeNumber].prosecutor) || (msg.sender == disputes[disputeNumber].defendant));
        _;
    }
}
