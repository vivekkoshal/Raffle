//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.18;

import{Raffle} from "../../src/Raffle.sol";
import{DeployRaffle} from "../../script/DeployRaffle.s.sol";
import{HelperConfig} from "../../script/HelperConfig.s.sol";
import{Test,console} from "forge-std/Test.sol";

contract RaffleTest is Test {

    Raffle public raffle;
    HelperConfig public helperConfig;

    address PLAYERS = makeAddr("player") ; //this is a cheat code which will make a random addres(a fake user) by which we will make tansaction to make thigs easy
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    uint256 enteranceFee; 
    uint256 interval;
    address vrfCoordinator;
    bytes32 gaslane;
    uint64 subscriptionId;
    uint32 callBackGasLimit;

    //Events
    event EnteredRaffle(address indexed player);  //we have to redefine them as they not types like enum or struct



    function setUp() external {

        DeployRaffle deployer = new DeployRaffle();
        (raffle , helperConfig) = deployer.run();

        ( enteranceFee, interval,vrfCoordinator,gaslane,subscriptionId,callBackGasLimit) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYERS , STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public  view {
        assert(raffle.getRaffleState()==Raffle.RaffleState.Open);  //Raffle.RaffleState.Open->by this we get the enum state we declared in Raffle contract(in class not in object)
    }

    //////////////////////////
    //enter Raffal functions//
    /////////////////////////

    function testRaffalRevertWhennotGivenEnoughEth() public {
        //arrange
        vm.prank(PLAYERS);

        //act
        vm.expectRevert(Raffle.Raffle__NotSufficientAmount.selector); //we will revert with an error message
        raffle.EnterRaffle(); //herevalue is zero it should revert
    }

    function testRaffalRecordWhenTheyEnter() public {
        //arrange
        vm.prank(PLAYERS);
    
        raffle.EnterRaffle{value: enteranceFee}();

        //assert
        assert(raffle.getPlayers(0)== address(PLAYERS));
    }

    function testEmitsEventOnEnter() public {
        //arrange
        vm.prank(PLAYERS);
        vm.expectEmit(true , false , false , false , address(raffle)); //constrctor has five parameters-> 1.(topic 1 (indexed parameter)) 2.(topic 2) 3.(topic 3) 4.(call data(non indexed parameters)) 5.(address of the constract on which to emit)
        emit EnteredRaffle(PLAYERS);        //here we first emit overself and in the next line we are expacting this type of emit through transaction(function)

        raffle.EnterRaffle{value: enteranceFee}();  // here the emit will be done automatically we will be compared to the above line(where we emited manually)

    }

    function testCannotEnterRaffleWhenitisCalculating() public {
        vm.prank(PLAYERS);
        
        //for raffle to be calculating we need that all parapemeters of checkupkeep are true
        raffle.EnterRaffle{value: enteranceFee}();
        vm.warp(block.timestamp+interval+1);  //this will set the time of this block to interval+1 from the time block was created
        vm.roll(block.number+1);   //this is used to set the blocknumber of this block

        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);  //this will revert with an error message
        vm.prank(PLAYERS);
        raffle.EnterRaffle{value: enteranceFee}();
  
    }

}
