pragma ton-solidity >= 0.35;
pragma AbiHeader expire;

import 'game_object.sol';
import 'battle_unit.sol';


// Контракт "Базовая станция" (Родитель "Игровой объект")
// - получить силу защиты
// - Добавить военный юнит (добавляет адрес военного юнита в массив или другую структуру данных)
// - Убрать военный юнит
// - обработка гибели [вызов метода самоуничтожения + вызов метода смерти для каждого из военных юнитов базы]

// p1 0:b03816e8a58ef9a4dad7c2547878a0ba1503214c223d3dc1a1802c541dca60ab

contract baseStation is gameObject {

    // Container for units belonging to this base
    address[] units;
    
	
    // Lives and defence of a base station are initialized in a constructor while creating
	constructor(int _lives, uint _defence) gameObject(_lives, _defence) public {
        require(tvm.pubkey() != 0, 101);
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();
    }

    function getUnits() public view returns (address[]) {
        return units;
    }

    function addUnit() external {
        tvm.accept();
        address unit_address = msg.sender;
        units.push(unit_address);
    }	

    function deleteUnit(address _unit_address) external {
        tvm.accept();

        for (uint index = 0; index < units.length; index++) {
            if (units[index] == _unit_address) {
                delete units[index];

                // Move array to delete 0:0000... value
                for (uint k = index; k < units.length; k++) {
                    units[k] = units[k+1];
                    units.pop();
                }
            }
        }      
    }	

    function lastThingBeforeDeath(address attacker) internal override {
        tvm.accept();

        // call deathBaseDestroyed() for every unit in array
        for (uint index = 0; index < units.length; index++) {
                battleUnit(units[index]).deathBaseDestroyed(attacker);               
                delete units[index];                
        }

        sendAllMoneyAndDestroy(attacker);
    } 
}