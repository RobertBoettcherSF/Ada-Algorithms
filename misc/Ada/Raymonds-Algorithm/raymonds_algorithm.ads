-- src/raymonds_algorithm.ads
-- Specification for Raymond's Tree-Based Distributed Mutual Exclusion Algorithm
--
-- This package implements Raymond's Algorithm for distributed mutual exclusion in
-- a tree-structured network. The algorithm ensures that only one node can be in
-- the Critical Section (CS) at any time by using a token-passing mechanism.
--
-- Key Concepts:
-- - Each node points toward the current token holder (forming a tree)
-- - A node can only enter CS when it possesses the token
-- - Requests are queued in FIFO order
-- - Token is passed to the next node in the queue upon CS release

package Raymonds_Algorithm is

   -- ==========================================
   -- Strong typing for Algorithm Data
   -- ==========================================
   
   -- Unique identifier for each node in the network
   type Node_Id is new Natural;
   
   -- Sentinel value representing an invalid/null node reference
   Null_Node : constant Node_Id := 0;

   -- ==========================================
   -- Message types exchanged in the tree topology
   -- ==========================================
   
   -- Types of messages that can be exchanged between nodes
   type Message_Type is (Request_Msg, Token_Msg);

   -- Message structure containing sender, receiver, and type
   type Message is record
      Kind     : Message_Type;
      Sender   : Node_Id;
      Receiver : Node_Id;
   end record;


   -- ==========================================
   -- Data Structures for Queue Management
   -- ==========================================

   -- Maximum size of the request queue
   Max_Queue : constant := 100;

   -- Fixed-size array for message buffering
   type Message_List is array (1 .. 10) of Message;
   
   -- Fixed-size array for node ID queue
   type Node_Id_List is array (1 .. Max_Queue) of Node_Id;

   -- Buffer for storing messages in transit
   type Message_Buffer is record
      Messages : Message_List;
      Count    : Natural := 0;
   end record;

   -- Circular queue for managing node requests
   type Node_Queue is record
      Data  : Node_Id_List := (others => Null_Node);
      Front : Positive := 1;    -- Index of the first element
      Rear  : Natural := 0;     -- Index of the last element
      Count : Natural := 0;    -- Number of elements in queue
   end record;

   -- ==========================================
   -- Core Node State defined by Raymond's Algorithm
   -- ==========================================
   
   -- Represents the complete state of a node in the distributed system
   type Node_State is record
      Id       : Node_Id := Null_Node;           -- Unique identifier for this node
      Holder   : Node_Id := Null_Node;           -- Points toward the token holder
      Using_CS : Boolean := False;               -- True if actively in Critical Section
      Asked    : Boolean := False;               -- True if a request was sent upward
      Req_Q    : Node_Queue;                   -- FIFO queue for incoming requests
   end record;

   -- ==========================================
   -- Exception Declarations
   -- ==========================================
   
   -- Raised when attempting to enqueue to a full queue
   Queue_Overflow  : exception;
   
   -- Raised when attempting to dequeue from an empty queue
   Queue_Underflow : exception;

   -- ==========================================
   -- Helper Functions (Queue & Messages)
   -- ==========================================
   
   -- Add an item to the circular queue
   procedure Enqueue (Q : in out Node_Queue; Item : Node_Id);
   
   -- Remove an item from the circular queue
   procedure Dequeue (Q : in out Node_Queue; Item : out Node_Id);
   
   -- Check if the queue is empty
   function Is_Empty (Q : Node_Queue) return Boolean;
   
   -- Add a message to the message buffer
   procedure Add_Message (Buffer : in out Message_Buffer; Msg : Message);

   -- ==========================================
   -- Variant 1: Standard Raymond's Algorithm
   -- ==========================================
   
   -- Initialize a node with its ID and the current token holder
   procedure Initialize (Node : in out Node_State; Id : Node_Id; Holder : Node_Id);
   
   -- Request access to the Critical Section
   procedure Request_CS (Node : in out Node_State; Out_Msgs : in out Message_Buffer);
   
   -- Release the Critical Section
   procedure Release_CS (Node : in out Node_State; Out_Msgs : in out Message_Buffer);
   
   -- Handle an incoming request message
   procedure Receive_Request (Node : in out Node_State; From : Node_Id; Out_Msgs : in out Message_Buffer);
   
   -- Handle an incoming token message
   procedure Receive_Token (Node : in out Node_State; Out_Msgs : in out Message_Buffer);

   -- Internal state transition (Exposed for strict unit testing)
   procedure Assign_Token (Node : in out Node_State; Out_Msgs : in out Message_Buffer);

   -- ==========================================
   -- Variant 2: Greedy / Piggybacked Protocol
   -- ==========================================
   -- 
   -- Optimized variant that suppresses duplicate network requests
   -- if a node is already queued, reducing network traffic.
   -- 
   procedure Greedy_Receive_Request (Node : in out Node_State; From : Node_Id; Out_Msgs : in out Message_Buffer);

end Raymonds_Algorithm;
