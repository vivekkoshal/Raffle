//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.18;

import{Raffle} from "../../src/Raffle.sol";
import{DeployRaffle} from "../../script/DeployRaffle.s.sol";
import{HelperConfig} from "../../script/HelperConfig.s.sol";
import{Test,console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";  //Is a special data type in foundary used to store recoded logs
import{VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

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
    address Link;

    //Events
    event EnteredRaffle(address indexed player);  //we have to redefine them as they not types like enum or struct



    function setUp() external {

        DeployRaffle deployer = new DeployRaffle();
        (raffle , helperConfig) = deployer.run();

        ( enteranceFee, interval,vrfCoordinator,gaslane,subscriptionId,callBackGasLimit ,Link) = helperConfig.activeNetworkConfig();
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

    //checkupkeep//

    function testCheckUpkeepReturnsFalseIfIthasnoBalance() public  {
        //we will make all the parameter true except the balance so test it
        //arrange
        vm.warp(block.timestamp+interval+1);  //make timepassed variable true
        vm.roll(block.number+1);  

        //act
        (bool upkeepNeeded, )= raffle.checkUpkeep("");

        //assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public  {
        //arrange
        vm.prank(PLAYERS);
        raffle.EnterRaffle{value: enteranceFee}();
        vm.warp(block.timestamp+interval+1);  //make timepassed variable true
        vm.roll(block.number+1);
        raffle.performUpkeep("");      //this will set the raffle state to calculatind state

        //act
        (bool upkeepNeeded, )= raffle.checkUpkeep("");

        //assert
        assert(!upkeepNeeded);
    }

    //testCheckUpkeepReturnsFalseIfEnoughTimrHasn'tpassed
    function testCheckUpkeepReturnsFalseIfEnoughTimrHasnotpassed()  public{
        //arrange
        vm.prank(PLAYERS);
        raffle.EnterRaffle{value: enteranceFee}();

       //act
        (bool upkeepNeeded, )= raffle.checkUpkeep("");

        //assert
        assert(!upkeepNeeded);
    }

    //testCheckUpkeepReturnsTrueWhenparametersaregood
    function testCheckUpkeepReturnsTrueWhenparametersaregood()  public{
        //arrange
        vm.prank(PLAYERS);
        raffle.EnterRaffle{value: enteranceFee}();
        vm.warp(block.timestamp+interval+1);  //make timepassed variable true
        vm.roll(block.number+1);

        //act
        (bool upkeepNeeded, )= raffle.checkUpkeep("");

        //assert
        assert(upkeepNeeded);
    }




    //performUpkeep//

    function testperformUpKeepCanOnlyRunifCheckUpkeepIsTrue() public {
        //arrange
        vm.prank(PLAYERS);
        raffle.EnterRaffle{value: enteranceFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);  //this line is of no use
        
        //act /assert
        raffle.performUpkeep(""); //if this transiction not revert the test is to be considered as passed
          
    }

    function testperformUpKeepRevertsifCheckUpkeepIsFalse() public {
        //arrange

        //here the rervet error msg needs parameter so will provide it
        uint256 currentBalance = 0;
        uint256 numPlayers =0 ;
        uint256 raffleState = 0;

        //act /assert
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector , currentBalance , numPlayers , raffleState));    //this is code when we want to revert with an error message with parameters
        raffle.performUpkeep("");
        //here enough time is not passed so it will obviously revert
    }


    modifier RaffleEnteredAndTimePassed{
        vm.prank(PLAYERS);
        raffle.EnterRaffle{value: enteranceFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);
        _;
    }
    //how we can get output of events(normally i nsmart contract we can never get the value the event emited but in test we can)
    //it is important to test events because the chain link node litsens the events 

    function testPerformUpkeepUpdatesRaffleStateandEmitsRequestId() public RaffleEnteredAndTimePassed{
        //arrange -done in modifier

        //act
        //capture the emited request id in events
        vm.recordLogs();  //recodes all the emitted events happed after this statement and to acces them use getRecordedLogs
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();   //Vm.log[] is a special data type in foundary used to store recoded logs
        bytes32 requestid = entries[1].topics[1]   ;        //we are have emited requesst id twice once in vrfcoordinator(automaticaly at index 0) once manually in our raffle contract here we used manually emited value at index 1        //all logs are bytes32 and the 
        //the oth topic refers to the entire event and 1st topic refer to requestt id

        Raffle.RaffleState rstate = raffle.getRaffleState();
        //assert
        assert(uint256(requestid) >0);  //by this we make sure that rquest id was generated
        assert(uint256(rstate) == 1);
    }


    //fullfilllRandomWords//

    function testFulfilRandomWordsCanOnlyRunIfPerformUpkeepIsTrue(uint256 RandomRequestId) public RaffleEnteredAndTimePassed {
        //arrange
        //we will try that mock call fulfill random words and it fails
        vm.expectRevert("nonexistent request");

        //fuzz test-> by defing uint256 RandomRequestId in the fuction parameter it will test on (256) random values of it
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(RandomRequestId , address(raffle)); //here we are pretending to be vrfcordinator as fullfil random words(as only chain link node can call it) can be called by anybody() //(uint256 _requestId, address _consumer) these are the input parameters
    }


    function testFulfillRandomWordPicksWinneerResetsAndSendMoney() public RaffleEnteredAndTimePassed{
        //arrange
        uint256 additionalEntrants = 3;
        uint256 startingIndex =1 ;
        for(uint256 i = startingIndex; i < startingIndex+additionalEntrants; i++){
            address Player = address(uint160(i));  //type casted the uint to address
            hoax(Player , STARTING_USER_BALANCE);  //hoax is equivalent to prank + deal;
            raffle.EnterRaffle{value: enteranceFee}();
        }
        uint256 startingTimeStamp = raffle.getLastTimeStamp();

        //act
        //NOW NEED TO pretend to be chain linkvrf to get random number and pick winnner
        vm.recordLogs();  //recodes all the emitted events happed after this statement and to acces them use getRecordedLogs
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();   //Vm.log[] is a special data type in foundary used to store recoded logs
        bytes32 requestid = entries[1].topics[1]   ;   //vm.log stoer everthing as bytes32

        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(uint256(requestid) , address(raffle)); //here we are pretending to be vrfcordinator as fullfil random words(as only chain link node can call it) can be called by anybody() //(uint256 _requestId, address _consumer) these are the input parameters

        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = enteranceFee*(additionalEntrants+1);

        //arrange
        assert(uint256(raffle.getRaffleState()) == 0); //as we reseted this to open
        assert(raffle.getRecentWinner() != address(0)); //as  it can never be zero because winner is (a random address + 1+2+3 )
        assert(raffle.getLengthOfplayers() == 0);   //as we reseted this palyers arary to zero
       assert(endingTimeStamp > startingTimeStamp);   //as we reseted this to open
        // console.log("hi look at me");     //just for debugging
        // console.log(raffle.getRecentWinner().balance);
        // console.log(STARTING_USER_BALANCE+prize- enteranceFee);
        assert(raffle.getRecentWinner().balance == STARTING_USER_BALANCE+prize-enteranceFee);

    }

    

}
