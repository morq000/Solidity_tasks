
pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

import 'interface_game_object.sol';

// Класс "игровой объект", реализующий интерфейс "игровой объект"
contract gameObject is IgameObject {

    // переменные, хранящие атаку и защиту юнита
    int internal lives;
    uint internal defence;

    // при создании экзепляра задаем ему кол-во жизней и защиту
    constructor(int _lives, uint _defence) public {
        require(tvm.pubkey() != 0, 101);
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();

        // Check that game unit will be given at least 1 life while spawn
        require(_lives > int(1), 166, "New unit has to have at least 1 life");

        defence = _defence;
        lives = _lives;

    }

    // Изменить параметр "защита" юнита
    function setDefence(uint _defence) external {
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();
        defence = _defence;
    }

    // Переопределение метода интерфейса
    function getDamage(uint _attackPower) external override {
        tvm.accept();

        uint damage;

        // Сохранение адреса атакующего
        address attacker = msg.sender;

        // Если атака больше защиты, юнит получает урон
        if (_attackPower > defence) {

            damage = _attackPower - defence;
            lives -= int(damage);
            
            // Вызов метода проверки, если юнит убит
            if (checkIfKilled()) {
                // Вызов метода обработки смерти
                lastThingBeforeDeath(attacker);
            }
        }    
    }

    // Метод проверки если юнит убит
    function checkIfKilled() internal returns (bool) {
        tvm.accept();
        if (lives <= 0) {
            return true;
        } else {
            return false;
        }
    }

    // Абстрактный метод обработки смерти
    function lastThingBeforeDeath(address attacker) virtual internal {
    }

    // Метод переслать деньги и уничтожить контакт
    function sendAllMoneyAndDestroy(address attacker) internal pure {
        tvm.accept();
        attacker.transfer(1, true, 160);
    }

    // Геттер чтобы узнать кол-во жизней            
    function getLives() public view returns (int) {
        return lives;
    }

    // Геттер чтобы узнать защиту
    function getDefence() public view returns (uint) {
        return defence;
    }
}
