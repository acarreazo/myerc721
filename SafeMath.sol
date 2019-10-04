pragma solidity ^0.5.10;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * @dev source: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/v1.6.0/contracts/math/SafeMath.sol
 * @notice Basic implementation of SafeMath Contract from OpenZeppelin
 */
contract SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function safeMul(uint256 a, uint256 b)
        private
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function safeDiv(uint256 a, uint256 b)
        private
        pure
        returns (uint256)
    {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function safeSub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function safeAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}
