// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IBaal} from "lib/Baal/contracts/interfaces/IBaal.sol";
import {IBaalToken} from "lib/Baal/contracts/interfaces/IBaalToken.sol";
import {Test, console2} from "lib/forge-std/src/Test.sol";
import {Accounts} from "./Accounts.t.sol";

contract BaalSetupLive is Test, Accounts {
    uint256 constant BLOCK_NUMBER = 244299097;
    address constant DAO_MASONS = 0x5B448757A34402DEAcC7729B79003408CDfe1438;

    IBaal internal _baal;
    IBaalToken internal _loot;
    IBaalToken internal _shares;

    function __setUpDAO(address _shamanAddress) internal {
        _baal = IBaal(DAO_MASONS);
        address[] memory shamans = new address[](1);
        uint256[] memory permissions = new uint256[](1);
        shamans[0] = _shamanAddress;
        permissions[0] = 2;

        vm.prank(_baal.avatar());

        _baal.setShamans(shamans, permissions);

        _loot = IBaalToken(_baal.lootToken());
        _shares = IBaalToken(_baal.sharesToken());
    }

    function dao() public view returns (IBaal) {
        return _baal;
    }

    function loot() public view returns (IBaalToken) {
        return _loot;
    }

    function shares() public view returns (IBaalToken) {
        return _shares;
    }

    function getLootBalance(address _hodler) public view returns (uint256) {
        return _loot.balanceOf(_hodler);
    }

    function getSharesBalance(address _hodler) public view returns (uint256) {
        return _shares.balanceOf(_hodler);
    }
}
