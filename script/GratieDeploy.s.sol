// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/Gratie.sol";
import "../contracts/MockERC20.sol";
import "../contracts/ProxyAdmin.sol";
import "../contracts/RewardToken.sol";
import "../contracts/BusinessNFTs.sol";
import "../contracts/ServiceProviderNFTs.sol";

import {Script} from "forge-std/Script.sol";
import "forge-std/console2.sol";
import "forge-std/StdCheats.sol";
import "forge-std/Vm.sol";
import "forge-std/Test.sol";

contract DeployGratie is Script {
    function run() external {
        uint256 privatekey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privatekey);
        address account = vm.addr(privatekey);
        uint256 initialSupply = 1_000_000;

        Gratie gratie = new Gratie();
        USDCMock usdcContract = new USDCMock(account, initialSupply);
        ProxyAdmin proxyAdmin = new ProxyAdmin(account);
        RewardToken rewardToken = new RewardToken();
        BusinessNFT businessNft = new BusinessNFT();
        ServiceProviderNFT serviceProviderNft = new ServiceProviderNFT();

        Gratie.BusinessNftTier[]
            memory _businessNftTier = new Gratie.BusinessNftTier[](1);
        _businessNftTier[0].name = "TIER1";
        _businessNftTier[0].ipfsMetadataLink = "ipfs://something";
        _businessNftTier[0].usdcPrice = 30;
        _businessNftTier[0].freeUsersCount = 1;
        _businessNftTier[0].usdcPerAdditionalUser = 5;
        _businessNftTier[0].platformFee = 2;
        _businessNftTier[0].isActive = true;

        address[] memory gratiePlatformAdmins = new address[](1);
        gratiePlatformAdmins[0] = account; //here we need an admin right so well have this so callled account from my private key

        address[] memory paymentMethods = new address[](2);
        paymentMethods[0] = address(usdcContract); // we need an token contract that woudld receive all the payements so i think we should add here the account actually
        paymentMethods[1] = address(0);

        Gratie.InitData memory _initData = Gratie.InitData({
            domainName: "Gratie.com",
            domainVersion: "v2",
            platformFeeReceiver: account, // this is required where will all the platform fee be given here we probably need the token actually
            businessNFTs: address(businessNft),
            serviceProviderNFTs: address(serviceProviderNft),
            rewardTokenImplementation: address(rewardToken),
            defaultAdminAddress: account,
            usdcContractAddress: address(usdcContract),
            paymentMethods: paymentMethods,
            gratiePlatformAdmins: gratiePlatformAdmins,
            businessNftTiers: _businessNftTier
        });

        TransparentUpgradeableProxy transparentUpgradeableProxy = new TransparentUpgradeableProxy(
                address(gratie),
                address(proxyAdmin),
                abi.encodeWithSignature(
                    "initialize((string,string,address,address,address,address,address,address,address[],address[],(string,string,uint256,uint256,uint256,uint256,bool)[]))",
                    _initData
                )
            );
        gratie = Gratie(address(transparentUpgradeableProxy));

        console.log("ProxyAdmin Address: ", address(proxyAdmin));
        console.log(
            "TransparentUpgradeableProxy Address: ",
            address(transparentUpgradeableProxy)
        );
        console.log("Gratie Address: ", address(gratie));
        console.log("USDCMock Address: ", address(usdcContract));
        console.log(
            "ServiceProviderNFT Address: ",
            address(serviceProviderNft)
        );
        console.log("BusinessNFT Address: ", address(businessNft));
        console.log("RewardToken Address: ", address(rewardToken));

        vm.stopBroadcast();
    }
}
