// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {HatsMinterShaman, Gate, GateType, Metadata, Badge} from "../src/HatsMinterShaman.sol";
import {BaalSetupLive} from "./setup/BaalSetup.t.sol";
import {HatsSetupLive} from "./setup/HatsSetup.t.sol";

contract HatsMinterShamanTest is BaalSetupLive, HatsSetupLive {
    HatsMinterShaman public _hatsMinterShaman;

    Metadata internal badgeMetadata = Metadata(1, "badge");

    // Loot
    Badge internal simpleBadge = Badge("simple badge", badgeMetadata, 1_000e18, false, true, false, true);
    Badge internal slashBadge = Badge("slash badge", badgeMetadata, 1_000e18, false, true, true, true);
    Badge internal noAmountBadge = Badge("no amount badge", badgeMetadata, 0, false, false, false, true);

    // Shares
    Badge internal sharesBadge = Badge("simple shares badge", badgeMetadata, 1_000e18, true, true, false, true);
    Badge internal slashSharesBadge = Badge("slash shares badge", badgeMetadata, 1_000e18, true, true, true, true);
    Badge internal noAmountSharesBadge = Badge("no amount shares badge", badgeMetadata, 0, true, false, false, true);

    // other
    Badge internal slashNoFixedLoot = Badge("slash no fixed loot", badgeMetadata, 0, false, false, true, true);
    Badge internal slashNoFixedShares = Badge("slash no fixed shares", badgeMetadata, 0, true, false, true, true);

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("arbitrumOne"), BLOCK_NUMBER);

        __setupHats();

        Gate[] memory gates = new Gate[](7);

        gates[0] = Gate(GateType.Hat, _badgeManagerId);
        gates[1] = Gate(GateType.Hat, _badgeManagerId);
        gates[2] = Gate(GateType.Hat, _minterAdminId);
        gates[3] = Gate(GateType.Hat, _minterAdminId);
        gates[4] = Gate(GateType.Hat, _minterAdminId);
        gates[5] = Gate(GateType.Hat, _minterAdminId);
        gates[6] = Gate(GateType.Dao, 0);

        bytes memory initParams = abi.encode(gates, DAO_MASONS, HATS);

        _hatsMinterShaman = new HatsMinterShaman(initParams);

        __setUpDAO(address(shaman()), address(hats()));
    }

    function shaman() public view returns (HatsMinterShaman) {
        return _hatsMinterShaman;
    }

    function testShamanSetup() public {
        assertEq(dao().shamans(address(shaman())), 2);
        assertEq(address(shaman().dao()), address(dao()));
        assertEq(address(shaman().hats()), HATS);

        assertEq(shaman().getGateHatId(0), _badgeManagerId);
        assertEq(uint8(shaman().getGatePermissionLevel(0)), uint8(GateType.Hat));

        assertEq(shaman().getGateHatId(1), _badgeManagerId);
        assertEq(uint8(shaman().getGatePermissionLevel(1)), uint8(GateType.Hat));

        assertEq(shaman().getGateHatId(2), _minterAdminId);
        assertEq(uint8(shaman().getGatePermissionLevel(2)), uint8(GateType.Hat));

        assertEq(shaman().getGateHatId(3), _minterAdminId);
        assertEq(uint8(shaman().getGatePermissionLevel(3)), uint8(GateType.Hat));

        assertEq(shaman().getGateHatId(4), _minterAdminId);
        assertEq(uint8(shaman().getGatePermissionLevel(4)), uint8(GateType.Hat));

        assertEq(shaman().getGateHatId(5), _minterAdminId);
        assertEq(uint8(shaman().getGatePermissionLevel(5)), uint8(GateType.Hat));

        assertEq(shaman().getGateHatId(6), 0);
        assertEq(uint8(shaman().getGatePermissionLevel(6)), uint8(GateType.Dao));
    }

    //////////////////////////////
    // Base Functionality
    //////////////////////////////

    function testCreateBadge() public {
        _createBadge();
        (
            string memory name,
            Metadata memory metadata,
            uint256 amount,
            bool isVotingToken,
            bool hasFixedAmount,
            bool isSlash,
            bool exists
        ) = shaman().badges(0);

        assertEq(name, simpleBadge.name);
        assertEq(metadata.protocol, simpleBadge.metadata.protocol);
        assertEq(metadata.pointer, simpleBadge.metadata.pointer);
        assertEq(amount, simpleBadge.amount);
        assertEq(hasFixedAmount, simpleBadge.hasFixedAmount);
        assertEq(isSlash, simpleBadge.isSlash);
        assertTrue(exists);
    }

    //////////////////////////////
    // Reverts
    //////////////////////////////

    //////////////////////////////
    // Compound Functionality
    //////////////////////////////

    function testCreateBadge_interates() public {
        _createBadge();
        _createSlashBadge();
        _createNoAmountBadge();

        assertEq(shaman().badgeNonce(), 3);

        Badge memory badge1 = shaman().getBadge(0);
        Badge memory badge2 = shaman().getBadge(1);
        Badge memory badge3 = shaman().getBadge(2);

        assertEq(badge1.name, simpleBadge.name);
        assertEq(badge2.name, slashBadge.name);
        assertEq(badge3.name, noAmountBadge.name);

        assertEq(badge1.metadata.protocol, simpleBadge.metadata.protocol);
        assertEq(badge2.metadata.protocol, slashBadge.metadata.protocol);
        assertEq(badge3.metadata.protocol, noAmountBadge.metadata.protocol);

        assertEq(badge1.metadata.pointer, simpleBadge.metadata.pointer);
        assertEq(badge2.metadata.pointer, slashBadge.metadata.pointer);
        assertEq(badge3.metadata.pointer, noAmountBadge.metadata.pointer);

        assertEq(badge1.amount, simpleBadge.amount);
        assertEq(badge2.amount, slashBadge.amount);
        assertEq(badge3.amount, noAmountBadge.amount);

        assertEq(badge1.hasFixedAmount, simpleBadge.hasFixedAmount);
        assertEq(badge2.hasFixedAmount, slashBadge.hasFixedAmount);
        assertEq(badge3.hasFixedAmount, noAmountBadge.hasFixedAmount);

        assertEq(badge1.isSlash, simpleBadge.isSlash);
        assertEq(badge2.isSlash, slashBadge.isSlash);
        assertEq(badge3.isSlash, noAmountBadge.isSlash);

        assertEq(badge1.exists, true);
        assertEq(badge2.exists, true);
        assertEq(badge3.exists, true);

        vm.expectRevert("HatsMinterShaman: badge doesn't exist");
        assertFalse(shaman().getBadge(3).exists);
    }

    //////////////////////////////
    // Getters
    //////////////////////////////

    function testGetBadge() public {
        _createBadge();

        Badge memory badge = shaman().getBadge(0);
        assertEq(badge.name, simpleBadge.name);
        assertEq(badge.metadata.protocol, simpleBadge.metadata.protocol);
        assertEq(badge.metadata.pointer, simpleBadge.metadata.pointer);
        assertEq(badge.amount, simpleBadge.amount);
        assertEq(badge.hasFixedAmount, simpleBadge.hasFixedAmount);
        assertEq(badge.isSlash, simpleBadge.isSlash);
        assertTrue(badge.exists);
        // assertEq(badge.metadata, simpleBadge.metadata);
    }

    //////////////////////////////
    // Helpers
    //////////////////////////////

    function _createBadge() internal {
        vm.startPrank(manager1().wearer);
        shaman().createBadge(simpleBadge);
        vm.stopPrank();
    }

    function _createSlashBadge() internal {
        vm.startPrank(manager1().wearer);
        shaman().createBadge(slashBadge);
        vm.stopPrank();
    }

    function _createNoAmountBadge() internal {
        vm.startPrank(manager1().wearer);
        shaman().createBadge(noAmountBadge);
        vm.stopPrank();
    }
}
