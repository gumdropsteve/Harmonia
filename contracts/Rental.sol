// contracts/SmartRPA.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Rental is ERC721 {
    address payable private owner;
    string public agreement;

    struct Dispute {
        address payable prosecutor;
        address payable defendant;
        uint256 compensationRequested;
        string disputeSummary;
    }
    Dispute[] public disputes;

    constructor() ERC721("Rental", "RENT") public {
        owner = msg.sender;
        }
    
    // file a dispute
    function submitDispute(uint256 _compensationRequested, string memory _disputeSummary) public { 
      disputes.push(Dispute(
        msg.sender,
        msg.sender,
        _compensationRequested,
        _disputeSummary
        ));
    }
}
