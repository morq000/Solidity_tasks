
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
        // require(lives > int(1), 166, "New unit has to have at least 1 life");

        defence = _defence;
        lives = _lives;

    }

    function setDefence(uint _defence) external {
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();
        defence = _defence;
        tvm.log(format("New defence value is {}", defence));
    }

    function getDamage(uint _attackPower) external override {
        uint damage;

        // Save attacker address to send money if unit dies
        address attacker = msg.sender;
        tvm.log(format("Attacker address: {}", attacker));

        if (_attackPower > defence) {

            // Case unit got damaged
            damage = _attackPower - defence;
            lives -= int(damage);
            tvm.log(format("Unit got damaged by {}, lives remaining: {}", damage, lives));

            // check if unit got killed by damage
            if (checkIfKilled()) {
            tvm.log("Unit lost all lives and got killed");

            // Call function to destroy contract and send all funds to the attacker
            playDead(attacker);
            }
        }
        else {
            tvm.log("Unit defence is bigger than attack value. Unit remains untouched.");
        }

        
    }

    function checkIfKilled() private view returns (bool) {
        if (lives <= 0) {
            return true;
        } else {
            return false;
        }
    }

    function playDead(address attacker) private pure {
        tvm.accept();
        // Send all money to killer and destroy contract
        attacker.transfer(1, true, 160);
        tvm.log("Contract destroyed and all funds sent to the attacker");
    }
}
