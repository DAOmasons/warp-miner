// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/StdCheats.sol";

contract Accounts is StdCheats {
    // //////////////////////
    // Wearers
    // //////////////////////
    function wearer1() public returns (address) {
        return makeAddr("admin_1");
    }

    function wearer2() public returns (address) {
        return makeAddr("admin_2");
    }

    function wearer3() public returns (address) {
        return makeAddr("admin_3");
    }

    // //////////////////////
    // Outsiders
    // //////////////////////

    function someGuy() public returns (address) {
        return makeAddr("some_guy");
    }
}
