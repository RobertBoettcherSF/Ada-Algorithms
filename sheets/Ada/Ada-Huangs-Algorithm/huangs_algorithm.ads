package Huangs_Algorithm is

   -- Strong typing for algorithm-specific data
   type Node_ID is new Positive;
   type Weight_Type is new Long_Float;
   type Node_State is (Idle, Active);

   Invalid_Operation : exception;

   type Node is record
      ID     : Node_ID;
      State  : Node_State := Idle;
      Weight : Weight_Type := 0.0;
   end record;

   type Node_Array is array (Node_ID range <>) of Node;

   -- System state represents a snapshot of the distributed environment
   type System_State (Num_Nodes : Node_ID) is record
      Nodes     : Node_Array (1 .. Num_Nodes);
      Initiator : Node_ID := 1;
   end record;

   -- ==========================================
   -- Core Algorithm Operations
   -- ==========================================
   procedure Initialize (Sys : out System_State; Initiator : Node_ID);

   -- Variant 1: Static Weight Splitting (Always sends exactly half of the current weight)
   procedure Send_Message_Static (Sys : in out System_State; From : Node_ID; W_Msg : out Weight_Type);

   -- Variant 2: Dynamic Weight Splitting (Sends a custom fraction of the current weight)
   procedure Send_Message_Dynamic (Sys : in out System_State; From : Node_ID; Fraction : Long_Float; W_Msg : out Weight_Type);

   -- Node receives a delegated task and its associated weight
   procedure Receive_Message (Sys : in out System_State; At_Node : Node_ID; W_Msg : Weight_Type);

   -- Node completes its task and yields its weight back to the system
   procedure Finish_Task (Sys : in out System_State; At_Node : Node_ID; W_Ret : out Weight_Type);

   -- Accumulator function for the controlling agent (Initiator)
   procedure Receive_Returned_Weight (Sys : in out System_State; W_Ret : Weight_Type);

   -- Checks if distributed computation is completely terminated
   function Is_Terminated (Sys : System_State) return Boolean;

   -- Helper: Validates weight boundaries preventing floating-point anomalies
   function Is_Virtually_Equal (W1, W2 : Weight_Type) return Boolean;

end Huangs_Algorithm;
