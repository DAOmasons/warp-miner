// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/forge-std/src/StdCheats.sol";

contract Accounts is StdCheats {
    // //////////////////////
    // users
    // //////////////////////
    function user1() public returns (address) {
        return makeAddr("user_1");
    }

    function user2() public returns (address) {
        return makeAddr("user_2");
    }

    function user3() public returns (address) {
        return makeAddr("user_3");
    }

    function user4() public returns (address) {
        return makeAddr("user_4");
    }

    function user5() public returns (address) {
        return makeAddr("user_5");
    }

    function user6() public returns (address) {
        return makeAddr("user_6");
    }

    function deployer() public returns (address) {
        return makeAddr("deployer");
    }

    // //////////////////////
    // Outsiders
    // //////////////////////

    function someGuy() public returns (address) {
        return makeAddr("some_guy");
    }

    function recipient1() public returns (address) {
        return makeAddr("recipient1");
    }

    function recipient2() public returns (address) {
        return makeAddr("recipient2");
    }

    function recipient3() public returns (address) {
        return makeAddr("recipient3");
    }

    function recipient4() public returns (address) {
        return makeAddr("recipient4");
    }
}
