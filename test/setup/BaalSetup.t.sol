// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IBaal} from "baal/interfaces/IBaal.sol";
import {Test} from "forge-std/Test.sol";

contract BaalSetup is Test {
    uint256 constant BLOCK_NUMBER = 244299097;
    address constant DAO_MASONS = 0x5B448757A34402DEAcC7729B79003408CDfe1438;

    IBaal internal _baal;

    function _setupBaal() internal {
        vm.createSelectFork(vm.rpcUrl("arbitrumOne"), BLOCK_NUMBER);

        _baal = IBaal(DAO_MASONS);

        uint256 totalLoot = _baal.totalLoot();
    }
}
