// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract CryptoMonster is ERC20("CryptoMonster", "CMON") {
    uint public totalCoins = 10000000 * 10 ** 12;
    uint public seedCoins = totalCoins * 10 / 100;
    uint public privateCoins = totalCoins * 30 / 100;
    uint public pubCoins = totalCoins * 60 / 100;

    uint public timeStart;
    uint public timeNow;
    uint public timeDif;
    uint public timeSystem;
    address public owner;

    enum Role {Private, Provider}

    struct Ticket {
        string name;
        address usrAddress;
    }

    // mapping(address => Ticket) requests;
    mapping(address => Role) public userRole;
    Ticket[] public requests;
    address[] public whiteList;

    //Shanghai
    constructor() {
        owner = msg.sender;
        userRole[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = Role.Private;
        userRole[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = Role.Provider;
        timeStart = block.timestamp;
        timeNow = timeStart;
        timeDif = 0;
        timeSystem = timeStart;
        _mint(msg.sender, totalCoins);
        _transfer(msg.sender,0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB , 300000 * 10 ** 12);
        seedCoins = seedCoins - 300000 * 10 ** 12;
        _transfer(msg.sender, 0x617F2E2fD72FD9D5503197092aC168c91465E7f2, 400000 * 10 ** 12);
        seedCoins = seedCoins - 400000 * 10 ** 12;
        _transfer(msg.sender, 0x17F6AD8Ef982297579C203069C1DbfFE4348c372, 200000 * 10 ** 12);
        seedCoins = seedCoins - 200000 * 10 ** 12;
    }

    modifier AccesControl(Role _role) {
        require(userRole[msg.sender] == _role, unicode"Ваша роль не позволяет это использовать");
        _;
    }

    function checkTime() public returns(uint){
        timeSystem = block.timestamp + timeDif;
        uint dif = timeSystem - timeStart;
        console.log(dif);
        return dif;
    }

    function makePrivateReq(string memory _name) public {
        requests.push(Ticket(_name, msg.sender));
    }

    function approveWhiteList(uint _idTicket, bool status) public AccesControl(Role.Private) {
        if(status) {
            whiteList.push(requests[_idTicket].usrAddress);
        } 
        else {
            delete requests[_idTicket];
        }
    }

    function buyPrivateToken(uint _amount) public payable returns(string memory) {
        require(_amount <= 100000, unicode"Больше 100000 нельзя купить");
        require(privateCoins > 0, unicode"Private коины закончились");
        for(uint i; i < whiteList.length; i++) {
            if(msg.sender == whiteList[i]) {
                _transfer(owner, msg.sender, _amount * 10 ** 12);
                privateCoins -= _amount * 10 ** 12;
                payable(msg.sender).transfer(_amount * 750000000000000);
            }
            else {
                return unicode"Вас нет в WhiteList";
            }
        }
        return unicode"Операция проведена успешна";
    }

    function buyPublicToken(uint _amount) public payable {
        require(_amount <= 5000, unicode"Больше 5000 нельзя купить");
        require(pubCoins > 0, unicode"Public коины закончились");
        _transfer(owner, msg.sender, _amount * 10 ** 12);
        pubCoins -= _amount * 10 ** 12;
        payable(msg.sender).transfer(_amount * 1000000000000000);
    }


}