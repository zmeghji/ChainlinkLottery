pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable{
    using SafeMathChainlink for uint256;
    AggregatorV3Interface internal ethUsdPriceFeed;

    enum LOTTERY_STATE {OPEN, CLOSED, CALCULATING_WINNER}

    LOTTERY_STATE public lotteryState ;
    uint usdEntryFee;
    address payable[] players;
    uint public linkFee;
    bytes32 public keyHash;
    address lastWinner;

    event RequestedRandomness(bytes32 id);
    constructor(address _ethUsdPriceFeed, address _vrfCoordinator, 
        address _link, bytes32 _keyHash) public 
        VRFConsumerBase(
            _vrfCoordinator, // VRF Coordinator
            _link  // LINK Token
        )
    {
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        usdEntryFee = 50;
        lotteryState = LOTTERY_STATE.CLOSED;
        linkFee = 10**17; //0.1 LINK;
        keyHash = _keyHash;
    }

    function enter() payable public {
        require(msg.value >= getEntranceFee());
        require(lotteryState ==LOTTERY_STATE.OPEN);

        players.push(msg.sender);
    }

    function getEntranceFee() public view returns(uint){
        uint ethUsdPrice = getLatestEthUsdPrice();
        // uint weiEntryFee = (usdEntryFee* 10**18) / (10**8 *ethUsdPrice);
        uint weiEntryFee = (usdEntryFee* 10**10) / ethUsdPrice;
        return weiEntryFee;
    }

    function getLatestEthUsdPrice() public view returns(uint){
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = ethUsdPriceFeed.latestRoundData();
        return uint(price);
    }

    function startLottery() public onlyOwner{
        require(lotteryState == LOTTERY_STATE.CLOSED, "Cannot start a lottery which is already open");
        lotteryState = LOTTERY_STATE.OPEN;
    }
    function endLottery() public onlyOwner{
        require(lotteryState == LOTTERY_STATE.OPEN, 
            "Cannot end a lottery which has already ended");
        lotteryState = LOTTERY_STATE.CALCULATING_WINNER;
        pickWinner();
    }

    function pickWinner() private returns(bytes32) {
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER, 
            "must be in calculating_winner state");
        bytes32 requestId = requestRandomness(keyHash, linkFee);
        emit RequestedRandomness(requestId);
        return requestId;
    }
    function fulfillRandomness(bytes32 /* requestId */, uint256 randomness) internal override {
        require(randomness >0, "random number not found");
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER, 
            "must be in calculating_winner state");

        lotteryState = LOTTERY_STATE.CLOSED;
        uint index = randomness% players.length;
        lastWinner = players[index];

        players[index].transfer(address(this).balance);
        delete players;

    }

}