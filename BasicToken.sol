// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./SafeMath.sol";

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20Basic {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function totalSupply() external view returns (uint);

    function balanceOf(address who) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function approve(address spender, uint value) external returns (bool);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
abstract contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    error wrongPayloadSize();
    error wrongAddress();
    error notEnoughBalance();
    // error tooManyFee();

    // uint public _totalSupply;

    mapping(address => uint) public balances;

    // additional variables for use if transaction fees ever became necessary
    // uint public basisPointsRate = 0;
    // uint public maximumFee = 0;
    // uint256 constant MAX_SETTABLE_BASIS_POINTS = 20;
    // uint256 constant MAX_SETTABLE_FEE = 50;

    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size) {
        if (msg.data.length < size + 4) {
            revert wrongPayloadSize();
        }
        _;
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(
        address _to,
        uint _value
    ) public virtual override onlyPayloadSize(2 * 32) returns (bool) {
        if (_to == address(this) || _to == address(0)) {
            revert wrongAddress();
        }
        if (_value > balances[msg.sender]) {
            revert notEnoughBalance();
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return balance An uint representing the amount owned by the passed address.
     */
    function balanceOf(
        address _owner
    ) public view virtual override returns (uint balance) {
        return balances[_owner];
    }
}
