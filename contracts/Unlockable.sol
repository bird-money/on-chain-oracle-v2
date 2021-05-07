// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Oracle service to find rating of any ethereum address
/// @author Bird Money
/// @dev this contract is made to avoid locking of any ERC20 token and Ether
abstract contract Unlockable is Ownable {
    /// @dev owner can take out any locked tokens in contract
    /// @param token the token owner wants to take out from contract
    /// @param amount amount of tokens
    event OwnerWithdraw(IERC20 token, uint256 amount);

    /// @dev owner can take out any locked tokens in contract
    /// @param amount amount of tokens
    event OwnerWithdrawETH(uint256 amount);

    /// @dev owner can take out any locked tokens in contract
    /// @param _amount amount of tokens
    function withdrawETHFromContract(uint256 _amount)
        external
        virtual
        onlyOwner
    {
        msg.sender.transfer(_amount);
        emit OwnerWithdrawETH(_amount);
    }

    /// @dev owner can take out any locked tokens in contract
    /// @param _token the token owner wants to take out from contract
    /// @param _amount amount of tokens
    function withdrawAnyTokenFromContract(IERC20 _token, uint256 _amount)
        external
        virtual
        onlyOwner
    {
        _token.transfer(msg.sender, _amount);
        emit OwnerWithdraw(_token, _amount);
    }

    fallback() external payable {}

    receive() external payable {}
}
