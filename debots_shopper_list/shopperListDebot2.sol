pragma ton-solidity >= 0.35;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "abstractDebot.sol";
import "commonMethodsDebot.sol";

contract shopperDebot2 is abstractDebot, commonMethodsDebot {

	// временное хранилище номера покупки
	uint32 thisPurchaseNumber;

	// возврат метаданных по деботу
	function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "Совершение покупок v.2";
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
		string separator = '_____________________________________________';
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
}