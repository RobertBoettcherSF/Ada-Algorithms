-- src/maekawa.ads
-- Specification for Maekawa's Distributed Mutual Exclusion Algorithm
-- Implements Basic and Deadlock-Free (Inquire/Yield/Fail) variants.

package Maekawa is
   
   -- Strong typing for algorithm-specific data
   Max_Nodes  : constant := 9; -- Represents a 3x3 grid
   Max_Queue  : constant := Max_Nodes;
   Max_Events : constant := 1000;

   type Node_Id is new Integer range 0 .. Max_Nodes;
   subtype Valid_Node_Id is Node_Id range 1 .. Max_Nodes;

   -- Quorum_Array now allows Node_Id so 0 can be used as an "empty" sentinel
   type Quorum_Array is array (Positive range <>) of Node_Id;
   
   type Message_Kind is 
     (Msg_Request, 
      Msg_Reply, 
      Msg_Release, 
      Msg_Inquire, 
      Msg_Fail, 
      Msg_Yield);

   type Node_State is (Init, Requesting, Holding);

   -- Types for Priority Queue
   type Queue_Item is record
      Node      : Valid_Node_Id;
      Timestamp : Integer;
   end record;

   type Queue_Array is array (1 .. Max_Queue) of Queue_Item;
   
   type Request_Queue is record
      Count : Natural := 0;
      Items : Queue_Array;
   end record;

   -- Node definition
   type Node_Type is record
      Id            : Valid_Node_Id := Valid_Node_Id'First;
      State         : Node_State := Init;
      Voted         : Boolean := False;
      Voted_For     : Node_Id := 0;
      Inquired      : Boolean := False;
      Timestamp     : Integer := 0;
      Replies_Count : Natural := 0;
      Quorum_Size   : Natural := 0;
      Quorum        : Quorum_Array(1 .. Max_Nodes) := (others => 0);
      Queue         : Request_Queue;
   end record;

   type Node_List is array (Valid_Node_Id) of Node_Type;

   -- Event structure for simulating distributed messages
   type Event_Type is record
      Kind      : Message_Kind;
      Sender    : Valid_Node_Id;
      Receiver  : Valid_Node_Id;
      Timestamp : Integer;
   end record;

   type Event_Array is array (1 .. Max_Events) of Event_Type;
   
   type Event_Queue is record
      Count : Natural := 0;
      Items : Event_Array;
   end record;

   -- System state holding all nodes and the network event queue
   type Maekawa_System is record
      Nodes  : Node_List;
      Events : Event_Queue;
   end record;

   -- Core Procedures
   procedure Initialize (System : out Maekawa_System);
   
   -- Variants of Quorum construction
   procedure Generate_Grid_Quorums (System : in out Maekawa_System);
   function Check_Intersection (System : Maekawa_System; N1, N2 : Valid_Node_Id) return Boolean;

   -- API for Nodes
   procedure Request_CS (System : in out Maekawa_System; Node : Valid_Node_Id; TS : Integer);
   procedure Release_CS (System : in out Maekawa_System; Node : Valid_Node_Id);
   
   -- Network Simulation
   procedure Process_Next_Event (System : in out Maekawa_System);
   procedure Process_All_Events (System : in out Maekawa_System);

   -- Custom Exceptions
   Capacity_Error : exception;
   Invalid_State_Error : exception;

private
   procedure Enqueue_Event (System : in out Maekawa_System; Ev : Event_Type);
   procedure Enqueue_Request (Q : in out Request_Queue; Item : Queue_Item);
   procedure Dequeue_Request (Q : in out Request_Queue; Item : out Queue_Item);
   
   -- Internal Message Handlers (Variants handled inside)
   procedure Handle_Request (System : in out Maekawa_System; Sender, Receiver : Valid_Node_Id; TS : Integer);
   procedure Handle_Reply   (System : in out Maekawa_System; Sender, Receiver : Valid_Node_Id);
   procedure Handle_Release (System : in out Maekawa_System; Sender, Receiver : Valid_Node_Id);
   procedure Handle_Inquire (System : in out Maekawa_System; Sender, Receiver : Valid_Node_Id);
   procedure Handle_Fail    (System : in out Maekawa_System; Sender, Receiver : Valid_Node_Id);
   procedure Handle_Yield   (System : in out Maekawa_System; Sender, Receiver : Valid_Node_Id);

end Maekawa;
