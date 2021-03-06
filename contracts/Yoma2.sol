pragma solidity ^0.4.23;



contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}



contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


contract GoldenUnitToken is BasicToken {
  string public constant name = "Golden Unite Token";
  string public constant symbol = "GUT";
  uint32 public constant decimals = 18;
  uint256 public INITIAL_SUPPLY = 50000 * 1 ether;
  address public CrowdsaleAddress;
  
  event Mint(address indexed to, uint256 amount);
  
  constructor(address _CrowdsaleAddress) public {
    
    CrowdsaleAddress = _CrowdsaleAddress;
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;      
  }
  
    modifier onlyOwner() {
    require(msg.sender == CrowdsaleAddress);
    _;
  }

    function acceptTokens(address _from, uint256 _value) public onlyOwner payable returns (bool){
        require (balances[_from]>= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[CrowdsaleAddress] = balances[CrowdsaleAddress].add(_value);
        return true;
    }
  
    function mint(uint256 _amount) onlyOwner public returns (bool){
        totalSupply_ = totalSupply_.add(_amount);
        balances[CrowdsaleAddress] = balances[CrowdsaleAddress].add(_amount);
        emit Mint(CrowdsaleAddress, _amount);
        emit Transfer(address(0), CrowdsaleAddress, _amount);
        return true;
    }


  function() external payable {
      // The token contract don`t receive ether
        revert();
  }  
}


 contract Ownable {
  address public owner;
  address candidate;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    candidate = newOwner;
  }

  function confirmOwnership() public {
    require(candidate == msg.sender);
    owner = candidate;
    delete candidate;
  }

}


contract Crowdsale is Ownable {
  using SafeMath for uint; 
  address myAddress = this;
  uint public  saleRate = 30;  //tokens for 1 ether
  uint public  purchaseRate = 30;  //tokens for 1 ether
  bool public purchaseTokens = false;

  event Mint(address indexed to, uint256 amount);

  modifier purchaseAlloved() {
      // The contract accept tokens
    require(purchaseTokens);
    _;
  }

  event SaleRates(uint256 indexed value);
  event PurchaseRates(uint256 indexed value);

  GoldenUnitToken public token = new GoldenUnitToken(myAddress);
  

    function mintTokens(uint256 _amount) public onlyOwner returns (bool){
        //_amount in tokens. 1 = 1 token
        require (_amount <=1000000);
        _amount = _amount.mul(1 ether);
        token.mint(_amount);
        return true;
    }


    function giveTokens(address _newInvestor, uint256 _value) public onlyOwner payable {
        // the function give tokens to new investors
        // the sum is entered in whole tokens (1 = 1 token)
        
        require (_newInvestor!= address(0));
        require (_value >= 1);
        _value = _value.mul(1 ether);
        token.transfer(_newInvestor, _value);
            
        
    }  
    


 
 
  function setSaleRate(uint newRate) public onlyOwner {
      saleRate = newRate;
      emit SaleRates(newRate);
  }
  
  function setPurchaseRate(uint newRate) public onlyOwner {
      purchaseRate = newRate;
      emit PurchaseRates(newRate);
  }  
   
  function startPurchaseTokens() public onlyOwner {
      purchaseTokens = true;
  }

  function stopPurchaseTokens() public onlyOwner {
      purchaseTokens = false;
  }
  
  function purchase (uint256 _valueTokens) public purchaseAlloved payable {
    // function purchase tokens and send ether to sender
    address profitOwner = msg.sender;
    require(profitOwner != address(0));
    require(_valueTokens > 0);
    _valueTokens = _valueTokens.mul(1 ether);
    // ��������� ��� ������ ����� ������� ������� �� �������
    require (token.balanceOf(profitOwner)>= _valueTokens);
    // ���������� ���-�� ����� � ������
    require (purchaseRate>0);
    uint256 _valueEther = _valueTokens.div(purchaseRate);
    // ��������� ��� ���-�� ����� ���� �� �������
    require (myAddress.balance >= _valueEther);
    // ��������� ������
    if (token.acceptTokens(msg.sender, _valueTokens)){
        // ��������� �����
        profitOwner.transfer(_valueEther);
    }
  }
  
  function WithdrawProfit (address _to, uint256 _value) public onlyOwner payable {
    // ����� ����� ������� ������ �������
    require (myAddress.balance >= _value);
    require(_to != address(0));
    _to.transfer(_value);
      
  }
 
    function saleTokens() internal {
        require (msg.value >= 1 ether);  //minimum 1 ether
        uint tokens = saleRate.mul(msg.value);
        token.transfer(msg.sender, tokens);
    }
 
    function() external payable {
        saleTokens();
    }    
 
}