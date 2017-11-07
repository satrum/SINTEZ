pragma solidity ^0.4.15;

 contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public returns (bool);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 /**
 * ERC23 token by Dexaran
 *
 * https://github.com/Dexaran/ERC23-tokens
 * 
 * Modified by PsychoZZ
 */
 
contract ERC223Token{
    
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
  
  
  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool) {
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
    if(isContract(_to)) {
        ContractReceiver receiver = ContractReceiver(_to);
        if(bytes(_custom_fallback).length != 0){
            receiver.call.value(0)(bytes4(sha3(_custom_fallback)), msg.sender, _value, _data);
        }else{
            receiver.tokenFallback(msg.sender, _value, _data);
        }
    }
    Transfer(msg.sender, _to, _value, _data);
    return true;
}
  

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) public returns (bool) {
      string memory empty;
      return transfer(_to,_value,_data,empty);
}
  
  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint _value) public returns (bool) {
      bytes memory empty;
      return transfer(_to,_value,empty);
}

//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) internal constant returns (bool) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
      }
      return (length>0);
    }

  function balanceOf(address _owner) public constant returns (uint) {
    return balances[_owner];
  }
}



contract SintezToken is ERC223Token{
    
    function SintezToken(){
        name = "SintezToken";
        symbol = "SINT";
        decimals = 18;
        balances[msg.sender] = 1000000000 ether;
        totalSupply = balances[msg.sender];
    }
}


