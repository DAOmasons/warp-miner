// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {HatsMinterShaman, Gate, GateType, Metadata, Badge} from "../src/HatsMinterShaman.sol";
import {BaalSetupLive} from "./setup/BaalSetup.t.sol";
import {HatsSetupLive} from "./setup/HatsSetup.t.sol";

contract HatsMinterShamanTest is BaalSetupLive, HatsSetupLive {
    HatsMinterShaman public _hatsMinterShaman;

    Metadata internal badgeMetadata = Metadata(1, "badge");

    Badge internal simpleBadge = Badge("simple badge", badgeMetadata, 1_000e18, false, true, false, true);
    Badge internal slashBadge = Badge("slash badge", badgeMetadata, 1_000e18, false, true, true, true);

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
        _addBadge();
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

    function testCreateBadge_interates() public {}

    //////////////////////////////
    // Reverts
    //////////////////////////////

    //////////////////////////////
    // Getters
    //////////////////////////////

    function testGetBadge() public {
        _addBadge();

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

    function _addBadge() internal {
        vm.startPrank(manager1().wearer);
        shaman().createBadge(simpleBadge);
        vm.stopPrank();
    }
}
