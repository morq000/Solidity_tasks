
pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

import 'interface_game_object.sol';

contract gameObject is IgameObject {

    int internal lives;
    uint internal defence;

//   Контракт "Игровой объект" (Реализует "Интерфейс Игровой объект")
// - получить силу защиты
// - принять атаку [адрес того, кто атаковал можно получить из msg] external
// - проверить, убит ли объект (private)
// - обработка гибели [вызов метода самоуничтожения (сл в списке)]
// - отправка всех денег по адресу и уничтожение
// - свойство с начальным количеством жизней (например, 5)

// Первый signer (игрок 1) деплоит контракт Базовой станции. У него есть база.
// Деплоит контракт "Воина", "Лучника" - у него на базе есть теперь пара воинов
// Второй signer (игрок 2) деплоит контракт Базовой станции. У него есть база.
// Деплоит контракт "Воина", "Лучника" - у него на базе есть теперь пара воинов
// Дальше игроки могут "сражаться".
// Игрок 2 может попросить кого-то из военных юнитов атаковать кого-то у первого игрока.
// В случает атаки, тот кого атакует "принимает атаку". Получает урон (сила атаки - сила защиты). Если дошло до нуля, то умирает.
// При "смерти" все кристаллы отдаются на адрес юнита, который его убил. А если умирает "Базовая станция", то и все воины этой базовой станции тоже от этого умирают и отдают все свои кристаллы.
    
    constructor(int _lives, uint _defence) public {
        require(tvm.pubkey() != 0, 101);
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();

        // Check that game unit will be given at least 1 life while spawn
        // require(_lives > int(1), 166, "New unit has to have at least 1 life");

        defence = _defence;
        lives = _lives;

    }

    function setDefence(uint _defence) external {
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();
        defence = _defence;
    }

    function getDamage(uint _attackPower) external override {
        tvm.accept();

        uint damage;

        // Save attacker address to send money if unit dies
        address attacker = msg.sender;

        if (_attackPower > defence) {

            // Case unit got damaged
            damage = _attackPower - defence;
            lives -= int(damage);
            
            // check if unit got killed by damage
            if (checkIfKilled()) {
                // Call function to process unit death
                lastThingBeforeDeath(attacker);
            }
        }    
    }

    function checkIfKilled() internal returns (bool) {
        tvm.accept();
        if (lives <= 0) {
            return true;
        } else {
            return false;
        }
    }

    function lastThingBeforeDeath(address attacker) virtual internal {
    }

    function sendAllMoneyAndDestroy(address attacker) internal pure {
        tvm.accept();
        // Send all money to killer and destroy contract
        attacker.transfer(1, true, 160);
    }

    function getLives() public view returns (int) {
        return lives;
    }

    function getDefence() public view returns (uint) {
        return defence;
    }
}
