pragma ton-solidity >= 0.35;
pragma AbiHeader expire;

import 'game_object.sol';
import 'battle_unit.sol';

contract baseStation is gameObject {

    // Список юнитов на этой базе
    address[] units;
    
	
    // При создании задать кол-во жизней и защиту
	constructor(int _lives, uint _defence) gameObject(_lives, _defence) public {
        require(tvm.pubkey() != 0, 101);
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();
    }

    // Посмотреть список юнитов базы
    function getUnits() public view returns (address[]) {
        return units;
    }

    // Добавить юнит в список юнитов. Вызывает сам юнит.
    function addUnit() external {
        tvm.accept();
        address unit_address = msg.sender;
        units.push(unit_address);
    }	

    // Удалить юнит из списка. Вызывает сам юнит.
    function deleteUnit(address _unit_address) external {
        tvm.accept();

        for (uint index = 0; index < units.length; index++) {
            if (units[index] == _unit_address) {
                delete units[index];

                // Сдвиг массива, чтобы не оставить пустых мест
                for (uint k = index; k < units.length; k++) {
                    units[k] = units[k+1];
                    units.pop();
                }
            }
        }      
    }	

    // Метод обработки умирания
    function lastThingBeforeDeath(address attacker) internal override {
        tvm.accept();

        // вызвать deathBaseDestroyed(), чтобы каждый юнит этой базы выпилился
        for (uint index = 0; index < units.length; index++) {
                battleUnit(units[index]).deathBaseDestroyed(attacker);               
                delete units[index];                
        }

        sendAllMoneyAndDestroy(attacker);
    } 
}