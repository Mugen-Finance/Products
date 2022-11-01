//SPDX-License-Identifier: ISC

pragma solidity 0.8.17;

import {ICrossChainSwaps} from "../CrossChainSwaps/interfaces/ICrossChainSwaps.sol";

abstract contract RewardHandler is ICrossChainSwaps {
    ICrossChainSwaps public immutable crossChainSwaps;

    constructor(address _swaps) {
        crossChainSwaps = ICrossChainSwaps(_swaps);
    }

    function claimAndRepay(uint8[] memory steps, bytes[] memory data) internal {
        //Claim reward logic goes here
        crossChainSwaps.swaps(steps, data);
    }
}
