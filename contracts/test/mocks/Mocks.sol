// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import { ERC20 } from "../../../modules/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

interface Hevm {
    function warp(uint256) external;
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

    bool public constant isPoolFinalized = false;

    address public immutable superFactory;
    address public immutable poolDelegate;

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
