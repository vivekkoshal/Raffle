//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import{Script , console} from "forge-std/Script.sol";
import{HelperConfig} from "script/HelperConfig.s.sol";
import{VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import{LinkToken} from "test/mocks/Linktoken.sol";
import{DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol"; //this is used to get the most recently deployed contact address


contract CreateSubscription is Script{


    function createSubscriptionUsingConfig() public returns (uint64){
        // if want to create a subscription we need the vrfCoordinator address
        HelperConfig helperConfig = new HelperConfig();
        ( , ,address vrfCoordinator,,,,) = helperConfig.activeNetworkConfig();
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
    //we need the vrfCoordinator address subId and Link tooken so we will create it in Helperconfig.s.sol
    ( , ,address vrfCoordinator,,uint64 subId,,address link) = helperConfig.activeNetworkConfig();

    //this will do the actuall funding
    fundSubcription(vrfCoordinator,subId , link);    
    }

    function fundSubcription(address vrfCoordinator, uint64 subId, address link) public { 
        console.log("funding subscription :" , subId);
        console.log("using vrfCoordinaator:" , vrfCoordinator);
        console.log("on chainId:" , block.chainid);

        if(block.chainid == 31337){ //we are on anvil chain
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT );
        vm.stopBroadcast();
        }else{            //on real chain
        vm.startBroadcast();
        LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT , abi.encode(subId));
        vm.stopBroadcast();
        }


    }


    function run() external{
        return FundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script{

    function addConsumerUsingConfig(address raffle) public{
        HelperConfig helperConfig = new HelperConfig();

     ( , ,address vrfCoordinator,,uint64 subId,,) = helperConfig.activeNetworkConfig();
        addConsumer(raffle , vrfCoordinator, subId);
    }

    function addConsumer(address raffle, address vrfCoordinator, uint64 subId) public{
        console.log("adding consumer contract:" , raffle);
        console.log("using vrfCoordinaator:" , vrfCoordinator);
        console.log("on chainId:" , block.chainid);
        vm.startBroadcast();
        //this add consumer is defines in VRFCoordinatorV2Mock 
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    function run() external{   //for this we need the most latest broadcast as the consumer
    address RecentRaffle = DevOpsTools.get_most_recent_deployment("Raffle" , block.chainid); // this is got the address of most reacently deployed fund_me contract
        addConsumerUsingConfig(RecentRaffle);
    }
    
}
