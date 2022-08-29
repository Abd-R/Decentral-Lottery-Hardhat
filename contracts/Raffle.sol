// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
// VRF verifying contract

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

error Raffle_upKeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 raffleState
);

error Raffle_NotEnoughEthEntered();
error Raffle_TransferFailed();
error Raffle_LotteryClosed();

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    // State Variables
    uint256 private immutable i_entranceFee;                    // i_ = immutable s_ = storage;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_interval;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint256 private s_lastTimeStamp;
    mapping(address => uint256) name;
    address payable[] private s_player;                         // one of these players will end up recieving eth, so payable;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

                                                                // Lottery Variables

    address private s_recentWinner;
    RaffleState private s_raffleState;

                                                                // Events
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        address vtfConsumerBaseV2,
        bytes32 keyHash,                                        // gas Lane
        uint64 subscriptionId,                                  // the id of our subscription
        uint32 callbackGasLimit,
        uint256 interval                                        // interval between lottery
    ) VRFConsumerBaseV2(vtfConsumerBaseV2) {
        i_subscriptionId = subscriptionId;
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vtfConsumerBaseV2);
        i_gasLane = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    function enterRaffle()
        public
        payable
                                                                // we will end up paying one of the address
    {
        if (msg.value < i_entranceFee) revert Raffle_NotEnoughEthEntered();
        if (s_raffleState != RaffleState.OPEN) revert Raffle_LotteryClosed();
        s_player.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);                           // name events with the reverse name of function
    }

    /**
     * this function is called by ChainLink keepers
     * to check if they need to perform upkeep or not
     *
     * it will work if
     * 1. Our Time Interval is up
     * 2. There is at least 1 player
     * 3. Subscription is funded with LINK
     * 4. The lottery is OPEN
     */

    function checkUpkeep(
        bytes memory /*checkdata*/                              // calldata(memory) specifies the input, bytes type mean even calling another func // overrides the keepers contract
    )
        public
        view
        override
        returns (
            bool upKeepNeeded,                                  // if the chain link keeper node needs to perform upKeep or not
            bytes memory                                        // perform data
        )
    {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_player.length > 0;
        bool hasBalance = address(this).balance > 0;
        upKeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
        return (upKeepNeeded, "0x0");
    }
                                                                // called by keeper
    function performUpkeep(
        bytes calldata /* performData */                        // over rides keepers' upKeep
    ) 
    public 
    override 
    {
        (bool upKeepNeeded, ) = checkUpkeep("");                // calldata is null
        if (!upKeepNeeded)
            revert Raffle_upKeepNotNeeded(
                address(this).balance,
                s_player.length,
                uint256(s_raffleState)
            );

        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(// Requested To a "Specific Oracle"
            i_gasLane,                                          // keyhash
            i_subscriptionId,                                   // id of our chainlink subscription
            REQUEST_CONFIRMATIONS,                              // blocks to wait
            i_callbackGasLimit,                                 // max gas to use, max computation to produce randomness
            NUM_WORDS                                           // total words requested
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(                                // Only "Requested" Oracle Can Call this. (check rawRandomFullFill)
        uint256, /*requestId*/                                  // not using requestID
        uint256[] memory randomWords                            // array of length NUM_WORDS. Contains Random Words 
                                                                // overrides the function of abstract class 
                                                                // will only be called internally, by VRFConsumerBaseV2
    ) 
    internal 
    override 
    {
        uint winnerIndex = randomWords[0] % s_player.length;
        address payable recentWinner = s_player[winnerIndex];
        bool success = recentWinner.send(address(this).balance);
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_player = new address payable[](0);                    // resetting our player arr.
        s_lastTimeStamp = block.timestamp;                      // updating the last timestamp
        if (!success) revert Raffle_TransferFailed();
        emit WinnerPicked(recentWinner);
    }

    function getEntranceFee() 
    public 
    view 
    returns 
    (uint256) 
    {
        return i_entranceFee;
    }

    function getPlayer
    (uint256 index) 
    public 
    view 
    returns 
    (address) 
    {
        return s_player[index];
    }

    function getRecentWinner() 
    public 
    view 
    returns 
    (address) 
    {
        return s_recentWinner;
    }

    function getRaffleState() 
    public 
    view 
    returns 
    (RaffleState) 
    {
        return s_raffleState;
    }

    function getNUM_WORDS()
    public
    pure                                                        // pure function is for getting constant variables
    returns 
    (uint256)
    {
                                                                // it is not view, as our contract does not need to view the storage
        return NUM_WORDS;                                       // because const var NUM word is part of  byte code
    }

    function getPlayers()  
    public
    view
    returns 
    (uint256) 
    {
        return s_player.length;
    }

    function getLatestTimeStamp()  
    public
    view
    returns 
    (uint256) 
    {
        return s_lastTimeStamp;
    }

    function getInterval()  
    public
    view
    returns 
    (uint256) 
    {
        return i_interval;
    }

}

// we want to deploy contract
// players take part
// player invest money to enter
// winner selected every x minute

// chainlink will take care of randomness, and event driven execution
// we will get off-chain info info from chain link oracle.
// we will use chain link keepers to EXECUTE the Winner Selection