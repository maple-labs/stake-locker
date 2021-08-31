// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { IStakeLocker } from "../../interfaces/IStakeLocker.sol";

import { PoolAdmin } from "./PoolAdmin.sol";

contract PoolDelegate is PoolAdmin {

    /************************/
    /*** Direct Functions ***/
    /************************/

    function stakeLocker_setAllowlist(address locker, address staker, bool status) external {
        IStakeLocker(locker).setAllowlist(staker, status);
    }

    function stakeLocker_openStakeLockerToPublic(address locker) external {
        IStakeLocker(locker).openStakeLockerToPublic();
    }

    function stakeLocker_setLockupPeriod(address locker, uint256 newLockupPeriod) external {
        IStakeLocker(locker).setLockupPeriod(newLockupPeriod);
    }

    /*********************/
    /*** Try Functions ***/
    /*********************/

    function try_stakeLocker_setAllowlist(address locker, address staker, bool status) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSelector(IStakeLocker.setAllowlist.selector, staker, status));
    }

    function try_stakeLocker_openStakeLockerToPublic(address locker) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSelector(IStakeLocker.openStakeLockerToPublic.selector));
    }

    function try_stakeLocker_setLockupPeriod(address locker, uint256 newLockupPeriod) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSelector(IStakeLocker.setLockupPeriod.selector, newLockupPeriod));
    }

}
