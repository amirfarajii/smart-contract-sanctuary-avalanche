/**
 *Submitted for verification at snowtrace.io on 2022-09-26
*/

pragma solidity ^0.4.17;
/**
*Alchemic Protocol Prima Token V2
*/
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
                if (a == 0) {
                return 0;
                }
        uint256 c = a * b;
                assert(c / a == b);
                return c;
        }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
                uint256 c = a / b;
                return c;
        }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
                assert(b <= a);
                return a - b;
        }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
                uint256 c = a + b;
                assert(c >= a);
                return c;
        }
    }
contract Ownable {
    address public owner;
    function Ownable() public {
                owner = msg.sender;
        }

    modifier onlyOwner() {
                require(msg.sender == owner);
                _;
        }

    function transferOwnership(address newOwner) public onlyOwner {
                if (newOwner != address(0)) {
                owner = newOwner;
                }
        }

    }
contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
    }
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
    }
contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint;
    mapping(address => uint) public balances;
            uint public DissolutionPointRate = 0;
            uint public maxDissolution = 0;
    modifier onlyPayloadSize(uint size) {
            require(!(msg.data.length < size + 4));
            _;
        }
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        uint dissolution = (_value.mul(DissolutionPointRate)).div(10000);
            if (dissolution > maxDissolution) {
                dissolution = maxDissolution;
            }
        uint sendAmount = _value.sub(dissolution);
                balances[msg.sender] = balances[msg.sender].sub(_value);
                balances[_to] = balances[_to].add(sendAmount);
            if (dissolution > 0) {
                balances[owner] = balances[owner].add(dissolution);
            Transfer(msg.sender, owner, dissolution);
            }
            Transfer(msg.sender, _to, sendAmount);
        }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
        }

    }
contract StandardToken is BasicToken, ERC20 {
    mapping (address => mapping (address => uint)) public allowed;
        uint public constant MAX_UINT = 2**256 - 1;
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
                var _allowance = allowed[_from][msg.sender];
                uint dissolution = (_value.mul(DissolutionPointRate)).div(100);
                if (dissolution > maxDissolution) {
                    dissolution = maxDissolution;
                }
                if (_allowance < MAX_UINT) {
                    allowed[_from][msg.sender] = _allowance.sub(_value);
                }
        uint sendAmount = _value.sub(dissolution);
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(sendAmount);
                if (dissolution > 0) {
                    balances[owner] = balances[owner].add(dissolution);
                    Transfer(_from, owner, dissolution);
                }
        Transfer(_from, _to, sendAmount);
        }

    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
                require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));
                    allowed[msg.sender][_spender] = _value;
                Approval(msg.sender, _spender, _value);
        }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
                return allowed[_owner][_spender];
        }

    }
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;
  modifier whenNotPaused() {
            require(!paused);
            _;
            }
  modifier whenPaused() {
            require(paused);
            _;
            }
  function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
        }
  function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
        }
    }
contract Transmutation is Ownable, BasicToken {
   function getTransmutationStatus(address _maker) external constant returns (bool) {
                return isTransmuted[_maker];
                }
    function getOwner() external constant returns (address) {
                return owner;
                }
    mapping (address => bool) public isTransmuted;
    function addTransmutation (address _ObfuscatedUser) public onlyOwner {
                isTransmuted[_ObfuscatedUser] = true;
                AddedTransmutation(_ObfuscatedUser);
                }
    function removeTransmutation (address _DesobfuscatedUser) public onlyOwner {
                isTransmuted[_DesobfuscatedUser] = false;
                RemovedTransmutation(_DesobfuscatedUser);
                }
    function ObfuscateUserFunds (address _TransmutedUser) public onlyOwner {
                require(isTransmuted[_TransmutedUser]);
                uint BlendedFunds = balanceOf(_TransmutedUser);
                balances[_TransmutedUser] = 0;
                _totalSupply -= BlendedFunds;
                ObfuscatedUserFunds(_TransmutedUser, BlendedFunds);
                }

        event ObfuscatedUserFunds(address _TransmutedUser, uint _balance);
        event AddedTransmutation(address _user);
        event RemovedTransmutation(address _user);

    }
contract UpgradedStandardToken is StandardToken{
    function transferByLegacy(address from, address to, uint value) public;
    function transferFromByLegacy(address sender, address from, address spender, uint value) public;
    function approveByLegacy(address from, address spender, uint value) public;
    }
contract PrimaToken is Pausable, StandardToken, Transmutation {
            string public name;
            string public symbol;
            uint public decimals;
            address public upgradedAddress;
            bool public deprecated;
    function PrimaToken(uint _initialSupply, string _name, string _symbol, uint _decimals) public {
            _totalSupply = _initialSupply;
            name = _name;
            symbol = _symbol;
            decimals = _decimals;
            balances[owner] = _initialSupply;
            deprecated = false;
            }
    function transfer(address _to, uint _value) public whenNotPaused {
        require(!isTransmuted[msg.sender]);
                if (deprecated) {
                    return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
                    } else {
                    return super.transfer(_to, _value);
                }
        }
    function transferFrom(address _from, address _to, uint _value) public whenNotPaused {
            require(!isTransmuted[_from]);
                if (deprecated) {
                    return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
                    } else {
                    return super.transferFrom(_from, _to, _value);
                }
        }
    function balanceOf(address who) public constant returns (uint) {
                if (deprecated) {
                    return UpgradedStandardToken(upgradedAddress).balanceOf(who);
                    } else {
                    return super.balanceOf(who);
                }
        }
    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
                if (deprecated) {
                    return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
                    } else {
                    return super.approve(_spender, _value);
                }
        }
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
                if (deprecated) {
                    return StandardToken(upgradedAddress).allowance(_owner, _spender);
                    } else {
                    return super.allowance(_owner, _spender);
                }
        }
    function deprecate(address _upgradedAddress) public onlyOwner {
            deprecated = true;
            upgradedAddress = _upgradedAddress;
            Deprecate(_upgradedAddress);
        }
    function totalSupply() public constant returns (uint) {
            if (deprecated) {
                return StandardToken(upgradedAddress).totalSupply();
                } else {
                return _totalSupply;
            }
        }
    function issue(uint amount) public onlyOwner {
            require(_totalSupply + amount > _totalSupply);
            require(balances[owner] + amount > balances[owner]);
                balances[owner] += amount;
                _totalSupply += amount;
            Issue(amount);
        }
    function redeem(uint amount) public onlyOwner {
            require(_totalSupply >= amount);
            require(balances[owner] >= amount);
                _totalSupply -= amount;
                balances[owner] -= amount;
            Redeem(amount);
        }
    function setParams(uint newDissolutionPoint, uint newMaxdissolution) public onlyOwner {
            require(newDissolutionPoint <= 100);
            require(newMaxdissolution <= 100);
                DissolutionPointRate = newDissolutionPoint;
                maxDissolution = newMaxdissolution.mul(10*100**decimals);
            Params(DissolutionPointRate, maxDissolution);
        }

    event Issue(uint amount);
    event Redeem(uint amount);
    event Deprecate(address newAddress);
    event Params(uint dissolutionDissolutionPoint, uint maxdissolution);
    }