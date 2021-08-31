// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import { DSTest } from "../../modules/ds-test/src/test.sol";

import { IStakeLocker } from "../interfaces/IStakeLocker.sol";

import { StakeLockerFactory } from "../StakeLockerFactory.sol";

import { Pool } from "./accounts/Pool.sol";

contract StakeLockerFactoryTest is DSTest {

    function test_newLocker(address stakeToken, address liquidityToken) external {
        StakeLockerFactory factory = new StakeLockerFactory();
        Pool               pool    = new Pool();

        IStakeLocker locker = IStakeLocker(pool.stakeLockerFactory_newLocker(address(factory), stakeToken, liquidityToken));

        // Validate the storage of factory.
        assertEq(factory.owner(address(locker)), address(pool), "Invalid owner");

        assertTrue(factory.isLocker(address(locker)), "Invalid isLocker");
    }

}
