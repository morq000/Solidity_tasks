pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

interface IRoot {
	function deployBasis(TvmCell codeIndexBasis) external;
	function mintNft() external;
}

