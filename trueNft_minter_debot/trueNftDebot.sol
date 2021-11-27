pragma ton-solidity >= 0.35;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "abstractTrueNftDebot.sol";

contract trueNftDebot is abstractTrueNftDebot {

	// возврат метаданных по деботу
	function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "Создание Nft коллекции";
        version = "0.0.1";
        publisher = "morq000";
        key = "Nft Collection";
        author = "morq000";
        support = address.makeAddrStd(0, 0);
        hello = "Привет, я дебот для создания Nft-коллекции";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

	function giveMenu() public override {
		string separator = '--------------------------';
		// использование библиотечного метода для вызова меню
		Menu.select("---Управление коллекцией---", separator, 		
			[
				MenuItem("Мои токены", "", tvm.functionId(getTokens)),
				MenuItem("Создать токен", "", tvm.functionId(mintToken)),
				MenuItem("Удалить токен", "", tvm.functionId(deleteToken)),
				MenuItem("Подарить токен", "", tvm.functionId(giveToken)),
				MenuItem("Выставить/снять с продажи", "", tvm.functionId(changeSaleStatus))
			]
		);
	}

	function getTokens() public {

	}

	function mintToken() public {
		
	}

	function deleteToken() public {
		
	}

	function giveToken() public {
		
	}

	function changeSaleStatus() public {
		
	}
	

}