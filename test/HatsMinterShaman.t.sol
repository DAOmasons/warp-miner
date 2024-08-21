// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {HatsMinterShaman, Gate, GateType, Metadata, Badge} from "../src/HatsMinterShaman.sol";
import {BaalSetupLive} from "./setup/BaalSetup.t.sol";
import {HatsSetupLive} from "./setup/HatsSetup.t.sol";
import {console2} from "lib/forge-std/src/Test.sol";

contract HatsMinterShamanTest is BaalSetupLive, HatsSetupLive {
    HatsMinterShaman public _hatsMinterShaman;

    Metadata internal badgeMetadata = Metadata(1, "badge");
    Metadata internal commentMetadata = Metadata(1, "comment");

    uint256 internal STANDARD_AMT = 1_000e18;
    uint256 internal CUSTOM_AMT = 10_000e18;

    // Loot
    Badge internal simpleBadge = Badge("simple badge", badgeMetadata, STANDARD_AMT, false, true, false, true);
    Badge internal slashBadge = Badge("slash badge", badgeMetadata, STANDARD_AMT, false, true, true, true);
    Badge internal noAmountBadge = Badge("no amount badge", badgeMetadata, 0, false, false, false, true);

    // Shares
    Badge internal sharesBadge = Badge("simple shares badge", badgeMetadata, STANDARD_AMT, true, true, false, true);
    Badge internal slashSharesBadge = Badge("slash shares badge", badgeMetadata, STANDARD_AMT, true, true, true, true);
    Badge internal noAmountSharesBadge = Badge("no amount shares badge", badgeMetadata, 0, true, false, false, true);

    // other
    Badge internal slashNoFixedLoot = Badge("slash no fixed loot", badgeMetadata, 0, false, false, true, true);
    Badge internal slashNoFixedShares = Badge("slash no fixed shares", badgeMetadata, 0, true, false, true, true);

    uint256[] internal _badgeIds;
    uint256[] internal _amounts;
    Metadata[] internal _comments;
    address[] internal _recipients;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("arbitrumOne"), BLOCK_NUMBER);

        __setupHats();

        Gate[] memory gates = new Gate[](3);

        gates[0] = Gate(GateType.Hat, _badgeManagerId);
        gates[1] = Gate(GateType.Hat, _minterAdminId);
        gates[2] = Gate(GateType.Dao, 0);

        bytes memory initParams = abi.encode(gates, DAO_MASONS, HATS);

        _hatsMinterShaman = new HatsMinterShaman(initParams);

        __setUpDAO(address(shaman()));
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

        assertEq(shaman().getGateHatId(1), _minterAdminId);
        assertEq(uint8(shaman().getGatePermissionLevel(1)), uint8(GateType.Hat));

        assertEq(shaman().getGateHatId(2), 0);
        assertEq(uint8(shaman().getGatePermissionLevel(2)), uint8(GateType.Dao));
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

    function testRemoveBadge() public {
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

        _removeBadge(0);

        (
            string memory nameAfter,
            Metadata memory metadataAfter,
            uint256 amountAfter,
            bool isVotingTokenAfter,
            bool hasFixedAmountAfter,
            bool isSlashAfter,
            bool existsAfter
        ) = shaman().badges(0);

        assertEq(nameAfter, "");
        assertEq(metadataAfter.protocol, 0);
        assertEq(metadataAfter.pointer, "");
        assertEq(amountAfter, 0);
        assertEq(isVotingTokenAfter, false);
        assertEq(hasFixedAmountAfter, false);
        assertEq(isSlashAfter, false);
        assertEq(existsAfter, false);
    }

    function testReplaceBadge() public {
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

        vm.startPrank(manager1().wearer);
        shaman().replaceBadge(0, slashNoFixedLoot);
        vm.stopPrank();

        (
            string memory nameAfter,
            Metadata memory metadataAfter,
            uint256 amountAfter,
            bool isVotingTokenAfter,
            bool hasFixedAmountAfter,
            bool isSlashAfter,
            bool existsAfter
        ) = shaman().badges(0);

        assertEq(nameAfter, slashNoFixedLoot.name);
        assertEq(metadataAfter.protocol, slashNoFixedLoot.metadata.protocol);
        assertEq(metadataAfter.pointer, slashNoFixedLoot.metadata.pointer);
        assertEq(amountAfter, slashNoFixedLoot.amount);
        assertEq(isVotingTokenAfter, slashNoFixedLoot.isVotingToken);
        assertEq(hasFixedAmountAfter, slashNoFixedLoot.hasFixedAmount);
        assertEq(isSlashAfter, slashNoFixedLoot.isSlash);
        assertEq(existsAfter, true);
    }

    function testApplySingleBadge() public {
        _createBadge();
        _applyBadgeSingle();

        assertEq(getLootBalance(recipient1()), simpleBadge.amount);
    }

    function testApplySingle_customAmount() public {
        _createNoAmountBadge();
        _applySingleCustomAmount(0);

        assertEq(getLootBalance(recipient1()), CUSTOM_AMT);
    }

    function testApplySlash() public {
        _createBadge();
        _createSlashBadge();

        _applyBadgeSingle();
        _applyBadgeSingle();

        _applyCustomBadge(1);

        assertEq(getLootBalance(recipient1()), STANDARD_AMT + STANDARD_AMT - STANDARD_AMT);

        _applyCustomBadge(1);

        assertEq(getLootBalance(recipient1()), 0);
    }

    function testApplySingle_shares() public {
        _createSharesBadge();
        _applyBadgeSingle();

        assertEq(getSharesBalance(recipient1()), STANDARD_AMT);
    }

    function testSlash_shares() public {
        _createSharesBadge();
        _createSlashSharesBadge();

        _applyBadgeSingle();
        _applyBadgeSingle();

        _applyCustomBadge(1);

        assertEq(getSharesBalance(recipient1()), STANDARD_AMT + STANDARD_AMT - STANDARD_AMT);
    }

    function testApplySingle_shares_customAmount() public {
        _createNoAmountSharesBadge();

        _applySingleCustomAmount(0);

        assertEq(getSharesBalance(recipient1()), CUSTOM_AMT);
    }

    function testSlash_customAmount_loot() public {
        _createNoAmountBadge();
        _createSlashNoFixedLoot();

        _applySingleCustomAmount(0);
        _applySingleCustomAmount(0);

        _applySingleCustomAmount(1);

        assertEq(getLootBalance(recipient1()), CUSTOM_AMT + CUSTOM_AMT - CUSTOM_AMT);
    }

    function testSlash_customAmount_shares() public {
        _createNoAmountSharesBadge();
        _createSlashNoFixedShares();

        _applySingleCustomAmount(0);
        _applySingleCustomAmount(0);

        _applySingleCustomAmount(1);

        assertEq(getSharesBalance(recipient1()), CUSTOM_AMT + CUSTOM_AMT - CUSTOM_AMT);
    }

    //////////////////////////////
    // Reverts
    //////////////////////////////

    function testRevert_createBadge_Falsy() public {
        Badge memory falsyBadge = Badge("falsy badge", badgeMetadata, 0, false, false, false, false);

        vm.expectRevert("HatsMinterShaman: badge.exists must be true");

        vm.startPrank(manager1().wearer);
        shaman().createBadge(falsyBadge);
        vm.stopPrank();
    }

    function testRevert_createBadge_nonFixedWithSpecifiedAmount() public {
        Badge memory badge = Badge("incorrect badge", badgeMetadata, 1, false, false, false, true);

        vm.expectRevert("HatsMinterShaman: badge amount must 0");

        vm.startPrank(manager1().wearer);
        shaman().createBadge(badge);
        vm.stopPrank();
    }

    function testRevert_removeBadge_nonexistent() public {
        vm.expectRevert("HatsMinterShaman: badge doesn't exist");

        vm.startPrank(manager1().wearer);
        shaman().removeBadge(0);
        vm.stopPrank();
    }

    function testRevert_replaceBadge_nonexistent() public {
        vm.expectRevert("HatsMinterShaman: badge doesn't exist");

        vm.startPrank(manager1().wearer);
        shaman().replaceBadge(0, simpleBadge);
        vm.stopPrank();
    }

    function testRevert_replaceBadge_Falsy() public {
        _createBadge();
        Badge memory falsyBadge = Badge("falsy badge", badgeMetadata, 0, false, false, false, false);
        vm.expectRevert("HatsMinterShaman: badge.exists must be true");

        vm.startPrank(manager1().wearer);
        shaman().replaceBadge(0, falsyBadge);
        vm.stopPrank();
    }

    function testRevert_replaceBadge_nonFixedWithSpecifiedAmount() public {
        _createBadge();
        Badge memory badge = Badge("incorrect badge", badgeMetadata, 1, false, false, false, true);

        vm.expectRevert("HatsMinterShaman: badge amount must 0");

        vm.startPrank(manager1().wearer);
        shaman().replaceBadge(0, badge);
        vm.stopPrank();
    }

    function testRevert_applyBadges_nonexistent() public {
        _createBadge();

        vm.expectRevert("HatsMinterShaman: badge doesn't exist");
        _applyCustomBadge(1);
    }

    function testRevert_applyBadges_arrayMismatch() public {
        uint256[] memory _badgeIds = new uint256[](1);
        uint256[] memory _amounts = new uint256[](2);
        Metadata[] memory _comments = new Metadata[](1);
        address[] memory _recipients = new address[](1);

        vm.expectRevert("HatsMinterShaman: length mismatch");

        vm.startPrank(admin1().wearer);
        shaman().applyBadges(_badgeIds, _amounts, _comments, _recipients);
        vm.stopPrank();

        _badgeIds = new uint256[](2);
        _amounts = new uint256[](1);

        vm.expectRevert("HatsMinterShaman: length mismatch");

        vm.startPrank(admin1().wearer);
        shaman().applyBadges(_badgeIds, _amounts, _comments, _recipients);
        vm.stopPrank();

        _badgeIds = new uint256[](1);
        _comments = new Metadata[](2);

        vm.expectRevert("HatsMinterShaman: length mismatch");

        vm.startPrank(admin1().wearer);
        shaman().applyBadges(_badgeIds, _amounts, _comments, _recipients);
        vm.stopPrank();

        _comments = new Metadata[](1);
        _recipients = new address[](2);

        vm.expectRevert("HatsMinterShaman: length mismatch");

        vm.startPrank(admin1().wearer);
        shaman().applyBadges(_badgeIds, _amounts, _comments, _recipients);
        vm.stopPrank();

        _recipients = new address[](1);

        vm.expectRevert("HatsMinterShaman: badge doesn't exist");

        vm.startPrank(admin1().wearer);
        shaman().applyBadges(_badgeIds, _amounts, _comments, _recipients);
        vm.stopPrank();
    }

    function testRevert_gate_hat_unauthorized() public {
        vm.expectRevert("HatsMinterShaman: unauthorized, not hat owner");
        // Test user without a hat
        vm.startPrank(someGuy());
        shaman().createBadge(simpleBadge);
        vm.stopPrank();

        vm.expectRevert("HatsMinterShaman: unauthorized, not hat owner");
        // Test user with wrong hat
        vm.startPrank(admin1().wearer);
        shaman().createBadge(simpleBadge);
        vm.stopPrank();

        // Test user with correct hat
        vm.startPrank(manager1().wearer);
        shaman().createBadge(simpleBadge);
        vm.stopPrank();
    }

    function testRevert_gate_dao_unauthorized() public {
        vm.expectRevert("HatsMinterShaman: unauthorized, not DAO");

        // test a random user
        vm.startPrank(someGuy());
        shaman().manageGate(2, GateType.None, 0);
        vm.stopPrank();

        vm.expectRevert("HatsMinterShaman: unauthorized, not DAO");
        // test a recognized hat wearer
        vm.startPrank(manager1().wearer);
        shaman().manageGate(2, GateType.None, 0);
        vm.stopPrank();

        // test the DAO
        vm.startPrank(dao().avatar());
        shaman().manageGate(2, GateType.None, 0);
        vm.stopPrank();

        // Now that the gate is change to none, anyone can change it
        vm.startPrank(someGuy());
        shaman().manageGate(2, GateType.Hat, admin1().id);
        vm.stopPrank();

        vm.expectRevert("HatsMinterShaman: unauthorized, not hat owner");
        vm.startPrank(someGuy());
        shaman().manageGate(2, GateType.Hat, admin1().id);
        vm.stopPrank();
    }

    function testRevert_gate_none() public {}

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

    function testCreateAllPossibleBadges() public {
        _createAllPossibleBadges();

        assertEq(shaman().badgeNonce(), 8);

        Badge memory badge1 = shaman().getBadge(0);
        Badge memory badge2 = shaman().getBadge(1);
        Badge memory badge3 = shaman().getBadge(2);
        Badge memory badge4 = shaman().getBadge(3);
        Badge memory badge5 = shaman().getBadge(4);
        Badge memory badge6 = shaman().getBadge(5);
        Badge memory badge7 = shaman().getBadge(6);
        Badge memory badge8 = shaman().getBadge(7);

        assertEq(badge1.name, simpleBadge.name);
        assertEq(badge2.name, slashBadge.name);
        assertEq(badge3.name, noAmountBadge.name);
        assertEq(badge4.name, sharesBadge.name);
        assertEq(badge5.name, slashSharesBadge.name);
        assertEq(badge6.name, noAmountSharesBadge.name);
        assertEq(badge7.name, slashNoFixedLoot.name);
        assertEq(badge8.name, slashNoFixedShares.name);

        assertEq(badge1.amount, simpleBadge.amount);
        assertEq(badge2.amount, slashBadge.amount);
        assertEq(badge3.amount, noAmountBadge.amount);
        assertEq(badge4.amount, sharesBadge.amount);
        assertEq(badge5.amount, slashSharesBadge.amount);
        assertEq(badge6.amount, noAmountSharesBadge.amount);
        assertEq(badge7.amount, slashNoFixedLoot.amount);
        assertEq(badge8.amount, slashNoFixedShares.amount);

        assertEq(badge1.hasFixedAmount, simpleBadge.hasFixedAmount);
        assertEq(badge2.hasFixedAmount, slashBadge.hasFixedAmount);
        assertEq(badge3.hasFixedAmount, noAmountBadge.hasFixedAmount);
        assertEq(badge4.hasFixedAmount, sharesBadge.hasFixedAmount);
        assertEq(badge5.hasFixedAmount, slashSharesBadge.hasFixedAmount);
        assertEq(badge6.hasFixedAmount, noAmountSharesBadge.hasFixedAmount);
        assertEq(badge7.hasFixedAmount, slashNoFixedLoot.hasFixedAmount);
        assertEq(badge8.hasFixedAmount, slashNoFixedShares.hasFixedAmount);

        assertEq(badge1.isSlash, simpleBadge.isSlash);
        assertEq(badge2.isSlash, slashBadge.isSlash);
        assertEq(badge3.isSlash, noAmountBadge.isSlash);
        assertEq(badge4.isSlash, sharesBadge.isSlash);
        assertEq(badge5.isSlash, slashSharesBadge.isSlash);
        assertEq(badge6.isSlash, noAmountSharesBadge.isSlash);
        assertEq(badge7.isSlash, slashNoFixedLoot.isSlash);
        assertEq(badge8.isSlash, slashNoFixedShares.isSlash);

        assertEq(badge1.exists, true);
        assertEq(badge2.exists, true);
        assertEq(badge3.exists, true);
        assertEq(badge4.exists, true);
        assertEq(badge5.exists, true);
        assertEq(badge6.exists, true);
        assertEq(badge7.exists, true);
        assertEq(badge8.exists, true);
    }

    function testBatchApplyBadges() public {
        _createAllPossibleBadges();

        uint256[] memory _badgeIds = new uint256[](10);
        uint256[] memory _amounts = new uint256[](10);
        Metadata[] memory _comments = new Metadata[](10);
        address[] memory _recipients = new address[](10);

        // comments are all the same
        _comments[0] = commentMetadata;
        _comments[1] = commentMetadata;
        _comments[2] = commentMetadata;
        _comments[3] = commentMetadata;
        _comments[4] = commentMetadata;
        _comments[5] = commentMetadata;
        _comments[6] = commentMetadata;
        _comments[7] = commentMetadata;
        _comments[8] = commentMetadata;
        _comments[9] = commentMetadata;

        // Award each user a simple loot badge
        _badgeIds[0] = 0;
        _badgeIds[1] = 0;
        _badgeIds[2] = 0;

        _amounts[0] = 0;
        _amounts[1] = 0;
        _amounts[2] = 0;

        _recipients[0] = recipient1();
        _recipients[1] = recipient2();
        _recipients[2] = recipient3();

        // recipient 1 loot: 1_000
        // recipient 2 loot: 1_000
        // recipient 3 loot: 1_000

        // slash recipient 2 loot

        _badgeIds[3] = 1;
        _amounts[3] = 0;
        _recipients[3] = recipient2();

        // recipient 1 loot: 1_000
        // recipient 2 loot: 0
        // recipient 3 loot: 1_000

        // Award user 1 & 2 a custom amount badge

        _badgeIds[4] = 2;
        _badgeIds[5] = 2;

        _amounts[4] = 500e18;
        _amounts[5] = 200e18;

        _recipients[4] = recipient1();
        _recipients[5] = recipient2();

        // recipient 1 loot: 1_500
        // recipient 2 loot: 200
        // recipient 3 loot: 1_000

        // Promote recipient 1 & 3 to shares
        // burn loot for recipient 1 & 3
        // burn both for 1_500 to test underflow behavior, both should be zero
        // Award custom amount of shares for recipient 1 & 3

        _badgeIds[6] = 6;
        _badgeIds[7] = 6;
        _badgeIds[8] = 5;
        _badgeIds[9] = 5;

        _amounts[6] = 1_500e18;
        _amounts[7] = 1_500e18;
        _amounts[8] = 1_500e18;
        _amounts[9] = 1_000e18;

        _recipients[6] = recipient1();
        _recipients[7] = recipient3();
        _recipients[8] = recipient1();
        _recipients[9] = recipient3();

        // recipient 1 shares: 1_500, loot: 0
        // recipient 2 shares: 0, loot: 200
        // recipient 3 shares: 1_000, loot: 0

        vm.startPrank(admin1().wearer);
        shaman().applyBadges(_badgeIds, _amounts, _comments, _recipients);
        vm.stopPrank();

        console2.log("recipient 1 loot: ", loot().balanceOf(recipient1()));
        console2.log("recipient 2 loot: ", loot().balanceOf(recipient2()));
        console2.log("recipient 3 loot: ", loot().balanceOf(recipient3()));

        assertEq(loot().balanceOf(recipient1()), 0);
        assertEq(loot().balanceOf(recipient2()), 200e18);
        assertEq(loot().balanceOf(recipient3()), 0);

        assertEq(shares().balanceOf(recipient1()), 1_500e18);
        assertEq(shares().balanceOf(recipient2()), 0);
        assertEq(shares().balanceOf(recipient3()), 1_000e18);
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
    }

    //////////////////////////////
    // Helpers
    //////////////////////////////

    function _createAllPossibleBadges() internal {
        _createBadge();
        _createSlashBadge();
        _createNoAmountBadge();
        _createSharesBadge();
        _createSlashSharesBadge();
        _createNoAmountSharesBadge();
        _createSlashNoFixedLoot();
        _createSlashNoFixedShares();
    }

    function _applyCustomBadge(uint256 _badgeId) internal {
        uint256[] memory _badgeIds = new uint256[](1);
        uint256[] memory _amounts = new uint256[](1);
        Metadata[] memory _comments = new Metadata[](1);
        address[] memory _recipients = new address[](1);

        _badgeIds[0] = _badgeId;
        _amounts[0] = 0;
        _comments[0] = commentMetadata;
        _recipients[0] = recipient1();

        vm.startPrank(admin1().wearer);
        shaman().applyBadges(_badgeIds, _amounts, _comments, _recipients);
        vm.stopPrank();
    }

    function _applySingleCustomAmount(uint256 _badgeId) internal {
        uint256[] memory _badgeIds = new uint256[](1);
        uint256[] memory _amounts = new uint256[](1);
        Metadata[] memory _comments = new Metadata[](1);
        address[] memory _recipients = new address[](1);

        _badgeIds[0] = _badgeId;
        _amounts[0] = CUSTOM_AMT;
        _comments[0] = commentMetadata;
        _recipients[0] = recipient1();

        vm.startPrank(admin1().wearer);
        shaman().applyBadges(_badgeIds, _amounts, _comments, _recipients);
        vm.stopPrank();
    }

    function _applyBadgeSingle() internal {
        uint256[] memory _badgeIds = new uint256[](1);
        uint256[] memory _amounts = new uint256[](1);
        Metadata[] memory _comments = new Metadata[](1);
        address[] memory _recipients = new address[](1);

        _badgeIds[0] = 0;
        _amounts[0] = 0;
        _comments[0] = commentMetadata;
        _recipients[0] = recipient1();

        vm.startPrank(admin1().wearer);
        shaman().applyBadges(_badgeIds, _amounts, _comments, _recipients);
        vm.stopPrank();
    }

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

    function _createSharesBadge() internal {
        vm.startPrank(manager1().wearer);
        shaman().createBadge(sharesBadge);
        vm.stopPrank();
    }

    function _createSlashSharesBadge() internal {
        vm.startPrank(manager1().wearer);
        shaman().createBadge(slashSharesBadge);
        vm.stopPrank();
    }

    function _createNoAmountSharesBadge() internal {
        vm.startPrank(manager1().wearer);
        shaman().createBadge(noAmountSharesBadge);
        vm.stopPrank();
    }

    function _createSlashNoFixedLoot() internal {
        vm.startPrank(manager1().wearer);
        shaman().createBadge(slashNoFixedLoot);
        vm.stopPrank();
    }

    function _createSlashNoFixedShares() internal {
        vm.startPrank(manager1().wearer);
        shaman().createBadge(slashNoFixedShares);
        vm.stopPrank();
    }

    function _removeBadge(uint256 _id) internal {
        vm.startPrank(manager1().wearer);
        shaman().removeBadge(_id);
        vm.stopPrank();
    }
}
