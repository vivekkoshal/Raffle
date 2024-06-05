//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
 
/**                    //this is a natspec to describe the contract in breif
*@title  A Raffle Contract
*@author Vivek 
*@notice This contract generates a sample Raffle contract
*@dev  Implement Chainlink VRFv2
*/

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions


import {VRFCoordinatorV2Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
    
    error Raffle__NotSufficientAmount();          //contractname__errorname ia good practice to identify the error in multiple code
    error Raffle__TransferFail();                  //if money cannot rach the sender
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance , uint256 numberOfPayers , uint256  RaffleState);

    //enums are used to creat coustom types with finite values
    enum RaffleState{Open /**0 */,Calculating_Winner  /**1 */}         //like bool can have two values true or fasle similarly raffle statte can also have only two values open or calculating;







    //satate variables

    uint256 private immutable i_enteranceFee;  //this is definesd when the contract is created and cannot be change
    address payable[] private s_players; //to keep track of players all the players who entered the raffle  //payable is used as at the end we have to pay them at the end
    uint256 private immutable i_interval;        //we want to auto pick the winner after a ceratin time after the contract is deployed  //@dev -> durration of lottery in seconds
    uint256 private s_lastTimeStamp;            //it is timestamp just at the time when we the contract is deployed (defined in constructor)
    VRFCoordinatorV2Interface private immutable i_vrfCOORDINATOR;  //it is different cahin to chain so we spacified it in the constructor
    bytes32 private immutable i_keyHash;         //it also varies cahin to cahin so defined in  constructor
    uint64 private immutable i_subscriptionId;  //it is our contract specific so defined in constructor
    uint16 private constant c_REQUEST_CONFIRMATIONS = 3; //number of confirmations we want to make to our function
    uint32 private immutable i_callBackGasLimit ; //gas limit for the callback function this is also contract specific
    uint32 private constant c_NUM_WORDS = 1;       //number of random numbers we want to get from the cahinlink VRFv2
    address private s_recentWinner;               //this is the address of the person who won the lastest raffle
    RaffleState private s_raffleState;           //this is the state of the raffle (Open or Calculating_Winner)


    //Events
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);


    constructor (uint256 enteranceFee , uint256 interval , address vrfCoordinator , bytes32 gaslane , uint64 subscriptionId , uint32 callBackGasLimit) VRFConsumerBaseV2() //as the interface also has inbulid constructor we can use it without defining the constructor for it
     payable {

        i_enteranceFee = enteranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;  //time when the contract is deployed
        i_vrfCOORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);  //type casted the adreess in this vrf interface
        i_keyHash = gaslane;
        i_subscriptionId = subscriptionId;
        i_callBackGasLimit = callBackGasLimit;
        s_raffleState = RaffleState.Open; //initally lottary is open to all
    }
    







    function EnterRaffle() external payable {                    //we use external when we do not use this function again in the contract(Public is used when we want to use this function in the contract) external is more gas efficient
        //require(msg.value >= i_enteranceFee, "Enterance fee not sufficient");   //Instead of require we will use coustum error as they are more gas efficient
        if(msg.value < i_enteranceFee){
            revert Raffle__NotSufficientAmount();
        }

        if(s_raffleState != RaffleState.Open){
            revert Raffle__RaffleNotOpen();
        }


        s_players.push(payable(msg.sender));     
        emit EnteredRaffle(msg.sender);    //events make migration easier //also make front enf indexing easier

    }


    //checkupkeep checks when the time is right to pick a winner (for cahinlink nodes to recognise this fuction we need input parameter but we don't need it so commented)
    /**
     *@dev this is the function that cahin link Automatation nodes call to see when the function is to be perfoemed (here the conditions are)
     * 1. the time interval has passed between raffle runs
     *2. the raffle is in open state
     * 3.the contract has ETH (i.e players)
     *4.(implicit) The subscription is funded with Link
     */
    function checkUpkeep(bytes calldata /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* performData */){   //her if we specify the variable name in the return it will automaticaly return that veriable valur without calling return statement
        bool timehasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen =   (RaffleState.Open == s_raffleState);
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = (s_players.length > 0);

        upkeepNeeded = timehasPassed && isOpen && hasBalance && hasPlayers;           //upkeepNeeded will only be true if all the above contidition are true
        return (upkeepNeeded, "0x0");   //0x0 is a waste thing(blank bytes object) no use of it
    }








   // function PickWinner() public { // name has to change to recgonisable by chain link node
      function performUpkeep(bytes calldata /* performData */) external{
        (bool upkeepneeded , ) = checkUpkeep("0x0");  //no need to pass checkData as we are not using it

        if(!upkeepneeded){
            revert Raffle__UpkeepNotNeeded(address(this).balance , s_players.length , uint256(s_raffleState)); // while reverting it will also give these info with the error
        }

        //Get a random number 
        //use the random number to pick the winner
        //must be automatically called

        //check if enough time has passed
        //this we have now implemented in the upkeep function
    //    if( block.timestamp - s_lastTimeStamp < i_interval){     //block.timestamp is a global variable which gives the current block time in seconds
    //     revert();
    //    }  

       s_raffleState = RaffleState.Calculating_Winner;     //so while we are waiting for the random number no one can enter the raffle

        //getting a ranndom number using chainlink VRFv2 its a two transtion process
        //1->request the RNG(random number generator)
        //2->get the random number

        //copied from the cahinlink doc ->https://docs.chain.link/vrf/v2/subscription/examples/get-a-random-number
        //we make a request and it will can a specific contract called vrfCoordinator dfined in VRFCoordinatorV2Interface(only chain link node can respond to this request) then that contract will can rawfullfil random words in VRFConsumerBaseV2 which we will define by overridding it
       uint256 requestId = i_vrfCOORDINATOR.requestRandomWords(       //chain link vrf coordinator address (every chain in which chainlink exsist(this adress is used to make call) has this value different)      //request random number is a function definded in cahil link interface
            i_keyHash,                         //gas lane (we can spacifify how much gas we want to spend)  //this is also dependent on the cahin
            i_subscriptionId,                //id we funded with link           //this is also our specific id so its also defined in constructor
            c_REQUEST_CONFIRMATIONS ,           //requestConfirmations,    //number of block confirmations for the random number // in this for example we want 3 confirmations  //the more the number is more time it takes
            i_callBackGasLimit,                //max gas limits for the callback function(on the second transaction to get the ramdom number we want to limit the gas it spends)
            c_NUM_WORDS                        //number of random numbers we want(here we only want one)
        );  //it will return with our random fulfillrandomwords function


    }

        //this fuction is to get back the random numbers taken from cahin link docs
    function fulfillRandomWords( uint256 _requestId, uint256[] memory _randomWords) internal override {   //if we overriding the function it must be spacified in an interface here (VRFConsumerBaseV2) as given in cahil link docs
        //we will use mod function to pick a random number
        //for example there are 10 player s_players =10
        //and our random number is = 19347189348015891346584;
        //we will modulo random number % s_players which will give the index of winner(reamder can be any number btw [0, s_players))
        // 19347189348015891346584%10 = 4 -> player at 4th index in the array is the winner
        
        uint256 indexOfWinner = _randomWords[0] % s_players.length;  //randaomWord array has only 1 number at index 0 as we only requested one
        address payable Winner = s_players[indexOfWinner];
        s_recentWinner = Winner;

        s_raffleState = RaffleState.Open; // after we get the winner raffal again gets open
        s_players = new address payable[](0); //clear the array so that privous players can't be part of new raffle
        s_lastTimeStamp = block.timestamp;  //to start the time for new lootry

        emit PickedWinner( address(Winner) );  //emit event to show that the winner has been picked and passed to the front end Picked(Winner);

        //send all the balance of this contract to the winner
        (bool success, ) = Winner.call{value : address(this).balance}("");
        if(!sucess){
            revert Raffle__TransferFail();
        }

       
    }










    //** Getter functions */

    function getEnteranceFee() external view returns(uint256){  
        return i_enteranceFee;
    }

}