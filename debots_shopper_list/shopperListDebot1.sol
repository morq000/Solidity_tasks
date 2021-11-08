// // 2. Два контракта деботов, которые унаследованы от абстрактного. 
// Деботы будут друг от друга отличаться по списку доступных в меню и в реализаии методов.

// // 2.1. Контракт "Дебот наполнение Списка Покупок"
// // Меню содержит:
// // Добавление продукта (обратите внимание, что вам несколько раз надо запрашивать у пользователя данные. 
// Сперва про название, затем про количество.
// // Вывод списка покупок
// // Удаление покупки

// // 2.3. Необязательный "Дебот базовые методы работы со списком". В этот дебот можно вынести 
// общие методы по выводу списка покупок, удалению покупок.


pragma ton-solidity >= 0.35;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "abstractDebot.sol";

contract shopperDebot1 is abstractDebot {

	// возврат метаданных по деботу
	function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "DeBot Список покупок v.1";
        version = "0.0.1";
        publisher = "morq000";
        key = "Purchase list";
        author = "morq000";
        support = address.makeAddrStd(0, 0x66e01d6df5a8d7677d9ab2daf7f258f1e2a7fe73da5320300395f99e01dc3b5f);
        hello = "Привет, я дебот по наполнению списка покупок";
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
				MenuItem("Добавить новую покупку", "", tvm.functionId(addPurchase)),
				MenuItem("Удалить покупку", "", tvm.functionId(deletePurchase)),
				MenuItem("Вывести список", "", tvm.functionId(getPurchaseList))
			]
		);
	}

	//////////////////////
	// Добавление покупки
	//////////////////////
	function addPurchase(uint32 index) public {
		index = index;
		Terminal.input(tvm.functionId(addPurchaseName_), "Название покупки: ", false);
	}

	function addPurchaseName_(string value) public {
		thisPurchaseName = value;
		Terminal.input(tvm.functionId(addPurchase_), "Сколько единиц товара нужно купить: ", false);
	}

	// Вызов метода Списка покупок для добавления покупки
	function addPurchase_(string value) public {
		(uint res, bool status) = stoi(value);
		if (status) {
			optional(uint256) pubkey=0;
			IshopperList(m_address).addProductToBuy{
				abiVer: 2,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
		}(thisPurchaseName, res).extMsg;
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
			Terminal.print(0, "В вашем текущем списке нет запланированных покупок.");
			_giveMenu();
		}
	}

	function deletePurchase_(string value) public view {
		(uint num,) = stoi(value);
		optional(uint256) pubkey = 0;
		IshopperList(m_address).deleteProductfromList{
				abiVer: 2,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
		}(uint32(num)).extMsg;
	}

	//////////////////////
	// Вывод статистики///
	//////////////////////
	function getPurchaseList(uint32 index) public view {
		index = index;
		optional(uint256) none;
		IshopperList(m_address).getPurchaseList{
			abiVer: 2,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showPurchases_),
            onErrorId: 0
		}().extMsg;
	}

	function showPurchases_(IshopperList.purchase[] purchaseList) public {
		if (purchaseList.length > 0) {
			Terminal.print(0, "Ваш список покупок:");
			for (uint256 index = 0; index < purchaseList.length; index++) {
				IshopperList.purchase _pur = purchaseList[index];
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