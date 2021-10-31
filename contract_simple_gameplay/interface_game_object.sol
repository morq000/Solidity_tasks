pragma ton-solidity >= 0.35;
pragma AbiHeader expire;

// Интерфейс с методом "принять урон"
interface IgameObject {
	function getDamage (uint damage) external;
}