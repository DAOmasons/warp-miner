// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {HatsMinterShaman, Gate, GateType} from "../src/HatsMinterShaman.sol";
import {BaalSetupLive} from "./setup/BaalSetup.t.sol";

contract HatsMinterShamanTest is BaalSetupLive {
    HatsMinterShaman public _hatsMinterShaman;

    function setUp() public {
        Gate[] memory gates = new Gate[](7);

        gates[0] = Gate(GateType.None, 0);
        gates[1] = Gate(GateType.None, 0);
        gates[2] = Gate(GateType.None, 0);
        gates[3] = Gate(GateType.None, 0);
        gates[4] = Gate(GateType.None, 0);
        gates[5] = Gate(GateType.None, 0);
        gates[6] = Gate(GateType.None, 0);

        bytes memory initParams = abi.encode(gates, DAO_MASONS, HATS);

        _hatsMinterShaman = new HatsMinterShaman(initParams);

        __setUpDAO(address(_hatsMinterShaman));
    }

    function test() public {
        // TODO
    }
}
