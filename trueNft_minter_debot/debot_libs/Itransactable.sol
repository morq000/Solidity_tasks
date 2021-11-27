pragma ton-solidity >= 0.35;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

// Позволяет вызвать метод кошелька для заброса монет на будущий адрес контракта
interface Itransactable {
	function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload) external;
}