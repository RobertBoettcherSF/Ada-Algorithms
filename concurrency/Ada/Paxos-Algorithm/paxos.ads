-- paxos.ads
package Paxos is

   -- Basic Types for Paxos
   type Node_ID is new Integer range 0 .. 10_000;
   type Proposal_Number is new Integer range 0 .. Integer'Last;
   type Value_Type is new Integer;
   Null_Value : constant Value_Type := -1;

   -- A Proposal ID must be globally unique. We combine a round number and node ID.
   type Proposal_ID is record
      Number : Proposal_Number := 0;
      Node   : Node_ID := 0;
   end record;

   -- Overload the ">" operator for Proposal_ID comparison
   function ">" (Left, Right : Proposal_ID) return Boolean;
   function ">=" (Left, Right : Proposal_ID) return Boolean;

   -- Acceptor State Machine
   type Acceptor_State is record
      Min_Proposal      : Proposal_ID := (0, 0);
      Accepted_Proposal : Proposal_ID := (0, 0);
      Accepted_Value    : Value_Type  := Null_Value;
   end record;

   -- Response structure for Phase 1 (Promise)
   type Promise_Response is record
      Ack               : Boolean := False;
      Previous_Proposal : Proposal_ID := (0, 0);
      Previous_Value    : Value_Type := Null_Value;
   end record;

   -------------------------------------------------
   -- VARIANT 1: Basic Paxos
   -------------------------------------------------
   
   -- Phase 1b: Promise
   procedure Basic_Paxos_Prepare
     (Acceptor : in out Acceptor_State;
      Proposal : in Proposal_ID;
      Response : out Promise_Response);

   -- Phase 2b: Accepted
   procedure Basic_Paxos_Accept
     (Acceptor : in out Acceptor_State;
      Proposal : in Proposal_ID;
      Value    : in Value_Type;
      Accepted : out Boolean);

   -------------------------------------------------
   -- VARIANT 2: Multi-Paxos
   -------------------------------------------------
   -- Extends Basic Paxos to an array of log instances.
   type Instance_ID is new Integer range 1 .. 1000;
   type Multi_Acceptor_Array is array (Instance_ID range <>) of Acceptor_State;

   procedure Multi_Paxos_Accept
     (Acceptors : in out Multi_Acceptor_Array;
      Instance  : in Instance_ID;
      Proposal  : in Proposal_ID;
      Value     : in Value_Type;
      Accepted  : out Boolean);

   -------------------------------------------------
   -- VARIANT 3: Fast Paxos
   -------------------------------------------------
   -- Fast Paxos allows clients to bypass the Proposer by sending 
   -- directly to Acceptors for a predetermined "Any" proposal.
   Fast_Proposal : constant Proposal_ID := (Number => 1, Node => 0);

   procedure Fast_Paxos_Any_Accept
     (Acceptor : in out Acceptor_State;
      Value    : in Value_Type;
      Accepted : out Boolean);

   -------------------------------------------------
   -- VARIANT 4: Cheap Paxos
   -------------------------------------------------
   -- Cheap Paxos relies on a Main Quorum and an Auxiliary Quorum. 
   -- Auxiliary nodes only participate if Main nodes fail.
   type Node_Role is (Main, Auxiliary);
   
   procedure Cheap_Paxos_Accept
     (Acceptor   : in out Acceptor_State;
      Role       : in Node_Role;
      Main_Is_Up : in Boolean;
      Proposal   : in Proposal_ID;
      Value      : in Value_Type;
      Accepted   : out Boolean);

   -- Exceptions
   Invalid_Proposal : exception;
   Invalid_Instance : exception;

end Paxos;
