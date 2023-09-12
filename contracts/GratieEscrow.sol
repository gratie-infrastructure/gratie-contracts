// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1155Upgradeable.sol";

interface IERC721 is IERC721Upgradeable {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IERC20 is IERC20Upgradeable {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract GratieEscrow {
    IERC721 public businessNFTs;
    IERC20 public rewardToken;

    struct QuestInfo {
        address owner;
        uint256 noOfParticipants;
        uint256 amountAllocationPerUser;
    }

    mapping(address => uint256) public businessBalance;
    mapping(address => QuestInfo) public businessQuests;

    event QuestInitialized(
        address indexed businessAddress,
        uint256 noOfParticipants,
        uint256 allocationPerUser
    );

    event QuestAirdrop(
        address indexed businessAddress,
        uint256 allocationPerUser,
        address[] recipients
    );

    // modifier to make sure user owns a business NFT, effectively making them a Business
    modifier onlyBusinessNFTHolder() {
        require(
            businessNFTs.balanceOf(msg.sender) > 0,
            "Not A Business NFT Holder"
        );
        _;
    }

    // Modifier to make sure user has enough reward tokens for quest creation
    modifier hasEnoughRewardTokens(
        uint256 _noOfParticipants,
        uint256 _allocationPerUser
    ) {
        uint256 expectedAmount = _noOfParticipants * _allocationPerUser;
        require(
            rewardToken.balanceOf(msg.sender) > expectedAmount,
            "Insufficient Reward Tokens Balance"
        );
        _;
    }

    constructor(address _businessNFTAddress, address _rewardTokenAddress) {
        businessNFTs = IERC721(_businessNFTAddress);
        rewardToken = IERC20(_rewardTokenAddress);
    }

    /**
     * @dev createQuest(_noOfParticipants, _allocationPerUser): Creates a new quest, store quest details and recieve rewardTokens for the quest based on the business's existing balance
     * @param _noOfParticipants: approved number of participants for the quest
     * @param _allocationPerUser: amount of rewardToken each approved participant should get from this quest
     *
     */
    function createQuest(
        uint256 _noOfParticipants,
        uint256 _allocationPerUser
    )
        public
        onlyBusinessNFTHolder
        hasEnoughRewardTokens(_noOfParticipants, _allocationPerUser)
    {
        uint256 existingBalance = getExistinBalance(msg.sender);
        uint256 questAllocation = _noOfParticipants * _allocationPerUser;
        uint256 expectedDeposit = questAllocation - existingBalance;

        rewardToken.transferFrom(msg.sender, address(this), expectedDeposit);
        businessBalance[msg.sender] += expectedDeposit;

        QuestInfo memory _questInfo = QuestInfo({
            owner: address(msg.sender),
            noOfParticipants: _noOfParticipants,
            amountAllocationPerUser: _allocationPerUser
        });
        businessQuests[msg.sender] = _questInfo;

        emit QuestInitialized(
            msg.sender,
            _noOfParticipants,
            _allocationPerUser
        );
    }

    /**
     * @dev airdropRewards(recipients): airdrops rewards to an array of users provided
     * @param recipients: array of recipients
     *
     *
     */
    function airdropRewards(
        address[] memory recipients
    ) public onlyBusinessNFTHolder {
        QuestInfo memory _questInfo = businessQuests[msg.sender];
        uint256 amountToBeAirdropped = recipients.length *
            _questInfo.noOfParticipants;
        require(
            businessBalance[msg.sender] > amountToBeAirdropped,
            "Insufficient Stored Balance"
        );

        for (uint256 index = 0; index < recipients.length; index++) {
            businessBalance[msg.sender] -= _questInfo.amountAllocationPerUser;
            bool sent = rewardToken.transfer(
                recipients[index],
                _questInfo.amountAllocationPerUser
            );
            require(sent, "Failed to airdrop tokens");
        }

        emit QuestAirdrop(
            msg.sender,
            _questInfo.amountAllocationPerUser,
            recipients
        );
    }

    /*
     * @dev getExistinBalance(businessAddress): returns the balance of a business in the contract
     * @param businessAddress: address of the business
     */
    function getExistinBalance(
        address businessAddress
    ) public view returns (uint256) {
        return businessBalance[businessAddress];
    }
}
