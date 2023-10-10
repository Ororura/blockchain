// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CryptoMonster is ERC20("CryptoMonster", "CMON") {
    address public owner;
    uint totalSupp = 10000000 * 10 ** 12;

    uint SEED_ALLOCATION = totalSupp * 10 / 100;
    uint PRIVATE_ALLOCATION = totalSupp * 30 / 100;
    uint PUBLIC_ALLOCATION = totalSupp * 60 / 100;

    uint256 public startTime;
    uint256 public privateSaleEndTime;
    uint256 public publicSaleEndTime;

    mapping(address => bool) public whitelist;

    modifier onlyOwner() {
        require(msg.sender == owner, unicode"Использовать может только владелец");
        _;
    }

    constructor() {
        owner = msg.sender;
        _mint(owner, totalSupp);
        _transfer(owner, address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2), SEED_ALLOCATION * 3 / 10); // investor1
        _transfer(owner, address(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db), SEED_ALLOCATION * 4 / 10); // investor2
        _transfer(owner, address(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB), SEED_ALLOCATION * 2 / 10); // bestFriend

        startTime = block.timestamp;
        privateSaleEndTime = startTime + 5 minutes;
        publicSaleEndTime = privateSaleEndTime + 10 minutes;
    }

    function startPublicSale() external view onlyOwner {
        require(block.timestamp >= publicSaleEndTime, unicode"Публичные продажи ещё начались");
        
    }

    function addToWhitelist(address[] memory users) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            whitelist[users[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            whitelist[users[i]] = false;
        }
    }

    function buyPrivateTokens(uint256 amount) external payable {
        require(whitelist[msg.sender], unicode"Вас нет в вайт листе");
        require(block.timestamp >= startTime && block.timestamp < privateSaleEndTime, unicode"Приватная продажа ещё не началась");
        require(amount <= 100000, unicode"Лимит покупок превышен");
        uint256 tokenPrice = 750000 wei; 
        uint256 cost = amount * tokenPrice;
        require(msg.value >= cost, "Insufficient funds");
        _transfer(owner, msg.sender, amount);
    }

    function buyPublicTokens(uint256 amount) external payable {
        require(block.timestamp >= privateSaleEndTime && block.timestamp < publicSaleEndTime, unicode"Публичная продажа ещё на началась");
        require(amount <= 5000, "Max purchase limit exceeded");
        uint256 tokenPrice = 1000 wei;
        uint256 cost = amount * tokenPrice;
        require(msg.value >= cost, unicode"Недостаточно средств");
        _transfer(owner, msg.sender, amount);
    }

    function transferPublicTokens(address recipient, uint256 amount) external onlyOwner {
        _transfer(owner, recipient, amount);
    }
}

