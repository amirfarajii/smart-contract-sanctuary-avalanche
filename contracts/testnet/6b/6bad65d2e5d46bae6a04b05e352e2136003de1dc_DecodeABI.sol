/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract DecodeABI {

    function decode(bytes memory data)
        public
        pure
        returns (
            string memory _str1
        )
    {
        (_str1) = abi.decode(data, (string));
    }

}