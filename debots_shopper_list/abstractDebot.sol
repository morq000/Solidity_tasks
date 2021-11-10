pragma ton-solidity >= 0.35;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "Debot.sol";
import "Terminal.sol";
import "Menu.sol";
import "AddressInput.sol";
import "ConfirmInput.sol";
import "Upgradable.sol";
import "Sdk.sol";


import "Itransactable.sol";
import "IshopperList.sol";
import "abstractShopperList.sol";

abstract contract abstractDebot is Debot, Upgradable  {
	
	bytes m_icon; // иконка дебота

	uint m_ownerPubkey; // хранит публичный ключ владельца контракта
	address m_signerAddress; // адрес кошелька владельца контракта

	TvmCell m_shopperListCode; // код целевого контракта списка покупок
	TvmCell m_shopperStateInit; // stateinit целевого контракта списка покупок
	TvmCell m_shopperListData; // data целевого контракта списка покупок
	address m_address; // адрес целевого контракта списка покупок
	purchaseSummary m_summary; // текущая сводка по списку покупок
		
	uint128 INIT_BALANCE = 199000000; //начальный баланс контракта Список покупок при деплое

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

	// переменная для временного хранения имени покупки во время добавления
	string thisPurchaseName;

	// Выдача меню реализована по-разному в каждом из ботов
	function _giveMenu() virtual internal;
	
	// Задать значение переменной, содержащей в себе stateinit заливаемого контракта
	function setShopperListCode(TvmCell code, TvmCell data) public {
		require(msg.pubkey() == tvm.pubkey(), 101, "Can't be called by non-owner");
		tvm.accept();
		//m_shopperListCode = code;
		m_shopperStateInit = tvm.buildStateInit(code, data);
	}

	// Точка входа в бота
	function start() public override {
		Terminal.input(tvm.functionId(saveOwnerPubkey), "Введите публичный ключ: ", false);
	}

	// возврат ID используемых интерфейсов
	function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID, ConfirmInput.ID, Sdk.ID];
    }

	// првоерка и сохранение введенного pubkey в качестве публичного ключа владельца 
	function saveOwnerPubkey(string value) public {
		// конвертируем строку в hex int, если удачно - сохраняем полученный pubkey в переменную
		(uint res, bool status) = stoi("0x"+value);
		if (status) {
			m_ownerPubkey = res;
			Terminal.print(0, "Посмотрим, есть ли у вас уже существующий список покупок...");
			// получаем deploy state из кода конртакта Список покупок и сохраненного публичного ключа владельца
			//TvmCell deployState  = tvm.insertPubkey(m_shopperListCode, m_ownerPubkey);
			TvmCell deployState  = tvm.insertPubkey(m_shopperStateInit, m_ownerPubkey);
			// адрес будущего контракта Список покупок
			m_address = address.makeAddrStd(0, tvm.hash(deployState));
			Terminal.print(0, format("Адрес контракта -Список покупок-: {}", m_address));
			// Определим тип контракта по этому адресу и вызовем колбэк
			Sdk.getAccountType(tvm.functionId(checkAccountStatus), m_address);

		}
		else {
			Terminal.print(tvm.functionId(saveOwnerPubkey), "Введенный публичный ключ имеет неправильный формат. Попробуйте ввести ключ еще раз: ");
		}
	}

	// проверка статуса аккаунта по адресу контракта Список покупок
	function checkAccountStatus(int8 acc_type) public {
		if (acc_type==1) { // если аккаунт активен и контракт на нем задеплоен
			// получаем статистику списка покупок, далее выходим на меню
			_getShopperStats(tvm.functionId(setStatsAndGiveMenu));
		} else if (acc_type==-1) { // контракт неактивен, нужно его создать и задеплоить
			Terminal.print(0, "У вас еще нет списка покупок, поэтому будет создан новый список. Необходимо пополнить баланс вашего списка на 0.199 ton");
			// вызов библиотечного метода для получения адреса, с которого спишутся монеты
			AddressInput.get(tvm.functionId(creditShopperList), "Необходимо подписать две транзакции. Выберите способ оплаты: ");
		}
		else if (acc_type==0) { // аккаунт есть, но не инициализирован
			Terminal.print(0, "Деплоим новый контракт. Если произойдет ошибка, проверьте баланс аккаунта Список покупок");
			// вызов метода деплоя контракта
			deploy();
		}
		else if (acc_type==2) { // аккаунт заморожен
			Terminal.print(0, format("Невозможно продолжить: аккаунт {} заморожен.", m_address));
		}
	}

	// обращение к методу конртакта Список покупок, чтобы получить статистику покупок
	// answerId - колбэк функция, передается в параметрах внешнего сообщения
	// Вызывается после получения статистики от конртакта Список покупок
	function _getShopperStats(uint32 answerId) private view {
		optional(uint256) none;

		IshopperList(m_address).getStats{
			abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: answerId,
            onErrorId: tvm.functionId(onError)
		}();
	}

	// присвоить значение переменной статистики покупок и вызвать меню дебота
	function setStatsAndGiveMenu(purchaseSummary summary) public {
		m_summary = summary;
		_giveMenu();
	} 

	//
	// запрос для заброса монет на адрес будущего контракта Списка покупок
	//
	function creditShopperList(address value) public {
		m_signerAddress = value;
		//
		Terminal.print(0, format("Got signer address {}", m_signerAddress));
		optional(uint256) pubkey = 0;
		TvmCell emptyCell;
		//
		Terminal.print(0, "Trying to call sendTransaction method");
		Itransactable(m_signerAddress).sendTransaction{
			abiVer: 2,
			extMsg: true,
			sign: true,
			pubkey: pubkey,
			time: uint64(now),
			expire: 0,
			callbackId: tvm.functionId(waitingBeforeDeploy),
			onErrorId: tvm.functionId(repeatCreditOnError)
		}(m_address, INIT_BALANCE, false, 3, emptyCell);
	}

	// вход в петлю для ожидания, когда статус поменяется на 0 и можно будет деплоить
	function waitingBeforeDeploy() public {
		// ждем, когда вернется тип аккаунта 0
		Sdk.getAccountType(tvm.functionId(checkIfAccStatusIs0), m_address);
	}

	// Если заброс монет не прошел, повторить
	function repeatCreditOnError(uint32 sdkError, uint32 exitCode) public {
		// вывести информацию об ошибках
		Terminal.print(0, format("Произошла ошибка при отправке монет на адрес контракта. sdkError {}, exitCode {}", sdkError, exitCode));
        // повторяем заброс монет
		creditShopperList(m_signerAddress);
	}

	// возврат к ожиданию, либо переход к методу деплоя
	function checkIfAccStatusIs0(int8 acc_type) public {
		if (acc_type == 0) {
			deploy();
		} else {
			waitingBeforeDeploy();
		}
	}
	
	//
	// деплой контракта Списка покупок и колбэки
	//
	function deploy() private view {
		// создание deploy state из кода контракта списка покупок и pubkey владельца
		//TvmCell deployState = tvm.insertPubkey(m_shopperListCode, m_ownerPubkey);
		TvmCell deployState = tvm.insertPubkey(m_shopperStateInit, m_ownerPubkey);
		optional(uint256) nonePubkey;
		// создаем внешнее сообщение для деплоя контракта список покупок
		TvmCell deployMessage = tvm.buildExtMsg({
			abiVer: 2,
			// адрес контракта списка, куда деплоим
			dest: m_address,
			// колбэк если деплоится успешно
			callbackId: tvm.functionId(onSuccess),
			// колбэк на повторный деплой если ошибка
			onErrorId: tvm.functionId(onErrorDeployRepeat),
			time: 0,
			expire: 0,
			sign: true,
			pubkey: nonePubkey,
			stateInit: deployState,
			// вызов конструктора контракта Список покупок, передача ему pubkey владельца
			call: {AShopperList, m_ownerPubkey}
		});
		tvm.sendrawmsg(deployMessage, 1);
	}
	
	// обновить статистику покупок и показать основное меню
	function onSuccess() public view {
		_getShopperStats(tvm.functionId(setStatsAndGiveMenu));
	}

	// Если деплой прошел с ошибками
	function onErrorDeployRepeat(uint32 sdkError, uint32 exitCode) public {
		// вывести информацию об ошибках
		Terminal.print(0, format("Произошла ошибка. sdkError {}, exitCode {}", sdkError, exitCode));
        // повторить деплой 
		deploy();
	}

	// Обработка ошибок при работе со списком покупок
	function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Произошла ошибка. sdkError {}, exitCode {}", sdkError, exitCode));
        _giveMenu();
    }

	/////////////////////
	//Upgradable interface
	/////////////////////
	function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }

}