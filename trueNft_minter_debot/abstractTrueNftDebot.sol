pragma ton-solidity >= 0.35;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "./debot_libs/Debot.sol";
import "./debot_libs/Terminal.sol";
import "./debot_libs/Menu.sol";
import "./debot_libs/AddressInput.sol";
import "./debot_libs/Upgradable.sol";
import "./debot_libs/Sdk.sol";
import "./debot_libs/Itransactable.sol";
import "./libraries/Constants.sol";

import "./trueNft/NftRoot.sol";
import "Interfaces.sol";

// Абстрактный класс для загрузки и создания контракта NftRoot
abstract contract abstractTrueNftDebot is Debot, Upgradable  {
	
	bytes m_icon; // иконка дебота
	TvmCell codeIndex; 
	TvmCell codeIndexBasis;
	TvmCell codeData;
	TvmCell codeRoot;
	address addressRoot;

	uint m_ownerPubkey;
	address m_signerAddress;
	address[] collections; // has NftRoot addresses

	// Установить иконку бота
	function setIcon(bytes icon) public {
		require(msg.pubkey() == tvm.pubkey(), 100);
		tvm.accept();
		m_icon = icon;
    }

	// Run this after deploying DeBot to save contract codes
	function getContractCodes(TvmCell _codeRoot, TvmCell _codeData, TvmCell _codeIndex, TvmCell _codeIndexBasis) public {
		require(msg.pubkey()==tvm.pubkey());
		tvm.accept();
		codeIndexBasis = _codeIndexBasis;
		codeIndex = _codeIndex;
		codeData = _codeData;
		codeRoot = _codeRoot;
	}

	// возврат ID используемых интерфейсов
	function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID, Sdk.ID];
    }

	// Точка входа в бота
	function start() public override {
		Terminal.print(0, format("Ваш публичный ключ {}", msg.pubkey()));
		
		Terminal.input(tvm.functionId(saveOwnerPubkey), "Введите публичный ключ: ", false);
	}

	// To be implemented in Debot
	function giveMenu() public virtual;

	// проверка и сохранение введенного pubkey в качестве публичного ключа владельца 
	function saveOwnerPubkey(string value) public {
		// конвертируем строку в hex int, если удачно - сохраняем полученный pubkey в переменную
		(uint res, bool status) = stoi("0x"+value);
		if (status) {
			m_ownerPubkey = res;
			Terminal.print(0, "Посмотрим, есть ли у вас уже существующая коллекция...");
			// получаем deploy state из кода конртакта NftRoot и сохраненного публичного ключа владельца
			//TvmCell deployState  = tvm.insertPubkey(m_shopperListCode, m_ownerPubkey);
			TvmCell deployState  = tvm.buildStateInit({code: codeRoot, pubkey: m_ownerPubkey});
			// адрес будущего контракта NftRoot
			addressRoot = address.makeAddrStd(0, tvm.hash(deployState));
			Terminal.print(0, format("Адрес контракта вашей коллекции: {}", addressRoot));
			// Определим тип контракта по этому адресу и вызовем колбэк
			Sdk.getAccountType(tvm.functionId(checkAccountStatus), addressRoot);

		}
		else {
			Terminal.print(tvm.functionId(saveOwnerPubkey), "Введенный публичный ключ имеет неправильный формат. Попробуйте ввести ключ еще раз: ");
		}
	}

	// проверка статуса аккаунта по адресу контракта Список покупок
	function checkAccountStatus(int8 acc_type) public {
		if (acc_type==1) { // если аккаунт активен и контракт на нем задеплоен
			// TODO меню: список токенов, создать токен, выставить на продажу, подарить, удалить
		} else if (acc_type==-1) { // контракт неактивен, нужно его создать и задеплоить
			Terminal.print(0, "У вас еще нет коллекции, поэтому будет создана новая. Необходимо пополнить баланс коллекции на 5 ton");
			// вызов интерфейсного метода для получения адреса, с которого спишутся монеты
			AddressInput.get(tvm.functionId(creditNftRoot), "Необходимо подписать две транзакции. Выберите способ оплаты: ");
		}
		else if (acc_type==0) { // аккаунт есть, но не инициализирован
			Terminal.print(0, "Деплоим новый контракт. Если произойдет ошибка, проверьте баланс аккаунта коллекции");
			// вызов метода деплоя контракта
			deployRoot();
		}
		else if (acc_type==2) { // аккаунт заморожен
			Terminal.print(0, format("Невозможно продолжить: аккаунт {} заморожен.", addressRoot));
			// TODO что делать дальше
		}
	}

	function creditNftRoot(address value) public {
		m_signerAddress = value;
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
		}(addressRoot, Constants.MIN_FOR_DEPLOY, false, 3, emptyCell);
	}

	function deployRoot() public {
		addressRoot = new NftRoot{
			value: 1 nano,
			code: codeRoot,
			pubkey: m_ownerPubkey
		}(codeIndex, codeData);

		Terminal.print(tvm.functionId(giveMenu), format("NftRoot address is {}", addressRoot));
	}

	// вход в петлю для ожидания, когда контракт можно будет деплоить
	function waitingBeforeDeploy() public {
		// ждем, когда вернется тип аккаунта 1
		Sdk.getAccountType(tvm.functionId(checkIfAccStatusIs0), addressRoot);
	}

	// возврат к ожиданию, либо переход к методу деплоя
	function checkIfAccStatusIs0(int8 acc_type) public {
		if (acc_type == 0) {
			deployRoot();
		} else {
			waitingBeforeDeploy();
		}
	}

	// Если заброс монет не прошел, повторить
	function repeatCreditOnError(uint32 sdkError, uint32 exitCode) public {
		// вывести информацию об ошибках
		Terminal.print(0, format("Произошла ошибка при отправке монет на адрес контракта. sdkError {}, exitCode {}", sdkError, exitCode));
        // повторяем заброс монет
		creditNftRoot(m_signerAddress);
	}
	
	//
	// деплой контракта Списка покупок и колбэки
	//
	// function deploy() private view {
	// 	// создание deploy state из кода контракта списка покупок и pubkey владельца
	// 	//TvmCell deployState = tvm.insertPubkey(m_shopperListCode, m_ownerPubkey);
	// 	TvmCell deployState = tvm.insertPubkey(m_shopperStateInit, m_ownerPubkey);
	// 	optional(uint256) nonePubkey;
	// 	// создаем внешнее сообщение для деплоя контракта список покупок
	// 	TvmCell deployMessage = tvm.buildExtMsg({
	// 		abiVer: 2,
	// 		// адрес контракта списка, куда деплоим
	// 		dest: m_address,
	// 		// колбэк если деплоится успешно
	// 		callbackId: tvm.functionId(onSuccess),
	// 		// колбэк на повторный деплой если ошибка
	// 		onErrorId: tvm.functionId(onErrorDeployRepeat),
	// 		time: 0,
	// 		expire: 0,
	// 		sign: true,
	// 		pubkey: nonePubkey,
	// 		stateInit: deployState,
	// 		// вызов конструктора контракта Список покупок, передача ему pubkey владельца
	// 		call: {AShopperList, m_ownerPubkey}
	// 	});
	// 	tvm.sendrawmsg(deployMessage, 1);
	// }
	
	// обновить статистику покупок и показать основное меню
	function onSuccess() public {
		giveMenu();
	}

	// Обработка ошибок при работе со списком покупок
	function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Произошла ошибка. sdkError {}, exitCode {}", sdkError, exitCode));
        giveMenu();
    }

	///////////////////////
	//Upgradable interface/
	///////////////////////
	function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }
}