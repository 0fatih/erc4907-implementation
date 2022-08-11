// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC4907.sol";

contract ERC4907 is ERC721, IERC4907 {
    // Custom errors
    error CanNotRentToZeroAddress();
    error NotOwnerOrApproved();
    error InvalidExpire();

    struct TenantInfo {
        address tenant;
        uint64 expires;
    }

    mapping(uint256 => TenantInfo) internal _tenants;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        for (uint256 i = 1; i <= 10; i++) {
            _mint(msg.sender, i);
        }
    }

    function setUser(
        uint256 tokenId,
        address tenant,
        uint64 expires
    ) public {
        if (ownerOf(tokenId) != msg.sender && getApproved(tokenId) != msg.sender) revert NotOwnerOrApproved();

        if (tenant == address(0)) revert CanNotRentToZeroAddress();

        if (expires <= block.timestamp) revert InvalidExpire();

        TenantInfo storage ref = _tenants[tokenId];
        ref.tenant = tenant;
        ref.expires = expires;

        emit UpdateUser(tokenId, tenant, expires);
    }

    function userOf(uint256 tokenId) public view returns (address) {
        TenantInfo storage ref = _tenants[tokenId];
        if (ref.expires >= block.timestamp) {
            return ref.tenant;
        } else {
            return address(0);
        }
    }

    function userExpires(uint256 tokenId) public view returns (uint256) {
        return _tenants[tokenId].expires;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC4907).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        TenantInfo storage ref = _tenants[tokenId];
        if (
            from != to &&
            ref.tenant != address(0) &&
            ref.expires <= block.timestamp
        ) {
            delete _tenants[tokenId];
            emit UpdateUser(tokenId, address(0), 0);
        }
    }
}
