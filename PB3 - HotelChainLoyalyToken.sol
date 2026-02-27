// SPDX-License-Identifier: LGPL-3.0-only 
pragma solidity 0.8.34; 

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// SMART CONTRACT

contract HotelChainLoyaltyToken is ERC20, Ownable{

// STATE VARIABLES

uint public constant MAX_SUPPLY = 100_000_000 ether; 
uint public burnRate = 50; 

uint public constant BURN_CHANGE_DELAY = 7 days; 
uint public proposedBurnRate;
uint public burnChangeTimestamp; 

address public hotelTreasury;

bool public burnChangePending;
bool public burnRateModified; 

struct TransferApproval {
    uint amount;
    uint expiry;
}
mapping(address => mapping(address => TransferApproval)) public approvals;

// MODIFIERS

 modifier onlyAuthorized() {
        require(
            msg.sender == owner() || msg.sender == hotelTreasury,
            "Not authorized"
        );
        _;
    }

// EVENTS

event ServicePayment(
    address indexed customer,
    uint256 totalAmount,
    uint256 burnedAmount,
    uint256 treasuryAmount
);

// CONSTRUCTOR

constructor(address _treasury) 
    ERC20("HotelChainLoyaltyToken", "HCLT")
    Ownable(msg.sender)
{
    require(_treasury != address(0), "Invalid treasury");
    hotelTreasury = _treasury;
}

// FUNCTIONS

function mint(address to, uint256 amount) external onlyOwner {
    require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");
    _mint(to, amount);
}

function payService(uint256 _amount) external {
    
    require (_amount > 0, "Amount must be greater than 0"); 
    uint256 burnAmount = (_amount * burnRate) / 100; 
    uint256 treasuryAmount = _amount - burnAmount; 

    _burn(msg.sender, burnAmount);
    _transfer(msg.sender, hotelTreasury, treasuryAmount);

    emit ServicePayment (msg.sender, _amount, burnAmount, treasuryAmount);

}

function proposeBurnRate(uint _newBurnRate) external onlyOwner {

    require (_newBurnRate <= 100, "Burn rate must be less than 100"); 

    if (burnChangePending) {
        require(!burnRateModified, "Modification already used");
        burnRateModified = true; 
    }
    else {
        burnChangePending = true;
        burnRateModified = false; 
        burnChangeTimestamp = block.timestamp;
    }

    proposedBurnRate = _newBurnRate;
} 

function executeBurnRateChange () external onlyOwner {

    require (block.timestamp >= BURN_CHANGE_DELAY + burnChangeTimestamp, "Burn rate change delay not met");
    require (burnChangePending == true, "Not burn rate change proposed");

     burnRate = proposedBurnRate; 
     proposedBurnRate = 0;
     burnChangePending = false;
     burnRateModified = false;
     burnChangeTimestamp = 0;

}

function getVipLevel(address user) public view returns (uint8) {

    uint256 balance = balanceOf(user);

    if (balance >= 5000 ether) {
        return 3; // Platinum
    } 
    else if (balance >= 2000 ether) {
        return 2; // Gold
    } 
    else if (balance >= 500 ether) {
        return 1; // Silver
    } 
    else {
        return 0; // Standard
    }
}

function _update (address _from, address _to, uint amount) internal override {

    // allow mint
    if (_from == address(0)) {
        super._update(_from, _to, amount);
        return;
    }
    // allow burn
    if (_to == address(0)) {
        super._update(_from, _to, amount);
        return;}
    // allow hotel transfers
    if (_from == hotelTreasury || _to == hotelTreasury) {
     super._update(_from, _to, amount);
        return;}
    
    // allow authorized transfers client-to-client
    TransferApproval storage approval = approvals[_from][_to];

    require(approval.amount == amount, "Amount not approved");
    require(block.timestamp <= approval.expiry, "Approval expired");


    // Delete the approval 
    delete approvals[_from][_to];

    super._update(_from, _to, amount);
}

function approveTransfer(
    address from,
    address to,
    uint256 amount
) external onlyAuthorized {

    require(from != address(0) && to != address(0), "Invalid address");
    require(amount > 0, "Invalid amount");

    approvals[from][to] = TransferApproval({
        amount: amount,
        expiry: block.timestamp + 24 hours
    });
}
}