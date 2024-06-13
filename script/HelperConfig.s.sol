//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.18;

import{Raffle} from "../src/Raffle.sol";
import{Script} from "forge-std/Script.sol";
import{VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import{LinkToken} from "test/mocks/Linktoken.sol";

//this basically works as a constructor when we deploy our raffle contract to any chain it will provide all the data needed
contract HelperConfig is Script{

    struct NetworkConfig {
        uint256 enteranceFee; 
        uint256 interval;
        address vrfCoordinator;
        bytes32 gaslane;
        uint64 subscriptionId;
        uint32 callBackGasLimit;
        address Link;
    }

    NetworkConfig public activeNetworkConfig;

     uint256 i_enteranceFee= activeNetworkConfig.enteranceFee;
    constructor(){
        if (block.chainid == 11155111) {
         activeNetworkConfig =  getSepoliaEthConfig();
        }
        else{
        activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }




    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({enteranceFee: 0.01 ether , interval: 30 , vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625 , gaslane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c /**Key hash */ , subscriptionId: 0 /**will update this with our subID */, callBackGasLimit: 500000 , Link: 0x404460C6A5EdE2D891e8297795264fDe62ADBB75 });

    }


    //here we will create/Mock everthing using MockV3aggrigator
    function getOrCreateAnvilConfig() public  returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }


        //VRFCoordinataorV2Mock constructor has 2 parameters
        uint96 baseFee = 0.25 ether; //0.25 LINK 
        uint96 gasPriceLink = 1e9; //1 gwei LINK //above the base fee this is to paid initially the node pay this and it gets refunded by the gas we pays
 

        // to link token we have imported an linktoken.sol from patrick
        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        return NetworkConfig({enteranceFee: 0.01 ether , interval: 30 , vrfCoordinator: address(vrfCoordinatorMock) /**Main differnce */, gaslane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c /**Key hash - does not matter here*/ , subscriptionId: 0 /**our scipt will add this */, callBackGasLimit: 500000 , Link: address(link)});

    }





}