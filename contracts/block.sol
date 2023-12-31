// SPDX-License-Identifier: MIT
// Доделать approve
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract CryptoMonster is ERC20("CryptoMonster", "CMON") {
    uint private  totalCoins = 10_000_000 * 10 ** decimals();
    uint private  publicPrice = 0.001 ether;
    uint private  leftBalOwner = 100_000 * 10 ** decimals();
    uint public  timeStart;
    uint private  timeDif;
    uint private providerTransactCounter;
    address private owner;
    address private publicProvider = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address private privateProvider = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

    enum Role {User, Private, Public, Owner}
    enum Phase {Seed, Private, Public}

    struct Ticket {
        string name;
        address wallet;
        bool status;
    }

    struct User {
        bool whiteList;
        string login;
        Role role;
        address wallet;
        uint seedBal;
        uint privateBal;
        uint publicBal;
    }


    mapping(address => User) private users;
    mapping(string => address) private logins;
    mapping(string => bytes32) public passwords; 
    Ticket[] requests;
    Ticket[] whiteList; 


    //Shanghai
    constructor() {
        owner = msg.sender;
        users[msg.sender] = User(true, "owner", Role.Owner, msg.sender, 0, totalCoins * 30 / 100, totalCoins * 60 / 100);
        timeStart = block.timestamp;
        _mint(msg.sender, totalCoins);
        users[privateProvider] = User(true, "private", Role.Private, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 0, 0, 0);
        users[publicProvider] = User(false, "public", Role.Public, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 0, 0, 0);
        users[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] = User(false, "investor1", Role.User, 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, 300000 * 10 ** decimals(), 0, 0);
        users[0x617F2E2fD72FD9D5503197092aC168c91465E7f2] = User(false, "investor2", Role.User, 0x617F2E2fD72FD9D5503197092aC168c91465E7f2, 400000 * 10 ** decimals(), 0, 0);
        users[0x17F6AD8Ef982297579C203069C1DbfFE4348c372] = User(false, "bestFriend", Role.User, 0x17F6AD8Ef982297579C203069C1DbfFE4348c372, 200000 * 10 ** decimals(), 0, 0);

        _transfer(msg.sender,0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB , 300000 * 10 ** decimals());
        _transfer(msg.sender, 0x617F2E2fD72FD9D5503197092aC168c91465E7f2, 400000 * 10 ** decimals());
        _transfer(msg.sender, 0x17F6AD8Ef982297579C203069C1DbfFE4348c372, 200000 * 10 ** decimals());
    }

    modifier AccessControl(Role _role) { 
        require(users[msg.sender].role == _role, unicode"Ваша роль не позволяет это использовать");
        _;
    }

    function decimals() public pure override returns (uint8) {
        return 12;
    }

    function checkTime() public view returns(uint){
        uint timeCycle = (block.timestamp + timeDif - timeStart);
        console.log(timeCycle);
        return timeCycle;
    }

    function skipTime() public {
        timeDif += 60;
    }

    function changePublicPrice(uint _newPrice) external AccessControl(Role.Public) {
        publicPrice = _newPrice;
    }

    function getProviderTransactCounter () external view returns(uint) {
        return providerTransactCounter;
    }

    function getWhiteList() external view AccessControl(Role.Private) returns(Ticket[] memory) {
        return whiteList;
    }

    function getRequestWhiteList() external view AccessControl(Role.Private) returns(Ticket[] memory) { 
        return requests;
    }

    function getPhaseBalance (Phase _phase) external view returns(uint, uint, uint, uint) {
        uint bal;
        if(_phase == Phase.Private) {
            bal = users[msg.sender].privateBal;
        }
        if(_phase == Phase.Public) {
            bal = users[msg.sender].publicBal;
        }
        if(_phase == Phase.Seed) {
            bal = users[msg.sender].seedBal;
        }
        return (users[msg.sender].privateBal, users[msg.sender].publicBal, users[msg.sender].seedBal, msg.sender.balance);

    }

    function approveTokensToUsers(address _user, uint _amount) external  {
        _approve(owner, _user, _amount);
    }

    function getApproveTokens(address _ownerTokens, uint _amount) external  {
        _transfer(_ownerTokens, msg.sender, _amount);
        if(checkTime() >= 5 * 60 && checkTime() < 15 * 60) {
            users[msg.sender].privateBal += _amount;
            users[_ownerTokens].privateBal -= _amount;
        } else {
            users[msg.sender].publicBal += _amount;
            users[_ownerTokens].publicBal -= _amount;
        }
    }

    function getTokenPrice() public view returns(uint) {
        uint price = 0;
        if(checkTime() >= 5 * 60 && checkTime() < 15 * 60) {
            price = 0.0075 ether;
        }
        else if(checkTime() >= 15 * 60) {
            price = publicPrice;
        }
        return price;
    }

    function registration(string memory _login, string memory _password) external {
        require(logins[_login] == address(0), unicode"Пользователь с таким логином уже существует");
        require(users[msg.sender].wallet == address(0), unicode"Пользователь с таким адресом уже существует");
        users[msg.sender] = User(false, _login, Role.User, msg.sender, 0, 0, 0);
        logins[_login] = msg.sender;
        passwords[_login] = keccak256(abi.encode(_password));
    }

    function login(string memory _login, string memory _password) external view returns(User memory) {
        require(keccak256(abi.encode(_password)) == passwords[_login], unicode"Неверный пароль"); 
        return users[logins[_login]]; 
    }

    function makePrivateReq(string memory _name) external {
        require(checkTime() < 5, unicode"Приватная фаза ещё не началась");
        require(!users[msg.sender].whiteList, unicode"Вы уже в white листе");
        for(uint i; i < requests.length; i++) {
            require(requests[i].wallet != msg.sender, unicode"Вы уже отправили запрос");
        }
        requests.push(Ticket(_name, msg.sender, false));
    }

    function approveWhiteList(uint _id, bool _status) external AccessControl(Role.Private) {
        if(_status) {
            users[requests[_id].wallet].whiteList = true;
            whiteList.push(requests[_id]);
            //поменять статус на True
        }
        else {
            delete requests[_id];
        }
    }

    function sendTokensToProvier() public AccessControl(Role.Owner){
        providerTransactCounter ++;

        if(checkTime() > 15 * 60) {
            users[publicProvider].publicBal += totalCoins * 60 / 100;
            _transfer(owner, publicProvider, totalCoins * 60 / 100);
            users[owner].privateBal -= totalCoins * 60 / 100;
            leftBalOwner += users[privateProvider].privateBal;
            users[privateProvider].privateBal = 0; 
        }
        else if(checkTime() > 5 * 60) {
            users[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2].privateBal += totalCoins * 30 / 100;
            _transfer(owner, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, totalCoins * 30 / 100);
            users[owner].privateBal -= totalCoins * 30 / 100;
            leftBalOwner += 100_000 * 10 ** decimals();
        } 
    }

    function payReward(uint _amount, address _user) external AccessControl(Role.Public) {
        require(users[publicProvider].publicBal >= _amount);
        _transfer(msg.sender, _user, _amount);
        users[publicProvider].publicBal -= _amount;
        users[_user].publicBal += _amount;
    }

    function sendToken(address _to, uint _amount, Phase _phase) external {
        if(msg.sender == owner) {
            require(leftBalOwner >= _amount, unicode"У вас нет остаточных коинов");
            leftBalOwner -= _amount;
        }

        if(_to == owner) {
            leftBalOwner += _amount;
        }

        if(_phase == Phase.Private) {
            require(users[msg.sender].privateBal >= _amount, unicode"У вас недостаточно токенов");
            _transfer(msg.sender, _to, _amount);
            users[msg.sender].privateBal -= _amount;
            users[_to].privateBal += _amount;
        }
        if(_phase == Phase.Seed) {
            require(users[msg.sender].seedBal >= _amount, unicode"У вас недостаточно токенов");
            _transfer(msg.sender, _to, _amount);
            users[msg.sender].seedBal -= _amount;
            users[_to].seedBal += _amount;
        }
        if(_phase == Phase.Public) {
            require(users[msg.sender].publicBal >= _amount, unicode"У вас недостаточно токенов");
            _transfer(msg.sender, _to, _amount);
            users[msg.sender].publicBal -= _amount;
            users[_to].publicBal += _amount;
        }
    }

    function buyToken(uint _amount) external payable{

        require(checkTime() > 5 * 60, unicode"Идёт подготовительная фаза");
        require(users[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2].privateBal > 0, unicode"Токены закончились");
        require(users[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db].publicBal > 0, unicode"Токены закончились");

        uint totalPrice = (_amount / 10 ** decimals()) * getTokenPrice(); 

        if(getTokenPrice() == 0.0075 ether) {
            require(users[msg.sender].whiteList, unicode"Free sale not started");
            require(_amount <= 100_000 * 10 ** decimals(), unicode"Превышен лимит токенов");
            users[msg.sender].privateBal += _amount;
            users[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2].privateBal -= _amount;
            _transfer(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, msg.sender, _amount);
        }

        else if(getTokenPrice() == publicPrice) {
            require(_amount <= 5000 * 10 ** decimals(), unicode"Превышен лимит токенов"); 
            users[msg.sender].publicBal += _amount;
            users[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db].publicBal -= _amount;
            _transfer(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, msg.sender, _amount);
        } else {
            revert(unicode"Нельзя купить токены в подготовительную фазу");
        }
        require(msg.value >= totalPrice, unicode"Недостаточно отправленной валюты");

        payable(owner).transfer(msg.value);
    }
}