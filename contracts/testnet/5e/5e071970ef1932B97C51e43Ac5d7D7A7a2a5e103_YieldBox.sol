// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// WARNING!!!
// Combining BoringBatchable with msg.value can cause double spending issues
// https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/

import "./interfaces/IERC20.sol";

contract BaseBoringBatchable {
    error BatchError(bytes innerError);

    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure{
        // If the _res length is less than 68, then
        // the transaction failed with custom error or silently (without a revert message)
        if (_returnData.length < 68) revert BatchError(_returnData);

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                _getRevertMsg(result);
            }
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IMasterContract.sol";

// solhint-disable no-inline-assembly

contract BoringFactory {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);

    /// @notice Mapping from clone contracts to their masterContract.
    mapping(address => address) public masterContractOf;

    /// @notice Mapping from masterContract to an array of all clones
    /// On mainnet events can be used to get this list, but events aren't always easy to retrieve and
    /// barely work on sidechains. While this adds gas, it makes enumerating all clones much easier.
    mapping(address => address[]) public clonesOf;

    /// @notice Returns the count of clones that exists for a specific masterContract
    /// @param masterContract The address of the master contract.
    /// @return cloneCount total number of clones for the masterContract.
    function clonesOfCount(address masterContract) public view returns (uint256 cloneCount) {
        cloneCount = clonesOf[masterContract].length;
    }

    /// @notice Deploys a given master Contract as a clone.
    /// Any ETH transferred with this call is forwarded to the new clone.
    /// Emits `LogDeploy`.
    /// @param masterContract The address of the contract to clone.
    /// @param data Additional abi encoded calldata that is passed to the new clone via `IMasterContract.init`.
    /// @param useCreate2 Creates the clone by using the CREATE2 opcode, in this case `data` will be used as salt.
    /// @return cloneAddress Address of the created clone contract.
    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) public payable returns (address cloneAddress) {
        require(masterContract != address(0), "BoringFactory: No masterContract");
        bytes20 targetBytes = bytes20(masterContract); // Takes the first 20 bytes of the masterContract's address

        if (useCreate2) {
            // each masterContract has different code already. So clones are distinguished by their data only.
            bytes32 salt = keccak256(data);

            // Creates clone, more info here: https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create2(0, clone, 0x37, salt)
            }
        } else {
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create(0, clone, 0x37)
            }
        }
        masterContractOf[cloneAddress] = masterContract;
        clonesOf[masterContract].push(cloneAddress);

        IMasterContract(cloneAddress).init{value: msg.value}(data);

        emit LogDeploy(masterContract, data, cloneAddress);
    }
}

// SPDX-License-Identifier: MIT
// Based on code and smartness by Ross Campbell and Keno
// Uses immutable to store the domain separator to reduce gas usage
// If the chain id changes due to a fork, the forked chain will calculate on the fly.
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly

