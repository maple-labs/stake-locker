// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { IStakeLocker }        from "../../interfaces/IStakeLocker.sol";
import { IStakeLockerFactory } from "../../interfaces/IStakeLockerFactory.sol";

contract StakeLockerOwner {

    function stakeLockerFactory_newLocker(address factory, address stakeAsset, address liquidityAsset) external returns (address) {
        return IStakeLockerFactory(factory).newLocker(stakeAsset, liquidityAsset);
    }

    function try_stakeLockerFactory_newLocker(address factory, address stakeAsset, address liquidityAsset) external returns (bool ok) {
        (ok,) = factory.call(abi.encodeWithSignature("newLocker(address,address)", stakeAsset, liquidityAsset));
    }

    function stakeLocker_pull(address locker, address destination, uint256 amount) external {
        IStakeLocker(locker).pull(destination, amount);
    }

    function try_stakeLocker_pull(address locker, address destination, uint256 amount) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSignature("pull(address,uint256)", destination, amount));
    }

}
