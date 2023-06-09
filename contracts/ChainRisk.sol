// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract newNFT is ChainlinkClient, ConfirmedOwner, ERC721URIStorage {

    // NFT -------------------------------------------------------

    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    string public ipfsBaseUrl = "ipfs://";
    string public _tokenURI;
    mapping (address => uint) private userLinkBalances;
    mapping (address => string) private userAPI;
    mapping (address => uint[]) private userNFTs;

    event Minted(address indexed to, string indexed tokenURI);

    // Chainlink -------------------------------------------------------

    using Chainlink for Chainlink.Request;

    string private rating;
    bytes32 private jobId;
    uint256 public fee; // Changed from a private to a public variable
    mapping( address => string ) public ratings;
    address public addressRequesting;

    event RequestRating(bytes32 indexed requestId, string rating);

    /**
     * @notice Initialize the link token and target oracle
     *
     * Mumbai Testnet details:
     * Link Token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Oracle: 0x40193c8518BB267228Fc409a613bDbD8eC5a97b3 (Chainlink DevRel)
     * jobId: 7d80a6386ef543a3abb52817f6707e3b (string)
     *
     */
    constructor(string memory _name, string memory _symbol) ConfirmedOwner(msg.sender) ERC721(_name, _symbol) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0x40193c8518BB267228Fc409a613bDbD8eC5a97b3);
        jobId = "7d80a6386ef543a3abb52817f6707e3b";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }

    /*-------------------------------------------------------------------------------------*/
    // Chainlink

    function getOracle() public view returns (address) {
        return chainlinkOracleAddress();
    }

    function getToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function requestRatingData() public returns (bytes32 requestId) {

        // Checks for LINK greater than fee
        require(userLinkBalances[msg.sender] >= fee, "Not enough LINK has been provided");
        userLinkBalances[msg.sender] -= fee;

        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        // Convert msg.sender to string
        string memory senderString = addressToString(msg.sender);
        addressRequesting = msg.sender;

        // Set the URL to perform the GET request on, including the msg.sender address
        string memory url = string(abi.encodePacked("https://chainlink-387612.uc.r.appspot.com/image?address=", senderString));

        // Get ipnft
        req.add("get", url);
        req.add("path", "ipnft");

        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    /**
     * Receive the response in the form of string
     */
    function fulfill(bytes32 _requestId, string memory _url) public recordChainlinkFulfillment(_requestId) {
        emit RequestRating(_requestId, _url);
        ratings[addressRequesting] = _url;
    }

    // Helper function to convert an address to a string
    function addressToString(address _address) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes20 value = bytes20(_address);
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i] & 0x0F)];
        }
        return string(str);
    }


    /*-------------------------------------------------------------------------------------*/
    // NFT

    // This function will need an API key as input as well
    function mintNFT(address _recipient)
        public
        returns (uint256)
    {
        // Checks user NFT balance
        require(balanceOf(msg.sender) < 1, "You have already minted an NFT");

        // Checks for a non empty response
        require(bytes(ratings[msg.sender]).length > 0, "The rating was not correctly fetched");

        string memory _tokenURI2 = string(abi.encodePacked(ipfsBaseUrl, ratings[msg.sender]));
        _tokenURI = string(abi.encodePacked(_tokenURI2, "/metadata.json"));

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(_recipient, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        userNFTs[msg.sender].push(newItemId);

        emit Minted(_recipient, _tokenURI);

        return newItemId;
    }

    function updateURI(uint _tokenId) public {
        // Checks if the caller is the owner of the NFT
        require(msg.sender == ownerOf(_tokenId), "You are not the owner of this NFT");

        // Checks if the ratings is null
        bytes32 _rating = keccak256(abi.encodePacked(ratings[msg.sender]));
        bytes32 _empty = keccak256(abi.encodePacked(""));
        require(_rating != _empty, "Your rating should not be null");

        // Checks if the ratings have changed
        string memory _newTokenURI = string(abi.encodePacked(ipfsBaseUrl, ratings[msg.sender]));
        _newTokenURI = string(abi.encodePacked(_newTokenURI, "/metadata.json"));
        bytes32 newTokenURIHash = keccak256(abi.encodePacked(_newTokenURI));
        bytes32 tokenURIHash = keccak256(abi.encodePacked(tokenURI(_tokenId)));
        require(tokenURIHash != newTokenURIHash, "Your rating is the same as previously");

        // Sets new token URI
        _setTokenURI(_tokenId, _newTokenURI);
    }

    function transferLink(uint amount) external {
        IERC20 linkToken = IERC20(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        bool success = linkToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Failed to transfer LINK tokens");
        userLinkBalances[msg.sender] += amount;
    }

    function withdrawLink(uint amount) external {
    require(userLinkBalances[msg.sender] >= amount, "Not enough LINK available to withdraw");
    IERC20 linkToken = IERC20(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    linkToken.transfer(msg.sender, amount);
    userLinkBalances[msg.sender] -= amount;
    }

    function getLinkBalance(address _address) public view returns (uint) {
        return userLinkBalances[_address];
    }

    function getRating() public view returns (string memory) {
        return ratings[msg.sender];
    }

    function getUserNFTS(address _address) public view returns(uint[] memory) {
        return userNFTs[_address];
    }
}