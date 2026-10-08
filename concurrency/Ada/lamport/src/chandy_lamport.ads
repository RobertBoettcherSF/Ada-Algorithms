pragma Ada_2012;
with Ada.Containers.Doubly_Linked_Lists;

-- Package implementing the Chandy-Lamport Distributed Snapshot Algorithm.
-- Supports both single-initiator and concurrent multi-initiator variants.
package Chandy_Lamport is

   -- System limits (configurable via recompilation for static allocation)
   Max_Nodes : constant := 3;
   Max_Snaps : constant := 2;

   subtype Node_ID is Integer range 1 .. Max_Nodes;
   subtype Snapshot_ID is Integer range 1 .. Max_Snaps;

   type Message_Kind is (App_Message, Marker_Message);

   -- Strong typing for algorithm-specific data
   type Message (Kind : Message_Kind := App_Message) is record
      Sender   : Node_ID;
      Receiver : Node_ID;
      case Kind is
         when App_Message =>
            Payload : Integer; 
         when Marker_Message =>
            Snap_ID : Snapshot_ID; -- Variant support: Identifies concurrent snapshots
      end case;
   end record;

   package Message_Queues is new Ada.Containers.Doubly_Linked_Lists (Element_Type => Message);
   subtype Message_Queue is Message_Queues.List;

   type Channel_State is record
      Is_Recording : Boolean := False;
      Is_Closed    : Boolean := True; -- True if no active snapshot or snapshot finished
      Messages     : Message_Queue;
   end record;

   type Channel_Array is array (Node_ID) of Channel_State;

   type Snapshot_Record is record
      Is_Active      : Boolean := False;
      Has_Recorded   : Boolean := False;
      Recorded_Value : Integer := 0;
      Channels       : Channel_Array;
   end record;

   type Snapshot_Array is array (Snapshot_ID) of Snapshot_Record;

   -- Represents a process/node in the distributed system
   type Node is record
      ID            : Node_ID;
      Current_Value : Integer := 0; -- Core application state (e.g., account balance)
      Snapshots     : Snapshot_Array;
   end record;

   -- Initializes a node with its ID and initial application state
   procedure Init_Node (N : out Node; ID : Node_ID; Initial_Value : Integer);

   -- Simulates normal application event (e.g., processing a transaction)
   procedure Update_Local_State (N : in out Node; Value_Change : Integer);

   -- Initiates a new snapshot (Variant 1: Single Initiator / Variant 2: Concurrent Multi-Initiator)
   procedure Initiate_Snapshot (N : in out Node; S_ID : Snapshot_ID; Out_Markers : out Message_Queue);

   -- Processes an incoming message, multiplexing logic based on Message_Kind
   procedure Receive_Message (N : in out Node; Msg : Message; Out_Markers : out Message_Queue);

   -- Helper Functions
   function Is_Snapshot_Complete (N : Node; S_ID : Snapshot_ID) return Boolean;
   function Get_Recorded_Value (N : Node; S_ID : Snapshot_ID) return Integer;
   function Get_Channel_Messages (N : Node; S_ID : Snapshot_ID; From : Node_ID) return Message_Queue;

end Chandy_Lamport;
