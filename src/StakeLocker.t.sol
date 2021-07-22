pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./StakeLocker.sol";

contract StakeLockerTest is DSTest {
    StakeLocker locker;

    function setUp() public {
        locker = new StakeLocker();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
