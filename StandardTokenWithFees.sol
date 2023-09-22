// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import {StandardToken} from "./StandardToken.sol";
import {Ownable} from "./Ownable.sol";
import "./SafeMath.sol";

abstract contract StandardTokenWithFees is StandardToken, Ownable {
    using SafeMath for uint;
    // Additional variables for use if transaction fees ever became necessary
    uint256 public basisPointsRate = 0;
    uint256 public maximumFee = 0;
    uint256 constant MAX_SETTABLE_BASIS_POINTS = 20;
    uint256 constant MAX_SETTABLE_FEE = 50;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint public _totalSupply;

    function calcFee(uint _value) public view returns (uint) {
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        return fee;
    }

    function transfer(
        address _to,
        uint _value
    ) public virtual override returns (bool) {
        uint fee = calcFee(_value);
        uint sendAmount = _value.sub(fee);

        super.transfer(_to, sendAmount);
        if (fee > 0) {
            super.transfer(owner, fee);
        }

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual override returns (bool) {
        if (_to == address(this) || _to == address(0)) {
            revert wrongAddress();
        }
        if (_value > balances[_from]) {
            revert notEnoughBalance();
        }
        if (_value > allowed[_from][msg.sender]) {
            revert notEnoughAllowance();
        }

        uint fee = calcFee(_value);
        uint sendAmount = _value.sub(fee);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (allowed[_from][msg.sender] < MAX_UINT) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        emit Transfer(_from, _to, sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(_from, owner, fee);
        }
        return true;
    }

    function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(newBasisPoints < MAX_SETTABLE_BASIS_POINTS);
        require(newMaxFee < MAX_SETTABLE_FEE);

        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(uint(10) ** decimals);

        emit Params(basisPointsRate, maximumFee);
    }

    // Called if contract ever adds fees
    event Params(uint feeBasisPoints, uint maxFee);
}
