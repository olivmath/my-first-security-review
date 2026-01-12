// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenSale {
    mapping(address => uint256) public balances;
    mapping(address => bool) public whitelist;
    address public owner;
    uint256 public tokenPrice = 1 ether;
    uint256 public totalSupply;
    bool public saleActive = true;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function addToWhitelist(address _user) external {
        whitelist[_user] = true;
    }

    function buyTokens(uint256 _amount) external payable {
        require(saleActive, "Sale not active");
        require(whitelist[msg.sender], "Not whitelisted");
        require(msg.value == _amount * tokenPrice, "Wrong ETH amount");

        balances[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function transfer(address _to, uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success);
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        tokenPrice = _newPrice;
    }

    function emergencyPause() external {
        saleActive = false;
    }

    function refund(uint256 _tokens) external {
        uint256 refundAmount = _tokens * tokenPrice;
        balances[msg.sender] -= _tokens;
        totalSupply -= _tokens;
        payable(msg.sender).transfer(refundAmount);
    }
}
