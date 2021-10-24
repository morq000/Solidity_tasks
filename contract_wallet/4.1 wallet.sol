pragma ton-solidity >= 0.50;
pragma AbiHeader expire;

/// @title Wallet
/// @author morq000

contract Wallet {
	
	constructor() public {

		// check that message is signed with owner's private key
		require(msg.pubkey()==tvm.pubkey(), 101);
		tvm.accept();
	}

	// modifier that allows only owner to execute modified function
	modifier checkOwnerAndAccept {
		require(msg.pubkey()==tvm.pubkey(), 102, "Msg sender is not owner");
		tvm.accept();
		_;
	}

	// This function sends value to destination address
	// forward fee is substracted from the value
	function sendValueIncludingFee
	(
		address destination,
		uint128 value
	) 
		public
		pure
		checkOwnerAndAccept
	{
		// Bounce = true allows to get sended value back if transaction fails
		// Flag = 0 means that forward fee is substracted from sended value
		destination.transfer(value, true, 0);
	}

	// This function sends value to dest addres, and the fee is paid separately
	function sendValueAndSeparateFee
	(
		address destination,
		uint128 value
	)
		public
		pure
		checkOwnerAndAccept
	{
		// Bounce = true allows to get sended value back if transaction fails
		// Flag = 0 + 1 means that forward fee is paid separately
		destination.transfer(value, true, 1);
	}

	// This function sends all remaining money of the wallet and destroys the wallet
	function sendAllMoneyAndDestroy
	(
		address destination
	)
		public
		pure
		checkOwnerAndAccept
	{
		// Bounce = true allows to get sended value back if transaction fails
		// Flag = 128+32 means that all money from the wallet should be sent to destination
		// and the wallet shpuld be destroyed.
		// Argument Value is ignored
		destination.transfer(1, true, 160);
	}
}