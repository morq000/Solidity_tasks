pragma ton-solidity >= 0.50;
pragma AbiHeader expire;

contract taskList {

	struct Task {
		string name;    
		uint timestamp;
		bool is_done;
	}

	mapping(int8=>Task) task_list;

	int8 counter = 0;

	constructor() public {
		tvm.accept();
	}

	modifier checkOwnerAndAccept() {
		require(msg.pubkey() == tvm.pubkey(), 101, "Cannot be executed by non-owner");
		tvm.accept();
		_;
	}

	// Function to add new task
	function addTask(string name) public checkOwnerAndAccept returns (mapping(int8=>Task)) {
		// Get current timestamp
		uint timestamp = now;

		// Add new sctructure element to mapping
		Task new_task;
		new_task = Task(name, timestamp, false);
		task_list[counter] = new_task;

		// Increment task counter
		counter ++;

		return task_list;
	}

	// Function to get number of open tasks (where Task.is_done == false)
	function getOpenTasks() public view checkOwnerAndAccept returns (uint) {
		uint open_tasks = 0;

		// Iterating over the counter and checking two conditions: 1. Element with current index exists 2. Task with this index is not done
		for (int8 index = 0; index <= counter; index++) {
			if (task_list.exists(index)) {
				if (task_list[index].is_done == false) {
					open_tasks ++;
				}
			}
		} 

		return open_tasks;
	}

	// Function to show all tasks
	function showTasks() public view checkOwnerAndAccept returns (mapping(int8=>Task)) {
		return task_list;
	}	

	// Function to get task description
	function getDescription(int8 _task_index) public view checkOwnerAndAccept returns (Task) {
			// Check if this task exists before accessing
			require(task_list.exists(_task_index), 110, "Job with this ID does not exist");

			return task_list[_task_index];
	}

	// Function to delete a task
	function deleteTask(int8 _task_index) public checkOwnerAndAccept returns (mapping(int8=>Task)) {
			// Check if this task exists before deleting
			require(task_list.exists(_task_index), 110, "Job with this ID does not exist");

			// Delete element from mapping
			delete task_list[_task_index];

			return task_list;
	}

	// Function to mark task as Done
	function markAsDone(int8 _task_index) public checkOwnerAndAccept returns (mapping(int8=>Task)) {
			// Check if this task exists before accessing
			require(task_list.exists(_task_index), 110, "Job with this ID does not exist");

			// Check that this task is not done yet
			require(task_list[_task_index].is_done == false, 111, "This task is already done");

			task_list[_task_index].is_done = true;

			return task_list;
	}
}