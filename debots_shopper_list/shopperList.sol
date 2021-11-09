pragma ton-solidity >= 0.35;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "IshopperList.sol";

contract shopperList is IshopperList {

// ------------------------------
// Интерфейсы:

// "Список покупок"
// - ...

// "Transactable"
// - sendTransaction

// Абстрактный контракт
// HasConstructorWithPubKey

	// Смарт-контракт Списка покупок:
// - конструктор
// - контроль за правами доступа (onlyOwner)
// - список покупок-статистика о покупках
// - добавление покупки в список (параметры: название продукта, количество)
// - удаление покупки из списка
// - купить [помечает, чты вы купили; купить обратно, то есть сбросить флаг покупки  не надо делать]. параметры: (ID, цена)

// Структура:
// "Покупка"
// - идентификатор/номер
// - название
// - количество (сколько надо купить)
// - когда заведена
// - флаг, что куплена (при заведении в список всегда false)
// - цена, за которую купили [за все единиицы сразу] (при заведении в список всегда 0)

	modifier onlyOwner {
        require(msg.pubkey() == m_ownerPubkey, 101);
        _;
    }

	// Переменная с pubkey ключом владельца контракта
	uint256 m_ownerPubkey;

	// Переменная Id покупки
	uint32 m_purchaseId;

	// Маппинг Id и покупки
	mapping (uint32=>purchase) purchases;
    
	constructor(uint256 pubkey) public {
		require(pubkey !=0, 119, "Owner pubkey shpuld not be 0");
		tvm.accept();
		m_ownerPubkey = pubkey;
	}

	//
	// Method definitions

	// Вывод статистики. Можно выполнять off-chain.
	function getStats() public view override returns(purchaseSummary summary) {
		uint purchased;
		uint notYetPurchased;
		uint totalSpent;

		for ((uint32 id, purchase _purchase) : purchases) {
			if (_purchase.isBought) {
				purchased += _purchase.quantity;
				totalSpent += _purchase.price;
			}
			else {
				notYetPurchased += _purchase.quantity;
			}
		}

		summary = purchaseSummary(purchased, notYetPurchased, totalSpent);
	}

	// Вывод списка покупок
	function getPurchaseList() public override view returns(purchase[] purchaseList){
		uint32 pid;
		string name;
		uint quantity;
		uint64 timeCreated;
		bool isBought;
		uint price;

		for ((uint32 id, purchase _purchase) : purchases) {
			pid = _purchase.id;
			name = _purchase.name;
			quantity = _purchase.quantity;
			timeCreated = _purchase.timeCreated;
			isBought = _purchase.isBought;
			price = _purchase.price;

			purchaseList.push(purchase(pid, name, quantity, timeCreated, isBought, price));
		}
	}

	// - добавление покупки в список (параметры: название продукта, количество)
	function addProductToBuy(string _name, uint _quantity) public override onlyOwner {
		tvm.accept();
		m_purchaseId++;
		purchases[m_purchaseId] = purchase(m_purchaseId, _name, _quantity, now, false, 0);
	}

	// - удаление покупки из списка
	function deleteProductfromList(uint32 Id) public override onlyOwner {
		
		// Проверить, есть ли в маппинге значение для данного Id.
		require(purchases.exists(Id), 104, "Продукт не найден");
		tvm.accept();
		delete purchases[Id];


	}

	// купить [помечает, чты вы купили]. параметры: (ID, цена)
	function buyProduct(uint32 Id, uint price) public override onlyOwner {

		// Проверить, есть ли в маппинге значение для данного Id.
		optional(purchase) _purchase = purchases.fetch(Id);
		require(_purchase.hasValue(), 104, "Продукт не найден");

		tvm.accept();

		// Сохранить покупку во временную переменную для внесения изменений
		purchase thisPurchase = _purchase.get();
		thisPurchase.isBought = true;
		thisPurchase.price = price;

		// Обновить информацию о покупке в списке
		purchases[Id] = thisPurchase;
	}

}