// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../src/Gratie.sol";
import "../src/TestUSDC.sol";
import "../src/ProxyAdmin.sol";
import "../src/RewardToken.sol";
import "../src/BusinessNFTs.sol";
import "../src/ServiceProviderNFTs.sol";

import {Script} from "forge-std/Script.sol";
import "forge-std/console2.sol"; 
import "forge-std/StdCheats.sol";
import "forge-std/Vm.sol";
import "forge-std/Test.sol";

contract DeployGratie is Script {
   
     function setUp() public {
    }
     function run() external  {
       address originalGratie;
       uint256 privatekey =  vm.envUint("PRIVATE_KEY");
       address account = vm.addr(privatekey);
       console.log(account);
       Gratie.BusinessNftTier[] memory _businessNftTier = new Gratie.BusinessNftTier[](1);
        _businessNftTier[0].name = "TIER1"; 
        _businessNftTier[0].ipfsMetadataLink = "ipfs://something";
        _businessNftTier[0].usdcPrice = 30;
        _businessNftTier[0].freeUsersCount = 1;
        _businessNftTier[0].usdcPerAdditionalUser = 5;
        _businessNftTier[0].platformFee = 2;
        _businessNftTier[0].isActive = true;

        address[] memory gratiePlatformAdmins = new address[](1);
        gratiePlatformAdmins[0] = account;      //here we need an admin right so well have this so callled account from my private key 

        address[] memory paymentMethods = new address[](1);
        paymentMethods[0] = address(usdcContract);    // we need an token contract that woudld receive all the payements so i think we should add here the account actually 

        vm.startBroadcast();
        // we need to deploy the contract 
        //call the initData function then 
        Gratie  gratie = new Gratie();
        originalGratie = address(gratie);
        USDCMock  usdcContract = new USDCMock();
        ProxyAdmin  proxyAdmin = new ProxyAdmin(account);
        RewardToken  rewardToken = new RewardToken();
        BusinessNFT  businessNft = new BusinessNFT();
        ServiceProviderNFT  serviceProviderNft = new ServiceProviderNFT();

         Gratie.InitData memory _initData = Gratie.InitData({
            domainName: "Gratie.com",
            domainVersion: "v2",
            platformFeeReceiver: address(PlatformFeeReceiver), // this is required where will all the platform fee be given here we probably need the token actually 
            businessNFTs: address(businessNft),
            serviceProviderNFTs: address(serviceProviderNft),
            rewardTokenImplementation: address(rewardToken),
            defaultAdminAddress: account,
            usdcContractAddress: address(usdcContract),
            paymentMethods: paymentMethods,
            gratiePlatformAdmins: gratiePlatformAdmins,
            businessNftTiers: _businessNftTier
        });

        TransparentUpgradeableProxy  transparentUpgradeableProxy = new TransparentUpgradeableProxy(
            address(gratie),
            address(proxyAdmin),
            abi.encodeWithSignature(
                "initialize((string,string,address,address,address,address,address,address,address[],address[],(string,string,uint256,uint256,uint256,uint256,bool)[]))",
                _initData
            )
        );
        vm.stopBroadcast();
    }
}