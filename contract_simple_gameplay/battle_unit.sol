// Контракт "Военный юнит" (Родитель "Игровой объект")
// - конструктор принимает "Базовая станция" и вызывает метод "Базовой Станции" "Добавить военный юнит" а у себя сохраняет адрес "Базовой станции"
// - атаковать (принимает ИИО [его адрес])
// - получить силу атаки
// - получить силу защиты
// - обработка гибели [вызов метода самоуничтожения + убрать военный юнит из базовой станции]
// - смерть из-за базы (проверяет, что вызов от родной базовой станции только будет работать) [вызов метода самоуничтожения]

pragma ton-solidity >= 0.35;
pragma AbiHeader expire;

import 'game_object.sol';
import 'base_station.sol' as base;

// наследует gameObject, оттуда вызывает getDamage()
contract battleUnit is gameObject {
	
	//свойства юнита, описание и создание экземпляра	
	struct structUnit {
        address unitAddress;
        string unitType;
        uint attackPower;
		address baseStationAddress;
    }
	structUnit thisUnit;

	// в конструкторе передаем колво жизней, защиту, атаку, 
	// а также объект базовой станции (затем используем ее метод addUnit())
	constructor(int _lives, uint _defence, uint _attack_power, base.baseStation _base1) gameObject(_lives, _defence) public {
        require(tvm.pubkey() != 0, 101);
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();

		thisUnit = structUnit(address(tvm.pubkey()), "none", _attack_power, _base1);
		_base1.addUnit(address(tvm.pubkey()));
		logtvm("Unit constructed");
    }

	function attackUnit(address victim) public {
		gameObject(victim).getDamage(thisUnit.attackPower);
		logtvm(format("attacked unit {} with {} power", victim, thisUnit.attackPower));
	}

	function playDead(){
		
	}

}