contract ICO is Ownable{
    
    using SafeMath for uint256;
    
    uint256 constant PRESALE_PROFIT = 100;
    uint256 constant SALE_MIN_PROFIT = 25;
    uint256 constant SALE_MAX_PROFIT = 35;
    uint256 constant ETHER_PROFIT_LIMIT = 3000;
    uint256 constant ETHER_PROFIT_STEP = 10000;
    uint256 constant AFTER_LIMIT_BASIC_PROFIT = 15;
    
    
    uint256 constant M100=100000000;
    uint256 constant LN3= 109861228; 
    uint256 constant LN10=230258512;
    uint256 constant LN20=299573231;
    uint256 constant LN30=340119743;
    uint256 constant LN50=391202307;
    uint256 constant LN100=460517025;
    uint256 constant LN200=529831743;
    uint256 constant LN500=621460819;
    uint256 constant LN1000=690775527;
    
    struct entry{
        uint256 keyItem;
        uint256 value;
    }
    
    address[] public payers;
    mapping(address => entry) public internalValue;
    
    uint256 public weiRaised;
    uint256 public preSaleWeiRaised;
    
    uint256 public totalInternalValue;
    uint256 public haveTokens;
    
    uint256 public paymentTime;
    uint256 public endPreSaleTime;
    
    SintezToken public token;
    
    modifier canSend() {
        require(haveTokens != 0);
        require(paymentTime < now);
        _;
    }
    
    modifier validPay{
        require(paymentTime >= now);
        _;
    }

    
    function ICO(SintezToken _token, uint256 _endPreSaleTime, uint256 _paymentTime) public {
        token = _token;
        paymentTime = _paymentTime;
        endPreSaleTime = _endPreSaleTime;
        payers.push(0x0);
    }
    
    function sendTokenTo(address _to) public canSend{
        require(internalValue[_to].keyItem != 0);
        uint256 tokenForSend = haveTokens.mul(internalValue[_to].value).div(totalInternalValue);
        
        uint256 key = internalValue[_to].keyItem;
        delete internalValue[_to];
        payers[key] = payers[payers.length-- - 1];
        internalValue[payers[key]].keyItem = key;
        
        token.transfer(_to,tokenForSend);
    }
    
    function sendTokenFor(uint8 _count) public canSend{
        require(_count < payers.length);
        for(uint256 i = payers.length.sub(1); i >= payers.length.sub(_count); i--){
            address payer = payers[i];
            uint256 tokenForSend = haveTokens.mul(internalValue[payer].value).div(totalInternalValue);
            
            token.transfer(payer,tokenForSend);
            
            delete internalValue[payer];
        }
        payers.length = payers.length.sub(_count);
        
    }
    
    function payersCount()public constant returns(uint256){
        return payers.length - 1;
    }
    
    function clearThis(address _target) public canSend onlyOwner{
        require(payers.length == 1);
        token.transfer(_target,token.balanceOf(this));
    }
    
    function modifair1(uint256 _value) public constant returns(uint256){
        uint256 a = _value.mul(M100).div(1 ether);
        require(a > 0);
        uint256 lnbase;
        uint256 a0;
        
        if(a > M100.mul(1000)){
            lnbase = LN1000;
            a0 = a.div(1000);
        }else if(a > M100.mul(500)){
            lnbase=LN500;
            a0 = a.div(500);
        }else if(a > M100.mul(200)){
            lnbase = LN200;
            a0 = a.div(200);
        }else if(a > M100.mul(100)){
            lnbase = LN100;
            a0 = a.div(100);
        }else if(a > M100.mul(50)){
            lnbase = LN50;
            a0 = a.div(50);
        }else if(a > M100.mul(30)){
            lnbase = LN30;
            a0 = a.div(30);
        }else if(a > M100.mul(20)){
            lnbase = LN20;
            a0 = a.div(20);
        }else if(a > M100.mul(10)){
            lnbase = LN10;
            a0 = a.div(10);
        }else if(a > M100.mul(3)){
            lnbase = LN3;
            a0 = a.div(3);
        }else if(a > M100){
            lnbase = 0;
            a0 = a;
        }else{
            return _value;
        }
        uint256 x=a0.sub(M100).mul(M100).div(a0.add(M100));
        uint256 y=x.add(x.mul(x).mul(x)/M100/M100/3).mul(2);
        y=lnbase.add(y);
        y=y.mul(7)/100;
        x=a.add(a.mul(y)/M100);
        x = x.add(a.mul(y).mul(y)/M100/M100/2);
        y = a.mul(y).mul(y).mul(y);
        x = x.add(y/M100/M100/M100/6);
        return x.mul(1 ether).div(M100);
    }
    
    function modifair2(uint256 _value) public constant returns(uint256){
        if (now < endPreSaleTime)
        return _value.mul(GetProfitPercentForValue(weiRaised)).div(100);
    }
    
    function GetProfitPercentForValue(uint256 _value) public constant returns (uint256){
        uint256 value = _value;
        if(_value > ETHER_PROFIT_LIMIT.mul(1 ether)){
            value = internalGetProfitPercentForValue2(value);
        }else{
            value = internalGetProfitPercentForValue1(value);
        }
            
        return value;
    }
    
    function internalGetProfitPercentForValue1(uint256 _value) internal returns (uint256)
    {
        uint256 step = SALE_MAX_PROFIT.sub(SALE_MIN_PROFIT); 
        uint256 valueRest = uint256(ETHER_PROFIT_LIMIT).sub(_value.div(1 ether));
        uint256 profitProcent = valueRest.mul(step).div(ETHER_PROFIT_LIMIT);
        return profitProcent.add(SALE_MIN_PROFIT).add(100);
    }
    function internalGetProfitPercentForValue2(uint256 _value) internal returns (uint256)
    {
        uint256 divider = _value.mul(100).div(ETHER_PROFIT_STEP.mul(1 ether)).add(100).sub(ETHER_PROFIT_LIMIT.div(100));
        return AFTER_LIMIT_BASIC_PROFIT.mul(100).div(divider).add(100);
    }
    
    function addPay(address _beneficiary,uint256 _value) public onlyOwner validPay{
        uint256 value = _value;
        value = modifair1(value);
        if(now > endPreSaleTime){
            weiRaised = weiRaised.add(_value);
            value = modifair2(value);
        }else{
            preSaleWeiRaised = preSaleWeiRaised.add(_value); 
            value = value.mul(PRESALE_PROFIT.add(100)).div(100);
        }
        totalInternalValue = totalInternalValue.add(value);
        internalValue[_beneficiary].value = internalValue[_beneficiary].value.add(value);
        uint256 key = internalValue[_beneficiary].keyItem;
        if(key == 0){
            key = payers.length++;
            payers[key] = _beneficiary;
            internalValue[_beneficiary].keyItem = key;
        }
    }
    
    function tokenFallback(address _from, uint _value, bytes _data) returns(bool){
        require(msg.sender == address(token));
        require(_value > 0);
        haveTokens = haveTokens.add(_value);
        return true;
    }
}

