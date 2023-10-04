// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract CompanionVendor{
    constructor() { 
        startTimestamp = block.timestamp; //set start time
    }
    uint public startTimestamp; 
    uint cycleLengthInSeconds = 60; 

    function _getCycle(uint timestamp) internal view returns (uint) {
        require(timestamp >= startTimestamp);
        return (((timestamp - startTimestamp) / uint256(cycleLengthInSeconds)) + 1);
    }
    
    function getCurrentCycle() public view returns (uint){
        return _getCycle(block.timestamp);
    }  

    function buy() public view returns(uint) {
        uint status = 0;
        if(getCurrentCycle() >= 2) {
            status = 1;
        }
        return status;
    }
}