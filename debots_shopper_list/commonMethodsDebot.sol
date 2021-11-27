pragma ton-solidity >= 0.35;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "abstractDebot.sol";

abstract contract commonMethodsDebot is abstractDebot {

	/////////////////////
	// Удаление покупки//
	/////////////////////
	function deletePurchase(uint32 index) public {
		index = index;
		if (m_summary.purchased + m_summary.notYetPurchased > 0) {
			Terminal.input(tvm.functionId(deletePurchase_), "Введите номер покупки для удаления", false);
		}
		else {
			Terminal.print(0, "Ваш текущий список покупок пуст");
			onSuccess();
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

	//////////////////////////
	// Вывод списка покупок///
	//////////////////////////
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
			Terminal.print(0, "-----Ваш список покупок-----");
			Terminal.print(0, "---------------------------------------------------");
			for (uint256 index = 0; index < purchaseList.length; index++) {
				purchase _pur = purchaseList[index];
				string _isBought;
				if (_pur.isBought) {
					_isBought = "✓";
				} else {
					_isBought = "X";
				}
				Terminal.print(0, format("НОМЕР: {}, НАЗВАНИЕ: {}, КОЛИЧЕСТВО: {}, КУПЛЕНО: {}, СТОИМОСТЬ: {}", _pur.id, _pur.name, _pur.quantity, _isBought, _pur.price));
			}
		} else {
			Terminal.print(0, "Список покупок пуст.");
		}
		onSuccess();
	}
}