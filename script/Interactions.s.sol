//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import{Script , console} from "forge-std/Script.sol";
import{HelperConfig} from "script/HelperConfig.s.sol";
import{VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract CreateSubscription is Script{


    function createSubscriptionUsingConfig() public returns (uint64){
        // if want to create a subscription we need the vrfCoordinator address
        HelperConfig helperConfig = new HelperConfig();
        ( , ,address vrfCoordinator,,,) = helperConfig.activeNetworkConfig();
        return createSubscriptionUsingAddress(vrfCoordinator);
    }

    function createSubscriptionUsingAddress(address vrfCoordinator) public returns (uint64){
        console.log("creating subscription on ChainId:" , block.chainid);

        vm.startBroadcast();
        //we will broadcast a transaction/function (createSubscription) from the VRFCoordinatorV2Mock
        uint64 subID=VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();   //check the VRFCoordinatorV2Mock.sol once to understand(in real ui subscription also the same fuction is called when we check in hex of metamask)
        vm.stopBroadcast();
        console.log("Your Subscription ID:" , subID);
        console.log("please update subscription id in HelperConfig.s.sol");
        return subID;

    } 
    function run() external returns (uint64){
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script{
    uint96 public constant FUND_AMOUNT = 3 ether;

    function FundSubscriptionUsingConfig() public {
    HelperConfig helperConfig = new HelperConfig();
    ( , ,address vrfCoordinator,,uint64 subId,) = helperConfig.activeNetworkConfig();
    
    
    }


    function run() external{
        return FundSubscriptionUsingConfig();
    }


}