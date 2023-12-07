// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface ISourceVault {
    function updateBalanceFromMockDestinationVault(
        uint256 _newBalance
    ) external;
}
