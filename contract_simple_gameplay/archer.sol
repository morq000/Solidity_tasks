// Контракт "Лучник" (родитель "Военный юнит")
// - получить силу атаки
// - получить силу защиты

// p1 0:e68e3c6ff3cbe33509bad8ee402f36be753599c443a8b925fcc513160e8fc9ac

pragma ton-solidity >= 0.35;
pragma AbiHeader expire;

import "battle_unit.sol";

contract warrior is battleUnit {

	constructor(int _lives, uint _defence, uint _attack_power, base.baseStation _base1) battleUnit(_lives, _defence, _attack_power, _base1) public {
		thisUnit.unitType = "Archer";
	}
}