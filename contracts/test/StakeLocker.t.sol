// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import { DSTest } from "../../modules/ds-test/src/test.sol";
import { ERC20 }  from "../../modules/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import { StakeLocker } from "../StakeLocker.sol";

import { StakeLockerOwner }        from "./accounts/StakeLockerOwner.sol";
import { StakeLockerPoolDelegate } from "./accounts/StakeLockerPoolDelegate.sol";
import { StakeLockerStaker }       from "./accounts/StakeLockerStaker.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
}

contract MapleGlobalsMock {

    bool public constant protocolPaused = false;
    uint256 public constant stakerCooldownPeriod = 1 days;
    uint256 public constant stakerUnstakeWindow = 1 days;

}

contract PoolFactoryMock {

    address public immutable globals;

    constructor(address _globals) public {
        globals = _globals;
    }

}

contract PoolMock {

    address public immutable superFactory;
    address public immutable poolDelegate;
    bool    public constant  isPoolFinalized = false;

    constructor(address _superFactory, address _poolDelegate) public {
        superFactory = _superFactory;
        poolDelegate = _poolDelegate;
    }

}

contract MockToken is ERC20 {

    constructor (string memory name, string memory symbol) ERC20(name, symbol) public {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

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

contract StakeLockerStakerTest is DSTest {

    Hevm hevm;

    StakeLockerPoolDelegate internal delegate;
    MapleGlobalsMock        internal globals;
    PoolFactoryMock         internal factory;
    PoolMock                internal pool;
    MockToken               internal stakeToken;
    MockToken               internal liquidityToken;
    StakeLocker             internal locker;
    StakeLockerStaker       internal staker;

    constructor() public {
        hevm = Hevm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));
    }

    function constrictToRange(uint256 value, uint256 min, uint256 max) internal pure returns (uint256) {
        return value % (max - min) + min;        
    }

    function setUp() external {
        delegate       = new StakeLockerPoolDelegate();
        globals        = new MapleGlobalsMock();
        factory        = new PoolFactoryMock(address(globals));
        pool           = new PoolMock(address(factory), address(delegate));
        stakeToken     = new MockToken("ST", "ST");
        liquidityToken = new MockToken("LT", "LT");
        locker         = new StakeLocker(address(stakeToken), address(liquidityToken), address(pool));
        staker         = new StakeLockerStaker();
    }

    function test_stake(uint256 amount) external {
        amount = constrictToRange(amount, 1, type(uint256).max / block.timestamp);

        stakeToken.mint(address(staker), amount);
        staker.erc20_approve(address(stakeToken), address(locker), amount);

        assertTrue(!staker.try_stakeLocker_stake(address(locker), amount));

        delegate.stakeLocker_openStakeLockerToPublic(address(locker));

        assertTrue( staker.try_stakeLocker_stake(address(locker), amount));
        
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

    function test_unstake(uint256 stakeAmount, uint256 unstakeAmount) external {
        stakeAmount = constrictToRange(stakeAmount, 1, type(uint256).max / block.timestamp);
        unstakeAmount = constrictToRange(unstakeAmount, 1, stakeAmount);

        stakeToken.mint(address(staker), stakeAmount);
        staker.erc20_approve(address(stakeToken), address(locker), stakeAmount);
        delegate.stakeLocker_openStakeLockerToPublic(address(locker));
        staker.stakeLocker_stake(address(locker), stakeAmount);
        staker.stakeLocker_intendToUnstake(address(locker));

        uint256 start = block.timestamp;

        // Can't unstake immediately (lockup not expired)
        assertTrue(!staker.try_stakeLocker_unstake(address(locker), unstakeAmount));

        hevm.warp(start + globals.stakerCooldownPeriod() - 1);

        // Can't unstake in cooldown (lockup not expired)
        assertTrue(!staker.try_stakeLocker_unstake(address(locker), unstakeAmount));

        hevm.warp(start + globals.stakerCooldownPeriod() + (globals.stakerUnstakeWindow() / 2));

        // Can't unstake in unstake window yet (lockup not expired)
        assertTrue(!staker.try_stakeLocker_unstake(address(locker), unstakeAmount));

        staker.stakeLocker_cancelUnstake(address(locker));

        hevm.warp(start + 180 days + 1);

        // Can't unstake immediately (did not intend)
        assertTrue(!staker.try_stakeLocker_unstake(address(locker), unstakeAmount));

        staker.stakeLocker_intendToUnstake(address(locker));

        hevm.warp(start + 180 days + 1 + globals.stakerCooldownPeriod() - 1);

        // Can't unstake in cooldown
        assertTrue(!staker.try_stakeLocker_unstake(address(locker), unstakeAmount));

        hevm.warp(start + 180 days + 1 + globals.stakerCooldownPeriod());

        // Can unstake in cooldown
        assertTrue(staker.try_stakeLocker_unstake(address(locker), unstakeAmount));
        
        assertEq(locker.balanceOf(address(staker)), stakeAmount - unstakeAmount);
    }

}

contract StakeLockerAsPoolDelegateTest is DSTest {

    StakeLockerPoolDelegate internal delegate;
    StakeLockerPoolDelegate internal notDelegate;
    MapleGlobalsMock        internal globals;
    PoolFactoryMock         internal factory;
    PoolMock                internal pool;
    StakeLocker             internal locker;

    function setUp() external {
        delegate    = new StakeLockerPoolDelegate();
        notDelegate = new StakeLockerPoolDelegate();
        globals     = new MapleGlobalsMock();
        factory     = new PoolFactoryMock(address(globals));
        pool        = new PoolMock(address(factory), address(delegate));
        locker      = new StakeLocker(address(1), address(2), address(pool));
    }

    function test_setAllowlist(address staker) external {
        assertTrue(     !locker.allowed(staker));
        assertTrue(!notDelegate.try_stakeLocker_setAllowlist(address(locker), staker, true));
        assertTrue(    delegate.try_stakeLocker_setAllowlist(address(locker), staker, true));
        assertTrue(      locker.allowed(staker));
        assertTrue(!notDelegate.try_stakeLocker_setAllowlist(address(locker), staker, false));
        assertTrue(    delegate.try_stakeLocker_setAllowlist(address(locker), staker, false));
        assertTrue(     !locker.allowed(staker));
    }

    function test_openStakeLockerToPublic() external {
        assertTrue(     !locker.openToPublic());
        assertTrue(!notDelegate.try_stakeLocker_openStakeLockerToPublic(address(locker)));
        assertTrue(    delegate.try_stakeLocker_openStakeLockerToPublic(address(locker)));
        assertTrue(      locker.openToPublic());
    }

}

contract StakeLockerAsPoolTest is DSTest {
    
    StakeLockerOwner internal owner;
    StakeLockerOwner internal nonOwner;
    MockToken        internal stakeToken;
    StakeLocker      internal locker;

    function setUp() external {
        owner       = new StakeLockerOwner();
        nonOwner    = new StakeLockerOwner();
        stakeToken  = new MockToken("ST", "ST");
        locker      = new StakeLocker(address(stakeToken), address(1), address(owner));
    }

    function test_pull(address destination, uint256 amount) external {
        destination = destination == address(0) ? address(1) : destination;
        stakeToken.mint(address(locker), amount);
        assertTrue(!nonOwner.try_stakeLocker_pull(address(locker), destination, amount));
        assertTrue(    owner.try_stakeLocker_pull(address(locker), destination, amount));
    }

}
