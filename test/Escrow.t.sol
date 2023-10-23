// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "forge-std/StdCheats.sol";
import "forge-std/Vm.sol";
import {USDCMock} from "./Gratie.t.sol";
import "../contracts/GratieEscrow.sol";
import "../contracts/BusinessNFTs.sol";

contract GratieEscrowTest is Test {
    GratieEscrow public gratieEscrow;
    USDCMock public usdcContract;
    BusinessNFT public businessNft;

    function setUp() public {
        businessNft = new BusinessNFT();
        gratieEscrow = new GratieEscrow(address(businessNft));
        usdcContract = new USDCMock(address(111), 1_000_000);

        businessNft.initialize("Business NFT", "BNFT");

        console.log("BusinessNFT Address: ", address(businessNft));
        console.log("Escrow Address: ", address(gratieEscrow));
        console.log("UsdcMock Address: ", address(usdcContract));
        console.log(
            "USDC Balance (111): ",
            usdcContract.balanceOf(address(111))
        );
    }

    function testCannotCreateQuest() public {
        uint256 _noOfParticpants = 10;
        uint256 _allocationPerUser = 1 ether;

        startHoax(address(1));
        vm.expectRevert("Not A Business NFT Holder");
        gratieEscrow.createQuest(
            _noOfParticpants,
            _allocationPerUser,
            address(usdcContract)
        );

        vm.stopPrank();
    }

    function testCanCreateQuest() public {
        uint256 _noOfParticpants = 10;
        uint256 _allocationPerUser = 10;
        uint256 _totalRewardAmount = _noOfParticpants * _allocationPerUser;

        businessNft.mint(address(111), 1, "ipfs://something");

        startHoax(address(111));

        usdcContract.approve(address(gratieEscrow), _totalRewardAmount);
        gratieEscrow.createQuest(
            _noOfParticpants,
            _allocationPerUser,
            address(usdcContract)
        );

        vm.stopPrank();
    }

    function testCanAirdropTokens() public {
        testCanCreateQuest();
        address[] memory recievers = new address[](1);
        recievers[0] = address(1);

        startHoax(address(111));
        gratieEscrow.airdropRewards(recievers, address(usdcContract));
        vm.stopPrank();

        assertTrue(usdcContract.balanceOf(address(1)) == 10);
    }

    function testCanGetExistingBalance() public {
        testCanAirdropTokens();
        uint256 businessRewardBalance = gratieEscrow.getExistingBalance(
            address(111),
            address(usdcContract)
        );

        assertTrue(businessRewardBalance == 90);
    }
}
