package Dijkstra_Scholten is

   -- Strong typing for custom data entities
   type Node_ID is new Integer range 0 .. 10_000;
   Null_Node : constant Node_ID := 0;

   -- Possible states for any node in the distributed system
   type Node_State is (Idle, Active);

   -- Record representing the individual state of a node in the network tree
   type Node_Record is record
      ID      : Node_ID := Null_Node;
      State   : Node_State := Idle;
      Parent  : Node_ID := Null_Node;
      Deficit : Natural := 0; -- Count of outgoing messages without corresponding acks
   end record;

   -- Unconstrained array for scaling network size
   type Network_Array is array (Node_ID range <>) of Node_Record;

   -- Core type encapsulating the entire simulated network
   type Network_Type (Max_Node : Node_ID) is record
      Initiator : Node_ID := Null_Node;
      Nodes     : Network_Array (1 .. Max_Node);
   end record;

   -- Custom Exception definitions for edge-cases and error handling
   Invalid_Node_Error     : exception;
   Invalid_State_Error    : exception;
   Negative_Deficit_Error : exception;

   -- Algorithm Procedures
   procedure Initialize (Network : out Network_Type; Initiator : Node_ID);
   
   -- Simulates sending a message, increasing deficit
   procedure Send_Message (Network : in out Network_Type; From, To : Node_ID);
   
   -- Simulates receiving a message, building the tree or sending immediate ack
   procedure Receive_Message (Network : in out Network_Type; From, To : Node_ID);
   
   -- Marks a node as computationally idle. It propagates acks if its deficit is 0
   procedure Set_Idle (Network : in out Network_Type; Node : Node_ID);
   
   -- Validates if the entire system has successfully terminated
   function Is_Terminated (Network : Network_Type) return Boolean;

   -- Exposed for cascade mechanisms internally but helpful for direct network simulation tests
   procedure Receive_Ack (Network : in out Network_Type; At_Node : Node_ID);

end Dijkstra_Scholten;
