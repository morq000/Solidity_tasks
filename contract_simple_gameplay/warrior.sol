pragma ton-solidity >= 0.35;
pragma AbiHeader expire;

import "battle_unit.sol";

contract warrior is battleUnit {

	constructor(int _lives, uint _defence, uint _attack_power, base.baseStation _base1) battleUnit(_lives, _defence, _attack_power, _base1) public {
		thisUnit.unitType = "Warrior";
	}
}