pragma solidity 0.7.6;

import "./safemath.sol";
import "./ownable.sol";

contract AaronCoin is Ownable{
    
    using SafeMath for uint;
    
    struct Account{
        mapping (address => uint) allowance;
        uint balance;
        uint readyTime;
        uint coolTime;
    }
    
    string constant _name = "AaronCoin";
    string constant _symbol = "@";
    uint8 _decimals = 8;
    uint private _totalSupply;
    uint private coolTimeBase = 10 seconds;
    uint private randNonce = 0;
    uint private lotteryLimit = 10000;
    uint private lotteryTime = block.timestamp;
    uint private lotteryValue = 1000;
    uint private lotteryDecreaseRate = 2;
    uint private coolTimeIncreaseRate = 10;
    uint private accountNum = 0;
    address [] private accountLUT;
    mapping (address => Account) accounts;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public pure returns (string memory){
        return _name;
    }
    function symbol() public pure returns (string memory){
        return _symbol;
    }
    function decimals() public view returns (uint8){
        return _decimals;
    }
    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance){
        return accounts[_owner].balance;
    }
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(_to != address(0) && _value >=0 && accounts[msg.sender].balance >= _value);
        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(_value);
        accounts[_to].balance = accounts[_to].balance.add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_from != address(0) && _to != address(0) && _value >=0);
        require(accounts[_from].balance >= _value && accounts[_from].allowance[msg.sender] >= _value);
        accounts[_from].balance = accounts[_from].balance.sub(_value);
        accounts[_to].balance = accounts[_to].balance.add(_value);
        accounts[_from].allowance[msg.sender] = accounts[_from].allowance[msg.sender].sub(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success){
        require(_spender != address(0) && _value >= 0 && accounts[msg.sender].balance >= _value);
        accounts[msg.sender].allowance[_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return accounts[_owner].allowance[_spender];
    }
    
    // special functions of AaronCoin
    function randMod(uint _modulus) private returns(uint) {
        randNonce = randNonce.add(1);
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % _modulus;
    }
    function lottery() public payable{
        require(msg.value == 1 ether);
        require(block.timestamp > accounts[msg.sender].readyTime);
        lotteryValue = lotteryValue.add(block.timestamp - lotteryTime);
        if (lotteryValue > lotteryLimit){
            lotteryValue = lotteryLimit;
        }
        uint rand = randMod(lotteryValue);
        lotteryValue = lotteryValue.div(lotteryDecreaseRate);
        _totalSupply = _totalSupply.add(rand);
        accounts[msg.sender].balance = accounts[msg.sender].balance.add(rand);
        accounts[msg.sender].readyTime = block.timestamp + accounts[msg.sender].coolTime;
        accounts[msg.sender].coolTime = accounts[msg.sender].coolTime.mul(coolTimeIncreaseRate);
        emit Transfer(address(0), msg.sender, rand);
    }
    function showContractBalance() public view onlyOwner returns(uint){
        return address(this).balance;
    }
    function withdraw() external onlyOwner {
        address payable _owner = address(uint160(owner()));
        _owner.transfer(address(this).balance);
        emit Transfer(address(this), msg.sender, address(this).balance);
    }

}