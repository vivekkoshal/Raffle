//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
 
import{Script , console} from "forge-std/Script.sol";
import{Raffle} from "../src/Raffle.sol";
import{HelperConfig} from "../script/HelperConfig.s.sol";
import{CreateSubscription ,FundSubscription , AddConsumer} from "../script/Interactions.s.sol";

 
contract DeployRaffle is Script {

    function run() external returns (Raffle ,HelperConfig){  //by this we ca use both the functions in while writing the test just by using deploy.run() 

        HelperConfig helperConfig = new HelperConfig();
        ( uint256 enteranceFee, uint256 interval,address vrfCoordinator,bytes32 gaslane,uint64 subscriptionId,uint32 callBackGasLimit , address Link, uint256 deployerKey) = helperConfig.activeNetworkConfig();
       
       if(subscriptionId == 0){
        //we need to creat a subscription!
        CreateSubscription createSub = new CreateSubscription();
        subscriptionId = createSub.createSubscriptionUsingAddress(vrfCoordinator , deployerKey);     //here if subid is 0 we are modifing it
       
       //now we also have to fnd it with links
        FundSubscription fundSub = new FundSubscription();
        fundSub.fundSubcription(vrfCoordinator,subscriptionId,Link ,deployerKey);  //we are directly using this function not calling the run function as we already have those parameters
        //after the we have funded the subscription we will deploy our contract and add consumer to it
       }


       
        vm.startBroadcast();
        Raffle raffle = new Raffle( enteranceFee,interval,vrfCoordinator,gaslane, subscriptionId, callBackGasLimit);
        vm.stopBroadcast();


        AddConsumer addConsum = new AddConsumer();
        addConsum.addConsumer(address(raffle) , vrfCoordinator,subscriptionId , deployerKey );

        return (raffle, helperConfig);
    } 

 }
