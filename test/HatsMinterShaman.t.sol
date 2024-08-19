// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {HatsMinterShaman, Gate, GateType} from "../src/HatsMinterShaman.sol";
import {BaalSetupLive} from "./setup/BaalSetup.t.sol";
import {HatsSetupLive} from "./setup/HatsSetup.t.sol";

contract HatsMinterShamanTest is BaalSetupLive, HatsSetupLive {
    HatsMinterShaman public _hatsMinterShaman;

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
}
