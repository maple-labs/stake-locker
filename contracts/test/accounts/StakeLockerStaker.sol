// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { IERC20 } from "../../../modules/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import { IStakeLocker } from "../../interfaces/IStakeLocker.sol";

contract StakeLockerStaker {

    /************************/
    /*** Direct Functions ***/
    /************************/
    function erc20_approve(address token, address spender, uint256 amount) external {
        IERC20(token).approve(spender, amount);
    }

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
        (ok,) = locker.call(abi.encodeWithSignature("stake(uint256)", amount));
    }

    function try_stakeLocker_intendToUnstake(address locker) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSignature("intendToUnstake()"));
    }

    function try_stakeLocker_cancelUnstake(address locker) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSignature("cancelUnstake()"));
    }

    function try_stakeLocker_unstake(address locker, uint256 amount) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSignature("unstake(uint256)", amount));
    }

}
