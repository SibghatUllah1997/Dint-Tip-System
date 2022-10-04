// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IDintReferral.sol";

contract Dint is IDintReferral, Ownable, AccessControl {
    using SafeERC20 for IERC20;


    mapping(address => bool) whitelistedAddresses;
    mapping(address => bool) public operators;
    mapping(address => address) public referrers; // user address => referrer address
    mapping(address => uint256) public referralsCount; // referrer address => referrals count
    // mapping(address => uint256) public totalReferralCommissions; // referrer address => total referral commissions

    event ReferralRecorded(address indexed user, address indexed referrer);
    event ReferralCommissionRecorded(
        address indexed referrer,
        uint256 commission
    );
    event OperatorUpdated(address indexed operator, bool indexed status);
    event UpdateWhitelistAddress(address indexed operator, bool indexed status);
    event GrantTip(address indexed beneficiary, address indexed user, address indexed tokenAddress, uint256 beneficiaryAmount);


    bytes32 public constant Operator_ROLE = keccak256("Operator_ROLE");
    address public dintAddress;
    // Modifier for Operator roles
    modifier onlyOperator() {
        require(
            hasRole(Operator_ROLE, _msgSender()),
            "Operator: Not a Operator role"
        );
        _;
    }

    function registerTipRecipient(address _user, address _referrer)
        public
        override
        onlyOperator
    {
        if (
            _user != address(0) &&
            _referrer != address(0) &&
            _user != _referrer &&
            referrers[_user] == address(0)
        ) {
            referrers[_user] = _referrer;
            referralsCount[_referrer] += 1;
            emit ReferralRecorded(_user, _referrer);
        }
    }

    constructor(address _dintAddress)  {
        _setupRole(Operator_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        dintAddress = _dintAddress;

    }

    // Get the referrer address that referred the user
    function getReferrer(address _user) public view override returns (address) {
        return referrers[_user];
    }

    // Update the status of the operator
    function updateOperator(address _operator, bool _status)
        external
        onlyOwner
    {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }

    function addInWhiteList(address _user)
        external
        onlyOperator
    {
        require(operators[_user], "Already WhiteListed");
        operators[_user] = true;
        emit UpdateWhitelistAddress(_user, true);
    }

    function removeWhiteList(address _user)
        external
        onlyOperator
    {
        require(!operators[_user], "Not White Listed");

        operators[_user] = false;
        emit UpdateWhitelistAddress(_user, false);
    }

    function isWhiteListed(address _user)
        public 
        view
        returns(bool)
    {
        return operators[_user];
    }

    // has Operator role
    function isOperator() external view returns (bool) {
        if (hasRole(Operator_ROLE, msg.sender)) return true;
        return false;
    }

    function grantTip(address _beneficiary, uint256 _amount, address _tokenAddress) public {
        uint256 _dintPercentage;
        uint256 _beneficiaryPercentage;
        uint256 _referralPercentage;

        require(operators[_beneficiary], "User is not registered");
        if(referrers[_beneficiary] != address(0x00)) {
            _dintPercentage = (_amount*15)/100;
            _referralPercentage = (_amount*5)/100;
            _beneficiaryPercentage = _amount-_dintPercentage-_referralPercentage;
            IERC20(_tokenAddress).safeTransfer(dintAddress,_dintPercentage);
            IERC20(_tokenAddress).safeTransfer(referrers[_beneficiary],_referralPercentage);
            IERC20(_tokenAddress).safeTransfer(_beneficiary,_beneficiaryPercentage);
        }
        else if(referrers[_beneficiary] == address(0x00)){
            _dintPercentage = (_amount*20)/100;
            _beneficiaryPercentage = _amount-_dintPercentage;
            IERC20(_tokenAddress).safeTransfer(dintAddress,_dintPercentage);
            IERC20(_tokenAddress).safeTransfer(_beneficiary,_beneficiaryPercentage);

        }

        emit  GrantTip(_beneficiary, msg.sender, _tokenAddress, _dintPercentage-_beneficiaryPercentage-_referralPercentage);

    }

}
