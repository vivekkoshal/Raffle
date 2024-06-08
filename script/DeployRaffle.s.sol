//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
 
import{Script , console} from "forge-std/Script.sol";
import{Raffle} from "../src/Raffle.sol";
import{HelperConfig} from "../script/HelperConfig.s.sol";
import{CreateSubscription} from "../script/Interactions.s.sol";

 
contract DeployRaffle is Script {

    function run() external returns (Raffle ,HelperConfig){  //by this we ca use both the functions in while writing the test just by using deploy.run() 

        HelperConfig helperConfig = new HelperConfig();
        ( uint256 enteranceFee, uint256 interval,address vrfCoordinator,bytes32 gaslane,uint64 subscriptionId,uint32 callBackGasLimit) = helperConfig.activeNetworkConfig();
       
       if(subscriptionId == 0){
        //we need to creat a subscription!
        CreateSubscription createSub = new CreateSubscription();
        subscriptionId = createSub.createSubscriptionUsingAddress(vrfCoordinator);     //here if subid is 0 we are modifing it
       
       //now we also have to fnd it with links
       
       
       }


       
        vm.startBroadcast();
        Raffle raffle = new Raffle( enteranceFee,interval,vrfCoordinator,gaslane, subscriptionId, callBackGasLimit);
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }

 }
