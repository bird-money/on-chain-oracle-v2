pragma solidity 0.6.12;

// © 2020 Bird Money
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Unlockable.sol";

/// @title Oracle service to find rating of any ethereum address
/// @author Bird Money
/// @notice Bird On-chain Oracle to confirm rating with consensus before update using the off-chain API
/// @dev for details https://www.bird.money/docs
contract BirdOracle is Unlockable {
    using SafeMath for uint256;
    /**
     * @dev Bird Standard API Request
     * id: "1"
     * ethAddress: address(0xcF01971DB0CAB2CBeE4A8C21BB7638aC1FA1c38c)
     * key: "bird_rating"
     * value: 400000000000000000   // 4.0
     * resolved: true / false
     * votesOf: 000000010000=> 2  (specific answer => number of votes of that answer)
     * statusOf: 0xcf021.. => VOTED
     */

    struct BirdRequest {
        uint256 id;
        address ethAddress;
        string key;
        uint256 value;
        bool resolved;
        mapping(uint256 => uint256) votesOf; //specific answer => number of votes of that answer
        mapping(address => uint256) statusOf; //offchain data provider address => VOTED or NOT
    }

    /// @notice keep track of list of on-chain requestes
    BirdRequest[] public onChainRequests;

    /// @notice minimum votes on an answer before confirmation
    uint256 public minConsensus = 2;

    /// @notice birds in nest count i.e total trusted providers
    uint256 public birdNest = 0;

    /// @notice current request id
    uint256 public trackId = 0;

    /// @notice all offchain oracle nodes i.e trusted and may be some are not trusted
    address[] public providers;

    /// @notice offchain data provider address => TRUSTED or NOT
    mapping(address => uint256) public statusOf;

    /// @notice offchain data provider address => (onPortion => no of answers) casted
    mapping(address => mapping(uint256 => uint256)) public answersGivenBy;

    /// @notice offchain data provider answers, onPortion => total no of answers
    mapping(uint256 => uint256) public totalAnswersGiven;

    /// @notice rewards of each provider
    mapping(address => uint256) public rewardOf;

    /// @notice status of providers with respect to all requests
    uint8 public constant NOT_TRUSTED = 0;
    uint8 public constant TRUSTED = 1;
    uint8 public constant WAS_TRUSTED = 2;

    /// @notice status of with respect to individual request
    uint8 public constant NOT_VOTED = 0;
    uint8 public constant VOTED = 2;

    mapping(address => uint256) private ratingOf; //saved ratings of eth addresses after consensus

    uint256 private onPortion = 1; // portion means portions of answers or group of answers, portion id from 0,1,2,.. to n

    /// @notice the token in which the reward is given
    IERC20 public rewardToken;

    /// @notice  Bird Standard API Request Off-Chain-Request from outside the blockchain
    event OffChainRequest(uint256 id, address ethAddress, string key);

    /// @notice  To call when there is consensus on final result
    event UpdatedRequest(
        uint256 id,
        address ethAddress,
        string key,
        uint256 value
    );

    /// @notice when an off-chain data provider is added
    event ProviderAdded(address provider);

    /// @notice when an off-chain data provider is removed
    event ProviderRemoved(address provider);

    /// @notice When min consensus value changes
    /// @param minConsensus minimum number of votes required to accept an answer from offchain data providers
    event MinConsensusChanged(uint256 minConsensus);

    constructor(address _rewardTokenAddr) public {
        rewardToken = IERC20(_rewardTokenAddr);
    }

    /// @notice add any address as off-chain data provider to trusted providers list
    /// @param _provider the address which is added
    function addProvider(address _provider) external onlyOwner {
        require(statusOf[_provider] != TRUSTED, "Provider is already added.");

        if (statusOf[_provider] == NOT_TRUSTED) providers.push(_provider);
        statusOf[_provider] = TRUSTED;
        ++birdNest;

        emit ProviderAdded(_provider);
    }

    /// @notice remove any address as off-chain data provider from trusted providers list
    /// @param _provider the address which is removed
    function removeProvider(address _provider) external onlyOwner {
        require(statusOf[_provider] == TRUSTED, "Provider is already removed.");

        statusOf[_provider] = WAS_TRUSTED;
        --birdNest;

        emit ProviderRemoved(_provider);
    }

    /// @notice Bird Standard API Request Off-Chain-Request from outside the blockchain
    /// @param _ethAddress the address which rating is required to read from offchain
    /// @param _key its tells offchain data providers from any specific attributes
    function newChainRequest(address _ethAddress, string memory _key) external {
        require(bytes(_key).length > 0, "String with 0 length no allowed");

        onChainRequests.push(
            BirdRequest({
                id: trackId,
                ethAddress: _ethAddress,
                key: _key,
                value: 0, // if resolved is true then read value
                resolved: false // if resolved is false then value do not matter
            })
        );

        //Off-Chain event trigger
        emit OffChainRequest(trackId, _ethAddress, _key);

        //update total number of requests
        trackId++;
    }

    /// @notice called by the Off-Chain oracle to record its answer
    /// @param _id the request id
    /// @param _response the answer to query of this request id
    function updatedChainRequest(uint256 _id, uint256 _response) external {
        BirdRequest storage req = onChainRequests[_id];
        address sender = msg.sender;

        require(
            !req.resolved,
            "Error: Consensus is complete so you can not vote."
        );

        require(
            statusOf[sender] == TRUSTED,
            "Error: You are not allowed to vote."
        );

        require(
            req.statusOf[sender] == NOT_VOTED,
            "Error: You have already voted."
        );

        answersGivenBy[sender][onPortion]++;
        totalAnswersGiven[onPortion]++;

        req.statusOf[sender] = VOTED;
        uint256 thisAnswerVotes = ++req.votesOf[_response];

        if (thisAnswerVotes >= minConsensus) {
            req.resolved = true;
            req.value = _response;
            ratingOf[req.ethAddress] = _response;
            emit UpdatedRequest(req.id, req.ethAddress, req.key, req.value);
        }
    }

    /// @notice get rating of any address
    /// @param _ethAddress the address which rating is required to read from offchain
    /// @return the required rating of any ethAddress
    function getRatingByAddress(address _ethAddress)
        external
        view
        returns (uint256)
    {
        return ratingOf[_ethAddress];
    }

    /// @notice get rating of caller address
    /// @return the required rating of caller
    function getRatingOfCaller() external view returns (uint256) {
        return ratingOf[msg.sender];
    }

    /// @notice get rating of trusted providers to show on ui
    /// @return the trusted providers list
    function getProviders() external view returns (address[] memory) {
        address[] memory trustedProviders = new address[](birdNest);
        uint256 t_i = 0;
        uint256 totalProviders = providers.length;
        for (uint256 i = 0; i < totalProviders; i++) {
            if (statusOf[providers[i]] == TRUSTED) {
                trustedProviders[t_i] = providers[i];
                t_i++;
            }
        }
        return trustedProviders;
    }

    /// @notice owner can set reward token according to the needs
    /// @param _minConsensus minimum number of votes required to accept an answer from offchain data providers
    function setMinConsensus(uint256 _minConsensus) external onlyOwner {
        minConsensus = _minConsensus;
        emit MinConsensusChanged(_minConsensus);
    }

    /// @notice owner can reward providers with USDT or any ERC20 token
    /// @param _totalSentReward the amount of tokens to be equally distributed to all trusted providers
    function rewardProviders(uint256 _totalSentReward) external onlyOwner {
        // handle 0 id and later etc.
        rewards[onPortion] = _totalSentReward;
        onPortion++;
        rewardToken.transferFrom(owner(), address(this), _totalSentReward);
    }

    mapping(address => uint256) private lastRewardPortionOf;

    /// @notice stores the list of rewards given by owner
    /// @dev answers are divided in portions, (uint256 => uint256) means (answersPortionId => ownerAddedRewardForThisPortion)
    mapping(uint256 => uint256) public rewards;

    /// @notice any node provider can call this method to withdraw his reward
    /// @param _portions amount of reward blocks from which you want to get your reward
    function withdrawReward(uint256 _portions) public {
        address sender = msg.sender;
        uint256 lastRewardedPortion = lastRewardPortionOf[sender];
        uint256 toRewardPortion = lastRewardedPortion + _portions;
        if (toRewardPortion > onPortion) toRewardPortion = onPortion;
        lastRewardPortionOf[sender] = toRewardPortion;
        uint256 accReward = getAccReward(lastRewardedPortion, toRewardPortion);
        rewardToken.transfer(sender, accReward);
    }

    /// @notice any node provider can call this method to withdraw his reward
    /// @param _portions amount of reward blocks from which you want to get your reward
    function seeReward(uint256 _portions) public view returns (uint256) {
        address sender = msg.sender;
        uint256 lastRewardedPortion = lastRewardPortionOf[sender];
        uint256 toRewardPortion = lastRewardedPortion + _portions;
        if (toRewardPortion > onPortion) toRewardPortion = onPortion;
        return getAccReward(lastRewardedPortion, toRewardPortion);
    }

    function getAccReward(uint256 lastRewardedPortion, uint256 toRewardPortion)
        private
        view
        returns (uint256)
    {
        address sender = msg.sender;
        uint256 accReward = 0;
        for (
            uint256 onThisPortion = lastRewardedPortion;
            onThisPortion < toRewardPortion;
            onThisPortion++
        ) {
            if (totalAnswersGiven[onThisPortion] > 0)
                accReward += rewards[onThisPortion]
                    .mul(answersGivenBy[sender][onThisPortion])
                    .div(totalAnswersGiven[onThisPortion]);
        }

        return accReward;
    }

    /// @notice owner calls this function to see how much reward should he give to node providers
    function getTotalAnswersGivenAfterReward() public view returns (uint256) {
        return totalAnswersGiven[onPortion];
    }
}
