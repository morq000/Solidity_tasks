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
//import "./debot_libs/SigningBoxInput.sol";
import "./libraries/Constants.sol";


import "./trueNft/NftRoot.sol";
import "./trueNft/ANftRoot.sol";
import "./interfaces/Interfaces.sol";
import "./interfaces/IData.sol";

// Абстрактный класс для загрузки и создания контракта NftRoot
contract abstractTrueNftDebot is Debot, Upgradable  {
	
	
	// Variables with TNFT files codes. To be assigned before starting Debot.
	TvmCell codeIndex; 
	TvmCell codeIndexBasis;
	TvmCell codeData;
	TvmCell codeRoot;
	TvmCell rootDeployState;
	//TvmCell dataRoot;

	bytes m_icon; // иконка дебота

	// Addresses of deployed TNFT contract files
	address m_addressRoot;
	
	// Owner data. Is asked by Debot from user
	uint m_ownerPubkey;
	address m_ownerAddress;

	// Var for testing. User can set how NFT Root will be deployed.
	uint _deployType;

	////////////////////////////////////////////////////////
	// Debot setup functions////////////////////////////////
	////////////////////////////////////////////////////////
	function setIcon(bytes icon) public {
		require(msg.pubkey() == tvm.pubkey(), 100);
		tvm.accept();
		m_icon = icon;
    }


	// Writing TNFT files code to Debot state
	function setRootCode(TvmCell code) public
	{
		require(msg.pubkey()==tvm.pubkey());
		tvm.accept();
		codeRoot = code;
	}

	function setIndexCode(TvmCell code) public
	{
		require(msg.pubkey()==tvm.pubkey());
		tvm.accept();
		codeIndex = code;
	}

	function setIndexBasisCode(TvmCell code) public
	{
		require(msg.pubkey()==tvm.pubkey());
		tvm.accept();
		codeIndexBasis = code;
	}

	function setDataCode(TvmCell code) public
	{
		require(msg.pubkey()==tvm.pubkey());
		tvm.accept();
		codeData = code;
	}


	// возврат ID используемых интерфейсов
	function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID, Sdk.ID];
    }


	//////////////////////////////////////////////////////////
	// Debot Opeation functions
	/////////////////////////////////////////////////////////

	// Точка входа в бота
	function start() public override {
		if (m_ownerAddress == address(0)) {
			AddressInput.get(tvm.functionId(saveMultisigAddress), "Введите адрес кошелька владельца");
		}
		else {
			restart();
		}
	}

	function restart() public {
        if (m_ownerPubkey == 0) {
            Terminal.input(tvm.functionId(saveOwnerPubkey), "Введите публичный ключ: ", false);
            //return;
        }
        resolveNFTRoot();
        Sdk.getAccountType(tvm.functionId(checkRootAccStatus), m_addressRoot);
	}

    function saveMultisigAddress(address value) public {
        m_ownerAddress = value;
        restart();
    }

	function resolveNFTRoot() public {
		rootDeployState = makeRootStateInit();
        m_addressRoot = address.makeAddrStd(0, tvm.hash(rootDeployState));
		Terminal.print(0, format("Resolved Root address {}", m_addressRoot));
    }

    function makeRootStateInit() public view returns (TvmCell state){
        state = tvm.buildStateInit({
            contr: NftRoot,
            varInit: {
                _ownerAddress: m_ownerAddress
            },
            code: codeRoot
        });
    }

	function saveOwnerPubkey(string value) public {
		// следует продумать более точную проверку, что введенное число pubkey
		(uint res, bool status) = stoi("0x"+value);
		if (status) {
			m_ownerPubkey = res;
			//Terminal.print(0, format("Введенный публичный ключ : {}", m_ownerPubkey));
			//restart();
		}
		else {
			Terminal.print(0, "Введенный публичный ключ имеет неправильный формат. Попробуйте ввести ключ еще раз: ");
			//restart();
		}
	}

	// проверка статуса аккаунта по адресу контракта Список покупок
	function checkRootAccStatus(int8 acc_type) public {
		if (acc_type==1) {
			// Acc is deployed and active
			giveMenu();
		} 
		else if (acc_type==-1) { 
			// контракт неактивен, нужно его создать и задеплоить
			Terminal.print(0, "У вас еще нет коллекции, поэтому будет создана новая. Необходимо пополнить баланс коллекции на 5 ton.");
			// вызов интерфейсного метода для получения адреса, с которого спишутся монеты
			Terminal.print(tvm.functionId(creditNftRoot), "Необходимо подписать две транзакции (пополнение баланса коллекции и плата за деплой коллекциию)");
		}
		else if (acc_type==0) { 
			// аккаунт есть, но не инициализирован
			Terminal.print(tvm.functionId(chooseDeployType), "Деплоим новый контракт. Если произойдет ошибка, проверьте баланс аккаунта коллекции");
		}
		else if (acc_type==2) { // аккаунт заморожен
			Terminal.print(0, format("Невозможно продолжить: аккаунт {} заморожен.", m_addressRoot));
			// TODO что делать дальше
		}
	}

	function creditNftRoot() public view {
		//Terminal.print(0, format("Got signer address {}", m_ownerAddress));
		optional(uint256) pubkey = 0;
		TvmCell emptyCell;
		//
		//Terminal.print(0, "Trying to call sendTransaction method");
		IMultisig(m_ownerAddress).sendTransaction{
			abiVer: 2,
			extMsg: true,
			sign: true,
			pubkey: pubkey,
			time: uint64(now),
			expire: 0,
			callbackId: tvm.functionId(waitingBeforeDeploy),
			onErrorId: tvm.functionId(repeatCreditOnError)
		}(m_addressRoot, Constants.MIN_FOR_DEPLOY, false, 3, emptyCell);
	}


	function deployRootFork() public {
		if (_deployType == 1) {
			deployRootRawMsg();
		}
		else if (_deployType == 2) {
			deployRootNew();
		}
		else {
			Terminal.print(tvm.functionId(chooseDeployType), ":Not implemented yet:");
		}
	}

	function deployRootNew() private {
		tvm.accept();
        address _addrRoot = new NftRoot {stateInit: rootDeployState, value: 3 ton}(codeIndex, codeData); 
        Terminal.print(tvm.functionId(deployIndexBasis), format("Root задеплоен по адресу {}", _addrRoot));
	}


	function deployRootRawMsg() public view {
		require(m_addressRoot != address(0), 113, "Can't deploy Root with empty NftRoot address");
		//require(!codeIndex.toSlice().empty(), 121);
		//require(!codeData.toSlice().empty(), 123);
		optional(uint256) nonePubkey;
		// создаем внешнее сообщение для деплоя контракта список покупок
		TvmCell deployMessage = tvm.buildExtMsg({
			abiVer: 2,
			// адрес контракта, куда деплоим
			dest: m_addressRoot,
			// колбэк если деплоится успешно
			callbackId: tvm.functionId(deployIndexBasis),
			// колбэк на повторный деплой если ошибка
			onErrorId: tvm.functionId(onErrorDeployRepeat),
			time: 0,
			expire: 0,
			sign: true,
			pubkey: nonePubkey,
			stateInit: rootDeployState,
			call: {ANftRoot, codeIndex, codeData}
		});
		tvm.sendrawmsg(deployMessage, 1);
	}

	// deploy IndexBasis
	function deployIndexBasis() public view {
		require(m_addressRoot != address(0), 109, "Can't deploy IndexBasis with empty NftRoot address");
		//require(!codeIndexBasis.toSlice().empty(), 112, "Can't deploy IndexBasis with empty code");
		TvmCell payload = tvm.encodeBody(
            NftRoot.deployBasis,
            codeIndexBasis
        );
        optional(uint256) none;
        IMultisig(m_ownerAddress).sendTransaction {
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: none,
            time: 0,
            expire: 0,
            callbackId: tvm.functionId(onDeploySuccess),
            onErrorId: tvm.functionId(onError)
            //signBoxHandle: _keyHandle
        }(m_addressRoot, 0.6 ton, true, 3, payload);		
    }

	//////////////////////
	// Deploy helpers/////
	//////////////////////

	function chooseDeployType() public {
		Terminal.input(tvm.functionId(setDeployType), "Choose deploy type: 1-Via RawMsg, 2-Via new, 3-Via transfer, 4-via constructo call", false);
	}

	function setDeployType(string value) public {
		(uint res, bool status) = stoi(value);
		if (status) {
			_deployType = res;
		}
		deployRootFork();
	}

	// вход в петлю для ожидания, когда контракт можно будет деплоить
	function waitingBeforeDeploy() public {
		// ждем, когда вернется тип аккаунта 0
		Terminal.print(0, "Waiting for TopUp");
		Sdk.getAccountType(tvm.functionId(checkIfAccStatusIs0), m_addressRoot);
	}

	// Если деплой прошел с ошибками
	function onErrorDeployRepeat(uint32 sdkError, uint32 exitCode) public {
		// вывести информацию об ошибках
		tvm.log(format("Произошла ошибка. sdkError {}, exitCode {}", sdkError, exitCode));
		Terminal.print(0, format("Произошла ошибка. sdkError {}, exitCode {}", sdkError, exitCode));
        // повторить деплой 
		chooseDeployType();
	}

	// возврат к ожиданию, либо переход к меню
	function checkIfAccStatusIs0(int8 acc_type) public {
		if (acc_type == 0) {
			chooseDeployType();
		} else {
			waitingBeforeDeploy();
		}
	}

	// Если заброс монет не прошел, повторить
	function repeatCreditOnError(uint32 sdkError, uint32 exitCode) public {
		// вывести информацию об ошибках
		Terminal.print(0, format("Произошла ошибка при отправке монет на адрес контракта. sdkError {}, exitCode {}", sdkError, exitCode));
        // повторяем заброс монет
		creditNftRoot();
	}
	
	// обновить статистику покупок и показать основное меню
	function onDeploySuccess() public {
		Terminal.print(0, "NftRoot и IndexBasis успешно созданы");
		giveMenu();
	}

	// Обработка ошибок при работе со списком покупок
	function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Произошла ошибка. sdkError {}, exitCode {}", sdkError, exitCode));
        giveMenu();
    }


	/////////////////
	//Debot interface
	/////////////////
	// возврат метаданных по деботу
	function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "Создание Nft коллекции";
        version = "0.0.4";
        publisher = "morq000";
        key = "Nft Collection";
        author = "morq000";
        support = address.makeAddrStd(0, 0);
        hello = "Привет, я дебот для создания Nft-коллекции";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

	function giveMenu() public {
		string separator = '--------------------------';
		// использование библиотечного метода для вызова меню
		Menu.select("---Управление коллекцией---", separator, 		
			[
				MenuItem("Мои токены", "", tvm.functionId(getTokenAddresses)),
				MenuItem("Создать токен", "", tvm.functionId(mintToken)),
				MenuItem("Информация о токене", "", tvm.functionId(askUserForTokenId)),
				MenuItem("Удалить токен", "", tvm.functionId(deleteToken)),			
				MenuItem("Подарить токен", "", tvm.functionId(giveToken)),
				MenuItem("Выставить/снять с продажи", "", tvm.functionId(changeSaleStatus))
			]
		);
	}

	function mintToken() public view {
		require(m_addressRoot != address(0), 109, "Can't deploy IndexBasis with empty NftRoot address");
		//require(!codeIndexBasis.toSlice().empty(), 112, "Can't deploy IndexBasis with empty code");
		TvmCell payload = tvm.encodeBody(
            NftRoot.mintNft
        );
        optional(uint256) none;
        IMultisig(m_ownerAddress).sendTransaction {
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: none,
            time: 0,
            expire: 0,
            callbackId: tvm.functionId(onMintSuccess),
            onErrorId: tvm.functionId(onError)
            //signBoxHandle: _keyHandle
        }(m_addressRoot, 1.3 ton, true, 3, payload);	
	}

	function getTokenAddresses() public view returns (address[] nftAddresses) {
		require(m_addressRoot != address(0), 137, "Can't be called withouth NftRoot address");
        optional(uint256) none;
        INftRoot(m_addressRoot).resolveNftAddresses {
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: 0,
            expire: 0,
            callbackId: tvm.functionId(_printAddresses),
            onErrorId: tvm.functionId(onError)
            //signBoxHandle: _keyHandle
        }();	
	}

	function _printAddresses(address[] nftAddresses) public {
		for (address _address: nftAddresses) {
			Terminal.print(0, format("NFT: {}", _address));
		}
		giveMenu();
	}

	function askUserForTokenId() public {
		Terminal.input(tvm.functionId(resolveDataAddress), "Token ID: ", false);
	}
	//function resolveData(address addrRoot, uint256 id) external returns (address addrData);
	function resolveDataAddress(string value) public view {
		require(m_addressRoot != address(0), 137, "Can't be called withouth NftRoot address");
		(uint id, bool status) = stoi(value);
		require(status, 163, "Wrong num input");
        optional(uint256) none;
        INftRoot(m_addressRoot).resolveData {
            abiVer: 2,
            extMsg: true,
            sign: false,
           // pubkey: none,
            time: 0,
            expire: 0,
            callbackId: tvm.functionId(getTokenDataFromAddress),
            onErrorId: tvm.functionId(onError)
            //signBoxHandle: _keyHandle
        }(m_addressRoot, id);
	}

	function printResolvedData(address addrData) public {
		Terminal.print(0, format("Resolved data {}",  addrData));
		getTokenDataFromAddress(addrData);
	}
	function getTokenDataFromAddress(address addrData) public view {
        optional(uint256) none;
		IData(addrData).getInfo {
			abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: 0,
            expire: 0,
            callbackId: tvm.functionId(printTokenData),
            onErrorId: tvm.functionId(onError)
            //signBoxHandle: _keyHandle
		}();
	}

	function printTokenData(address addrRoot, address addrOwner, address addrData) public {
		Terminal.print(tvm.functionId(giveMenu), format("Nft Address: {}, Root Address {}, Owner Address {}", addrRoot, addrOwner, addrData));
	}

	function destructBasis() public {

	}

	function onMintSuccess() public {
		Terminal.print(tvm.functionId(giveMenu), format("Nft token successfully minted"));
	}

	function deleteToken() public {
		// TODO
	}

	function giveToken() public {
		// TODO
	}

	function changeSaleStatus() public {
		// TODO
	}
	

	///////////////////////
	//Upgradable interface/
	///////////////////////
	function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }
}