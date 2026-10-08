package Ricart_Agrawala is
   -- Defines the maximum number of nodes in the distributed system.
   Max_Nodes : constant := 10;
   type Node_ID is range 1 .. Max_Nodes;
   type Sequence_Number is new Natural;

   type Node_State is (Released, Wanted, Held);
   
   -- Algorithm variant: Standard sends N-1 requests.
   -- Roucairol_Carvalho caches implicit permissions.
   type Algorithm_Variant is (Standard, Roucairol_Carvalho);

   -- Boolean mask used for tracking requests, deferred replies, and permissions.
   type Node_Set is array (Node_ID) of Boolean;

   type RA_Node is tagged private;

   -- Initializes the node to a safe default state.
   procedure Initialize 
     (Node    : out RA_Node;
      ID      : in  Node_ID;
      Variant : in  Algorithm_Variant := Algorithm_Variant'(Standard));

   -- Called when the node wishes to enter the Critical Section (CS).
   -- Returns a boolean mask of nodes that must be sent a REQUEST message.
   procedure Request_Critical_Section
     (Node              : in out RA_Node;
      Outgoing_Requests : out Node_Set);

   -- Processes an incoming REQUEST message.
   -- Send_Reply is True if an immediate REPLY should be sent back.
   procedure Receive_Request
     (Node       : in out RA_Node;
      Sender     : in  Node_ID;
      Req_Seq    : in  Sequence_Number;
      Send_Reply : out Boolean);

   -- Processes an incoming REPLY message.
   procedure Receive_Reply
     (Node   : in out RA_Node;
      Sender : in  Node_ID);

   -- Checks if all necessary replies have been received.
   function Can_Enter_CS (Node : in RA_Node) return Boolean;

   -- Explicitly enters the CS if conditions are met.
   procedure Enter_CS (Node : in out RA_Node);

   -- Called when exiting the CS. 
   -- Returns a boolean mask of nodes that must now be sent a REPLY message.
   procedure Release_Critical_Section
     (Node             : in out RA_Node;
      Outgoing_Replies : out Node_Set);

   -- Observers for Verification & Validation testing
   function Get_State (Node : in RA_Node) return Node_State;
   function Get_Seq_Num (Node : in RA_Node) return Sequence_Number;

private
   -- RA_Node represents a single node in the distributed system.
   -- Each node maintains its own state and communicates with peers
   -- to achieve mutual exclusion for the Critical Section.
   type RA_Node is tagged record
      ID               : Node_ID := 1;              -- Unique identifier for this node
      State            : Node_State := Released;    -- Current CS state machine position
      Seq_Num          : Sequence_Number := 0;       -- Lamport logical clock: current request sequence
      Highest_Seen_Seq : Sequence_Number := 0;       -- Lamport logical clock: highest seen from any node
      Variant          : Algorithm_Variant := Algorithm_Variant'(Standard);  -- Algorithm variant in use
      Deferred         : Node_Set := (others => False);  -- Nodes whose REQUESTs were deferred (will REPLY later)
      Replies_Needed   : Natural := 0;               -- Count of outstanding REPLY messages needed
      Permissions      : Node_Set := (others => False); -- For Roucairol-Carvalho: cached implicit permissions
   end record;
end Ricart_Agrawala;
