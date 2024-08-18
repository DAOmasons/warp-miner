// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IBaal} from "lib/Baal/contracts/interfaces/IBaal.sol";
import {Test, console2} from "lib/forge-std/src/Test.sol";
import {Accounts} from "./Accounts.t.sol";

contract BaalSetup is Test, Accounts {
    uint256 constant BLOCK_NUMBER = 244299097;
    address constant DAO_MASONS = 0x5B448757A34402DEAcC7729B79003408CDfe1438;

    IBaal internal _baal;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("arbitrumOne"), BLOCK_NUMBER);

        _baal = IBaal(DAO_MASONS);
        address[] memory shamans = new address[](1);
        uint256[] memory permissions = new uint256[](1);
        shamans[0] = someGuy();
        permissions[0] = 2;

        vm.prank(_baal.avatar());

        _baal.setShamans(shamans, permissions);
    }

    function test() public {
        uint256 permission = _baal.shamans(someGuy());

        console2.log("permission", permission);
    }
}