contract Domain {
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";

    // solhint-disable var-name-mixedcase
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;

    /// @dev Calculate the DOMAIN_SEPARATOR
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, chainId, address(this)));
    }

    constructor() {
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = block.chainid);
    }

    /// @dev Return the DOMAIN_SEPARATOR
    // It's named internal to allow making it public from the contract that uses it by creating a simple view function
    // with the desired public name, such as DOMAIN_SEPARATOR or domainSeparator.
    // solhint-disable-next-line func-name-mixedcase
    function _domainSeparator() internal view returns (bytes32) {
        return block.chainid == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(block.chainid);
    }

    function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA, _domainSeparator(), dataHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC165.sol";

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155TokenReceiver {
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface IERC721Enumerable /* is ERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly
// solhint-disable no-empty-blocks

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
                case 1 {
                    mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
                }
                case 2 {
                    mstore(sub(resultPtr, 1), shl(248, 0x3d))
                }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly

library BoringAddress {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendNative(address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: amount}("");
        require(success, "BoringAddress: transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TOTALSUPPLY = 0x18160ddd; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to) internal view returns (uint256 amount) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_BALANCE_OF, to));
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    }

    /// @notice Provides a gas-optimized totalSupply to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @return totalSupply The token totalSupply.
    function safeTotalSupply(IERC20 token) internal view returns (uint256 totalSupply) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_TOTALSUPPLY));
        require(success && data.length >= 32, "BoringERC20: totalSupply failed");
        totalSupply = abi.decode(data, (uint256));
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringAddress.sol";
import "./ERC1155.sol";

// An asset is a token + a strategy
struct Asset {
    TokenType tokenType;
    address contractAddress;
    IStrategy strategy;
    uint256 tokenId;
}

contract AssetRegister is ERC1155 {
    using BoringAddress for address;

    event AssetRegistered(
        TokenType indexed tokenType,
        address indexed contractAddress,
        IStrategy strategy,
        uint256 indexed tokenId,
        uint256 assetId
    );

    // ids start at 1 so that id 0 means it's not yet registered
    mapping(TokenType => mapping(address => mapping(IStrategy => mapping(uint256 => uint256)))) public ids;
    Asset[] public assets;

    constructor() {
        assets.push(Asset(TokenType.None, address(0), NO_STRATEGY, 0));
    }

    function assetCount() public view returns (uint256) {
        return assets.length;
    }

    function _registerAsset(
        TokenType tokenType,
        address contractAddress,
        IStrategy strategy,
        uint256 tokenId
    ) internal returns (uint256 assetId) {
        // Checks
        assetId = ids[tokenType][contractAddress][strategy][tokenId];

        // If assetId is 0, this is a new asset that needs to be registered
        if (assetId == 0) {
            // Only do these checks if a new asset needs to be created
            require(tokenId == 0 || tokenType != TokenType.ERC20, "YieldBox: No tokenId for ERC20");
            require(
                strategy == NO_STRATEGY ||
                    (tokenType == strategy.tokenType() && contractAddress == strategy.contractAddress() && tokenId == strategy.tokenId()),
                "YieldBox: Strategy mismatch"
            );
            // If a new token gets added, the isContract checks that this is a deployed contract. Needed for security.
            // Prevents getting shares for a future token whose address is known in advance. For instance a token that will be deployed with CREATE2 in the future or while the contract creation is
            // in the mempool
            require((tokenType == TokenType.Native && contractAddress == address(0)) || contractAddress.isContract(), "YieldBox: Not a token");

            // Effects
            assetId = assets.length;
            assets.push(Asset(tokenType, contractAddress, strategy, tokenId));
            ids[tokenType][contractAddress][strategy][tokenId] = assetId;

            // The actual URI isn't emitted here as per EIP1155, because that would make this call super expensive.
            emit URI("", assetId);
            emit AssetRegistered(tokenType, contractAddress, strategy, tokenId, assetId);
        }
    }

    function registerAsset(
        TokenType tokenType,
        address contractAddress,
        IStrategy strategy,
        uint256 tokenId
    ) public returns (uint256 assetId) {
        // Native assets can only be added internally by the NativeTokenFactory
        require(
            tokenType == TokenType.ERC20 || tokenType == TokenType.ERC721 || tokenType == TokenType.ERC1155,
            "AssetManager: cannot add Native"
        );
        assetId = _registerAsset(tokenType, contractAddress, strategy, tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library BoringMath {
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= type(uint128).max, "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= type(uint64).max, "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= type(uint32).max, "BoringMath: uint32 Overflow");
        c = uint32(a);
    }

    function muldiv(
        uint256 value,
        uint256 mul,
        uint256 div,
        bool roundUp
    ) internal pure returns (uint256 result) {
        result = (value * mul) / div;
        if (roundUp && (result * div) / mul < value) {
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title TokenType
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The YieldBox can hold different types of tokens:
/// Native: These are ERC1155 tokens native to YieldBox. Protocols using YieldBox should use these is possible when simple token creation is needed.
/// ERC20: ERC20 tokens (including rebasing tokens) can be added to the YieldBox.
/// ERC1155: ERC1155 tokens are also supported. This can also be used to add YieldBox Native tokens to strategies since they are ERC1155 tokens.
enum TokenType {
    Native,
    ERC20,
    ERC721,
    ERC1155,
    None
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155TokenReceiver.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringAddress.sol";

// Written by OreNoMochi (https://github.com/OreNoMochii), BoringCrypto

contract ERC1155 is IERC1155 {
    using BoringAddress for address;

    // mappings
    mapping(address => mapping(address => bool)) public override isApprovedForAll; // map of operator approval
    mapping(address => mapping(uint256 => uint256)) public override balanceOf; // map of tokens owned by
    mapping(uint256 => uint256) public totalSupply; // totalSupply per token

    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return
            interfaceID == this.supportsInterface.selector || // EIP-165
            interfaceID == 0xd9b67a26 || // ERC-1155
            interfaceID == 0x0e89341c; // EIP-1155 Metadata
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view override returns (uint256[] memory balances) {
        uint256 len = owners.length;
        require(len == ids.length, "ERC1155: Length mismatch");

        balances = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            balances[i] = balanceOf[owners[i]][ids[i]];
        }
    }

    function _mint(
        address to,
        uint256 id,
        uint256 value
    ) internal {
        require(to != address(0), "No 0 address");

        balanceOf[to][id] += value;
        totalSupply[id] += value;

        emit TransferSingle(msg.sender, address(0), to, id, value);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 value
    ) internal {
        require(from != address(0), "No 0 address");

        balanceOf[from][id] -= value;
        totalSupply[id] -= value;

        emit TransferSingle(msg.sender, from, address(0), id, value);
    }

    function _transferSingle(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) internal {
        require(to != address(0), "No 0 address");

        balanceOf[from][id] -= value;
        balanceOf[to][id] += value;

        emit TransferSingle(msg.sender, from, to, id, value);
    }

    function _transferBatch(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values
    ) internal {
        require(to != address(0), "No 0 address");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 value = values[i];
            balanceOf[from][id] -= value;
            balanceOf[to][id] += value;
        }

        emit TransferBatch(msg.sender, from, to, ids, values);
    }

    function _requireTransferAllowed(address from) internal view virtual {
        require(from == msg.sender || isApprovedForAll[from][msg.sender] == true, "Transfer not allowed");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override {
        _requireTransferAllowed(from);

        _transferSingle(from, to, id, value);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, value, data) ==
                    bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")),
                "Wrong return value"
            );
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override {
        require(ids.length == values.length, "ERC1155: Length mismatch");
        _requireTransferAllowed(from);

        _transferBatch(from, to, ids, values);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, values, data) ==
                    bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")),
                "Wrong return value"
            );
        }
    }

    function setApprovalForAll(address operator, bool approved) external virtual override {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function uri(
        uint256 /*assetId*/
    ) external view virtual returns (string memory) {
        return "";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155TokenReceiver.sol";

contract ERC1155TokenReceiver is IERC1155TokenReceiver {
    // ERC1155 receivers that simple accept the transfer
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xf23a6e61; //bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xbc197c81; //bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "../enums/YieldBoxTokenType.sol";
import "./IYieldBox.sol";

interface IStrategy {
    /// Each strategy only works with a single asset. This should help make implementations simpler and more readable.
    /// To safe gas a proxy pattern (YieldBox factory) could be used to deploy the same strategy for multiple tokens.

    /// It is recommended that strategies keep a small amount of funds uninvested (like 5%) to handle small withdrawals
    /// and deposits without triggering costly investing/divesting logic.

    /// #########################
    /// ### Basic Information ###
    /// #########################

    /// Returns the address of the yieldBox that this strategy is for
    function yieldBox() external view returns (IYieldBox yieldBox_);

    /// Returns a name for this strategy
    function name() external view returns (string memory name_);

    /// Returns a description for this strategy
    function description() external view returns (string memory description_);

    /// #######################
    /// ### Supported Token ###
    /// #######################

    /// Returns the standard that this strategy works with
    function tokenType() external view returns (TokenType tokenType_);

    /// Returns the contract address that this strategy works with
    function contractAddress() external view returns (address contractAddress_);

    /// Returns the tokenId that this strategy works with (for EIP1155)
    /// This is always 0 for EIP20 tokens
    function tokenId() external view returns (uint256 tokenId_);

    /// ###########################
    /// ### Balance Information ###
    /// ###########################

    /// Returns the total value the strategy holds (principle + gain) expressed in asset token amount.
    /// This should be cheap in gas to retrieve. Can return a bit less than the actual, but MUST NOT return more.
    /// The gas cost of this function will be paid on any deposit or withdrawal onto and out of the YieldBox
    /// that uses this strategy. Also, anytime a protocol converts between shares and amount, this gets called.
    function currentBalance() external view returns (uint256 amount);

    /// Returns the maximum amount that can be withdrawn
    function withdrawable() external view returns (uint256 amount);

    /// Returns the maximum amount that can be withdrawn for a low gas fee
    /// When more than this amount is withdrawn it will trigger divesting from the actual strategy
    /// which will incur higher gas costs
    function cheapWithdrawable() external view returns (uint256 amount);

    /// ##########################
    /// ### YieldBox Functions ###
    /// ##########################

    /// Is called by YieldBox to signal funds have been added, the strategy may choose to act on this
    /// When a large enough deposit is made, this should trigger the strategy to invest into the actual
    /// strategy. This function should normally NOT be used to invest on each call as that would be costly
    /// for small deposits.
    /// If the strategy handles native tokens (ETH) it will receive it directly (not wrapped). It will be
    /// up to the strategy to wrap it if needed.
    /// Only accept this call from the YieldBox
    function deposited(uint256 amount) external;

    /// Is called by the YieldBox to ask the strategy to withdraw to the user
    /// When a strategy keeps a little reserve for cheap withdrawals and the requested withdrawal goes over this amount,
    /// the strategy should divest enough from the strategy to complete the withdrawal and rebalance the reserve.
    /// If the strategy handles native tokens (ETH) it should send this, not a wrapped version.
    /// With some strategies it might be hard to withdraw exactly the correct amount.
    /// Only accept this call from the YieldBox
    function withdraw(address to, uint256 amount) external;
}

IStrategy constant NO_STRATEGY = IStrategy(address(0));

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

interface IWrappedNative is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "../enums/YieldBoxTokenType.sol";

interface IYieldBox {
    function wrappedNative() external view returns (address wrappedNative);

    function assets(uint256 assetId)
        external
        view
        returns (
            TokenType tokenType,
            address contractAddress,
            address strategy,
            uint256 tokenId
        );

    function nativeTokens(uint256 assetId)
        external
        view
        returns (
            string memory name,
            string memory symbol,
            uint8 decimals
        );

    function owner(uint256 assetId) external view returns (address owner);

    function totalSupply(uint256 assetId) external view returns (uint256 totalSupply);

    function depositAsset(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function transfer(
        address from,
        address to,
        uint256 assetId,
        uint256 share
    ) external;

    function batchTransfer(
        address from,
        address to,
        uint256[] calldata assetIds_,
        uint256[] calldata shares_
    ) external;

    function transferMultiple(
        address from,
        address[] calldata tos,
        uint256 assetId,
        uint256[] calldata shares
    ) external;

    function toShare(
        uint256 assetId,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function toAmount(
        uint256 assetId,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./AssetRegister.sol";
import "./BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringFactory.sol";

struct NativeToken {
    string name;
    string symbol;
    uint8 decimals;
    string uri;
}

/// @title NativeTokenFactory
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The NativeTokenFactory is a token factory to create ERC1155 tokens. This is used by YieldBox to create
/// native tokens in YieldBox. These have many benefits:
/// - low and predictable gas usage
/// - simplified approval
/// - no hidden features, all these tokens behave the same
/// TODO: MintBatch? BurnBatch?
contract NativeTokenFactory is AssetRegister, BoringFactory {
    using BoringMath for uint256;

    mapping(uint256 => NativeToken) public nativeTokens;
    mapping(uint256 => address) public owner;
    mapping(uint256 => address) public pendingOwner;

    event TokenCreated(address indexed creator, string name, string symbol, uint8 decimals, uint256 tokenId);
    event OwnershipTransferred(uint256 indexed tokenId, address indexed previousOwner, address indexed newOwner);

    // ***************** //
    // *** MODIFIERS *** //
    // ***************** //

    /// Modifier to check if the msg.sender is allowed to use funds belonging to the 'from' address.
    /// If 'from' is msg.sender, it's allowed.
    /// If 'msg.sender' is an address (an operator) that is approved by 'from', it's allowed.
    /// If 'msg.sender' is a clone of a masterContract that is approved by 'from', it's allowed.
    modifier allowed(address from) {
        if (from != msg.sender && !isApprovedForAll[from][msg.sender]) {
            address masterContract = masterContractOf[msg.sender];
            require(masterContract != address(0) && isApprovedForAll[from][masterContract], "YieldBox: Not approved");
        }
        _;
    }

    /// @notice Only allows the `owner` to execute the function.
    /// @param tokenId The `tokenId` that the sender has to be owner of.
    modifier onlyOwner(uint256 tokenId) {
        require(msg.sender == owner[tokenId], "NTF: caller is not the owner");
        _;
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param tokenId The `tokenId` of the token that ownership whose ownership will be transferred/renounced.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        uint256 tokenId,
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner(tokenId) {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "NTF: zero address");

            // Effects
            emit OwnershipTransferred(tokenId, owner[tokenId], newOwner);
            owner[tokenId] = newOwner;
            pendingOwner[tokenId] = address(0);
        } else {
            // Effects
            pendingOwner[tokenId] = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    /// @param tokenId The `tokenId` of the token that ownership is claimed for.
    function claimOwnership(uint256 tokenId) public {
        address _pendingOwner = pendingOwner[tokenId];

        // Checks
        require(msg.sender == _pendingOwner, "NTF: caller != pending owner");

        // Effects
        emit OwnershipTransferred(tokenId, owner[tokenId], _pendingOwner);
        owner[tokenId] = _pendingOwner;
        pendingOwner[tokenId] = address(0);
    }

    /// @notice Create a new native token. This will be an ERC1155 token. If later it's needed as an ERC20 token it can
    /// be wrapped into an ERC20 token. Native support for ERC1155 tokens is growing though.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    /// @param decimals The number of decimals of the token (this is just for display purposes). Should be set to 18 in normal cases.
    function createToken(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        string calldata uri
    ) public returns (uint32 tokenId) {
        // To keep each Token unique in the AssetRegister, we use the assetId as the tokenId. So for native assets, the tokenId is always equal to the assetId.
        tokenId = assets.length.to32();
        _registerAsset(TokenType.Native, address(0), NO_STRATEGY, tokenId);
        // Initial supply is 0, use owner can mint. For a fixed supply the owner can mint and revoke ownership.
        // The msg.sender is the initial owner, can be changed after.
        nativeTokens[tokenId] = NativeToken(name, symbol, decimals, uri);
        owner[tokenId] = msg.sender;

        emit TokenCreated(msg.sender, name, symbol, decimals, tokenId);
        emit TransferSingle(msg.sender, address(0), address(0), tokenId, 0);
        emit OwnershipTransferred(tokenId, address(0), msg.sender);
    }

    /// @notice The `owner` can mint tokens. If a fixed supply is needed, the `owner` should mint the totalSupply and renounce ownership.
    /// @param tokenId The token to be minted.
    /// @param to The account to transfer the minted tokens to.
    /// @param amount The amount of tokens to mint.
    function mint(
        uint256 tokenId,
        address to,
        uint256 amount
    ) public onlyOwner(tokenId) {
        _mint(to, tokenId, amount);
    }

    /// @notice Burns tokens. Only the holder of tokens can burn them.
    /// @param tokenId The token to be burned.
    /// @param amount The amount of tokens to burn.
    function burn(
        uint256 tokenId,
        address from,
        uint256 amount
    ) public allowed(from) {
        require(assets[tokenId].tokenType == TokenType.Native, "NTF: Not native");
        _burn(msg.sender, tokenId, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

// The YieldBox
// The original BentoBox is owned by the Sushi team to set strategies for each token. Abracadabra wanted different strategies, which led to
// them launching their own DegenBox. The YieldBox solves this by allowing an unlimited number of strategies for each token in a fully
// permissionless manner. The YieldBox has no owner and operates fully permissionless.

// Other improvements:
// Better system to make sure the token to share ratio doesn't reset.
// Full support for rebasing tokens.

// This contract stores funds, handles their transfers, approvals and strategies.

// Copyright (c) 2021, 2022 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

// Since the contract is permissionless, only one deployment per chain is needed. If it's not yet deployed
// on a chain or if you want to make a derivative work, contact @BoringCrypto. The core of YieldBox is
// copyrighted. Most of the contracts that it builds on are open source though.

// BEWARE: Still under active development
// Security review not done yet

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
import "./interfaces/IWrappedNative.sol";
import "./interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC721.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/Base64.sol";
import "@boringcrypto/boring-solidity/contracts/Domain.sol";
import "./ERC1155TokenReceiver.sol";
import "./ERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./AssetRegister.sol";
import "./NativeTokenFactory.sol";
import "./YieldBoxRebase.sol";
import "./YieldBoxURIBuilder.sol";

// solhint-disable no-empty-blocks

/// @title YieldBox
/// @author BoringCrypto, Keno
/// @notice The YieldBox is a vault for tokens. The stored tokens can assigned to strategies.
/// Yield from this will go to the token depositors.
/// Any funds transfered directly onto the YieldBox will be lost, use the deposit function instead.
contract YieldBox is BoringBatchable, NativeTokenFactory, ERC1155TokenReceiver {
    using BoringAddress for address;
    using BoringERC20 for IERC20;
    using BoringERC20 for IWrappedNative;
    using YieldBoxRebase for uint256;

    // ************** //
    // *** EVENTS *** //
    // ************** //

    // TODO: Add events

    // ******************* //
    // *** CONSTRUCTOR *** //
    // ******************* //

    IWrappedNative public immutable wrappedNative;
    YieldBoxURIBuilder public immutable uriBuilder;

    constructor(IWrappedNative wrappedNative_, YieldBoxURIBuilder uriBuilder_) {
        wrappedNative = wrappedNative_;
        uriBuilder = uriBuilder_;
    }

    // ************************** //
    // *** INTERNAL FUNCTIONS *** //
    // ************************** //

    /// @dev Returns the total balance of `token` this contracts holds,
    /// plus the total amount this contract thinks the strategy holds.
    function _tokenBalanceOf(Asset storage asset) internal view returns (uint256 amount) {
        if (asset.strategy == NO_STRATEGY) {
            if (asset.tokenType == TokenType.ERC20) {
                return IERC20(asset.contractAddress).safeBalanceOf(address(this));
            } else {
                return IERC1155(asset.contractAddress).balanceOf(address(this), asset.tokenId);
            }
        } else {
            return asset.strategy.currentBalance();
        }
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param assetId The id of the asset.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function depositAsset(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) public allowed(from) returns (uint256 amountOut, uint256 shareOut) {
        // Checks
        Asset storage asset = assets[assetId];
        require(asset.tokenType != TokenType.Native, "YieldBox: can't deposit Native");
        require(asset.tokenType != TokenType.ERC721, "YieldBox: use DepositNFT");

        // Effects
        uint256 totalAmount = _tokenBalanceOf(asset);
        if (share == 0) {
            // value of the share may be lower than the amount due to rounding, that's ok
            share = amount._toShares(totalSupply[assetId], totalAmount, false);
        } else {
            // amount may be lower than the value of share due to rounding, in that case, add 1 to amount (Always round up)
            amount = share._toAmount(totalSupply[assetId], totalAmount, true);
        }

        _mint(to, assetId, share);

        address destination = asset.strategy == NO_STRATEGY ? address(this) : address(asset.strategy);

        // Interactions
        if (asset.tokenType == TokenType.ERC20) {
            IERC20(asset.contractAddress).safeTransferFrom(from, destination, amount);
        } else {
            // ERC1155
            // When depositing yieldBox tokens into the yieldBox, things can be simplified
            if (asset.contractAddress == address(this)) {
                _transferSingle(from, destination, asset.tokenId, amount);
            } else {
                IERC1155(asset.contractAddress).safeTransferFrom(from, destination, asset.tokenId, amount, "");
            }
        }

        if (asset.strategy != NO_STRATEGY) {
            asset.strategy.deposited(amount);
        }

        return (amount, share);
    }

    /// @notice Deposit an NFT asset
    /// @param assetId The id of the asset.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function depositNFTAsset(
        uint256 assetId,
        address from,
        address to
    ) public allowed(from) returns (uint256 amountOut, uint256 shareOut) {
        // Checks
        Asset storage asset = assets[assetId];
        require(asset.tokenType == TokenType.ERC721, "YieldBox: not ERC721");

        // Effects
        _mint(to, assetId, 1);

        address destination = asset.strategy == NO_STRATEGY ? address(this) : address(asset.strategy);

        // Interactions
        IERC721(asset.contractAddress).safeTransferFrom(from, destination, asset.tokenId);

        if (asset.strategy != NO_STRATEGY) {
            asset.strategy.deposited(1);
        }

        return (1, 1);
    }

    function depositETHAsset(
        uint256 assetId,
        address to,
        uint256 amount
    )
        public
        payable
        returns (
            // TODO: allow shares with refund?
            uint256 amountOut,
            uint256 shareOut
        )
    {
        // Checks
        Asset storage asset = assets[assetId];
        require(asset.tokenType == TokenType.ERC20 && asset.contractAddress == address(wrappedNative), "YieldBox: not wrappedNative");

        // Effects
        uint256 share = amount._toShares(totalSupply[assetId], _tokenBalanceOf(asset), false);

        _mint(to, assetId, share);

        // Interactions
        wrappedNative.deposit{ value: amount }();
        if (asset.strategy != NO_STRATEGY) {
            // Strategies always receive wrappedNative (supporting both wrapped and raw native tokens adds too much complexity)
            wrappedNative.safeTransfer(address(asset.strategy), amount);
        }

        if (asset.strategy != NO_STRATEGY) {
            asset.strategy.deposited(amount);
        }

        return (amount, share);
    }

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param assetId The id of the asset.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) public allowed(from) returns (uint256 amountOut, uint256 shareOut) {
        // Checks
        Asset storage asset = assets[assetId];
        require(asset.tokenType != TokenType.Native, "YieldBox: can't withdraw Native");

        // Effects
        uint256 totalAmount = _tokenBalanceOf(asset);
        if (share == 0) {
            // value of the share paid could be lower than the amount paid due to rounding, in that case, add a share (Always round up)
            share = amount._toShares(totalSupply[assetId], totalAmount, true);
        } else {
            // amount may be lower than the value of share due to rounding, that's ok
            amount = share._toAmount(totalSupply[assetId], totalAmount, false);
        }

        _burn(from, assetId, share);

        // Interactions
        if (asset.strategy == NO_STRATEGY) {
            if (asset.tokenType == TokenType.ERC20) {
                // Native tokens are always unwrapped when withdrawn
                if (asset.contractAddress == address(wrappedNative)) {
                    wrappedNative.withdraw(amount);
                    to.sendNative(amount);
                } else {
                    IERC20(asset.contractAddress).safeTransfer(to, amount);
                }
            } else if (asset.tokenType == TokenType.ERC721) {
                IERC721(asset.contractAddress).safeTransferFrom(address(this), to, asset.tokenId);
            } else {
                // IERC1155
                IERC1155(asset.contractAddress).safeTransferFrom(address(this), to, asset.tokenId, amount, "");
            }
        } else {
            asset.strategy.withdraw(to, amount);
        }

        return (amount, share);
    }

    function _requireTransferAllowed(address from) internal view override allowed(from) {}

    /// @notice Transfer shares from a user account to another one.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param assetId The id of the asset.
    /// @param share The amount of `token` in shares.
    function transfer(
        address from,
        address to,
        uint256 assetId,
        uint256 share
    ) public allowed(from) {
        _transferSingle(from, to, assetId, share);
    }

    function batchTransfer(
        address from,
        address to,
        uint256[] calldata assetIds_,
        uint256[] calldata shares_
    ) public allowed(from) {
        _transferBatch(from, to, assetIds_, shares_);
    }

    /// @notice Transfer shares from a user account to multiple other ones.
    /// @param assetId The id of the asset.
    /// @param from which user to pull the tokens.
    /// @param tos The receivers of the tokens.
    /// @param shares The amount of `token` in shares for each receiver in `tos`.
    function transferMultiple(
        address from,
        address[] calldata tos,
        uint256 assetId,
        uint256[] calldata shares
    ) public allowed(from) {
        // Checks
        uint256 len = tos.length;
        for (uint256 i = 0; i < len; i++) {
            require(tos[i] != address(0), "YieldBox: to not set"); // To avoid a bad UI from burning funds
        }

        // Effects
        uint256 totalAmount;
        for (uint256 i = 0; i < len; i++) {
            address to = tos[i];
            uint256 share_ = shares[i];
            balanceOf[to][assetId] += share_;
            totalAmount += share_;
            emit TransferSingle(msg.sender, from, to, assetId, share_);
        }
        balanceOf[from][assetId] -= totalAmount;
    }

    function setApprovalForAll(address operator, bool approved) external override {
        // Checks
        require(operator != address(0), "YieldBox: operator not set"); // Important for security
        require(masterContractOf[msg.sender] == address(0), "YieldBox: user is clone");
        require(operator != address(this), "YieldBox: can't approve yieldBox");

        // Effects
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // This functionality has been split off into a separate contract. This is only a view function, so gas usage isn't a huge issue.
    // This keeps the YieldBox contract smaller, so it can be optimized more.
    function uri(uint256 assetId) external view override returns (string memory) {
        return uriBuilder.uri(assets[assetId], nativeTokens[assetId], totalSupply[assetId], owner[assetId]);
    }

    function name(uint256 assetId) external view returns (string memory) {
        return uriBuilder.name(assets[assetId], nativeTokens[assetId].name);
    }

    function symbol(uint256 assetId) external view returns (string memory) {
        return uriBuilder.symbol(assets[assetId], nativeTokens[assetId].symbol);
    }

    function decimals(uint256 assetId) external view returns (uint8) {
        return uriBuilder.decimals(assets[assetId], nativeTokens[assetId].decimals);
    }

    // Included to support unwrapping wrapped native tokens such as WETH
    receive() external payable {}

    // Helper functions

    function assetTotals(uint256 assetId) external view returns (uint256 totalShare, uint256 totalAmount) {
        totalShare = totalSupply[assetId];
        totalAmount = _tokenBalanceOf(assets[assetId]);
    }

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param assetId The id of the asset.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        uint256 assetId,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share) {
        if (assets[assetId].tokenType == TokenType.Native || assets[assetId].tokenType == TokenType.ERC721) {
            share = amount;
        } else {
            share = amount._toShares(totalSupply[assetId], _tokenBalanceOf(assets[assetId]), roundUp);
        }
    }

    /// @dev Helper function represent shares back into the `token` amount.
    /// @param assetId The id of the asset.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        uint256 assetId,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount) {
        if (assets[assetId].tokenType == TokenType.Native || assets[assetId].tokenType == TokenType.ERC721) {
            amount = share;
        } else {
            amount = share._toAmount(totalSupply[assetId], _tokenBalanceOf(assets[assetId]), roundUp);
        }
    }

    /// @dev Helper function represent the balance in `token` amount for a `user` for an `asset`.
    /// @param user The `user` to get the amount for.
    /// @param assetId The id of the asset.
    function amountOf(address user, uint256 assetId) external view returns (uint256 amount) {
        if (assets[assetId].tokenType == TokenType.Native || assets[assetId].tokenType == TokenType.ERC721) {
            amount = balanceOf[user][assetId];
        } else {
            amount = balanceOf[user][assetId]._toAmount(totalSupply[assetId], _tokenBalanceOf(assets[assetId]), false);
        }
    }

    function deposit(
        TokenType tokenType,
        address contractAddress,
        IStrategy strategy,
        uint256 tokenId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) public returns (uint256 amountOut, uint256 shareOut) {
        if (tokenType == TokenType.Native) {
            // If native token, register it as an ERC1155 asset (as that's what it is)
            return depositAsset(registerAsset(TokenType.ERC1155, address(this), strategy, tokenId), from, to, amount, share);
        } else {
            return depositAsset(registerAsset(tokenType, contractAddress, strategy, tokenId), from, to, amount, share);
        }
    }

    function depositETH(
        IStrategy strategy,
        address to,
        uint256 amount
    ) public payable returns (uint256 amountOut, uint256 shareOut) {
        return depositETHAsset(registerAsset(TokenType.ERC20, address(wrappedNative), strategy, 0), to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;
import "./interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/Base64.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringAddress.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/Domain.sol";
import "./ERC1155TokenReceiver.sol";
import "./ERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import "@boringcrypto/boring-solidity/contracts/BoringFactory.sol";

library YieldBoxRebase {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function _toShares(
        uint256 amount,
        uint256 totalShares_,
        uint256 totalAmount,
        bool roundUp
    ) internal pure returns (uint256 share) {
        // To prevent reseting the ratio due to withdrawal of all shares, we start with
        // 1 amount/1e8 shares already burned. This also starts with a 1 : 1e8 ratio which
        // functions like 8 decimal fixed point math. This prevents ratio attacks or inaccuracy
        // due to 'gifting' or rebasing tokens. (Up to a certain degree)
        totalAmount++;
        totalShares_ += 1e8;

        // Calculte the shares using te current amount to share ratio
        share = (amount * totalShares_) / totalAmount;

        // Default is to round down (Solidity), round up if required
        if (roundUp && (share * totalAmount) / totalShares_ < amount) {
            share++;
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function _toAmount(
        uint256 share,
        uint256 totalShares_,
        uint256 totalAmount,
        bool roundUp
    ) internal pure returns (uint256 amount) {
        // To prevent reseting the ratio due to withdrawal of all shares, we start with
        // 1 amount/1e8 shares already burned. This also starts with a 1 : 1e8 ratio which
        // functions like 8 decimal fixed point math. This prevents ratio attacks or inaccuracy
        // due to 'gifting' or rebasing tokens. (Up to a certain degree)
        totalAmount++;
        totalShares_ += 1e8;

        // Calculte the amount using te current amount to share ratio
        amount = (share * totalAmount) / totalShares_;

        // Default is to round down (Solidity), round up if required
        if (roundUp && (amount * totalShares_) / totalAmount < share) {
            amount++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/Base64.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "./interfaces/IYieldBox.sol";
import "./NativeTokenFactory.sol";

// solhint-disable quotes

contract YieldBoxURIBuilder {
    using BoringERC20 for IERC20;
    using Strings for uint256;
    using Base64 for bytes;

    struct AssetDetails {
        string tokenType;
        string name;
        string symbol;
        uint256 decimals;
    }

    function name(Asset calldata asset, string calldata nativeName) external view returns (string memory) {
        if (asset.strategy == NO_STRATEGY) {
            if (asset.tokenType == TokenType.ERC20) {
                IERC20 token = IERC20(asset.contractAddress);
                return token.safeName();
            } else if (asset.tokenType == TokenType.ERC1155) {
                return
                    string(abi.encodePacked("ERC1155:", uint256(uint160(asset.contractAddress)).toHexString(20), "/", asset.tokenId.toString()));
            } else {
                return nativeName;
            }
        } else {
            if (asset.tokenType == TokenType.ERC20) {
                IERC20 token = IERC20(asset.contractAddress);
                return string(abi.encodePacked(token.safeName(), " (", asset.strategy.name(), ")"));
            } else if (asset.tokenType == TokenType.ERC1155) {
                return
                    string(
                        abi.encodePacked(
                            string(
                                abi.encodePacked(
                                    "ERC1155:",
                                    uint256(uint160(asset.contractAddress)).toHexString(20),
                                    "/",
                                    asset.tokenId.toString()
                                )
                            ),
                            " (",
                            asset.strategy.name(),
                            ")"
                        )
                    );
            } else {
                return string(abi.encodePacked(nativeName, " (", asset.strategy.name(), ")"));
            }
        }
    }

    function symbol(Asset calldata asset, string calldata nativeSymbol) external view returns (string memory) {
        if (asset.strategy == NO_STRATEGY) {
            if (asset.tokenType == TokenType.ERC20) {
                IERC20 token = IERC20(asset.contractAddress);
                return token.safeSymbol();
            } else if (asset.tokenType == TokenType.ERC1155) {
                return "ERC1155";
            } else {
                return nativeSymbol;
            }
        } else {
            if (asset.tokenType == TokenType.ERC20) {
                IERC20 token = IERC20(asset.contractAddress);
                return string(abi.encodePacked(token.safeSymbol(), " (", asset.strategy.name(), ")"));
            } else if (asset.tokenType == TokenType.ERC1155) {
                return string(abi.encodePacked("ERC1155", " (", asset.strategy.name(), ")"));
            } else {
                return string(abi.encodePacked(nativeSymbol, " (", asset.strategy.name(), ")"));
            }
        }
    }

    function decimals(Asset calldata asset, uint8 nativeDecimals) external view returns (uint8) {
        if (asset.tokenType == TokenType.ERC1155) {
            return 0;
        } else if (asset.tokenType == TokenType.ERC20) {
            IERC20 token = IERC20(asset.contractAddress);
            return token.safeDecimals();
        } else {
            return nativeDecimals;
        }
    }

    function uri(
        Asset calldata asset,
        NativeToken calldata nativeToken,
        uint256 totalSupply,
        address owner
    ) external view returns (string memory) {
        AssetDetails memory details;
        if (asset.tokenType == TokenType.ERC1155) {
            // Contracts can't retrieve URIs, so the details are out of reach
            details.tokenType = "ERC1155";
            details.name = string(
                abi.encodePacked("ERC1155:", uint256(uint160(asset.contractAddress)).toHexString(20), "/", asset.tokenId.toString())
            );
            details.symbol = "ERC1155";
        } else if (asset.tokenType == TokenType.ERC20) {
            IERC20 token = IERC20(asset.contractAddress);
            details = AssetDetails("ERC20", token.safeName(), token.safeSymbol(), token.safeDecimals());
        } else {
            // Native
            details.tokenType = "Native";
            details.name = nativeToken.name;
            details.symbol = nativeToken.symbol;
            details.decimals = nativeToken.decimals;
        }

        string memory properties = string(
            asset.tokenType != TokenType.Native
                ? abi.encodePacked(',"tokenAddress":"', uint256(uint160(asset.contractAddress)).toHexString(20), '"')
                : abi.encodePacked(',"totalSupply":', totalSupply.toString(), ',"fixedSupply":', owner == address(0) ? "true" : "false")
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    abi
                        .encodePacked(
                            '{"name":"',
                            details.name,
                            '","symbol":"',
                            details.symbol,
                            '"',
                            asset.tokenType == TokenType.ERC1155 ? "" : ',"decimals":',
                            asset.tokenType == TokenType.ERC1155 ? "" : details.decimals.toString(),
                            ',"properties":{"strategy":"',
                            uint256(uint160(address(asset.strategy))).toHexString(20),
                            '","tokenType":"',
                            details.tokenType,
                            '"',
                            properties,
                            asset.tokenType == TokenType.ERC1155 ? string(abi.encodePacked(',"tokenId":', asset.tokenId.toString())) : "",
                            "}}"
                        )
                        .encode()
                )
            );
    }
}