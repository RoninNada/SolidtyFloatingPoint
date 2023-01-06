// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

/**
 * @title Floating Point
 * @author RoninNada
 *
 * Library that defines a number that can support decimal places, & perform math
 */
library FloatingPoint {
    using SafeMath for uint256;

    // ============ Structs ============

    struct FP256 {
        uint256 value;
        uint256 decimalValue;
        uint8 decimals;
        uint256 rawValue;
    }

    function getBase(uint8 _decimals) internal pure returns (uint256) {
        return 10**_decimals;
    }

    function zero(uint8 _decimals) internal pure returns (FP256 memory) {
        return FP256({
            value: uint256(0),
            decimalValue: uint256(0),
            decimals: _decimals,
            rawValue: uint256(0)
        });
    }

    function one(uint8 _decimals) internal pure returns (FP256 memory) {
        uint256 base = getBase(_decimals);
        return FP256({
            value: base,
            decimalValue: 0,
            decimals: _decimals,
            rawValue: base
        });
    }

    function set(uint256 _value, uint256 _decimalValue, uint8 _decimals) internal pure returns (FP256 memory) {
        return FP256({
            value: _value,
            decimalValue: _decimalValue,
            decimals: _decimals,
            rawValue: _value
        });        
    }

    function fromUint(uint256 a, uint8 _decimals) internal pure returns (FP256 memory) {

        uint256 base = getBase(_decimals);
        uint256 maxValue = base - 1;
        
        if(a > maxValue) {
            uint256 _value = a.div(base);

            return FP256({
                value: _value,
                decimalValue: a.sub(_value.mul(base)),
                decimals: _decimals,
                rawValue: a
            }); 
        } else {
            return FP256({
                value: 0,
                decimalValue: a,
                decimals: _decimals,
                rawValue: a
            });              
        }
    }

    function ratio(
        uint256 a,
        uint256 b,
        uint8 _decimals) internal pure returns (FP256 memory) {

        return fromUint(getPartial(a, 10**_decimals, b), _decimals);
    }

    function add(
        FP256 memory self,
        uint256 b) internal pure returns (FP256 memory) {

        return fromUint(self.rawValue.add(b), self.decimals);
    }

    function addDecimal(
        FP256 memory self,
        FP256 memory b) internal pure returns (FP256 memory) {

        require(self.decimals == b.decimals, "Addition: Different Decimals Between Numbers");

        return fromUint(self.rawValue.add(b.rawValue), self.decimals); 
    }

    function sub(
        FP256 memory self,
        uint256 b) internal pure returns (FP256 memory) {

        return fromUint(self.rawValue.sub(b), self.decimals);
    }

    function subDecimal(
        FP256 memory self,
        FP256 memory b) internal pure returns (FP256 memory) {

        require(self.decimals == b.decimals, "Subtract: Different Decimals Between Numbers");
        return fromUint(self.rawValue.sub(b.rawValue), self.decimals); 
    }

    function mul(
        FP256 memory self,
        uint256 b) internal pure returns (FP256 memory) {

        return fromUint(self.rawValue.mul(b), self.decimals);
    }

    function div(
        FP256 memory self,
        uint256 b) internal pure returns (FP256 memory) {

        return fromUint(self.rawValue.div(b), self.decimals);
    }

    function divRounding(
        FP256 memory self,
        uint256 b) internal pure returns (FP256 memory) {

        uint256 quotient = self.rawValue.div(b);
        uint256 remainder = self.rawValue % b;
        if(remainder == 0) {
            return fromUint(quotient, self.decimals);
        } else {
            uint256 fractional = remainder * 10 / b;
            uint8 fractionalDigits = numDigits(fractional); 
            if(fractionalDigits < self.decimals) {
                return set(quotient, fractional * (10**(self.decimals - fractionalDigits)), self.decimals);
            } else if(fractionalDigits < self.decimals) {
                return set(quotient, fractional / (10**(self.decimals - fractionalDigits)), self.decimals);
            } else {
                return set(quotient, fractional, self.decimals);
            }                       
        }       
    }

    function pow(
        FP256 memory self,
        uint256 b) internal pure returns (FP256 memory) {
        if (b == 0) {
            fromUint(1, self.decimals);
        }

        uint256 temp = self.rawValue;
        for (uint256 i = 1; i < b; i++) {
            temp = temp.mul(self.rawValue);
        }

        return fromUint(temp, self.decimals);
    }

    function toUint(FP256 memory self) internal pure returns (uint256) {
        return self.value.mul(10**self.decimals).add(self.decimalValue);
    }

    function equals(FP256 memory self, FP256 memory b) internal pure returns (bool) {
        require(self.decimals == b.decimals, "Equals: Different Decimals Between Numbers");
        return self.value == b.value && self.decimalValue == b.decimalValue;
    }

    function greaterThan(FP256 memory self, FP256 memory b) internal pure returns (bool) {
        require(self.decimals == b.decimals, "> Different Decimals Between Numbers");
        return compareTo(self, b) == 2;
    }

    function lessThan(FP256 memory self, FP256 memory b) internal pure returns (bool) {
        require(self.decimals == b.decimals, "< Different Decimals Between Numbers");
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(FP256 memory self, FP256 memory b) internal pure returns (bool) {
        require(self.decimals == b.decimals, ">= Different Decimals Between Numbers");
        return compareToDifferent(self, b) > 0;
    }

    function lessThanOrEqualTo(FP256 memory self, FP256 memory b) internal pure returns (bool) {
        require(self.decimals == b.decimals, "<= Different Decimals Between Numbers");
        return compareToDifferent(self, b) < 2;
    }

    function greaterThanDifferent(FP256 memory self, FP256 memory b) internal pure returns (bool) {
        return compareToDifferent(self, b) == 2;
    }

    function lessThanDifferent(FP256 memory self, FP256 memory b) internal pure returns (bool) {
        return compareToDifferent(self, b) == 0;
    }

    function greaterThanOrEqualToDifferent(FP256 memory self, FP256 memory b) internal pure returns (bool) {
        return compareToDifferent(self, b) > 0;
    }

    function lessThanOrEqualToDifferent(FP256 memory self, FP256 memory b) internal pure returns (bool) {
        return compareToDifferent(self, b) < 2;
    }

    function compareTo(
        FP256 memory a,
        FP256 memory b) private pure returns (uint256) {
            require(a.decimals == b.decimals);
            if (a.rawValue == b.rawValue) {
                return 1;
            }
            return a.rawValue > b.rawValue ? 2 : 0;                
        }

    function compareToDifferent(
        FP256 memory a,
        FP256 memory b) private pure returns (uint256) {
        if (a.value == b.value) {
            if(a.decimalValue == b.decimalValue) {
                return 1;
            } else {
                return a.decimalValue > b.decimalValue ? 2: 0;
            }
        }
        return a.value > b.value ? 2 : 0;
    }

    function isZero(FP256 memory self) internal pure returns (bool) {
        return self.rawValue == 0;
    } 

    function isPartial(FP256 memory self) internal pure returns (bool) {
        return self.value == 0 && self.decimalValue > 0;
    } 

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator) private pure returns (uint256) {

        return target.mul(numerator).div(denominator);
    }  

    function numDigits(uint256 number) private pure returns (uint8) {
        uint8 digits = 0;
        while (number != 0) {
            number /= 10;
            digits++;
        }
        return digits;
    } 
}
