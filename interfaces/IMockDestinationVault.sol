// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMockDestinationVault {
    function swapAndAppendBalance(uint256 mockCCIPBnMAmount) external;
}
