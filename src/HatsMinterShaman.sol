// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IBaal} from "lib/Baal/contracts/interfaces/IBaal.sol";
import {IBaalToken} from "lib/Baal/contracts/interfaces/IBaalToken.sol";
import {IHats} from "lib/hats-protocol/src/Interfaces/IHats.sol";
import {console2} from "lib/forge-std/src/Test.sol";

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
            require(isDAO(msg.sender), "HatsMinterShaman: dao owner only");
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

        if (_badge.hasFixedAmount == false) {
            require(_badge.amount == 0, "HatsMinterShaman: badge amount must 0");
        }
        badges[badgeNonce] = _badge;
        badgeNonce++;
    }

    function removeBadge(uint256 _badgeId) public hasPermission(1) {
        require(badges[_badgeId].exists, "HatsMinterShaman: badge doesn't exist");
        delete badges[_badgeId];
    }

    function replaceBadge(uint256 _badgeId, Badge memory _badge) public hasPermission(1) {
        require(_badge.exists, "HatsMinterShaman: badge.exists must be true");
        if (_badge.hasFixedAmount == false) {
            require(_badge.amount == 0, "HatsMinterShaman: badge amount must 0");
        }
        require(badges[_badgeId].exists, "HatsMinterShaman: badge doesn't exist");
        badges[_badgeId] = _badge;
    }

    //
    function applyBadges(
        uint256[] memory _badgeIds,
        uint256[] memory _amounts,
        Metadata[] memory _metadata,
        address[] memory _recipients
    ) public hasPermission(2) {
        // TODO: test all possible cases for length mismatch
        if (
            _badgeIds.length != _amounts.length || _badgeIds.length != _metadata.length
                || _badgeIds.length != _recipients.length
        ) {
            revert("HatsMinterShaman: length mismatch");
        }

        for (uint256 i = 0; i < _badgeIds.length; i++) {
            console2.log("badgeId: ", _badgeIds[i]);
            Badge memory _badge = getBadge(_badgeIds[i]);

            if (_badge.hasFixedAmount) {
                _amounts[i] = _badge.amount;
            }

            address[] memory _recipient = new address[](1);
            uint256[] memory _amount = new uint256[](1);

            _recipient[0] = _recipients[i];
            _amount[0] = _amounts[i];

            if (_badge.isVotingToken) {
                if (_badge.isSlash) {
                    // load token balance to prevent underflows
                    IBaalToken sharesToken = IBaalToken(dao.sharesToken());
                    uint256 _recipientBalance = sharesToken.balanceOf(_recipients[i]);

                    // if recipient balance is less than amount, set amount to balance
                    // so prevent underflow and remove remnaining balance
                    if (_amount[0] > _recipientBalance) {
                        _amount[0] = _recipientBalance;
                    }

                    dao.burnShares(_recipient, _amount);
                } else {
                    dao.mintShares(_recipient, _amount);
                }
            } else {
                if (_badge.isSlash) {
                    IBaalToken lootToken = IBaalToken(dao.lootToken());
                    uint256 _recipientBalance = lootToken.balanceOf(_recipients[i]);

                    if (_amount[0] > _recipientBalance) {
                        _amount[0] = _recipientBalance;
                    }
                    console2.log("HatsMinterShaman: slash amount: ", _amount[0]);
                    dao.burnLoot(_recipient, _amount);
                } else {
                    console2.log("HatsMinterShaman: mint amount: ", _amount[0]);
                    dao.mintLoot(_recipient, _amount);
                }
            }
        }
    }

    function manageGate(uint8 _gateIndex, GateType _gateType, uint256 _hatId) public hasPermission(6) {
        /// TODO:
    }

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
