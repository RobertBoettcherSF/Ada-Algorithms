-- src/naimi_trehel.ads
package Naimi_Trehel is

   Max_Nodes : constant := 100;
   type Node_ID is range 0 .. Max_Nodes;
   Null_Node : constant Node_ID := 0;
   
   -- Strong typing: Valid nodes are strictly 1 to Max_Nodes
   subtype Valid_Node_ID is Node_ID range 1 .. Max_Nodes;

   type Message_Kind is (Request_Msg, Token_Msg);
   type Message is record
      Kind   : Message_Kind;
      Source : Valid_Node_ID;
      Dest   : Valid_Node_ID;
   end record;

   -- Node state modeling the dynamic tree structure
   type Node_State is record
      Owner         : Valid_Node_ID := 1;
      Next_Node     : Node_ID := Null_Node;
      Token_Present : Boolean := False;
      Requesting    : Boolean := False;
   end record;

   type Node_Array is array (Valid_Node_ID range <>) of Node_State;
   
   type Message_Array is array (1 .. 1000) of Message;
   type Message_Queue is record
      Items : Message_Array;
      Count : Natural := 0;
   end record;

   -- Simulator encapsulates the entire distributed system graph
   type Distributed_System (Num_Nodes : Valid_Node_ID) is record
      Nodes : Node_Array (1 .. Num_Nodes);
      Queue : Message_Queue;
   end record;

   -- Exceptions for strict error boundaries
   Critical_Section_Violation : exception;
   Queue_Overflow : exception;
   Queue_Underflow : exception;

   -- Core API
   procedure Initialize (Sys : out Distributed_System; Initial_Token_Holder : Valid_Node_ID := 1);
   procedure Request_Critical_Section (Sys : in out Distributed_System; Node : Valid_Node_ID);
   procedure Release_Critical_Section (Sys : in out Distributed_System; Node : Valid_Node_ID);
   
   -- Simulation Network API
   procedure Process_Next_Message (Sys : in out Distributed_System; Success : out Boolean);
   procedure Process_All_Messages (Sys : in out Distributed_System);
   
   -- Helper Queries
   function Has_Token (Sys : Distributed_System; Node : Valid_Node_ID) return Boolean;
   function Is_Requesting (Sys : Distributed_System; Node : Valid_Node_ID) return Boolean;
   function Pending_Messages (Sys : Distributed_System) return Natural;

end Naimi_Trehel;
