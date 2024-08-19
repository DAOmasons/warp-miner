// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IBaal} from "lib/Baal/contracts/interfaces/IBaal.sol";
import {IHats} from "lib/hats-protocol/src/Interfaces/IHats.sol";

enum GateType {
    None,
    Hat,
    Dao
}

/// ===============================
/// ========== Struct =============
/// ===============================

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
    bool isVotingToken;
    bool hasFixedAmount;
    bool isSlash;
    bool exists;
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
            require(isWearer(msg.sender, gate.hatId), "HatsMinterShaman: not a hat owner");
        } else if (gate.gateType == GateType.Dao) {
            require(isDAO(msg.sender), "HatsMinterShaman: gate is locked to DAO");
        } else {
            revert("HatsMinterShaman: unknown gate type");
        }
        _;
    }

    constructor(bytes memory _initParams) {
        (Gate[] memory _gates, address _dao, address _hats) = abi.decode(_initParams, (Gate[], address, address));

        require(_gates.length == 7, "HatsMinterShaman: invalid number of gates");
        require(_hats != address(0), "HatsMinterShaman: invalid hats address");
        require(_dao != address(0), "HatsMinterShaman: invalid dao address");

        // gates = _gates;
        dao = IBaal(_dao);
        hats = IHats(_hats);

        for (uint256 i = 0; i < _gates.length; i++) {
            gates[i] = _gates[i];
        }
    }

    function createBadge(Badge memory _badge) public hasPermission(0) {
        require(_badge.exists, "HatsMinterShaman: badge.exists must be true");
        badges[badgeNonce] = _badge;
        badgeNonce++;
    }

    function removeBadge(uint256 _badgeId) public hasPermission(1) {
        require(badges[_badgeId].exists, "HatsMinterShaman: badge doesn't exist");
        delete badges[_badgeId];
    }

    function replaceBadge(uint256 _badgeId, Badge memory _badge) public hasPermission(1) {
        require(_badge.exists, "HatsMinterShaman: badge.exists must be true");
        require(badges[_badgeId].exists, "HatsMinterShaman: badge doesn't exist");
        badges[_badgeId] = _badge;
    }

    function applyBadge(uint256 _badgeId, uint256 _amount, Metadata memory _metadata, address _to)
        public
        hasPermission(2)
    {
        require(badges[_badgeId].exists, "HatsMinterShaman: badge doesn't exist");

        if (badges[_badgeId].hasFixedAmount) {
            _amount = badges[_badgeId].amount;
        }
    }

    function revokeBadge(uint256 _badgeId, uint256 _amount, Metadata memory _metadata, address _from)
        public
        hasPermission(3)
    {
        /// TODO:
    }

    function customMint(uint256 _amount, Metadata memory _metadata, address _to) public hasPermission(4) {
        /// TODO:
    }

    function customBurn(uint256 _hatId, Metadata memory _metadata, address _from) public hasPermission(5) {
        /// TODO:
    }

    function manageGate(uint8 _gateIndex, GateType _gateType, uint256 _hatId) public hasPermission(6) {
        /// TODO:
    }

    // function _handleMint() internal {

    // }

    // function _handleBurn() internal {

    // }

    function getBadge(uint256 _badgeId) public view returns (Badge memory badge) {
        require(badges[_badgeId].exists, "HatsMinterShaman: badge doesn't exist");
        return badges[_badgeId];
    }

    function getGate(uint8 _gateIndex) public view returns (Gate memory gate) {
        require(_gateIndex < gates.length || _gateIndex >= gates.length, "HatsMinterShaman: gate index out of bounds");
        return gates[_gateIndex];
    }

    function getGatePermissionLevel(uint8 _gateIndex) public view returns (GateType) {
        return getGate(_gateIndex).gateType;
    }

    function getGateHatId(uint8 _gateIndex) public view returns (uint256) {
        return getGate(_gateIndex).hatId;
    }

    function isDAO(address _sender) public view returns (bool) {
        return _sender == dao.avatar();
    }

    function isWearer(address _sender, uint256 _hatId) public view returns (bool) {
        return hats.isWearerOfHat(_sender, _hatId) && hats.isInGoodStanding(_sender, _hatId);
    }
}
