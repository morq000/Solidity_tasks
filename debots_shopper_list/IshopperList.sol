pragma ton-solidity >= 0.35;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

interface IshopperList {

	struct purchaseSummary {
		uint purchased;
		uint notYetPurchased;
		uint totalSpent;
	}

	struct purchase {
		uint32 id;
		string name;
		uint quantity;
		uint64 timeCreated;
		bool isBought;
		uint price;
	}

	// - список покупок-статистика о покупках
	function getStats() external view returns (purchaseSummary summary);

	// - добавление покупки в список (параметры: название продукта, количество)
	function addProductToBuy(string _name, uint _quantity) external;

	// - удаление покупки из списка
	function deleteProductfromList(uint32 Id) external;

	// - купить [помечает, чты вы купили; купить обратно, то есть сбросить флаг покупки  не надо делать]. параметры: (ID, цена)
	function buyProduct(uint32 Id, uint price) external;

	function getPurchaseList() external returns (purchase[] purchaseList);
}