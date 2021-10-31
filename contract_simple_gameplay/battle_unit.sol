pragma ton-solidity >= 0.35;
pragma AbiHeader expire;

import 'game_object.sol';
import 'base_station.sol' as base;

// наследует gameObject, оттуда вызывает getDamage()
contract battleUnit is gameObject {
	
	//Структура "свойства юнита", описание и создание экземпляра	
	struct structUnit {
        address unitAddress;
        string unitType;
        uint attackPower;
		address baseStationAddress;
    }
	structUnit public thisUnit;

	// в конструкторе передаем колво жизней, защиту, атаку, 
	// а также объект базовой станции (чтобы затем использовать ее метод addUnit())
	constructor(int _lives, uint _defence, uint _attack_power, base.baseStation _base1) gameObject(_lives, _defence) public {
        require(tvm.pubkey() != 0, 101);
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();

		thisUnit = structUnit(address(this), "none", _attack_power, _base1);

		// Сохраняем адрес базовой станции в структуру свойств юнита
		thisUnit.baseStationAddress = _base1;
		
		// Вызов метода базовой станции чтобы добавить юнит в список юнитов базовой станции
		_base1.addUnit();	
    }

	// Атаковать другой юнит
	function attackUnit(IgameObject victimAddress) public {
		tvm.accept();
		victimAddress.getDamage(thisUnit.attackPower);
	}

	// Override чтобы сделать кастомную последовательность умирания
	function lastThingBeforeDeath(address attacker) internal override {
		tvm.accept();

		// Метод базовой станции, к которой приписан юнит. Удаляет его из списка юнитов базовой станции.
		base.baseStation(thisUnit.baseStationAddress).deleteUnit(thisUnit.unitAddress);
		
		// Отправить кристаллы и уничтожить контракт
        sendAllMoneyAndDestroy(attacker);
    }

	// база, к которой приписан юнит, вызывает этот метод в случае своей смерти
	function deathBaseDestroyed(address attacker) external returns (bool) {
		tvm.accept();
		if (msg.sender == thisUnit.baseStationAddress) {

			// Отправить кристаллы и уничтожить контракт
        	sendAllMoneyAndDestroy(attacker);

		}
		else {
			return false;
		}
	}

}