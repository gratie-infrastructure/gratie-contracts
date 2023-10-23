// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

    struct QuestInfo {
        address owner;
        address questRewardToken;
        uint256 noOfParticipants;
        uint256 amountAllocationPerUser;
    }

    mapping(address => mapping(address => uint256)) public businessBalance;
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
        uint256 _allocationPerUser,
        address _tokenTracker
    ) {
        uint256 expectedAmount = _noOfParticipants * _allocationPerUser;
        require(
            IERC20(_tokenTracker).balanceOf(msg.sender) > expectedAmount,
            "Insufficient Reward Tokens Balance"
        );
        _;
    }

    constructor(address _businessNFTAddress) {
        businessNFTs = IERC721(_businessNFTAddress);
    }

    /**
     * @dev createQuest(_noOfParticipants, _allocationPerUser): Creates a new quest, store quest details and recieve rewardTokens for the quest based on the business's existing balance
     * @param _noOfParticipants: approved number of participants for the quest
     * @param _allocationPerUser: amount of rewardToken each approved participant should get from this quest
     *
     */
    function createQuest(
        uint256 _noOfParticipants,
        uint256 _allocationPerUser,
        address _tokenTracker
    )
        public
        onlyBusinessNFTHolder
        hasEnoughRewardTokens(
            _noOfParticipants,
            _allocationPerUser,
            _tokenTracker
        )
    {
        uint256 existingBalance = getExistingBalance(msg.sender, _tokenTracker);
        uint256 questAllocation = _noOfParticipants * _allocationPerUser;
        uint256 expectedDeposit = questAllocation - existingBalance;

        IERC20(_tokenTracker).transferFrom(
            msg.sender,
            address(this),
            expectedDeposit
        );
        businessBalance[msg.sender][_tokenTracker] += expectedDeposit;

        QuestInfo memory _questInfo = QuestInfo({
            owner: address(msg.sender),
            questRewardToken: address(_tokenTracker),
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
        address[] memory recipients,
        address _tokenTracker
    ) public onlyBusinessNFTHolder {
        QuestInfo memory _questInfo = businessQuests[msg.sender];
        uint256 amountToBeAirdropped = recipients.length *
            _questInfo.noOfParticipants;
        require(
            businessBalance[msg.sender][_tokenTracker] > amountToBeAirdropped,
            "Insufficient Stored Balance"
        );

        for (uint256 index = 0; index < recipients.length; index++) {
            businessBalance[msg.sender][_tokenTracker] -= _questInfo
                .amountAllocationPerUser;
            bool sent = IERC20(_tokenTracker).transfer(
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
     * @dev getExistingBalance(businessAddress): returns the balance of a business in the contract
     * @param businessAddress: address of the business
     */
    function getExistingBalance(
        address businessAddress,
        address _tokenTracker
    ) public view returns (uint256) {
        return businessBalance[businessAddress][_tokenTracker];
    }
}
