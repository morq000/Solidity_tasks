pragma ton-solidity >= 0.50;
pragma AbiHeader expire;

contract Multiplier {

    uint public result;

    constructor() public {
        result = 1;
        tvm.accept();
    }

    function multiply(uint mult) public returns (string) {
        require(mult >= 1 && mult <= 10, 101, 'Multiplier should be between 1 and 10');
        result *= mult;
    }           
}