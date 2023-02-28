// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {console2} from "forge-std/console2.sol";

/// @dev interface for interacting with the strategy
interface IStrategy {
    function want() external view returns (IERC20);
    function beforeDeposit() external;
    function deposit() external;
    function withdraw(uint256) external;
    function balanceOf() external view returns (uint256);
}

/// @dev safu yield vault with automated strategy
contract SafuVault is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // The strategy currently in use by the vault.
    IStrategy public strategy;

    constructor (
        address _strategy,
        string memory _name,
        string memory _symbol
    ) ERC20 (
        _name,
        _symbol
    ) {
        strategy = IStrategy(_strategy);
    }

    /// @dev Token required as input for this strategy
    function want() public view returns (IERC20) {
        return IERC20(strategy.want());
    }

    /// @dev Calculates amount of funds available to put to work in strategy
    function available() public view returns (uint256) {
        return want().balanceOf(address(this));
    }

    /// @dev Calculates total underlying value of tokens held by system (vault + strategy)
    function balance() public view returns (uint256) {
        return available() + strategy.balanceOf();
    }

    /// @dev Calls deposit() with all the sender's funds
    function depositAll() external {
      deposit(want().balanceOf(msg.sender));
    }

    /// @dev Entrypoint of funds into the system
    /// @dev People deposit with this function into the vault
    function deposit(uint256 _amount) public nonReentrant {
        strategy.beforeDeposit();

        uint256 _pool = balance();
        want().safeTransferFrom(msg.sender, address(this), _amount);
        earn();
        uint256 _after = balance();
        _amount = _after - _pool; // Additional check for deflationary tokens

        uint256 shares;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply()) / (_pool);
        }
        _mint(msg.sender, shares);
    }

    /// @dev Sends funds to strategy to put them to work, by calling deposit() function
    function earn() public {
        uint256 _bal = available();
        want().safeTransfer(address(strategy), _bal);
        strategy.deposit();
    }

    /// @dev Helper function to call withdraw() with all sender's funds
    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
        // balanceOf(msg.sender) = 20000
        // withdraw(20000)
    }

    /// @dev Allows user to withdraw specified funds
    function withdraw(uint256 _shares) public {
        console2.log("withdraw(%d)", _shares);
        uint256 r = (balance() * _shares) / (totalSupply());
        console2.log("r = (%d * %d) / %d", balance(), _shares, totalSupply());
        console2.log("r = ", r);
        _burn(msg.sender, _shares); // Will revert if _shares > what user has
        console2.log("burn(msg.sender, %d)", _shares);

        uint256 b = want().balanceOf(address(this)); // Check vault balance
        console2.log("b = %d", b);
        if (b < r) { // Withdraw any extra required funds from strategy
            uint256 _withdraw = r - b;
            console2.log("_withdraw = %d - %d = %d", r, b, _withdraw);
            strategy.withdraw(_withdraw);

            uint256 _after = want().balanceOf(address(this));
            console2.log("_after = ", _after);
            uint256 _diff = _after - b;
            console2.log("_diff = %d - %d = %d", _after, b, _diff);
            if (_diff < _withdraw) {
                console2.log("_diff < _withdraw");
                r = b + _diff;
                console2.log("r = %d + %d = %d", b, _diff, r);
            }
        }

        console2.log("want().safeTransfer(msg.sender, %d)", r);
        want().safeTransfer(msg.sender, r);
    }

    /// @dev Deposit funds into the system for other user
    function depositFor(
        address token,
        uint256 _amount,
        address user
    ) public {
        console2.log("depositFor()");
        console2.log("_amount = ", _amount);
        strategy.beforeDeposit();

        uint256 _pool = balance();
        console2.log("_pool =   ", _pool);
        // _pool = 10000, 11000, ..., 20000
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

        earn();
        uint256 _after = balance();
        console2.log("_after = %d", _after);
        _amount = _after - _pool; // Additional check for deflationary tokens
        console2.log("_amount = _after - _pool = %d - %d = %d", _after, _pool, _after - _pool);

        uint256 shares;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            console2.log("totalSupply() = ", totalSupply());
            shares = (_amount * totalSupply()) / (_pool);
            console2.log("shares = (%d * %d) / %d", _amount, totalSupply(), _pool);
        }
        console2.log("shares = %d", shares);

        _mint(user, shares);
    }
}
