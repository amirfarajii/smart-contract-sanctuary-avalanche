// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.5;

library NormalLib {
    function libDo(uint256 n) pure external returns (uint256) {
        return n * 2;
    }
}

library ConstructorLib {
    function libDo(uint256 n) pure external returns (uint256) {
        return n * 4;
    }
}

contract OnlyNormalLib {

    string message = "0xDc4Ffc46389E95c8df14A5F6bb2a0A93639193081";

    constructor() {}

    function getNumber(uint256 aNumber) pure public returns (uint256) {
        return NormalLib.libDo(aNumber);
    }
}

contract OnlyConstructorLib {

    uint256 public someNumber;
    string message = "0xDc4Ffc46389E95c8df14A5F6bb2a0A93639193082";

    constructor(uint256 aNumber) {
        someNumber = ConstructorLib.libDo(aNumber);
    }
}

contract BothLibs {

    uint256 public someNumber;
    string message = "0xDc4Ffc46389E95c8df14A5F6bb2a0A93639193083";

    constructor(uint256 aNumber) {
        someNumber = ConstructorLib.libDo(aNumber);
    }

    function getNumber(uint256 aNumber) pure public returns (uint256) {
        return NormalLib.libDo(aNumber);
    }
}