// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { ERC2258User } from "../../../modules/custodial-ownership-token/contracts/test/accounts/ERC2258User.sol";

import { IStakeLocker } from "../../interfaces/IStakeLocker.sol";

import { StakeLockerFDTUser } from "./StakeLockerFDTUser.sol";

contract Staker is ERC2258User, StakeLockerFDTUser {

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

}
