// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import {StandardTokenWithFees} from "./StandardTokenWithFees.sol";
import {StandardToken} from "./StandardToken.sol";
import {ERC20Basic} from "./BasicToken.sol";
import {Pausable} from "./Pausable.sol";
import {BlackList, Ownable} from "./BlackList.sol";
import "./SafeMath.sol";

interface UpgradedStandardToken is ERC20Basic {
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    function transferByLegacy(
        address from,
        address to,
        uint value
    ) external view returns (bool);

    function transferFromByLegacy(
        address sender,
        address from,
        address spender,
        uint value
    ) external view returns (bool);

    function approveByLegacy(
        address from,
        address spender,
        uint value
    ) external view returns (bool);

    function increaseApprovalByLegacy(
        address from,
        address spender,
        uint addedValue
    ) external view returns (bool);

    function decreaseApprovalByLegacy(
        address from,
        address spender,
        uint subtractedValue
    ) external view returns (bool);
}

contract EQuicoin is Pausable, StandardTokenWithFees, BlackList {
    using SafeMath for uint;

    error AddressZero();
    error inBlackList();
    error wrongFeeParams();
    error wrongAmount();
    error onDeprecated();

    address public upgradedAddress;
    bool public deprecated;

    modifier notAddressZero(address target) {
        if (target == address(0)) {
            revert AddressZero();
        }
        _;
    }

    modifier notInBlackList(address user) {
        if (isBlackListed[user]) {
            revert inBlackList();
        }
        _;
    }

    modifier onlyNotDeprecated() {
        if (deprecated) {
            revert onDeprecated();
        }
        _;
    }

    // @param _balance Initial supply of the contract
    // @param _name Token Name
    // @param _symbol Token symbol
    // @param _decimals Token decimals
    constructor(
        uint _initialSupply,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) payable Ownable() {
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[owner] = _initialSupply;
        deprecated = false;
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transfer(
        address _to,
        uint _value
    )
        public
        virtual
        override
        whenNotPaused
        notAddressZero(_to)
        notInBlackList(msg.sender)
        returns (bool)
    {
        if (deprecated) {
            return
                UpgradedStandardToken(upgradedAddress).transferByLegacy(
                    msg.sender,
                    _to,
                    _value
                );
        } else {
            return super.transfer(_to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transferFrom(
        address _from,
        address _to,
        uint _value
    )
        public
        virtual
        override
        whenNotPaused
        notAddressZero(_to)
        notInBlackList(_from)
        returns (bool)
    {
        if (deprecated) {
            return
                UpgradedStandardToken(upgradedAddress).transferFromByLegacy(
                    msg.sender,
                    _from,
                    _to,
                    _value
                );
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function balanceOf(
        address who
    ) public view virtual override returns (uint) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function approve(
        address _spender,
        uint _value
    ) public virtual override onlyPayloadSize(2 * 32) returns (bool) {
        if (deprecated) {
            return
                UpgradedStandardToken(upgradedAddress).approveByLegacy(
                    msg.sender,
                    _spender,
                    _value
                );
        } else {
            return super.approve(_spender, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function allowance(
        address _owner,
        address _spender
    ) public view virtual override returns (uint remaining) {
        if (deprecated) {
            return StandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

    // deprecate current contract in favour of a new one
    function deprecate(address _upgradedAddress) public onlyOwner {
        if (_upgradedAddress == upgradedAddress) {
            revert wrongAddress();
        }
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    // deprecate current contract if favour of a new one
    function totalSupply() public view virtual override returns (uint) {
        if (deprecated) {
            return StandardToken(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }

    // Issue a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function issue(uint amount) public onlyOwner onlyNotDeprecated {
        if (
            _totalSupply + amount <= _totalSupply ||
            balances[owner] + amount <= balances[owner]
        ) {
            revert wrongAmount();
        }

        balances[owner] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), owner, amount);
    }

    // Redeem tokens.
    // These tokens are withdrawn from the owner address
    // if the balance must be enough to cover the redeem
    // or the call will fail.
    // @param _amount Number of tokens to be issued
    function redeem(uint amount) public onlyOwner {
        if (_totalSupply < amount || balances[owner] < amount) {
            revert wrongAmount();
        }

        _totalSupply = _totalSupply.sub(amount);
        balances[owner] = balances[owner].sub(amount);
        emit Transfer(owner, address(0), amount);
    }

    function destroyBlackFunds(address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply = _totalSupply.sub(dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address indexed _blackListedUser, uint _balance);
    // Called when contract is deprecated
    event Deprecate(address newAddress);
}
