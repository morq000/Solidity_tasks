pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

interface INftRoot {
	function deployBasis(TvmCell codeIndexBasis) external;
	function mintNft() external;
    function resolveNftAddresses() external returns (address[] nftAddresses);
	function destructBasis() external;
    function resolveData(address addrRoot, uint256 id) external returns (address addrData);
}

interface IMultisig {
    function submitTransaction(
        address dest,
        uint128 value,
        bool bounce,
        bool allBalance,
        TvmCell payload)
    external returns (uint64 transId);

    function sendTransaction(
        address dest,
        uint128 value,
        bool bounce,
        uint8 flags,
        TvmCell payload)
    external;
}

