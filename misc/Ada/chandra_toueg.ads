-- chandra_toueg.ads
-- Specification for the Chandra-Toueg Consensus Algorithm using 
-- Unreliable Failure Detectors (Eventually Weak).
package Chandra_Toueg is

   -- System configuration
   Max_Processes : constant := 5;
   Majority      : constant := (Max_Processes / 2) + 1;
   
   type Process_ID is new Positive range 1 .. Max_Processes;
   type Round_Number is new Natural;
   type Value_Type is new Integer;

   type Process_Status is (Alive, Crashed);
   type Consensus_State is (Undecided, Decided);
   type Vote_Type is (None, Ack, Nack);

   -- Strong typing for a process's internal state
   type Process_State is record
      Status        : Process_Status := Alive;
      State         : Consensus_State := Undecided;
      Has_Estimate  : Boolean := False;
      Estimate      : Value_Type := 0;
      TS            : Round_Number := 0; -- Timestamp of last update
      Decided_Value : Value_Type := 0;
   end record;

   type Process_Array is array (Process_ID) of Process_State;

   -- Failure Detector: FD(i, j) = True means process 'i' suspects process 'j'
   type Failure_Detector is array (Process_ID, Process_ID) of Boolean;

   -- Messages for Phase 1
   type Estimate_Message is record
      Valid        : Boolean := False;
      Sender       : Process_ID := 1;
      Has_Estimate : Boolean := False;
      Estimate     : Value_Type := 0;
      TS           : Round_Number := 0;
   end record;
   type Estimate_Array is array (Process_ID) of Estimate_Message;
   type Vote_Array is array (Process_ID) of Vote_Type;

   -- Named type required for procedure parameters in Ada
   type Value_Array is array (Process_ID) of Value_Type;

   -- Simulator encapsulates the entire distributed system state for deterministic testing
   type Simulator is record
      Processes     : Process_Array;
      FD            : Failure_Detector := (others => (others => False));
      Current_Round : Round_Number := 1;

      -- Mailboxes representing network channels for a given round
      Phase_1_Messages : Estimate_Array := (others => (Valid => False, others => <>));
      Phase_2_Proposal : Value_Type := 0;
      Phase_2_Valid    : Boolean := False;
      Phase_3_Votes    : Vote_Array := (others => None);
   end record;

   -- Rotating coordinator selection (Variant handling)
   function Get_Coordinator (R : Round_Number) return Process_ID;

   -- The four distinct phases of the Chandra-Toueg algorithm
   procedure Phase_1 (Sim : in out Simulator);
   procedure Phase_2 (Sim : in out Simulator);
   procedure Phase_3 (Sim : in out Simulator);
   procedure Phase_4 (Sim : in out Simulator);

   -- Helper to execute a full round sequentially
   procedure Run_Round (Sim : in out Simulator);

   -- Setup and failure injection helpers
   procedure Initialize (Sim : out Simulator; Initial_Values : Value_Array);
   procedure Crash_Process (Sim : in out Simulator; P : Process_ID);
   procedure Suspect (Sim : in out Simulator; Suspector, Suspected : Process_ID);
   
end Chandra_Toueg;
