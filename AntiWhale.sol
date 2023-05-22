// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AntiWhale BEP20 Token
 * @dev Implementation of the AntiWhale BEP20 token.
 * @author propaksitani (github.com/propaksitani)
 */
contract AntiWhale {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isExemptFromTax;

    uint256 private maxWalletLimit;
    uint256 private maxTransferAmount;

    uint256 private _taxPercentage;
    uint256 private constant _taxMultiplier = 10000;

    address private _deployer;
    address private _marketingWallet;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Initializes the AntiWhale token contract.
     * @param marketingWallet The address of the marketing wallet.
     */
    constructor(address marketingWallet) {
        name = "AntiWhale";
        symbol = "ANTW";
        totalSupply = 100000 * 10**10; // 10^10 decimals
        decimals = 10;

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);

        maxWalletLimit = totalSupply / 50; // 2% of total supply
        maxTransferAmount = totalSupply / 2000; // 0.05% of total supply

        isExemptFromTax[msg.sender] = true;
        _deployer = msg.sender;

        _taxPercentage = 500; // 5%

        _marketingWallet = marketingWallet;
    }

    /**
     * @dev Transfers tokens from the sender to the given recipient.
     * @param to The address to transfer tokens to.
     * @param value The amount of tokens to transfer.
     * @return A boolean value indicating whether the transfer was successful.
     */
    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid amount");

        if (isExemptFromTax[msg.sender] || msg.sender == _deployer) {
            require(balanceOf[msg.sender] >= value, "Insufficient balance");
            require(balanceOf[to] + value <= maxWalletLimit, "Exceeds maximum wallet limit");
            require(value <= maxTransferAmount, "Exceeds maximum transfer amount");

            balanceOf[msg.sender] -= value;
            balanceOf[to] += value;

            emit Transfer(msg.sender, to, value);
        } else {
            uint256 taxAmount = (value * _taxPercentage) / _taxMultiplier;
            uint256 transferAmount = value - taxAmount;

            require(balanceOf[msg.sender] >= value, "Insufficient balance");
            require(balanceOf[to] + transferAmount <= maxWalletLimit, "Exceeds maximum wallet limit");
            require(transferAmount <= maxTransferAmount, "Exceeds maximum transfer amount");

            balanceOf[msg.sender] -= value;
            balanceOf[to] += transferAmount;

            if (taxAmount > 0) {
                balanceOf[_marketingWallet] += taxAmount;
                emit Transfer(msg.sender, _marketingWallet, taxAmount);
            }

            emit Transfer(msg.sender, to, transferAmount);
        }

        return true;
    }

    /**
     * @dev Approves the given spender to spend tokens on behalf of the owner.
     * @param spender The address allowed to spend tokens.
     * @param value The amount of tokens to approve.
     * @return A boolean value indicating whether the approval was successful.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), "Invalid address");

        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfers tokens from the given sender to the given recipient.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param value The amount of tokens to transfer.
     * @return A boolean value indicating whether the transfer was successful.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(from != address(0), "Invalid address");
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid amount");
        require(value <= allowance[from][msg.sender], "Exceeds allowance");

        allowance[from][msg.sender] -= value;
        transferTokens(from, to, value);
        return true;
    }

    /**
     * @dev Internal function to transfer tokens from one address to another.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param value The amount of tokens to transfer.
     */
    function transferTokens(address from, address to, uint256 value) internal {
        if (isExemptFromTax[from] || from == _deployer) {
            require(balanceOf[from] >= value, "Insufficient balance");
            require(balanceOf[to] + value <= maxWalletLimit, "Exceeds maximum wallet limit");
            require(value <= maxTransferAmount, "Exceeds maximum transfer amount");

            balanceOf[from] -= value;
            balanceOf[to] += value;

            emit Transfer(from, to, value);
        } else {
            uint256 taxAmount = (value * _taxPercentage) / _taxMultiplier;
            uint256 transferAmount = value - taxAmount;

            require(balanceOf[from] >= value, "Insufficient balance");
            require(balanceOf[to] + transferAmount <= maxWalletLimit, "Exceeds maximum wallet limit");
            require(transferAmount <= maxTransferAmount, "Exceeds maximum transfer amount");

            balanceOf[from] -= value;
            balanceOf[to] += transferAmount;

            if (taxAmount > 0) {
                balanceOf[_marketingWallet] += taxAmount;
                emit Transfer(from, _marketingWallet, taxAmount);
            }

            emit Transfer(from, to, transferAmount);
        }
    }

    /**
     * @dev Sets the tax percentage applied to token transfers.
     * @param percentage The new tax percentage.
     */
    function setTaxPercentage(uint256 percentage) external {
        require(msg.sender == _deployer, "Only deployer can change the tax percentage");
        _taxPercentage = percentage;
    }

    /**
     * @dev Sets the maximum transaction limit.
     * @param limit The new maximum transaction limit as a percentage of the total supply.
     */
    function setMaxTransactionLimit(uint256 limit) external {
        require(msg.sender == _deployer, "Only deployer can change the max transaction limit");
        maxTransferAmount = totalSupply * limit / 10000;
    }

    /**
     * @dev Sets the maximum tokens per wallet limit.
     * @param limit The new maximum tokens per wallet limit as a percentage of the total supply.
     */
    function setMaxWalletLimit(uint256 limit) external {
        require(msg.sender == _deployer, "Only deployer can change the max wallet limit");
        maxWalletLimit = totalSupply * limit / 10000;
    }

    /**
     * @dev Sets the address of the marketing wallet.
     * @param wallet The new marketing wallet address.
     */
    function setMarketingWallet(address wallet) external {
        require(msg.sender == _deployer, "Only deployer can change the marketing wallet");
        require(wallet != address(0), "Invalid wallet address");
        _marketingWallet = wallet;
    }

    /**
     * @dev Sets the exemption status for the given account from token taxes.
     * @param account The account address.
     * @param exempt Whether the account is exempt from taxes.
     */
    function setExemptFromTax(address account, bool exempt) external {
        require(msg.sender == _deployer, "Only deployer can set tax exemptions");
        isExemptFromTax[account] = exempt;
    }
}
