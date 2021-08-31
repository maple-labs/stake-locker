// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import { DSTest } from "../../modules/ds-test/src/test.sol";

import { StakeLocker } from "../StakeLocker.sol";

import { Pool }         from "./accounts/Pool.sol";
import { PoolDelegate } from "./accounts/PoolDelegate.sol";
import { Staker }       from "./accounts/Staker.sol";

import { MapleGlobalsMock, PoolFactoryMock, PoolMock, MockToken } from "./mocks/Mocks.sol";

interface Hevm {
    function warp(uint256) external;
}

contract StakeLockerConstructorTest is DSTest {

    function test_constructor(address stakeAsset, address liquidityAsset, address pool) external {
        StakeLocker locker = new StakeLocker(stakeAsset, liquidityAsset, pool);

        assertEq(address(locker.stakeAsset()),     stakeAsset,     "Incorrect address of stake asset");
        assertEq(address(locker.liquidityAsset()), liquidityAsset, "Incorrect address of liquidity asset");
        assertEq(locker.pool(),                    pool,           "Incorrect address of pool");
        assertEq(locker.lockupPeriod(),            180 days,       "Incorrect lockup period");
    }

}

contract StakerTest is DSTest {

    Hevm hevm;

    PoolDelegate     internal delegate;
    PoolFactoryMock  internal factory;
    PoolMock         internal pool;
    MapleGlobalsMock internal globals;
    MockToken        internal stakeToken;
    MockToken        internal liquidityToken;
    StakeLocker      internal locker;
    Staker           internal staker;

    constructor() public {
        hevm = Hevm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));
    }

    function constrictToRange(uint256 value, uint256 min, uint256 max) internal pure returns (uint256) {
        return (value % (max - min)) + min;
    }

    function setUp() external {
        delegate       = new PoolDelegate();
        globals        = new MapleGlobalsMock();
        factory        = new PoolFactoryMock(address(globals));
        pool           = new PoolMock(address(factory), address(delegate));
        stakeToken     = new MockToken("ST", "ST");
        liquidityToken = new MockToken("LT", "LT");
        locker         = new StakeLocker(address(stakeToken), address(liquidityToken), address(pool));
        staker         = new Staker();
    }

    function test_stake(uint256 amount) external {
        amount = constrictToRange(amount, 1, type(uint256).max / block.timestamp);

        stakeToken.mint(address(staker), amount);
        staker.erc20_approve(address(stakeToken), address(locker), amount);

        assertTrue(!staker.try_stakeLocker_stake(address(locker), amount));

        delegate.stakeLocker_openStakeLockerToPublic(address(locker));

        assertTrue(staker.try_stakeLocker_stake(address(locker), amount));
        
        assertEq(locker.stakeDate(address(staker)), block.timestamp);
        assertEq(locker.balanceOf(address(staker)), amount);
    }

    function test_intendToUnstake(uint256 amount) external {
        amount = constrictToRange(amount, 1, type(uint256).max / block.timestamp);

        stakeToken.mint(address(staker), amount);
        staker.erc20_approve(address(stakeToken), address(locker), amount);
        delegate.stakeLocker_openStakeLockerToPublic(address(locker));
        staker.stakeLocker_stake(address(locker), amount);

        assertTrue(staker.try_stakeLocker_intendToUnstake(address(locker)));
        
        assertEq(locker.unstakeCooldown(address(staker)), block.timestamp);
    }

    function test_cancelUnstake(uint256 amount) external {
        amount = constrictToRange(amount, 1, type(uint256).max / block.timestamp);

        stakeToken.mint(address(staker), amount);
        staker.erc20_approve(address(stakeToken), address(locker), amount);
        delegate.stakeLocker_openStakeLockerToPublic(address(locker));
        staker.stakeLocker_stake(address(locker), amount);
        staker.stakeLocker_intendToUnstake(address(locker));

        assertTrue(staker.try_stakeLocker_cancelUnstake(address(locker)));
        
        assertEq(locker.unstakeCooldown(address(staker)), 0);
    }

    function test_unstake(uint256 stakeAmount, uint256 unstakeAmount1, uint256 unstakeAmount2) external {
        stakeAmount    = constrictToRange(stakeAmount, 100, type(uint256).max / block.timestamp);
        unstakeAmount1 = constrictToRange(unstakeAmount1, stakeAmount / 4, stakeAmount / 2);
        unstakeAmount2 = constrictToRange(unstakeAmount2, stakeAmount / 4, stakeAmount / 2);

        stakeToken.mint(address(staker), stakeAmount);
        staker.erc20_approve(address(stakeToken), address(locker), stakeAmount);
        delegate.stakeLocker_openStakeLockerToPublic(address(locker));
        staker.stakeLocker_stake(address(locker), stakeAmount);
        staker.stakeLocker_intendToUnstake(address(locker));

        uint256 start = block.timestamp;

        hevm.warp(start + globals.stakerCooldownPeriod() + (globals.stakerUnstakeWindow() / 2));

        // Can't unstake in unstake window yet (lockup not expired)
        assertTrue(!staker.try_stakeLocker_unstake(address(locker), 1));

        staker.stakeLocker_cancelUnstake(address(locker));

        hevm.warp(start + locker.lockupPeriod());

        // Can't unstake immediately (did not intend)
        assertTrue(!staker.try_stakeLocker_unstake(address(locker), 1));

        staker.stakeLocker_intendToUnstake(address(locker));

        hevm.warp(start + locker.lockupPeriod() + globals.stakerCooldownPeriod() - 1);

        // Can't unstake in cooldown
        assertTrue(!staker.try_stakeLocker_unstake(address(locker), 1));

        hevm.warp(start + locker.lockupPeriod() + globals.stakerCooldownPeriod());

        // Can unstake at start of unstake window
        assertTrue(staker.try_stakeLocker_unstake(address(locker), unstakeAmount1));
        
        assertEq(locker.balanceOf(address(staker)), stakeAmount - unstakeAmount1);

        hevm.warp(start + locker.lockupPeriod() + globals.stakerCooldownPeriod() + globals.stakerUnstakeWindow());

        // Can unstake at end of unstake window
        assertTrue(staker.try_stakeLocker_unstake(address(locker), unstakeAmount2));
        
        assertEq(locker.balanceOf(address(staker)), stakeAmount - (unstakeAmount1 + unstakeAmount2));

        hevm.warp(start + locker.lockupPeriod() + globals.stakerCooldownPeriod() + globals.stakerUnstakeWindow() + 1);

        // Can't unstake past unstake window
        assertTrue(!staker.try_stakeLocker_unstake(address(locker), 1));
    }

}

