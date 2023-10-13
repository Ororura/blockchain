// SPDX-License-Identifier: MIT

// Сделать функционал передачи оставшихся коинов; Сделать переводы оставшихся коинов на leftBalOwner.
// Сделать покупку токенов одной функцией

// ПОФИКСИТЬ СОЗДАНИЕ РЕКВЕСТОВ НА ДОБАВЛЕНИЕ В ВАЙТ ЛИСТ

pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract CryptoMonster is ERC20("CryptoMonster", "CMON") {
    uint private  totalCoins = 10000000 * 10 ** decimals();
    uint private  seedTokens = totalCoins * 10 / 100;
    uint private  privateTokens = totalCoins * 30 / 100;
    uint private  publicTokens = totalCoins * 60 / 100;
    uint private  publicPrice = 0.001 ether;
    uint private  leftBalOwner;
    uint private  timeStart;
    uint private  timeDif;
    uint private  timeSystem;
    address private owner;

    enum Role {User, Private, Public, Owner}
    enum Phase {Seed, Privat, Public}
    enum ReqStatus{Denied, Accepted, UnderReview}

    struct Ticket {
        string name;
        address wallet;
        ReqStatus status;
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
    mapping(address => bytes32) public passwords;
    mapping(address => Ticket) public requests;


    //Shanghai
    constructor() {
        owner = msg.sender;
        users[msg.sender] = User(true, "owner", Role.Owner, msg.sender, 0, 0, 0);
        timeStart = block.timestamp;
        timeSystem = timeStart;
        _mint(msg.sender, totalCoins);

        users[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = User(true, "private", Role.Private, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 0, 0, 0);
        users[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = User(false, "public", Role.Public, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 0, 0, 0);
        users[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] = User(false, "investor1", Role.User, 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, 300000 * 10 ** decimals(), 0, 0);
        users[0x617F2E2fD72FD9D5503197092aC168c91465E7f2] = User(false, "investor2", Role.User, 0x617F2E2fD72FD9D5503197092aC168c91465E7f2, 400000 * 10 ** decimals(), 0, 0);
        users[0x17F6AD8Ef982297579C203069C1DbfFE4348c372] = User(false, "bestFriend", Role.User, 0x17F6AD8Ef982297579C203069C1DbfFE4348c372, 200000 * 10 ** decimals(), 0, 0);

        _transfer(msg.sender,0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB , 300000 * 10 ** decimals());
        seedTokens = seedTokens - 300000 * 10 ** decimals();
        _transfer(msg.sender, 0x617F2E2fD72FD9D5503197092aC168c91465E7f2, 400000 * 10 ** decimals());
        seedTokens = seedTokens - 400000 * 10 ** decimals();
        _transfer(msg.sender, 0x17F6AD8Ef982297579C203069C1DbfFE4348c372, 200000 * 10 ** decimals());
        seedTokens = seedTokens - 200000 * 10 ** decimals();
    }

    modifier AccesControl(Role _role) {
        require(users[msg.sender].role == _role, unicode"Ваша роль не позволяет это использовать");
        _;
    }

    function decimals() public pure override returns (uint8) {
        return 12;
    }

    function checkTime() public returns(uint){
        timeSystem = block.timestamp + timeDif;
        uint timeCycle = (timeSystem - timeStart);
        console.log(timeCycle);
        return timeCycle;
    }

    function skipTime(uint _minutes) public {
        timeDif += _minutes * 60;
    }

    function changePublicPrice(uint _newPrice) external AccesControl(Role.Public) {
        publicPrice = _newPrice;
    }

    function getTokenPrice() public returns(uint){
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
            leftBalOwner += seedTokens;
        }
        if(checkTime() > 15 * 60) {
            leftBalOwner += privateTokens;
        }
    }

    // Сделать проверку на юзера в системе через AccessControl !!!!!!!!!!!!!!!!!!!!!!!!
    function registration(string memory _login, string memory _password) external {
        users[msg.sender] = User(false, _login, Role.User, msg.sender, 0, 0, 0);
        logins[_login] = msg.sender;
        passwords[msg.sender] = keccak256(abi.encode(_password));
    }

    function login(string memory _login, string memory _password) external view returns(User memory) {
        require(logins[_login] == address(0), unicode"Пользователь с таким логином уже существует");
        require(users[msg.sender].wallet == address(0), unicode"Пользователь с таким адресом уже существует");
        string memory storedLogin = users[msg.sender].login;
        require(keccak256(abi.encode(_login)) == keccak256(abi.encode(storedLogin)));
        require(keccak256(abi.encode(_password)) == passwords[msg.sender]);
        return users[msg.sender];
    }

    function makePrivateReq(string memory _name) external {
        require(checkTime() >15, unicode"Приватная фаза закончилась");
        require(!users[msg.sender].whiteList, unicode"Вы уже в white листе");
        require(requests[msg.sender].wallet == address(0));
        requests[msg.sender] = Ticket(_name, msg.sender, ReqStatus.UnderReview);
    }

    function approveWhiteList(address _user, ReqStatus _status) external AccesControl(Role.Private) {
        require(_status != ReqStatus.UnderReview, unicode"Укажите Accepted или Denied");
        
        if(_status == ReqStatus.Accepted) {
            users[_user].whiteList = true;
        }
        else {
            requests[_user].status = ReqStatus.Denied;
        }
    }

    function giveCoinsFromOwner(uint _amount, address _user) external AccesControl(Role.Owner) {
        require(leftBalOwner > 0, unicode"У вас нет остаточных коинов");
        _transfer(msg.sender, _user, _amount * 10 **decimals());
    }

    function sendTokensToProvier(uint _amount, address _provider) external AccesControl(Role.Owner){
        require(_amount > 0, unicode"Кол-во не может быть 0 или меньше 0"); 
        _transfer(msg.sender, _provider, _amount);
    }

    function payReward(uint _amount, address _user) external AccesControl(Role.Public) {
        require(_amount > 0, unicode"Кол-во не может быть 0 или меньше 0"); 
        _transfer(msg.sender, _user, _amount);
        publicTokens -= _amount * 10 ** decimals();
    }

    function sendToken(address _to, uint _amount, Phase _phase) external {
        // А нахуя мы отправляем в структуры токены из разных фаз??
        require(_amount > 0, unicode"Кол-во не может быть 0 или меньше 0"); 
        _amount = _amount * 10 ** decimals();

        if(_phase == Phase.Privat) {
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

    function buyToken(uint _amount) public {
        _amount = _amount * 10 ** decimals();
        require(checkTime() > 5 * 60, unicode"Идёт подготовительная фаза");
        require(_amount > 0, unicode"Кол-во не может быть 0 или меньше 0"); 
        require(users[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2].privateBal > 0, unicode"Токены закончились");
        require(users[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db].publicBal > 0, unicode"Токены закончились");
        _transfer(owner, msg.sender, _amount);

        if(getTokenPrice() == 0.0075 ether) {
            users[msg.sender].privateBal += _amount;
            users[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2].privateBal -= _amount;
            _transfer(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, msg.sender, _amount);
            privateTokens -= _amount;
        }
        else {
            users[msg.sender].publicBal += _amount;
            users[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db].publicBal -= _amount;
            _transfer(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, msg.sender, _amount);
            publicTokens -= _amount;
        }

        payable(msg.sender).transfer(_amount * getTokenPrice());
    }


}