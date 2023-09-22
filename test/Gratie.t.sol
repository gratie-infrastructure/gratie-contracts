// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "forge-std/StdCheats.sol";
import "forge-std/Vm.sol";
import "../contracts/Gratie.sol";
import "../contracts/MockERC20.sol";
import "../contracts/ProxyAdmin.sol";
import "../contracts/RewardToken.sol";
import "../contracts/BusinessNFTs.sol";
import "../contracts/ServiceProviderNFTs.sol";
import "../contracts/TransparentUpgradeableProxy.sol";

contract GratieTest is Test {
    Gratie public gratieContract;
    USDCMock public usdcContract;
    ProxyAdmin public proxyAdmin;
    RewardToken public rewardToken;
    BusinessNFT public businessNft;
    ServiceProviderNFT public serviceProviderNft;
    TransparentUpgradeableProxyCustom public transparentUpgradeableProxy;

    struct BusinessNftTier {
        string name;
        string ipfsMetadataLink;
        uint256 usdcPrice;
        uint256 freeUsersCount;
        uint256 usdcPerAdditionalUser;
        uint256 platformFee;
        bool isActive;
    }

    struct InitData {
        string domainName;
        string domainVersion;
        address platformFeeReceiver;
        address businessNFTs;
        address serviceProviderNFTs;
        address rewardTokenImplementation;
        address defaultAdminAddress;
        address usdcContractAddress;
        address[] paymentMethods;
        address[] gratiePlatformAdmins;
        BusinessNftTier[] businessNftTiers;
    }

    function setUp() public {
        gratieContract = new Gratie();
        usdcContract = new USDCMock();
        proxyAdmin = new ProxyAdmin(address(1337));
        rewardToken = new RewardToken();
        businessNft = new BusinessNFT();
        serviceProviderNft = new ServiceProviderNFT();

        BusinessNftTier[] memory _businessNftTier;

        _businessNftTier[0].name = "Test";
        _businessNftTier[0].ipfsMetadataLink = "ipfs://something";
        _businessNftTier[0].usdcPrice = 30;
        _businessNftTier[0].freeUsersCount = 1;
        _businessNftTier[0].usdcPerAdditionalUser = 5;
        _businessNftTier[0].platformFee = 2;
        _businessNftTier[0].isActive = true;

        address[] memory gratiePlatformAdmins;
        gratiePlatformAdmins[0] = address(1000);

        address[] memory paymentMethods;
        paymentMethods[0] = address(999);

        InitData memory _initData;
        _initData.domainName = "gratie.com";
        _initData.domainVersion = "v1";
        _initData.platformFeeReceiver = address(700);
        _initData.businessNFTs = address(businessNft);
        _initData.serviceProviderNFTs = address(serviceProviderNft);
        _initData.rewardTokenImplementation = address(rewardToken);
        _initData.defaultAdminAddress = address(777);
        _initData.usdcContractAddress = address(usdcContract);
        _initData.paymentMethods = paymentMethods;
        _initData.gratiePlatformAdmins = gratiePlatformAdmins;
        _initData.businessNftTiers = _businessNftTier;

        transparentUpgradeableProxy = new TransparentUpgradeableProxyCustom(
            address(gratieContract),
            address(proxyAdmin),
            abi.encodeWithSignature(
                "initialize(string,string,address,address,address,address,address,address,address[],address[],(string,string,uint256,uint256,uint256,uint256,bool)[])",
                _initData.domainName,
                _initData.domainVersion,
                _initData.platformFeeReceiver,
                _initData.businessNFTs,
                _initData.serviceProviderNFTs,
                _initData.rewardTokenImplementation,
                _initData.defaultAdminAddress,
                _initData.usdcContractAddress,
                _initData.paymentMethods,
                _initData.gratiePlatformAdmins,
                _initData.businessNftTiers
            )
        );

        gratieContract = Gratie(address(transparentUpgradeableProxy));

        // transparentUpgradeableProxy.initialize(_initData);
    }

    function testIsValidPaymentMethodsAreSet() public view {
        assert(gratieContract.isValidPaymentMethod(address(999)));
    }
}
