// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IBaal} from "lib/Baal/contracts/interfaces/IBaal.sol";
import {IBaalToken} from "lib/Baal/contracts/interfaces/IBaalToken.sol";
import {IHats} from "lib/hats-protocol/src/Interfaces/IHats.sol";

/// ================================
/// ========== Struct/Enum =========
/// ================================

/// @notice Enum to indicate the security level of the gate
enum GateType {
    None,
    Hat,
    Dao
}
/// @notice Struct to store gate information. Optional hatId to allow for different hats per gate.
/// @note HatId is only required if GateType is Hat. If gateType is not hat, hatId should be 0.

struct Gate {
    GateType gateType;
    uint256 hatId;
}

/// @notice Struct to store metadata. Protocol indicates the storage medium (eg. 1 == IPFS, 2 == Arweave) and pointer indicates the endpoint of the storage
struct Metadata {
    uint256 protocol;
    string pointer;
}
/// @notice Struct to store badge information

struct Badge {
    string name;
    Metadata metadata;
    uint256 amount;
    bool isVotingToken;
    bool hasFixedAmount;
    bool isSlash;
    bool exists;
}

/// @title ScaffoldDaoShaman
/// @author Jord
/// @notice DAO contribitution scaffolding system for Moloch V3. Uses Hats Protocol to build to easily award repuatation and governance power to contributors and harden security over time.
contract ScaffoldDaoShaman {
    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emmitted when the contract is constructed
    /// @param gates Array of gates for the contract
    /// @param dao Address of the Moloch we are interacting with
    /// @param hats Address of hats protocol
    /// @param lootTokenAddress Address of the loot token
    /// @param sharesTokenAddress Address of the shares token
    /// @param lootTokenSymbol Symbol of the loot token
    /// @param sharesTokenSymbol Symbol of the shares token
    event Inintialized(
        Gate[] gates,
        address dao,
        address hats,
        address lootTokenAddress,
        address sharesTokenAddress,
        string lootTokenSymbol,
        string sharesTokenSymbol
    );

    /// @notice Emmitted when a badge is saved (create or replace)
    /// @param badgeId Id of the badge
    /// @param name Name of the badge
    /// @param metadata Metadata of the badge
    /// @param amount anount awarded or slashed when badge is applied
    /// @param isVotingToken Whether the badge is a voting token (shares) or non-voting (loot)
    /// @param hasFixedAmount Whether the badge has a fixed amount
    /// @param isSlash Whether the badge is slashes the users balance (burn) or not (mint)
    event BadgeSaved(
        uint256 badgeId,
        string name,
        Metadata metadata,
        uint256 amount,
        bool isVotingToken,
        bool hasFixedAmount,
        bool isSlash
    );

    /// @notice Emmitted when a badge is removed
    /// @param badgeId Id of the badge
    event BadgeRemoved(uint256 badgeId);

    /// @notice Emmitted when a badge is assigned
    /// @param badgeId Id of the badge
    /// @param recipient Address of the recipient
    /// @param amount Amount awarded or slashed
    /// @param comment Metadata
    event BadgeAssigned(uint256 badgeId, address recipient, uint256 amount, Metadata comment);

    /// @notice Emmitted when a badge is updated
    /// @param gateIndex Index of the gate
    /// @param gateType Type of the gate
    /// @param hatId Id of the hat
    event GateUpdated(uint8 gateIndex, GateType gateType, uint256 hatId);

    /// ===============================
    /// ========== Storage ============
    /// ===============================

    /// @notice Reference to the DAO (Ball Moloch V3) contract
    IBaal public dao;
    ///@notice Reference to the DAO voting token (shares)
    IBaalToken public shares;
    ///@notice Reference to the DAO non-voting token (loot)
    IBaalToken public loot;

    /// @notice Reference to Hats Protocol
    IHats public hats;
    /// @notice Incrementing badge nonce
    uint256 public badgeNonce;

    /// @notice Array of gates, each gate has a configureable and updateable security level
    Gate[3] public gates;
    // 0 => manages who can create, remove, and replace new badges
    // 1 => manages who can mint/slash rewards with applyBadges
    // 2 => manages who can change the Gates with manageGate

    /// @notice Mapping of badges
    /// @dev badgeId => Badge
    mapping(uint256 => Badge) public badges;

    /// ===============================
    /// ========== Modifiers ==========
    /// ===============================

    /// @notice Modifier to check the gate security level and apply security checks based on the gate security level
    modifier hasPermission(uint8 _gateIndex) {
        require(_gateIndex < gates.length || _gateIndex >= gates.length, "HatsMinterShaman: gate index out of bounds");

        Gate memory gate = gates[_gateIndex];

        if (gate.gateType == GateType.None) {
            assert(true);
        } else if (gate.gateType == GateType.Hat) {
            require(isWearer(msg.sender, gate.hatId), "HatsMinterShaman: unauthorized, not hat owner");
        } else if (gate.gateType == GateType.Dao) {
            require(isDAO(msg.sender), "HatsMinterShaman: unauthorized, not DAO");
        } else {
            revert("HatsMinterShaman: unknown gate type");
        }
        _;
    }

    /// ===============================
    /// ========== Constructor ========
    /// ===============================

    /// @notice Constructor
    /// @param _initParams bytes Init params
    /// @dev  _gates => Array of Gates
    /// @dev  _dao => Address of the DAO
    /// @dev  _hats => Address of the hats protocol
    constructor(bytes memory _initParams) {
        (Gate[] memory _gates, address _dao, address _hats) = abi.decode(_initParams, (Gate[], address, address));

        require(_gates.length == 3, "HatsMinterShaman: invalid number of gates");
        require(_hats != address(0), "HatsMinterShaman: invalid hats address");
        require(_dao != address(0), "HatsMinterShaman: invalid dao address");

        dao = IBaal(_dao);
        hats = IHats(_hats);
        shares = IBaalToken(dao.sharesToken());
        loot = IBaalToken(dao.lootToken());

        for (uint256 i = 0; i < _gates.length; i++) {
            gates[i] = _gates[i];
        }

        string memory lootTokenSymbol = loot.symbol();
        string memory sharesTokenSymbol = shares.symbol();

        emit Inintialized(_gates, _dao, _hats, address(loot), address(shares), lootTokenSymbol, sharesTokenSymbol);
    }

    /// @notice Create a new badge
    /// @param _badge Badge to create
    function createBadge(Badge memory _badge) public hasPermission(0) {
        require(_badge.exists, "HatsMinterShaman: badge.exists must be true");

        if (_badge.hasFixedAmount == false) {
            require(_badge.amount == 0, "HatsMinterShaman: badge amount must 0");
        }
        badges[badgeNonce] = _badge;

        emit BadgeSaved(
            badgeNonce,
            _badge.name,
            _badge.metadata,
            _badge.amount,
            _badge.isVotingToken,
            _badge.hasFixedAmount,
            _badge.isSlash
        );

        badgeNonce++;
    }

    /// @notice Remove a badge
    /// @param _badgeId Id of the badge
    function removeBadge(uint256 _badgeId) public hasPermission(0) {
        require(badges[_badgeId].exists, "HatsMinterShaman: badge doesn't exist");
        delete badges[_badgeId];

        emit BadgeRemoved(_badgeId);
    }

    /// @notice Replace an existing badge
    /// @param _badgeId Id of the badge
    /// @param _badge New badge
    function replaceBadge(uint256 _badgeId, Badge memory _badge) public hasPermission(0) {
        require(_badge.exists, "HatsMinterShaman: badge.exists must be true");
        if (_badge.hasFixedAmount == false) {
            require(_badge.amount == 0, "HatsMinterShaman: badge amount must 0");
        }
        require(badges[_badgeId].exists, "HatsMinterShaman: badge doesn't exist");
        badges[_badgeId] = _badge;

        emit BadgeSaved(
            _badgeId,
            _badge.name,
            _badge.metadata,
            _badge.amount,
            _badge.isVotingToken,
            _badge.hasFixedAmount,
            _badge.isSlash
        );
    }

    /// @notice Apply badges
    /// @param _badgeIds Ids of the badges
    /// @param _amounts Amounts of the badges
    /// @param _comments Comments of the badges
    /// @param _recipients Recipients of the badges
    function applyBadges(
        uint256[] memory _badgeIds,
        uint256[] memory _amounts,
        Metadata[] memory _comments,
        address[] memory _recipients
    ) public hasPermission(1) {
        if (
            _badgeIds.length != _amounts.length || _badgeIds.length != _comments.length
                || _badgeIds.length != _recipients.length
        ) {
            revert("HatsMinterShaman: length mismatch");
        }

        for (uint256 i = 0; i < _badgeIds.length; i++) {
            // getBadge checks if badge ID exists
            Badge memory _badge = getBadge(_badgeIds[i]);

            // if badge has fixed amount
            // set amount to badge amount
            if (_badge.hasFixedAmount) {
                _amounts[i] = _badge.amount;
            }

            // load operation into array to conform to Baal mint/burn signature
            address[] memory _recipient = new address[](1);
            uint256[] memory _amount = new uint256[](1);

            _recipient[0] = _recipients[i];
            _amount[0] = _amounts[i];

            if (_badge.isVotingToken) {
                if (_badge.isSlash) {
                    // load recipient balance
                    uint256 _recipientBalance = shares.balanceOf(_recipients[i]);

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
                    uint256 _recipientBalance = loot.balanceOf(_recipients[i]);

                    if (_amount[0] > _recipientBalance) {
                        _amount[0] = _recipientBalance;
                    }

                    dao.burnLoot(_recipient, _amount);
                } else {
                    dao.mintLoot(_recipient, _amount);
                }
            }

            emit BadgeAssigned(_badgeIds[i], _recipient[0], _amount[0], _comments[i]);
        }
    }

    /// @notice Manage a gate
    /// @param _gateIndex Index of the gate
    /// @param _gateType Type of the gate
    /// @param _hatId Id of the hat
    function manageGate(uint8 _gateIndex, GateType _gateType, uint256 _hatId) public hasPermission(2) {
        require(_gateIndex < gates.length || _gateIndex >= gates.length, "HatsMinterShaman: gate index out of bounds");

        gates[_gateIndex] = Gate(_gateType, _hatId);

        emit GateUpdated(_gateIndex, _gateType, _hatId);
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get a badge
    /// @param _badgeId Id of the badge
    /// @return badge Badge
    function getBadge(uint256 _badgeId) public view returns (Badge memory badge) {
        require(badges[_badgeId].exists, "HatsMinterShaman: badge doesn't exist");
        return badges[_badgeId];
    }

    /// @notice Get a gate
    /// @param _gateIndex Index of the gate
    /// @return gate Gate
    function getGate(uint8 _gateIndex) public view returns (Gate memory gate) {
        require(_gateIndex < gates.length || _gateIndex >= gates.length, "HatsMinterShaman: gate index out of bounds");
        return gates[_gateIndex];
    }

    /// @notice Determines if the sender is the DAO
    /// @param  _sender The address of the sender
    /// @return result bool - Whether the sender is the DAO
    function isDAO(address _sender) public view returns (bool result) {
        return _sender == dao.avatar();
    }

    /// @notice Determines if the sender is a hat wearer and is in good standing
    /// @param  _sender The address of of the sender
    /// @param  _hatId The id of the Hat
    /// @return result bool - Whether the sender is a hat wearer and is in good standing
    function isWearer(address _sender, uint256 _hatId) public view returns (bool) {
        return hats.isWearerOfHat(_sender, _hatId) && hats.isInGoodStanding(_sender, _hatId);
    }
}
