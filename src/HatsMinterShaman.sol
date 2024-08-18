// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IBaal } from "baal/interfaces/IBaal.sol";


struct Metadata {
    uint256 protocol;
    string pointer;
}


struct Badge {
    string name;
    Metadata metadata;
    mapping (uint256 => bool) minters;
}



contract HatsMinterShaman {
    IBaal public dao;

  
}
