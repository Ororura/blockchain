// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Test { 
    constructor() {
        timerStart = block.timestamp;
    }
    uint public timerStart;
    
    function timeNow() public view returns (uint) {
        return block.timestamp;
    }

    

}