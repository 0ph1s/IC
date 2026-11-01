A finite state machine (FSM) is ==a mathematical model of computation that can be in only one of a finite number of states at any given time==. It transitions from one state to another based on inputs, and these transitions can trigger actions or outputs. FSMs are used to model systems with sequential logic, such as turnstiles, traffic lights, or software. 

## Key components of an FSM

- **States:** A finite set of operating modes or conditions the system can be in (e.g., "locked" or "unlocked"). 

- **Transitions:** The paths that allow the system to move from one state to another. 

- **Inputs:** The events or conditions that trigger a transition. 

- **Actions:** The operations that are performed when a transition occurs or when the machine is in a specific state. 

How it works

An FSM operates by:

1. Starting in an initial state. 
	
2. Waiting for an input. 
	
3. When an input is received, it checks its current state and the input to determine the next state. 
	
 4. If a transition to a new state is defined for that input, it moves to the new state and performs any associated actions. 
	
 5. It continues this process indefinitely.

### Examples

- **Turnstile:** Has two states: "locked" and "unlocked". 
	- **Input:** A coin is inserted. Action: Transition from "locked" to "unlocked". 
	- **Input:** A push. Action: Transition from "unlocked" to "locked" and allow passage. 

- **Traffic light:** Has states like "red," "yellow," and "green". 
	- **Input:** A timer expires. Action: Transition to the next state in the sequence (e.g., "green" to "yellow"). 

- **Simple vending machine:**  Has states like "no coin," "coin inserted," and "item selected". 
	- **Input:** A coin is inserted. Action: Transition from "no coin" to "coin inserted". 
	- **Input:** Item is selected. Action: Dispense item and transition to "no coin".