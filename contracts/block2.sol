// SPDX-License-Identifier: MIT

// Сделать функционал передачи оставшихся коинов; Сделать переводы оставшихся коинов на leftBalOwner.
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract CryptoMonster is ERC20("CryptoMonster", "CMON") {
    uint public totalCoins = 10000000 * 10 ** decimals();
    uint public seedCoins = totalCoins * 10 / 100;
    uint public privateCoins = totalCoins * 30 / 100;
    uint public pubCoins = totalCoins * 60 / 100;

    uint public leftBalOwner;
    uint public publicPrice;
    uint public timeStart;
    uint public timeDif = 0;
    uint public timeSystem;
    address public owner;

    enum Role {User, Private, Public}

    struct Ticket {
        string name;
        address usrAddress;
    }


    mapping(address => Role) public userRole;
    Ticket[] public requests;
    address[] public whiteList;

    //Shanghai
    constructor() {
        owner = msg.sender;
        timeStart = block.timestamp;
        timeSystem = timeStart;
        _mint(msg.sender, totalCoins);

        userRole[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = Role.Private;
        userRole[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = Role.Public;

        _transfer(msg.sender,0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB , 300000 * 10 ** decimals());
        seedCoins = seedCoins - 300000 * 10 ** decimals();
        _transfer(msg.sender, 0x617F2E2fD72FD9D5503197092aC168c91465E7f2, 400000 * 10 ** decimals());
        seedCoins = seedCoins - 400000 * 10 ** decimals();
        _transfer(msg.sender, 0x17F6AD8Ef982297579C203069C1DbfFE4348c372, 200000 * 10 ** decimals());
        seedCoins = seedCoins - 200000 * 10 ** decimals();
    }

    modifier AccesControl(Role _role) {
        require(userRole[msg.sender] == _role, unicode"Ваша роль не позволяет это использовать");
        _;
    }

    modifier OnlyOwner() {
        require(msg.sender == owner, unicode"Вы не владелец контракта");
        _;
    }

    function decimals() public pure override returns (uint8) {
        return 12;
    }

    function checkTime() public returns(uint){
        timeSystem = block.timestamp + timeDif;
        uint timeCycle = (timeSystem - timeStart)/60;
        console.log(timeCycle);
        return timeCycle;
    }

    function updateLeftBalOwner () public {
        if(checkTime() > 5) {
            leftBalOwner += seedCoins;
        }
        if(checkTime() > 15) {
            leftBalOwner += privateCoins;
        }
    }

    function skipTime(uint _minutes) public {
        timeDif += _minutes * 60;
    }

    function giveCoinsFromOwner(uint _amount, address _user) public OnlyOwner() {
        require(leftBalOwner > 0, unicode"У вас нет остаточных коинов");
        _transfer(msg.sender, _user, _amount * 10 **decimals());
    }

    function payReward(uint _amount, address _user) public AccesControl(Role.Public) {
        _transfer(msg.sender, _user, _amount);
        pubCoins -= _amount * 10 ** decimals();
    }

    function changePublicPrice(uint _newPrice) public AccesControl(Role.Public) {
        publicPrice = _newPrice;
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
        require(checkTime() >= 5, unicode"Приватная фаза ещё не началась");
        require(checkTime() <= 15, unicode"Приватная фаза закончилась");
        require(_amount <= 100000, unicode"Больше 100000 нельзя купить");
        require(privateCoins > 0, unicode"Private коины закончились");

        bool isWhiteListed = false;
        for(uint i; i < whiteList.length; i++) {
            if(msg.sender == whiteList[i]) {
                isWhiteListed = true;
            }
        }
        require(isWhiteListed, unicode"Вас нет в WhiteList");
        _transfer(owner, msg.sender, _amount * 10 ** decimals());
        privateCoins -= _amount * 10 ** decimals();
        payable(msg.sender).transfer(_amount * 750000000000000);
    }

    function buyPublicToken(uint _amount) public payable {
        require(checkTime() >= 10, unicode"Public фаза ещё не началась");
        require(_amount <= 5000, unicode"Больше 5000 нельзя купить");
        require(pubCoins > 0, unicode"Public коины закончились");
        _transfer(owner, msg.sender, _amount * 10 ** decimals());
        pubCoins -= _amount * 10 ** decimals();
        payable(msg.sender).transfer(_amount * 1000000000000000);
    }


}