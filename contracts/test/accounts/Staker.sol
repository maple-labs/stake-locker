// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { IStakeLocker } from "../../interfaces/IStakeLocker.sol";

import { StakeLockerFDTUser } from "./StakeLockerFDTUser.sol";

contract Staker is StakeLockerFDTUser {

    /************************/
    /*** Direct Functions ***/
    /************************/

    function stakeLocker_stake(address locker, uint256 amount) external {
        IStakeLocker(locker).stake(amount);
    }

    function stakeLocker_intendToUnstake(address locker) external {
        IStakeLocker(locker).intendToUnstake();
    }

    function stakeLocker_cancelUnstake(address locker) external {
        IStakeLocker(locker).cancelUnstake();
    }

    function stakeLocker_unstake(address locker, uint256 amount) external {
        IStakeLocker(locker).unstake(amount);
    }

    function stakeLocker_increaseCustodyAllowance(address locker, address custodian, uint256 amount) external {
        IStakeLocker(locker).increaseCustodyAllowance(custodian, amount);
    }

    /*********************/
    /*** Try Functions ***/
    /*********************/

    function try_stakeLocker_stake(address locker, uint256 amount) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSelector(IStakeLocker.stake.selector, amount));
    }

    function try_stakeLocker_intendToUnstake(address locker) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSelector(IStakeLocker.intendToUnstake.selector));
    }

    function try_stakeLocker_cancelUnstake(address locker) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSelector(IStakeLocker.cancelUnstake.selector));
    }

    function try_stakeLocker_unstake(address locker, uint256 amount) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSelector(IStakeLocker.unstake.selector, amount));
    }

    function try_stakeLocker_increaseCustodyAllowance(address locker, address custodian, uint256 amount) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSelector(IStakeLocker.increaseCustodyAllowance.selector, custodian, amount));
    }

}