contract StakeLockerAsPoolDelegateTest is DSTest {

    MapleGlobalsMock internal globals;
    PoolDelegate     internal delegate;
    PoolDelegate     internal notDelegate;
    PoolFactoryMock  internal factory;
    PoolMock         internal pool;
    StakeLocker      internal locker;

    function setUp() external {
        delegate    = new PoolDelegate();
        notDelegate = new PoolDelegate();
        globals     = new MapleGlobalsMock();
        factory     = new PoolFactoryMock(address(globals));
        pool        = new PoolMock(address(factory), address(delegate));
        locker      = new StakeLocker(address(1), address(2), address(pool));
    }

    function test_setAllowlist(address staker) external {
        assertTrue(!notDelegate.try_stakeLocker_setAllowlist(address(locker), staker, true));
        assertTrue(    delegate.try_stakeLocker_setAllowlist(address(locker), staker, true));

        assertTrue(locker.allowed(staker));

        assertTrue(!notDelegate.try_stakeLocker_setAllowlist(address(locker), staker, false));
        assertTrue(    delegate.try_stakeLocker_setAllowlist(address(locker), staker, false));

        assertTrue(!locker.allowed(staker));
    }

    function test_openStakeLockerToPublic() external {
        assertTrue(!notDelegate.try_stakeLocker_openStakeLockerToPublic(address(locker)));
        assertTrue(    delegate.try_stakeLocker_openStakeLockerToPublic(address(locker)));

        assertTrue(locker.openToPublic());
    }

}

contract StakeLockerAsPoolTest is DSTest {
    
    MockToken   internal stakeToken;
    Pool        internal owner;
    Pool        internal nonOwner;
    StakeLocker internal locker;

    function setUp() external {
        owner      = new Pool();
        nonOwner   = new Pool();
        stakeToken = new MockToken("ST", "ST");
        locker     = new StakeLocker(address(stakeToken), address(1), address(owner));
    }

    function test_pull(address destination, uint256 amount) external {
        destination = destination == address(0) ? address(1) : destination;
        stakeToken.mint(address(locker), amount);

        assertTrue(!nonOwner.try_stakeLocker_pull(address(locker), destination, amount));
        assertTrue(    owner.try_stakeLocker_pull(address(locker), destination, amount));
    }

}
