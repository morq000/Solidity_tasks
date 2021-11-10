pragma ton-solidity >= 0.35;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "abstractDebot.sol";

contract shopperDebot2 is abstractDebot {

	uint32 thisPurchaseNumber;

	// возврат метаданных по деботу
	function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "DeBot Список покупок v.2";
        version = "0.0.2";
        publisher = "morq000";
        key = "Purchase list";
        author = "morq000";
        support = address.makeAddrStd(0, 0x2e08eb28bfaab81e20f54b03a55a46eb1ca3148980795e8fc443486eade98c39);
        hello = "Привет, я дебот-покупатель.";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

	function _giveMenu() internal override {
		string separator = '**********************************';
		// использование библиотечного метода для вызова меню
		Menu.select(
			format(
				"Сделано покупок {}, предстоит сделать {}, потрачено денег {}",
				m_summary.purchased,
				m_summary.notYetPurchased,
				m_summary.totalSpent
			), 	
				separator, 		
			[
				MenuItem("Совершить покупку", "", tvm.functionId(makePurchase)),
				MenuItem("Удалить покупку", "", tvm.functionId(deletePurchase)),
				MenuItem("Вывести список", "", tvm.functionId(getPurchases))
			]
		);
	}

	//////////////////////
	// Добавление покупки
	//////////////////////
	function makePurchase(uint32 index) public {
		index = index;
		if (m_summary.notYetPurchased > 0) {
			Terminal.input(tvm.functionId(addPurchasePrice_), "Введите номер совершенной покупки", false);
		}
		else {
			Terminal.print(0, "В вашем текущем списке нет запланированных покупок");
			_giveMenu();
		}
	}

	function addPurchasePrice_(string value) public {
		(uint res, bool status) = stoi(value);
		if (status) {
			thisPurchaseNumber = uint32(res);
		}
		else {
			Terminal.print(0, "Что-то пошло не так. Попробуйте снова.");
			_giveMenu();
		}
		Terminal.input(tvm.functionId(makePurchase_), "Стоимость покупки: ", false);
	}

	// Вызов метода Списка покупок для добавления покупки
	function makePurchase_(string value) public {
		(uint res, bool status) = stoi(value);
		if (status) {
			optional(uint256) pubkey=0;
			IshopperList(m_address).buyProduct{
				abiVer: 2,
				extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
		}(thisPurchaseNumber, res);
		}
		else {
			Terminal.print(0, "Что-то пошло не так. Попробуйте снова.");
			_giveMenu();
		}
		
	}

	////////////////////
	// Удаление покупки
	////////////////////
	function deletePurchase(uint32 index) public {
		index = index;
		if (m_summary.purchased + m_summary.notYetPurchased > 0) {
			Terminal.input(tvm.functionId(deletePurchase_), "Введите номер покупки для удаления", false);
		}
		else {
			Terminal.print(0, "Ваш текущий список покупок пуст");
			_giveMenu();
		}
	}

	function deletePurchase_(string value) public view {
		(uint num,) = stoi(value);
		optional(uint256) pubkey = 0;
		IshopperList(m_address).deleteProductfromList{
				abiVer: 2,
				extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
		}(uint32(num));
	}

	//////////////////////
	// Вывод списка покупок///
	//////////////////////
	function getPurchases(uint32 index) public view {
		index = index;
		optional(uint256) none;
		IshopperList(m_address).getPurchaseList{
			abiVer: 2,
			extMsg: true,
        	sign: false,
        	pubkey: none,
        	time: uint64(now),
        	expire: 0,
        	callbackId: tvm.functionId(showPurchases_),
        	onErrorId: tvm.functionId(onError)
		}();
	}

	function showPurchases_(purchase[] purchaseList) public {
		if (purchaseList.length > 0) {
			Terminal.print(0, "Ваш список покупок:");
			for (uint256 index = 0; index < purchaseList.length; index++) {
				purchase _pur = purchaseList[index];
				string _isBought;
				if (_pur.isBought) {
					_isBought = "да";
				} else {
					_isBought = "нет";
				}
				Terminal.print(0, format("{}, количество: {}, куплено: {}, цена покупки: {}", _pur.name, _pur.quantity, _isBought, _pur.price));
			}
		} else {
			Terminal.print(0, "Список покупок пуст.");
		}
		_giveMenu();
	}
	
}