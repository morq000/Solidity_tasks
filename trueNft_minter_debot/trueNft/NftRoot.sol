pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import '../resolvers/IndexResolver.sol';
import '../resolvers/DataResolver.sol';

import './IndexBasis.sol';

import '../interfaces/IData.sol';
import '../interfaces/IIndexBasis.sol';

contract NftRoot is DataResolver, IndexResolver {

    uint256 _totalMinted;
    address _addrBasis;

    address static _ownerAddress;

    constructor(TvmCell codeIndex, TvmCell codeData) public {
        tvm.accept();
        _codeIndex = codeIndex;
        _codeData = codeData;
    }

    modifier onlyOwner {
        require(msg.sender==_ownerAddress, 142);
        _;
    }

    function mintNft() public {
        //require(tvm.pubkey()==msg.pubkey(), 117, "Minting called by non-owner");
        require(msg.value > 1.2 ton, 151, "Not enough tons for minting");
        tvm.accept();
        TvmCell codeData = _buildDataCode(address(this));
        TvmCell stateData = _buildDataState(codeData, _totalMinted);
        address new_nft = new Data{stateInit: stateData, value: 1.1 ton}(msg.sender, _codeIndex);

        _totalMinted++;
    }

    function deployBasis(TvmCell codeIndexBasis) public onlyOwner{
        require(msg.value > 0.5 ton, 131);
        uint256 codeHashData = resolveCodeHashData();
        TvmCell state = tvm.buildStateInit({
            contr: IndexBasis,
            varInit: {
                _codeHashData: codeHashData,
                _addrRoot: address(this)
            },
            code: codeIndexBasis
        });
        _addrBasis = new IndexBasis{stateInit: state, value: 0.4 ton}();
    }

    function resolveNftAddresses() public view returns (address[] nftAddresses) {
        for (uint256 index = 0; index < _totalMinted; index++) {
            nftAddresses.push(resolveData(address(this), index));
        }
    }

    function returnAddrBasis() public view returns (address addrBasis){
        addrBasis = _addrBasis;
    }

    function destructBasis() public view {
        IIndexBasis(_addrBasis).destruct();
    }
}