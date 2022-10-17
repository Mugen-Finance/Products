// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {ReentrancyGuard} from "openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC20} from "openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "openzeppelin/contracts/security/Pausable.sol";

contract MockStaking is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 30 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    address public yieldDistributor;
    uint256 private _totalSupply;

    /*///////////////////////////////////////////////////////////////
                            Mappings
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private _balances;

    /*///////////////////////////////////////////////////////////////
                            Errors
    //////////////////////////////////////////////////////////////*/

    error ZeroRewards();
    error FeeNotSet();
    error NotYield();
    error TRANSFER_FAILED();

    /*///////////////////////////////////////////////////////////////
                              Events
    //////////////////////////////////////////////////////////////*/

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
    event YieldDistributorSet(
        address indexed caller,
        address indexed _yieldDistributor
    );
    event Compounded(
        address indexed _caller,
        uint256 _wethClaimed,
        uint256 _mgnCompounded
    );
    event FeeSet(address indexed _caller, uint24 _fee);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _stakingToken, address _rewardsToken) {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
    }

    /*///////////////////////////////////////////////////////////////
                        Admin Functions
    //////////////////////////////////////////////////////////////*/

    function setYield(address _yield) external onlyOwner {
        yieldDistributor = _yield;
        emit YieldDistributorSet(msg.sender, _yield);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /*///////////////////////////////////////////////////////////////
                        Reward Logic
    //////////////////////////////////////////////////////////////*/

    ///@param _rewards amount of yield generated to deposit

    function issuanceRate(uint256 _rewards)
        public
        nonReentrant
        updateReward(address(0))
    {
        if (msg.sender != yieldDistributor) {
            revert NotYield();
        }
        require(_rewards > 0, "Zero rewards");
        require(_totalSupply != 0, "xMGN:UVS:ZERO_SUPPLY");
        if (block.timestamp >= periodFinish) {
            rewardRate = _rewards / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (_rewards + leftover) / rewardsDuration;
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        IERC20(rewardsToken).safeTransferFrom(
            msg.sender,
            address(this),
            _rewards
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;

        emit RewardAdded(_rewards);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                1e18) / _totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    /*///////////////////////////////////////////////////////////////
                        User Functions 
    //////////////////////////////////////////////////////////////*/

    function stake(uint256 amount)
        public
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot stake 0");
        _totalSupply += amount;
        _balances[msg.sender] = _balances[msg.sender] + amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply - amount;
        _balances[msg.sender] = _balances[msg.sender] - amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    ///@notice claims fees, swaps them for Mugen, and stakes that Mugen

    function compound(uint256 amount)
        external
        updateReward(msg.sender)
        returns (uint256)
    {
        uint256 claimed = getReward();
        compoundedStake(claimed, msg.sender);
        emit Compounded(msg.sender, claimed, claimed);
        return claimed;
    }

    function compoundedStake(uint256 _amount, address _account)
        internal
        nonReentrant
    {
        require(_amount > 0, "Cannot stake 0");
        _totalSupply += _amount;
        _balances[_account] = _balances[_account] + _amount;
        emit Staked(_account, _amount);
    }

    function compoundClaim(address account)
        internal
        nonReentrant
        returns (uint256)
    {
        uint256 reward = rewards[account];
        if (reward > 0) {
            rewards[account] = 0;
            emit RewardPaid(account, reward);
        }
        return reward;
    }

    function getReward()
        public
        nonReentrant
        updateReward(msg.sender)
        returns (uint256)
    {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
        return reward;
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /*///////////////////////////////////////////////////////////////
                        View Functions 
    //////////////////////////////////////////////////////////////*/

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /*///////////////////////////////////////////////////////////////
                        Modifier Functions 
    //////////////////////////////////////////////////////////////*/
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
}
