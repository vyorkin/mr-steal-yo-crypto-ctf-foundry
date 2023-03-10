// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Counters} from "openzeppelin/utils/Counters.sol";
import {AssetHolder} from "./AssetHolder.sol";

interface IGameAsset {
    function ownerOf(uint256 tokenId) external returns (address);
    function isApprovedForAll(
        address owner,
        address operator
    ) external returns (bool);
    function setOwnerOperator(
        address to,
        uint256 tokenId
    ) external;
}

/// @dev Functionality for wrapping and unwrapping assets for use in the game
/// @dev the game strictly references this contract for determining assets user owns
/// @dev stores a whitelist of GameAsset contracts that are used by this game
/// @dev while NFTs are used in the game, they cannot be bought/sold/transferred
/// @dev that is why this contract temporarily takes ownership of NFTs used in-game
contract AssetWrapper is AssetHolder, Ownable {
    // Used to keep track of the current token ID for newly added GameAssets
    using Counters for Counters.Counter;

    Counters.Counter private _tokenId;

    /// @dev Allows whitelisting of GameAsset contracts
    mapping(address => bool) private _whitelist;

    /// @dev Token ID for each whitelisted GameAsset contract
    mapping(address => uint256) private _assetId;

    constructor(
        string memory uri
    ) AssetHolder (
        uri
    ) {}

    /// @dev Owner can whitelist GameAsset ERC721 contracts
    /// @dev a GameAsset contract cannot be removed from the WL
    function updateWhitelist(address asset) external onlyOwner {
        if (!_whitelist[asset]) {
            _assetId[asset] = _tokenId.current();
            _whitelist[asset] = true;
            _tokenId.increment();
        }
    }

    /// @dev Returns whether an asset is whitelisted
    function isWhitelisted(address asset) public view returns (bool) {
        return _whitelist[asset];
    }

    /// @dev Wraps arbitrary whitelisted ERC721 game assets
    /// @param nftId Unique id of the asset the user is wrapping
    /// @param assetOwner Address of owner to assign this game asset
    /// @param assetAddress Address of the GameAsset contract
    function wrap(
        uint256 nftId,
        address assetOwner,
        address assetAddress
    ) public {
        require(isWhitelisted(assetAddress), "Wrapper: asset not whitelisted");
        _wrap(assetOwner, assetAddress, nftId);

        IGameAsset asset = IGameAsset(assetAddress);
        address owner = asset.ownerOf(nftId);

        // Can be removed to allow wrapping to any account, saving gas on transfer
        require(assetOwner == owner, "Wrapper: incorrect receiver for wrap");

        require(
            owner == msg.sender ||
                isApprovedForAll(owner, msg.sender) || // Approval for all WLed contracts
                asset.isApprovedForAll(owner, msg.sender), // Approval for this WL contract
            "Wrapper: asset is not owned by sender"
        );

        asset.setOwnerOperator( // Wrapper takes control of asset
            address(this),
            nftId
        );
    }

    /// @dev Unwraps assets and transfers NFT back to user `assetOwner`
    /// @dev per game mechanics user has max of one wrapped NFT per token ID
    function unwrap(
        address assetOwner,
        address assetAddress
    ) public {
        require(isWhitelisted(assetAddress), "Wrapper: asset not whitelisted");

        IGameAsset asset = IGameAsset(assetAddress);

        require(
            assetOwner == msg.sender ||
                isApprovedForAll(assetOwner, msg.sender) || // Approval for all WLed contracts
                asset.isApprovedForAll(assetOwner, msg.sender), // Approval for this WL contract
            "Wrapper: asset if not owned by sender"
        );

        _unwrap(assetOwner, assetAddress);
    }

    function _wrap(
        address assetOwner,
        address assetAddress,
        uint256 nftId
    ) private {
        uint256 assetId = _assetId[assetAddress];
        bytes memory data = abi.encode(nftId);
        _mint(assetOwner, assetId, 1, data);
    }

    function _unwrap(
        address assetOwner,
        address assetAddress
    ) private {
        uint256 assetId = _assetId[assetAddress];
        uint256 nftId = getIdOwned(assetId, assetOwner); // NFT id owned by user

        _burn(assetOwner, assetId, 1); // Reverts if user doesn't own asset

        IGameAsset(assetAddress).setOwnerOperator( // Wrapper relinquishes control of asset
            assetOwner,
            nftId
        );
    }
}
