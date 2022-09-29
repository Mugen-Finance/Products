//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * TODO
 * Handle rejected bond offers
 * handle repayment situations (ie. has it been repayed yet or not. )
 */

import {ERC721} from "openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";

contract PrivateBonds is ERC721, Ownable {
    using SafeERC20 for IERC20;

    mapping(uint256 => mapping(address => BondDetails)) public offers;
    mapping(uint256 => bool) public decisions;
    uint256 public bondId;
    uint256 public offerId;

    event OfferMade(
        address indexed caller,
        address indexed token,
        uint256 loanAmount,
        uint24 interestRate,
        uint256 expirationDate
    );
    event OfferAccepted(bool decision, uint256 offerNumber);
    event OfferDeclined(bool decision, uint256 offerNumber);
    event Repayed(address indexed _creditor, uint256 loanAmount);

    error NotEnoguh();

    struct BondDetails {
        address token;
        uint256 amount;
        uint24 interestRate;
        uint256 expiration;
    }

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    function offer(BondDetails memory details) external {
        require(IERC20(details.token).balanceOf(msg.sender) > details.amount);
        uint256 id = bondId;
        offers[id][msg.sender] = details;
        bondId++;
        emit OfferMade(
            msg.sender,
            details.token,
            details.amount,
            details.interestRate,
            details.expiration
        );
    }

    function repay(
        uint256 loanId,
        address creditor,
        uint256 amount
    ) external onlyOwner {
        BondDetails memory bond = offers[loanId][creditor];
        uint256 interest = (bond.amount * bond.interestRate) / 1000;
        uint256 requiredRepayment = bond.amount + interest;
        if (amount < requiredRepayment) revert NotEnoguh();
        IERC20(bond.token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(bond.token).safeTransfer(creditor, amount);
        emit Repayed(creditor, loanId);
    }

    function offerDecision(
        bool decision,
        uint256 offerNumber,
        address loaner
    ) external onlyOwner {
        if (decision == true) {
            BondDetails memory details = offers[offerNumber][loaner];
            IERC20(details.token).safeTransferFrom(
                loaner,
                address(this),
                details.amount
            );
            emit OfferAccepted(decision, offerNumber);
        } else {
            emit OfferDeclined(decision, offerNumber);
        }
    }
}
