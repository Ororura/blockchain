// SPDX-License-Identifier: MIT

// Перевод остатка на leftBal
// getter на вайтлист, баланс(address), реквесВайтлиста, getter counter перевода провайдера 
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract CryptoMonster is ERC20("CryptoMonster", "CMON") {
    uint private  totalCoins = 10000000 * 10 ** decimals();
    uint private  publicPrice = 0.001 ether;
    uint private  leftBalOwner = 100000 * 10 ** decimals();
    uint private  timeStart;
    uint private  timeDif;
    uint private providerTransactCounter;
    address private owner;

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
    User[] whiteList;


    //Shanghai
    constructor() {
        owner = msg.sender;
        users[msg.sender] = User(true, "owner", Role.Owner, msg.sender, 0, 0, 0);
        timeStart = block.timestamp;
        _mint(msg.sender, totalCoins);
        users[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = User(true, "private", Role.Private, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 0, 0, 0);
        users[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = User(false, "public", Role.Public, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 0, 0, 0);
        users[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] = User(false, "investor1", Role.User, 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, 300000 * 10 ** decimals(), 0, 0);
        users[0x617F2E2fD72FD9D5503197092aC168c91465E7f2] = User(false, "investor2", Role.User, 0x617F2E2fD72FD9D5503197092aC168c91465E7f2, 400000 * 10 ** decimals(), 0, 0);
        users[0x17F6AD8Ef982297579C203069C1DbfFE4348c372] = User(false, "bestFriend", Role.User, 0x17F6AD8Ef982297579C203069C1DbfFE4348c372, 200000 * 10 ** decimals(), 0, 0);

        _transfer(msg.sender,0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB , 300000 * 10 ** decimals());
        _transfer(msg.sender, 0x617F2E2fD72FD9D5503197092aC168c91465E7f2, 400000 * 10 ** decimals());
        _transfer(msg.sender, 0x17F6AD8Ef982297579C203069C1DbfFE4348c372, 200000 * 10 ** decimals());
    }

    modifier AccesControl(Role _role) {
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

    function skipTime(uint _minutes) public {
        timeDif += _minutes * 60;
    }

    function changePublicPrice(uint _newPrice) external AccesControl(Role.Public) {
        publicPrice = _newPrice;
    }

    function getWhiteList(uint _id) public view returns(User memory) {
        return whiteList[_id];
    }

    function getRequestWhiteList(uint _id) external view returns(Ticket memory) {
        return requests[_id];
    }

    function getPhaseBalance (Phase _phase) public view returns(uint) {
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
        return bal;

    }

    function getTokenPrice() public view returns(uint) {
        uint price = 0;
        if(checkTime() >= 5 * 60 && checkTime() <= 15 * 60) {
            price = 0.0075 ether;
        }
        if(checkTime() >= 15 * 60) {
            price = publicPrice;
        }
        console.log(price);
        return price;
    }

    function updateLeftBalOwner () external AccesControl(Role.Owner) {
        if(checkTime() > 5 * 60) {
            leftBalOwner += users[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2].privateBal;
            users[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2].privateBal = 0;
        }
        if(checkTime() > 15 * 60) {
            leftBalOwner += users[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db].publicBal;
            users[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db].publicBal = 0;
        }
    }

    function registration(string memory _login, string memory _password) external {
        require(logins[_login] == address(0), unicode"Пользователь с таким логином уже существует");
        require(users[msg.sender].wallet == address(0), unicode"Пользователь с таким адресом уже существует");
        users[msg.sender] = User(false, _login, Role.User, msg.sender, 0, 0, 0);
        logins[_login] = msg.sender;
        passwords[_login] = keccak256(abi.encode(_password));
    }

    function login(string memory _login, string memory _password) external view returns(User memory) {
        require(keccak256(abi.encode(_password)) == passwords[_login]);
        return users[logins[_login]]; 
    }

    function makePrivateReq(string memory _name) external {
        require(checkTime() >15, unicode"Приватная фаза закончилась");
        require(!users[msg.sender].whiteList, unicode"Вы уже в white листе");
        for(uint i; i < requests.length; i++){
            require(requests[i].wallet != msg.sender, unicode"Вы уже отправили запрос");
        }
        requests.push(Ticket(_name, msg.sender, false));
    }

    function approveWhiteList(uint _id, bool _status) external AccesControl(Role.Private) {
        if(_status) {
            users[requests[_id].wallet].whiteList = true;
            whiteList.push(users[requests[_id].wallet]);
        }
        else {
            delete requests[_id];
        }
    }

    function sendTokensToProvier() external AccesControl(Role.Owner){
        providerTransactCounter ++;
        if(checkTime() > 5 * 60) {
            users[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2].privateBal += totalCoins * 30 / 100;
            _transfer(owner, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, totalCoins * 30 / 100);
        }
        if(checkTime() > 15 * 60) {
            users[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db].privateBal += totalCoins * 30 / 100;
            _transfer(owner, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, totalCoins * 30 / 100);
        }
    }

    function payReward(uint _amount, address _user) external AccesControl(Role.Public) {
        require(_amount > 0, unicode"Кол-во не может быть 0 или меньше 0"); 
        _transfer(msg.sender, _user, _amount);
        users[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db].publicBal -= _amount;
    }

    function sendToken(address _to, uint _amount, Phase _phase) external {
        require(_amount > 0, unicode"Кол-во не может быть 0 или меньше 0"); 
        _amount = _amount * 10 ** decimals();

        // Перевод остаточных коинов
        if(msg.sender == owner) {
            require(leftBalOwner > 0, unicode"У вас нет остаточных коинов");
            leftBalOwner -= _amount;
            _transfer(msg.sender, _to, _amount);
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

    function buyToken(uint _amount) public payable{
        require(checkTime() > 5 * 60, unicode"Идёт подготовительная фаза");
        require(_amount > 0, unicode"Кол-во не может быть 0 или меньше 0"); 
        require(users[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2].privateBal > 0, unicode"Токены закончились");
        require(users[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db].publicBal > 0, unicode"Токены закончились");
        
        // Проверка: Хватает ли 

        if(getTokenPrice() == 0.0075 ether) {
            users[msg.sender].privateBal += _amount;
            users[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2].privateBal -= _amount;
            _transfer(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, msg.sender, _amount);
        }
        else {
            users[msg.sender].publicBal += _amount;
            users[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db].publicBal -= _amount;
            _transfer(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, msg.sender, _amount);
        }

        payable(owner).transfer(msg.value);
    }


}