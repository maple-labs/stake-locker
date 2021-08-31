// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { IStakeLocker } from "../../interfaces/IStakeLocker.sol";

contract Custodian {

    /************************/
    /*** Direct Functions ***/
    /************************/

    function stakeLocker_transferByCustodian(address locker, address from, address to, uint256 amount) external {
        IStakeLocker(locker).transferByCustodian(from, to, amount);
    }

    /*********************/
    /*** Try Functions ***/
    /*********************/

    function try_stakeLocker_transferByCustodian(address locker, address from, address to, uint256 amount) external returns (bool ok) {
        (ok,) = locker.call(abi.encodeWithSelector(IStakeLocker.transferByCustodian.selector, from, to, amount));
    }

}
