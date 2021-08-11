// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { IStakeLocker } from "../../interfaces/IStakeLocker.sol";

contract StakeLockerPoolDelegate {

    /************************/
    /*** Direct Functions ***/
    /************************/
    function stakeLocker_setAllowlist(address locker, address staker, bool status) external {
        IStakeLocker(locker).setAllowlist(staker, status);
    }

    function stakeLocker_openStakeLockerToPublic(address locker) external {
        IStakeLocker(locker).openStakeLockerToPublic();
    }

    /*********************/
    /*** Try Functions ***/
    /*********************/
    function try_stakeLocker_setAllowlist(address locker, address staker, bool status) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSignature("setAllowlist(address,bool)", staker, status));
    }

    function try_stakeLocker_openStakeLockerToPublic(address locker) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSignature("openStakeLockerToPublic()"));
    }

}
