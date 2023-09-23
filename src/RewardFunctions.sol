// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;  

import "openzeppelin-contracts-upgradeable/contracts/interfaces/IERC721Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/ClonesUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/interfaces/IERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
interface IERC721 is IERC721Upgradeable {
    function mint(
        address _receiver,
        uint256 _tokenId,
        string memory _tokenURI
    ) external;

    function mintBatch(
        address[] calldata _receivers,
        uint256[] calldata _tokenIds,
        string[] calldata _tokenURIs
    ) external;
}

interface IERC20Mintable is IERC20Upgradeable {
    function mint(
        address _receiver,
        uint256 _amount
    ) external;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _iconURI,
        address _gratieContract
    ) external;
}

contract RewardFunctions  is OwnableUpgradeable{


    IERC721 public businessNFTs;
    mapping(uint256 => uint256) public rewardTokenMints;
    mapping(uint256 => Business) public businesses;
    address public rewardTokenImplementation;
    mapping(uint256 => BusinessNftTier) public businessNftTiers;
    uint256 public totalBusinesses;
    mapping(uint256 => mapping(uint256 => RewardTokenDistribution)) public rewardDistributions;
    mapping(uint256 => mapping(address => uint256)) public serviceProviderRegisteredAt;
    mapping(uint256 => uint256) public rewardTokensAvailable;
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public hasClaimedRewards;
    mapping(uint256 => uint256) public rewardDistributionsCreated;
    mapping(uint256 => uint256) public rewardTokensDistributed;

      struct Business {
        string name;
        string email;
        address rewardToken;
        uint256 businessNftTier;
        uint256 divisionsInBusiness;
        uint256 totalServiceProviders;
        mapping(uint256 => ServiceProviderDivision) serviceProviderDivisions;
    }
        
      struct RewardTokenMint {
        uint256 businessId;
        uint256 amount;
        uint256 lockInPercentage;
        uint256 mintNonce;
    }
     struct ServiceProviderDivision {
        string name;
        string ipfsMetadataLink;
        uint256 serviceProviderNftID;
        uint256 serviceProvidersInDivision;
    }

     struct BusinessNftTier {
        string name;
        string ipfsMetadataLink;
        uint256 usdcPrice;
        uint256 freeUsersCount;
        uint256 usdcPerAdditionalUser;
        uint256 platformFee;
        bool isActive;
    }

     struct RewardTokenDistribution {
        uint256 totalServiceProviders;
        uint256 tokensPerProvider;
        uint256 startTimestamp;
        uint256 percentageToDistribute;
        uint256 availableRewardTokens;
        uint256 claimsDone;
    }

    event RewardTokensGenerated(
        address indexed by,
        uint256 indexed businessId,
        uint256 indexed mintNonce,
        address rewardToken,
        uint256 amount,
        uint256 lockInPercentage,
        uint256 totalSupply,
        string tokenName,
        string tokenSymbol,
        string tokenIconURL,
        uint256 timestamp
    );

    event RewardDistributionCreated(
        address indexed by,
        uint256 indexed businessId,
        uint256 indexed distributionNo,
        uint256 totalServiceProviders,
        uint256 percentageToDistribute,
        uint256 availableRewardTokens,
        uint256 tokensPerProvider,
        uint256 startTimestamp
    );

    event RewardTokensClaimed(
        address indexed by,
        uint256 indexed businessId,
        uint256 indexed distributionNo,
        address rewardToken,
        uint256 amount,
        uint256 timestamp
    );


    function generateRewardTokens(
    RewardTokenMint memory _data,
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _tokenIconURL
) external {
    // Remove the signature-related check

    require(
        msg.sender == businessNFTs.ownerOf(_data.businessId),
        "Not the business owner!"
    );
    require(
        _data.mintNonce == ++rewardTokenMints[_data.businessId],
        "Invalid mint nonce!"
    );
    require(
        _data.lockInPercentage <= 10000,
        "Invalid lock in percentage!"
    );

    address rewardToken = businesses[_data.businessId].rewardToken;
    if (rewardToken == address(0)) {
        rewardToken = ClonesUpgradeable.clone(rewardTokenImplementation);
        IERC20Mintable(rewardToken).initialize(_tokenName, _tokenSymbol, _tokenIconURL, address(this));
        businesses[_data.businessId].rewardToken = rewardToken;
    }

    uint256 platformFee = (businessNftTiers[businesses[_data.businessId].businessNftTier].platformFee * _data.amount) / 10000;
    uint256 lockInAmount = (_data.lockInPercentage * _data.amount) / 10000;
    rewardTokensAvailable[_data.businessId] += lockInAmount;

    IERC20Mintable(rewardToken).mint(address(this), lockInAmount);
    IERC20Mintable(rewardToken).mint(owner(), platformFee);
    IERC20Mintable(rewardToken).mint(msg.sender, _data.amount - platformFee - lockInAmount);

    emit RewardTokensGenerated(
        msg.sender,
        _data.businessId,
        _data.mintNonce,
        rewardToken,
        _data.amount,
        _data.lockInPercentage,
        IERC20Mintable(rewardToken).totalSupply(),
        _tokenName,
        _tokenSymbol,
        _tokenIconURL,
        block.timestamp
    );
}



    function startRewardDistribution(
        uint256 _businessID,
        uint256 _percentageToDistribute
    ) external {
        require(
            msg.sender == businessNFTs.ownerOf(_businessID),
            "Not the business owner!"
        );
        require(
            _percentageToDistribute > 0 &&
            _percentageToDistribute <= 10000,
            "Invalid distribution percentage!"
        );
        require(
            rewardTokensAvailable[_businessID] > 0,
            "No reward tokens available to distribute!"
        );
        uint256 tokensPerProvider = (_percentageToDistribute * rewardTokensAvailable[_businessID]) /
            (10000 * businesses[_businessID].totalServiceProviders);

        rewardDistributions[_businessID][++rewardDistributionsCreated[_businessID]] = RewardTokenDistribution(
            businesses[_businessID].totalServiceProviders,
            tokensPerProvider,
            block.timestamp,
            _percentageToDistribute,
            rewardTokensAvailable[_businessID],
            0
        );
        emit RewardDistributionCreated(
            msg.sender,
            _businessID,
            rewardDistributionsCreated[_businessID],
            businesses[_businessID].totalServiceProviders,
            _percentageToDistribute,
            rewardTokensAvailable[_businessID],
            tokensPerProvider,
            block.timestamp
        );
    }


    function claimRewardTokens(
        uint256 _businessID,
        uint256 _distributionNo
    ) external {
        require(
            _businessID > 0 &&
            _businessID <= totalBusinesses,
            "Invalid business id!"
        );
        RewardTokenDistribution storage _distribution = rewardDistributions[_businessID][_distributionNo];
        require(
            _distribution.startTimestamp != 0,
            "Invalid distribution no!"
        );
        require(
            serviceProviderRegisteredAt[_businessID][msg.sender] > 0 &&
            serviceProviderRegisteredAt[_businessID][msg.sender] <= _distribution.startTimestamp,
            "Not eligible for this distribution!"
        );
        require(
            hasClaimedRewards[msg.sender][_businessID][_distributionNo] == false,
            "Already Claimed!"
        );

        rewardTokensAvailable[_businessID] -= _distribution.tokensPerProvider;
        rewardTokensDistributed[_businessID] += _distribution.tokensPerProvider;
        hasClaimedRewards[msg.sender][_businessID][_distributionNo] = true;
        _distribution.claimsDone += 1;

        IERC20Upgradeable(businesses[_businessID].rewardToken).transfer(msg.sender, _distribution.tokensPerProvider);

        emit RewardTokensClaimed(
            msg.sender,
            _businessID,
            _distributionNo,
            businesses[_businessID].rewardToken,
            _distribution.tokensPerProvider,
            block.timestamp
        );
    }
}