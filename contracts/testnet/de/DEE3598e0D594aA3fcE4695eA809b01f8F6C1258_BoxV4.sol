// contracts/BoxV4.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BoxV2.sol";

contract BoxV4 is BoxV2 {
    string private name;

    event NameChanged(string name);

    function setName(string memory _name) public {
        name = _name;
        emit NameChanged(name);
    }

    function getName() public view returns (string memory) {
        //   return string(abi.encodePacked("Name: ",name));
        // return string(bytes.concat("Name: ", bytes(name)));

        // Solidity 0.8.12   String concatenation
        return string.concat("Name: ", name);
    }
}

// contracts/BoxV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Box.sol";

contract BoxV2 is Box {
    // Increments the stored value by 1
    function increment() public {
        store(retrieve() + 1);
    }
}

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Box {
    uint256 private value;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}