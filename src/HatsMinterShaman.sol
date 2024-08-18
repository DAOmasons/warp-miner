// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IBaal} from "baal/interfaces/IBaal.sol";
import {IHats} from "hats-protocol/src/Interfaces/IHats.sol";

enum GateType {
    None,
    Hat,
    Dao
}

struct Gate {
    GateType gateType;
    uint256 hatId;
}

struct Metadata {
    uint256 protocol;
    string pointer;
}

struct Badge {
    string name;
    Metadata metadata;
    uint256 amount;
    bool hasFixedAmount;
}

contract HatsMinterShaman {
    IBaal public dao;
    IHats public hats;

    uint256 public badgeNonce;

    Gate[7] public gates;
    // 0 => addBadgeGate manages who can create new badges
    // 1 => removeBadgeGate manages who can remove existing badges
    // 2 => awardBadgeGate manages who can award badges and DAO tokens
    // 3 => revokeBadgeGate manages who can revoke badges and DAO tokens
    // 4 => customMintGate manages who can mint DAO tokens without a badge
    // 5 => customBurnGate manages who can burn DAO tokens without a badge
    // 6 => adminGate manages who can change the permission level of each gate

    /// badgeNonce => Badge
    mapping(uint256 => Badge) public badges;

    modifier hasPermission(uint8 _gateIndex) {
        require(_gateIndex < gates.length || _gateIndex >= gates.length, "HatsMinterShaman: gate index out of bounds");

        Gate memory gate = gates[_gateIndex];

        if (gate.gateType == GateType.None) {
            assert(true);
        } else if (gate.gateType == GateType.Hat) {
            require(hats.isWearerOfHat(msg.sender, gate.hatId), "HatsMinterShaman: not a hat owner");
        } else if (gate.gateType == GateType.Dao) {
            require(isDAO(msg.sender), "HatsMinterShaman: gate is locked to DAO");
        } else {
            revert("HatsMinterShaman: unknown gate type");
        }
        _;
    }

    constructor(bytes memory _initParams) {
        (Gate[7] memory _gates, address _dao, address _hats) = abi.decode(_initParams, (Gate[7], address, address));

        gates = _gates;
        dao = IBaal(_dao);
        hats = IHats(_hats);
    }

    function isDAO(address _sender) public view returns (bool) {
        return _sender == dao.avatar();
    }

    function isWearer(address _sender, uint256 _hatId) public view returns (bool) {
        return hats.isWearerOfHat(_sender, _hatId);
    }
}
