pragma solidity ^0.6.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


// Note that it's ownable and the owner wields tremendous power. The ownership
// should be transferred to a governance smart contract once Nerve.
contract Token is ERC20('Token', 'TKN'), Ownable {
   using SafeMath for uint256;

    /**
    * @notice The stakes for each stakeholder.
    */
    mapping(address => uint256) internal stakes;

    /**
    * @notice The accumulated rewards for each stakeholder.
    */
    mapping(address => uint256) internal rewards;
    
    /**
    * @notice The block number when token mining starts.
    */
    uint256 startBlock;
    
    /**
    * @notice The constructor for the Staking Token.
    * @param _owner The address to receive all tokens on construction.
    * @param _supply The amount of tokens to mint on construction.
    */
    constructor(address _owner, uint256 _supply) public {
        startBlock = block.number;
        _mint(_owner, _supply);
    }

    /**
    * @notice A method to retrieve the stake for a stakeholder.
    * @param _stakeholder The stakeholder to retrieve the stake for.
    * @return uint256 The amount of wei staked.
    */
    function stakeOf(address _stakeholder) public view returns(uint256) {
        return stakes[_stakeholder];
    }

    /**
    * @notice A method for a stakeholder to create a stake.
    * @param _stake The size of the stake to be created.
    */
    function createStake(uint256 _stake) public {
        _burn(msg.sender, _stake);
        stakes[msg.sender] = stakes[msg.sender].add(_stake);
    }

    /**
    * @notice A method for a stakeholder to remove a stake.
    * @param _stake The size of the stake to be removed.
    */
    function removeStake(uint256 _stake) public {
        stakes[msg.sender] = stakes[msg.sender].sub(_stake);
        _mint(msg.sender, _stake);
    }

    /**
    * @notice A method for a stakeholder to accrue rewards. Can only be called by the owner of the contract.
    * @param _reward The amount of rewards accrued.
    * @param _stakeholder The stakeholder receiving rewards.
    */
    function assignRewards(uint256 _reward, address _stakeholder) public onlyOwner {
        rewards[_stakeholder] = rewards[_stakeholder].add(_reward);
    }

    /**
    * @notice A method to retrieve the stake for a stakeholder.
    * @param _stakeholder The stakeholder to retrieve the rewards for.
    * @return uint256 The amount of wei in rewards.
    */
    function rewardOf(address _stakeholder) public view returns(uint256) {
        return rewards[_stakeholder];
    }

    /**
    * @notice A method for a stakeholder to withdraw rewards.
    * @param _reward The amount of rewards to withdraw.
    */
    function withdrawRewards(uint256 _reward) public {
        rewards[msg.sender] = rewards[msg.sender].sub(_reward);
        _mint(msg.sender, _reward);
    }
} 