contract ContinuousSale is Ownable{
    
    using SafeMath for uint256;
    
    uint256 constant BASIC_TOKEN_DAY_LIMIT = 2000000 ether;
    uint256 constant BASIC_COEFFICENT_1 = 60;
    
    struct entry{
        uint256 keyItem;
        uint256 value;
    }
    
    struct daily {
        uint256 saleTokens;
        uint256 totalSupply;
        mapping (address => entry) investor;
        address[] addressList;
    }
    
    SintezToken token;
    
    uint256 startTime;
    uint256 haveTokens;
    
    mapping (uint256 => daily) public organizer;
    
    function ContinuousSale(SintezToken _token, uint256 _startTime) public {
        startTime = _startTime;
        token = _token;
    }
    
    function dayFor(uint256 _timestamp) public constant returns (uint256) {
        return _timestamp < startTime ? 0: _timestamp.sub(startTime).div(5 minutes).add(1);
    }
    
    function today() public constant returns (uint256){
        return dayFor(now);
    }
    
    function selectTokens(uint256 _day) public constant returns (uint256){
        uint256 calculated = BASIC_TOKEN_DAY_LIMIT.mul(BASIC_COEFFICENT_1).div(BASIC_COEFFICENT_1.add(_day.sub(1)));
        return calculated;
    }
    
    function tokenForDay(uint256 _day) public returns (uint256){
        if(organizer[_day].saleTokens == 0){
            uint256 calc = selectTokens(_day);
            organizer[_day].saleTokens = (calc < haveTokens)? calc: haveTokens;
            haveTokens = haveTokens.sub(organizer[_day].saleTokens);
        }
        return organizer[_day].saleTokens;
    }
    
    function claim(uint8 _day) public{
        claimTo(msg.sender,_day);
    }
    
    function claimTo(address _beneficiary, uint8 _day) public {
        require(_day > 0 && _day < today());
        uint256 keyItem = organizer[_day].investor[_beneficiary].keyItem;
        require(keyItem != 0);
        
        uint256 value = tokenForDay(_day).mul(organizer[_day].investor[_beneficiary].value).div(organizer[_day].totalSupply);
        organizer[_day].addressList[keyItem] = organizer[_day].addressList[--organizer[_day].addressList.length];
        delete organizer[_day].investor[_beneficiary];
        
        token.transfer(_beneficiary,value);
    }
    
    function addPay(address _beneficiary,uint256 _value) public onlyOwner {
        uint256 _today = today();
        require(_today > 0);
        require(tokenForDay(_today) != 0);
        
        organizer[_today].investor[_beneficiary].value = organizer[_today].investor[_beneficiary].value.add(_value);
        if(organizer[_today].investor[_beneficiary].keyItem == 0){
            if(organizer[_today].addressList.length == 0){
                organizer[_today].addressList.push(0x0);
            }
            organizer[_today].investor[_beneficiary].keyItem = organizer[_today].addressList.length++;
        }
        organizer[_today].addressList[organizer[_today].investor[_beneficiary].keyItem] = _beneficiary;
        
        organizer[_today].totalSupply = organizer[_today].totalSupply.add(_value);
    }
    
        
    function tokenFallback(address _from, uint _value, bytes _data) returns(bool){
        require(msg.sender == address(token));
        require(_value > 0);
        haveTokens = haveTokens.add(_value);
        return true;
    }
    
}

contract TestCrowdsale is Ownable{
    ICO public ico;
    ContinuousSale public cont;
    
    SintezToken public token;
    
    uint256 public startPreSaleTime;
    uint256 public endPreSaleTime;
    uint256 public startIcoTime;
    uint256 public endIcoTime;
    address public beneficiary;
    
    
    function TestCrowdsale() public{
        token = new SintezToken();
        beneficiary = msg.sender;
    }
    
    function changeBeneficiary(address _beneficiary) onlyOwner
    {
        beneficiary = msg.sender;
    }
    
    function startICO(uint256 _startPreSaleTime, uint256 _endPreSaleTime, uint256 _startIcoTime, uint256 _endIcoTime) public onlyOwner{
        require(now < _startPreSaleTime && _startPreSaleTime<_endPreSaleTime && _endPreSaleTime<_startIcoTime && _startIcoTime < _endIcoTime);

        startPreSaleTime = _startPreSaleTime;
        endPreSaleTime = _endPreSaleTime;
        startIcoTime = _startIcoTime;
        endIcoTime = _endIcoTime;
        
        ico = new ICO(token, endPreSaleTime, endIcoTime);
        token.transfer(address(ico),250000000 ether);
    }
    
    function startContinuousSale(uint256 _firstDay)public onlyOwner{
        require(_firstDay > endIcoTime);
        cont = new ContinuousSale(token,_firstDay);
        token.transfer(address(cont),500000000 ether);
    }
    
    //TODO Выпилить
    //-->
    function byeToken(address _beneficiary, uint256 _value) public{
        require(address(ico) != 0x0);
        if((endIcoTime >= now && startIcoTime <= now) || (endPreSaleTime >= now && startPreSaleTime <= now)){
            ico.addPay(_beneficiary, _value);
        }else{
            require(address(cont) != 0x0 && endIcoTime < now);
            cont.addPay(_beneficiary, _value);
        }
    }
    
    function testPay(uint256 _value) public{
        byeToken(msg.sender, _value);
    }
    //<--
    
    
    // function byeToken(address _beneficiary) public payable{
    //     require(address(ico) != 0x0);
    //     if((endIcoTime >= now && startIcoTime <= now) || (endPreSaleTime >= now && startPreSaleTime <= now)){
    //         ico.addPay(_beneficiary, msg.value);
    //     }else{
    //         require(address(cont) != 0x0 && endIcoTime < now);
    //         cont.addPay(_beneficiary, msg.value);
    //     }
    //     beneficiary.transfer(msg.value);
    // }
    
    // function () public payable{
    //     byeToken(msg.sender);
    // }
    
}