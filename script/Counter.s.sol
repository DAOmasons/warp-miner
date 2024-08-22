// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract CounterScript is Script {
    string _network;

    uint256 constant FACILITATOR_HAT = 377439664716248287426848749960570468768546267599534423130416380641280;
    address constant DAO = 0xb6FDF1C6a4D0EAd9aB894b5fAa48D82334C4e1e9;
    address constant HATS = 0x3bc1A0Ad72417f2d411118085256fC53CBdDd137;

    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(pk);
        _setEnvString();

        vm.startBroadcast(deployer);

        vm.stopBroadcast();
    }

    function _setEnvString() internal {
        uint256 key;

        assembly {
            key := chainid()
        }

        _network = vm.toString(key);
    }

    // function _deploy
}
