// Контракт "Воин" (родитель "Военный юнит")
// - получить силу атаки
// - получить силу защиты

// p1 0:2e70cbc8061c37cde89c68314112ee06bff0419f545becce35616d1f140f05b7
// p2 0:fe84a1740e382de91eae93b866ed313e652cc1b15c9e22993e74a3b4b1bd2636

pragma ton-solidity >= 0.35;
pragma AbiHeader expire;

import "battle_unit.sol";

contract warrior is battleUnit {

	constructor(int _lives, uint _defence, uint _attack_power, base.baseStation _base1) battleUnit(_lives, _defence, _attack_power, _base1) public {
		thisUnit.unitType = "Warrior";
	}
}