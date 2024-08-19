// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {HatsMinterShaman, Gate, GateType} from "../src/HatsMinterShaman.sol";
import {BaalSetupLive} from "./setup/BaalSetup.t.sol";

contract HatsMinterShamanTest is BaalSetupLive {
    HatsMinterShaman public _hatsMinterShaman;

    function setUp() public {
        Gate[] memory gates = new Gate[](7);

        gates[0] = Gate(GateType.None, 1);
        gates[1] = Gate(GateType.None, 1);
        gates[2] = Gate(GateType.None, 1);
        gates[3] = Gate(GateType.None, 1);
        gates[4] = Gate(GateType.None, 1);
        gates[5] = Gate(GateType.None, 1);
        gates[6] = Gate(GateType.None, 1);

        bytes memory initParams = abi.encode(gates, DAO_MASONS, HATS);

        _hatsMinterShaman = new HatsMinterShaman(initParams);

        __setUpDAO(address(_hatsMinterShaman));
    }

    function shaman() public view returns (HatsMinterShaman) {
        return _hatsMinterShaman;
    }

    function testShamanSetup() public {
        assertEq(dao().shamans(address(shaman())), 2);
        assertEq(address(shaman().dao()), address(dao()));
        assertEq(address(shaman().hats()), HATS);

        assertEq(shaman().getGateHatId(0), 1);
        assertEq(uint8(shaman().getGatePermissionLevel(0)), uint8(GateType.None));

        assertEq(shaman().getGateHatId(1), 1);
        assertEq(uint8(shaman().getGatePermissionLevel(1)), uint8(GateType.None));

        assertEq(shaman().getGateHatId(2), 1);
        assertEq(uint8(shaman().getGatePermissionLevel(2)), uint8(GateType.None));

        assertEq(shaman().getGateHatId(3), 1);
        assertEq(uint8(shaman().getGatePermissionLevel(3)), uint8(GateType.None));

        assertEq(shaman().getGateHatId(4), 1);
        assertEq(uint8(shaman().getGatePermissionLevel(4)), uint8(GateType.None));

        assertEq(shaman().getGateHatId(5), 1);
        assertEq(uint8(shaman().getGatePermissionLevel(5)), uint8(GateType.None));

        assertEq(shaman().getGateHatId(6), 1);
        assertEq(uint8(shaman().getGatePermissionLevel(6)), uint8(GateType.None));
    }
}
