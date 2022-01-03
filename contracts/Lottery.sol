pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract Lottery{
    using SafeMathChainlink for uint256;
    AggregatorV3Interface internal ethUsdPriceFeed;

    uint usdEntryFee;

    constructor(address _ethUsdPriceFeed) public {
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        usdEntryFee = 50;
    }

    function enter() payable{
        require(msg.value >= getEntranceFee());
    }

    function getEntranceFee public view returns(uint){
        uint ethUsdPrice = getLatestEthUsdPrice();
        // uint weiEntryFee = (usdEntryFee* 10**18) / (10**8 *ethUsdPrice);
        uint weiEntryFee = (usdEntryFee* 10**10) / *ethUsdPrice;
        return weiEntryFee;
    }

    function getLatestEthUsdPrice public view returns(uint){
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = ethUsdPriceFeed.latestRoundData();
        return uint(price);
    }

    // function startLottery() public {

    // }
    // function stopLottery() public {

    // }

    // function pickWinner() public {

    // }
}