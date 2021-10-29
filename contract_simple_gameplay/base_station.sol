pragma ton-solidity >= 0.35;
pragma AbiHeader expire;

import 'game_object.sol';


// Контракт "Базовая станция" (Родитель "Игровой объект")
// - получить силу защиты
// - Добавить военный юнит (добавляет адрес военного юнита в массив или другую структуру данных)
// - Убрать военный юнит
// - обработка гибели [вызов метода самоуничтожения + вызов метода смерти для каждого из военных юнитов базы]

contract baseStation is gameObject {

    // Container for units belonging to this base
    address[] units;
    
	
    // Lives and defence of a base station are initialized in a constructor while creating
	constructor(int _lives, uint _defence) gameObject(_lives, _defence) public {
        require(tvm.pubkey() != 0, 101);
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();
    }

    function getLives() public view returns (int) {
        return lives;
    }

    function getDefence() public view returns (uint) {
        return defence;
    }

    function addUnit(address _unit_address) external {
        tvm.accept();
        units.push(_unit_address);
        tvm.log(format("Unit added: {}", _unit_address));
    }	

    function deleteUnit(address _unit_address) external {
        tvm.accept();
        //delete units[_unit_address];
        tvm.log(format("Unit added: {}", _unit_address));
    }	
}