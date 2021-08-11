// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface IMapleGlobalsLike {
    function governor() external view returns (address);
    function stakerCooldownPeriod() external view returns (uint256);
    function stakerUnstakeWindow() external view returns (uint256);
    function protocolPaused() external view returns (bool);
}

interface IPoolLike {
    function isPoolFinalized() external view returns (bool);
    function poolDelegate() external pure returns (address);
    function poolAdmins(address poolAdmin) external view returns (bool);
    function superFactory() external pure returns (address);
}

interface IPoolFactoryLike {
    function globals() external view returns (address);
}
