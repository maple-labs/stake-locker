// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { IStakeLocker } from "../../interfaces/IStakeLocker.sol";

contract PoolAdmin {

    /************************/
    /*** Direct Functions ***/
    /************************/

    function stakeLocker_pause(address locker) external {
        IStakeLocker(locker).pause();
    }

    function stakeLocker_unpause(address locker) external {
        IStakeLocker(locker).unpause();
    }

    /*********************/
    /*** Try Functions ***/
    /*********************/

    function try_stakeLocker_pause(address locker) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSelector(IStakeLocker.pause.selector));
    }

    function try_stakeLocker_unpause(address locker) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSelector(IStakeLocker.unpause.selector));
    }

}
