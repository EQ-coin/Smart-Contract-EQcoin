// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import {Ownable} from "./Ownable.sol";

abstract contract BlackList is Ownable {
    /////// Getters to allow the same blacklist to be used also by other contracts (including upgraded Tether) ///////
    function getBlackListStatus(address _maker) public view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    mapping(address => bool) public isBlackListed;

    function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    // function destroyBlackFunds(address _blackListedUser) public onlyOwner {
    //     require(isBlackListed[_blackListedUser]);
    //     uint dirtyFunds = balanceOf(_blackListedUser);
    //     balances[_blackListedUser] = 0;
    //     _totalSupply -= dirtyFunds;
    //     emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    // }

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);
}
