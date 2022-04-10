//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract OwaneFarm is ChainlinkClient, Ownable 
{
    string public name = "CurlIn Defi";
    IERC20 public owaneToken;

    address[] public stakers;
    address[] public allowedTokens;

    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;

    constructor(address _owaneTokenAddress) public 
    {
        owaneToken = IERC20(_owaneTokenAddress);
    }

    // Stake Owane Tokens
    function stakeTokens(uint256 _amount, address _token) public 
    {
        require(_amount > 0, "Amount cannot be 0");
        require(tokenIsAllowed(_token), "Token is not allowed");
        updateUniqueTokensStaked(msg.sender, _token);
        IERC20(_token).transferFrom(msg.sender, address(this), _amount); // Tranfer Owane Token from msg.sender to staking protocol
        stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender] + _amount;
        if(uniqueTokensStaked[msg.sender] == 1) 
        {
        stakers.push(msg.sender);
        }
    }
    //Unstake Owane Tokens (Withdraw)
    function unstakeTokens(address _token) public 
    {
        // Fetch staked balance
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "staked balance cannot be zero");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] =0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] -1;
    }
    // Permission to interact with ERC20 contract
    function tokenIsAllowed(address _token) public view returns (bool) 
    {
        for 
        (
        uint256 allowedTokensIndex = 0;
        allowedTokensIndex < allowedTokens.length;
        allowedTokensIndex++
        )
        {
        if(allowedTokens[allowedTokensIndex] == _token) 
        {
            return true;
        }
        }
        return false;
    }
    // Initial allowed Owane Tokens
    function addAllowedTokens(address _token) public onlyOwner 
    {
        allowedTokens.push(_token);
    }
    // Call to DONs for valid pric feed
    function setPriceFeedContract(address _token, address priceFeed) public onlyOwner 
    {
        tokenPriceFeedMapping[_token] = priceFeed;
    }
    // Owane Token value in Ether
    function getTokenEthPrice(address _token) public view returns (uint256, uint8) 
    {
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface
        (
            priceFeedAddress
        );
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return (uint256(price), priceFeed.decimals());
    }
    // Owane Token value from msg.sender
    function getUserTotalValue(address _user) public view returns (uint256) 
    {
        uint256 totalValue = 0;
        if (uniqueTokensStaked[_user] > 0) 
        {
            for 
            (
                uint256 allowedTokensIndex = 0;
                allowedTokensIndex < allowedTokens.length;
                allowedTokensIndex++
            )
            {
                totalValue = totalValue + getUserTokenStakingBalanceEthValue(_user, allowedTokens[allowedTokensIndex]);
            }
        }
        return totalValue;
    }
    // Owane Token staked value in Ether
    function getUserTokenStakingBalanceEthValue(address _token, address _user) public view returns (uint256) 
    {
        if (uniqueTokensStaked[_user] <= 0) 
        {
            return 0;
        } 
        (uint256 price, uint8 decimals) = getTokenEthPrice(_token);
        return (stakingBalance[_token][_user] * price) / (10**uint256(decimals));
    }
    // Allocation of Owane Tokens
    function issueTokens() public onlyOwner 
    {
        for 
        (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex ++
        )
        {
            address recipient = stakers[stakersIndex];
            owaneToken.transfer(recipient, getUserTotalValue(recipient));
        }
    }
    // Update
    function updateUniqueTokensStaked(address _token, address _user) internal 
    {
        if (stakingBalance[_token][_user] <= 0) 
        {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] +1;
        }
    }
}