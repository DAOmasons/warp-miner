// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Hats} from "lib/hats-protocol/src/Hats.sol";
import {Accounts} from "./Accounts.t.sol";
import {Test, console2} from "lib/forge-std/src/Test.sol";

struct HatWearer {
    uint256 id;
    address wearer;
}

contract HatsSetupLive is Test, Accounts {
    Hats internal _hats;
    address constant HATS = 0x3bc1A0Ad72417f2d411118085256fC53CBdDd137;

    uint256 _topHatId;
    uint256 _badgeManagerId;
    uint256 _minterAdminId;
    uint256 _auditorId;

    HatWearer internal _badgeManager1;
    HatWearer internal _badgeManager2;
    HatWearer internal _minterAdmin1;
    HatWearer internal _minterAdmin2;
    HatWearer internal _auditor1;
    HatWearer internal _auditor2;

    function __setupHats() internal {
        _hats = Hats(HATS);

        _topHatId = hats().mintTopHat(deployer(), "", "");

        vm.startPrank(deployer());

        _badgeManagerId = hats().createHat(_topHatId, "badge manager", 100, address(1), address(1), true, "");
        _minterAdminId = hats().createHat(_topHatId, "minter admin", 100, address(1), address(1), true, "");
        _auditorId = hats().createHat(_topHatId, "auditor", 100, address(1), address(1), true, "");

        hats().mintHat(_badgeManagerId, user1());
        hats().mintHat(_badgeManagerId, user2());

        hats().mintHat(_minterAdminId, user3());
        hats().mintHat(_minterAdminId, user4());

        hats().mintHat(_auditorId, user5());
        hats().mintHat(_auditorId, user6());

        _badgeManager1 = HatWearer(_badgeManagerId, user1());
        _badgeManager2 = HatWearer(_badgeManagerId, user2());

        _minterAdmin1 = HatWearer(_minterAdminId, user3());
        _minterAdmin2 = HatWearer(_minterAdminId, user4());

        _auditor1 = HatWearer(_auditorId, user5());
        _auditor2 = HatWearer(_auditorId, user6());

        assertTrue(hats().isWearerOfHat(_badgeManager1.wearer, _badgeManager1.id));
        assertTrue(hats().isWearerOfHat(_badgeManager2.wearer, _badgeManager2.id));

        assertTrue(hats().isWearerOfHat(_minterAdmin1.wearer, _minterAdmin1.id));
        assertTrue(hats().isWearerOfHat(_minterAdmin2.wearer, _minterAdmin2.id));

        assertTrue(hats().isWearerOfHat(_auditor1.wearer, _auditor1.id));
        assertTrue(hats().isWearerOfHat(_auditor2.wearer, _auditor2.id));

        assertTrue(hats().isInGoodStanding(_badgeManager1.wearer, _badgeManager1.id));
        assertTrue(hats().isInGoodStanding(_badgeManager2.wearer, _badgeManager2.id));

        assertTrue(hats().isInGoodStanding(_minterAdmin1.wearer, _minterAdmin1.id));
        assertTrue(hats().isInGoodStanding(_minterAdmin2.wearer, _minterAdmin2.id));

        assertTrue(hats().isInGoodStanding(_auditor1.wearer, _auditor1.id));
        assertTrue(hats().isInGoodStanding(_auditor2.wearer, _auditor2.id));

        vm.stopPrank();
    }

    function hats() internal view returns (Hats) {
        return _hats;
    }

    function manager1() internal view returns (HatWearer memory) {
        return _badgeManager1;
    }

    function manager2() internal view returns (HatWearer memory) {
        return _badgeManager2;
    }

    function admin1() internal view returns (HatWearer memory) {
        return _minterAdmin1;
    }

    function admin2() internal view returns (HatWearer memory) {
        return _minterAdmin2;
    }

    function auditor1() internal view returns (HatWearer memory) {
        return _auditor1;
    }

    function auditor2() internal view returns (HatWearer memory) {
        return _auditor2;
    }
}
