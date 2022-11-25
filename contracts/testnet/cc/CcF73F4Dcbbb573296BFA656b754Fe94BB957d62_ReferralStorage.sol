// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

contract Governable {
    address public gov;

    event SetGov(address prevGov, address nextGov);

    error Unauthorized(address msgSender, string role);

    constructor() {
        _setGov(msg.sender);
    }

    modifier onlyGov() {
        if (msg.sender != gov) {
            revert Unauthorized(msg.sender, "GOV");
        }
        _;
    }

    function setGov(address _gov) external onlyGov {
        _setGov(_gov);
    }

    function _setGov(address _gov) internal {
        address prevGov = gov;
        gov = _gov;

        emit SetGov(prevGov, _gov);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../referral/IReferralStorage.sol";
import "../gov/Governable.sol";

contract ReferralStorage is IReferralStorage, Governable {
    uint256 public constant BASIS_POINTS = 10000;

    mapping (address => uint256) public override referrerDiscountShares; // to override default value in tier
    mapping (address => uint256) public override referrerTiers; // link between user <> tier
    mapping (uint256 => ReferralTier.Props) public override tiers;

    mapping (address => bool) public isHandler;

    mapping (bytes32 => address) public override codeOwners;
    mapping (address => bytes32) public override traderReferralCodes;

    event SetHandler(address handler, bool isActive);
    event SetTraderReferralCode(address account, bytes32 code);
    event SetTier(uint256 tierId, uint256 totalRebate, uint256 discountShare);
    event SetReferrerTier(address referrer, uint256 tierId);
    event SetReferrerDiscountShare(address referrer, uint256 discountShare);
    event RegisterCode(address account, bytes32 code);
    event SetCodeOwner(address account, address newAccount, bytes32 code);
    event GovSetCodeOwner(bytes32 code, address newAccount);

    modifier onlyHandler() {
        require(isHandler[msg.sender], "ReferralStorage: forbidden");
        _;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
        emit SetHandler(_handler, _isActive);
    }

    function setTier(uint256 _tierId, uint256 _totalRebate, uint256 _discountShare) external override onlyGov {
        require(_totalRebate <= BASIS_POINTS, "ReferralStorage: invalid totalRebate");
        require(_discountShare <= BASIS_POINTS, "ReferralStorage: invalid discountShare");

        ReferralTier.Props memory tier = tiers[_tierId];
        tier.totalRebate = _totalRebate;
        tier.discountShare = _discountShare;
        tiers[_tierId] = tier;
        emit SetTier(_tierId, _totalRebate, _discountShare);
    }

    function setReferrerTier(address _referrer, uint256 _tierId) external override onlyGov {
        referrerTiers[_referrer] = _tierId;
        emit SetReferrerTier(_referrer, _tierId);
    }

    function setReferrerDiscountShare(uint256 _discountShare) external {
        require(_discountShare <= BASIS_POINTS, "ReferralStorage: invalid discountShare");

        referrerDiscountShares[msg.sender] = _discountShare;
        emit SetReferrerDiscountShare(msg.sender, _discountShare);
    }

    function setTraderReferralCode(address _account, bytes32 _code) external override onlyHandler {
        _setTraderReferralCode(_account, _code);
    }

    function setTraderReferralCodeByUser(bytes32 _code) external {
        _setTraderReferralCode(msg.sender, _code);
    }

    function registerCode(bytes32 _code) external {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");
        require(codeOwners[_code] == address(0), "ReferralStorage: code already exists");

        codeOwners[_code] = msg.sender;
        emit RegisterCode(msg.sender, _code);
    }

    function setCodeOwner(bytes32 _code, address _newAccount) external {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");

        address account = codeOwners[_code];
        require(msg.sender == account, "ReferralStorage: forbidden");

        codeOwners[_code] = _newAccount;
        emit SetCodeOwner(msg.sender, _newAccount, _code);
    }

    function govSetCodeOwner(bytes32 _code, address _newAccount) external override onlyGov {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");

        codeOwners[_code] = _newAccount;
        emit GovSetCodeOwner(_code, _newAccount);
    }

    function getTraderReferralInfo(address _account) external override view returns (bytes32, address) {
        bytes32 code = traderReferralCodes[_account];
        address referrer;
        if (code != bytes32(0)) {
            referrer = codeOwners[code];
        }
        return (code, referrer);
    }

    function _setTraderReferralCode(address _account, bytes32 _code) private {
        traderReferralCodes[_account] = _code;
        emit SetTraderReferralCode(_account, _code);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ReferralTier.sol";

interface IReferralStorage {
    function codeOwners(bytes32 _code) external view returns (address);
    function traderReferralCodes(address _account) external view returns (bytes32);
    function referrerDiscountShares(address _account) external view returns (uint256);
    function referrerTiers(address _account) external view returns (uint256);
    function getTraderReferralInfo(address _account) external view returns (bytes32, address);
    function setTraderReferralCode(address _account, bytes32 _code) external;
    function setTier(uint256 _tierId, uint256 _totalRebate, uint256 _discountShare) external;
    function setReferrerTier(address _referrer, uint256 _tierId) external;
    function govSetCodeOwner(bytes32 _code, address _newAccount) external;

    function tiers(uint256 _tierLevel) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library ReferralTier {
    struct Props {
        uint256 totalRebate;
        uint256 discountShare;
    }
}