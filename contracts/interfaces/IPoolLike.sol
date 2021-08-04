// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface IPoolLike {

    function isPoolFinalized() external view returns (bool);

    function poolDelegate() external pure returns (address);

    function poolAdmins(address poolAdmin) external view returns (bool);

    function superFactory() external pure returns (address);

}
