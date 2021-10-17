pragma ton-solidity >= 0.50;
pragma AbiHeader expire;

contract  ShopQueue {

	string[] public queue;

	constructor() public {
		queue = ["Curt", "Janet", "Sid"];
		tvm.accept();
	}

	modifier checkOwnerAndAccept() {
		require(tvm.pubkey() == msg.pubkey(), 105, "Only owner can execute");
		tvm.accept();
		_;
	}

	// Function to output current queue qhile running on a test net
	function outputQueue() public checkOwnerAndAccept returns (string[]) {
		return queue;
	}

	// Function to add new member to the end of queue
	function join(string new_name) public checkOwnerAndAccept returns (string[]) {
		queue.push(new_name);

		return queue;
	}

	// Function to pop out the first member of the queue and move other values
	function callNext() public checkOwnerAndAccept returns (string[]) {
		// Check if array is already empty
		require(queue.length > 0, 107, "The queue is already empty");

		// Delete element at index 0
		delete queue[0];

		// Move all elements one step left
		for (uint256 index = 0; index < queue.length - 1; index++) {
			queue[index] = queue[index+1];
		}
		
		// Pop out the last element as it is already moved
		queue.pop();

		return queue;
	}
	
}