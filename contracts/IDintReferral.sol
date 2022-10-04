// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IDintReferral {
    /**
     * @dev Record referral.
     */
    function registerTipRecipient(address user, address referrer) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}
