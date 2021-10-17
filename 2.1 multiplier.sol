pragma ton-solidity >= 0.50;
pragma AbiHeader expire;

contract Multiplier {

    uint public result;

    constructor() public {
        result = 1;
        tvm.accept();
    }

    modifier checkOwnerAndAccept() {
        // Allows to execute code on a test net if a contract owner calls it
        require(tvm.pubkey() == msg.pubkey(), 112, "Only owner can execute this");
        tvm.accept();
        _;
    }

    function multiply(uint mult) public checkOwnerAndAccept returns (uint) {
        require(mult >= 1 && mult <= 10, 101, 'Multiplier should be between 1 and 10');
        result *= mult;
        return result;
    }           
}