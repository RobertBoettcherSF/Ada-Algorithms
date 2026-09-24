-- vector_clocks.ads
-- 
-- Vector Clocks Algorithm Implementation for Distributed Systems
-- 
-- This package implements the Vector Clocks algorithm as described in:
--   - Fidge, C. J. (1988). "Timestamps in a Distributed System: A Formal Specification and Implementation"
--   - Mattern, F. (1988). "Virtual Time and Global States of Distributed Systems"
--
-- Vector clocks provide a mechanism for capturing causality in distributed systems.
-- Unlike Lamport timestamps, vector clocks can determine if two events are:
--   1. Causally related (one happened before the other)
--   2. Concurrent (happened independently, no causal relationship)
--
-- Author: Robert Boettcher
-- License: MIT

package Vector_Clocks is

   -- =========================================================================
   -- TYPE DEFINITIONS
   -- =========================================================================

   -- Vector_Clock: An unconstrained array representing the logical clock state.
   -- Each element corresponds to a process in the distributed system.
   -- The value at index i represents the number of events that have occurred
   -- at process i, from the perspective of the current process.
   --
   -- Example: Vector_Clock(1..3) := (2, 1, 0) means:
   --   - Process 1 has experienced 2 events
   --   - Process 2 has experienced 1 event
   --   - Process 3 has experienced 0 events (from this process's perspective)
   type Vector_Clock is array (Positive range <>) of Natural;

   -- Process_Node: Represents a single process in the distributed system.
   -- 
   -- The discriminant Num_Processes defines the total number of processes
   -- in the system and determines the size of the vector clock.
   -- This ensures type safety - you cannot accidentally mix processes from
   -- different system configurations.
   --
   -- Fields:
   --   ID: The unique identifier for this process (1 to Num_Processes)
   --   Clock: The current state of this process's vector clock
   type Process_Node (Num_Processes : Positive) is record
      ID    : Positive := 1;
      Clock : Vector_Clock (1 .. Num_Processes) := (others => 0);
   end record;

   -- =========================================================================
   -- EXCEPTIONS
   -- =========================================================================

   -- Mismatched_Dimensions: Raised when attempting to compare or merge
   -- vector clocks of different sizes. This prevents out-of-bounds errors
   -- and ensures type safety across operations.
   Mismatched_Dimensions : exception;

   -- Invalid_Process_ID: Raised when attempting to assign a process ID
   -- that exceeds the declared number of processes (Num_Processes).
   -- This enforces the constraint that process IDs must be in the range [1, Num_Processes].
   Invalid_Process_ID    : exception;

   -- =========================================================================
   -- CORE ALGORITHM OPERATIONS
   -- 
   -- These procedures implement the fundamental vector clock operations
   -- as defined in the original papers.
   -- =========================================================================

   -- Setup: Initializes a process node with a given ID.
   -- 
   -- This procedure zeroes out the process's vector clock and assigns
   -- the specified ID. It validates that the ID is within valid bounds.
   --
   -- Parameters:
   --   P  : in out Process_Node - The process node to initialize
   --   ID : in     Positive     - The process identifier (must be <= Num_Processes)
   --
   -- Raises:
   --   Invalid_Process_ID if ID > Num_Processes
   --
   -- Example:
   --   declare
   --      P : Process_Node(3);
   --   begin
   --      Setup(P, 2);  -- Initialize as process 2 in a 3-process system
   --   end;
   procedure Setup (P : in out Process_Node; ID : Positive);

   -- Internal_Event: Records that a process has experienced an internal event.
   -- 
   -- In vector clock terminology, an internal event is any event that
   -- occurs at a process that does not involve communication (e.g., local
   -- computation, user input). This increments only the process's own
   -- clock component.
   --
   -- Parameters:
   --   P : in out Process_Node - The process experiencing the internal event
   --
   -- Effect:
   --   P.Clock(P.ID) is incremented by 1
   --
   -- Note: This is the simplest vector clock operation and forms the basis
   -- for the Send_Message operation.
   procedure Internal_Event (P : in out Process_Node);

   -- Send_Message: Prepares a message for transmission to another process.
   -- 
   -- According to the vector clock algorithm, sending a message is equivalent
   -- to experiencing an internal event. The process increments its own clock
   -- and returns a copy of its current vector clock to be included with the
   -- message payload.
   --
   -- Parameters:
   --   P : in out Process_Node - The process sending the message
   --
   -- Returns:
   --   Vector_Clock - A copy of the process's current clock state
   --
   -- Effect:
   --   P.Clock(P.ID) is incremented by 1 (via Internal_Event)
   --
   -- Usage:
   --   declare
   --      P : Process_Node(2);
   --      Msg_Clock : Vector_Clock;
   --   begin
   --      Setup(P, 1);
   --      Msg_Clock := Send_Message(P);  -- Send message with clock (1, 0)
   --   end;
   function Send_Message (P : in out Process_Node) return Vector_Clock;

   -- Receive_Message: Processes an incoming message from another process.
   -- 
   -- When a process receives a message, it must merge the received vector
   -- clock with its own. The merge operation uses element-wise maximum:
   --   For each index i: P.Clock(i) := max(P.Clock(i), Msg_Clock(i))
   --
   -- After merging, the process increments its own clock component to
   -- record the receive event itself.
   --
   -- Parameters:
   --   P         : in out Process_Node - The process receiving the message
   --   Msg_Clock : in     Vector_Clock  - The vector clock from the received message
   --
   -- Raises:
   --   Mismatched_Dimensions if P.Clock'Length /= Msg_Clock'Length
   --
   -- Effect:
   --   1. Each element of P.Clock is updated to max(P.Clock(i), Msg_Clock(i))
   --   2. P.Clock(P.ID) is incremented by 1
   --
   -- Note: The element-wise max operation ensures that the receiving process
   -- accounts for all events that the sender was aware of, maintaining
   -- causality tracking across the distributed system.
   procedure Receive_Message (P : in out Process_Node; Msg_Clock : Vector_Clock);

   -- =========================================================================
   -- PARTIAL ORDERING COMPARISON FUNCTIONS
   -- 
   -- These functions implement the happens-before relationship and
   -- concurrency detection as defined in the vector clock algorithm.
   -- =========================================================================

   -- "<=" (Less-than or equal): Determines non-strict happens-before.
   -- 
   -- Returns True if Left is less-than-or-equal to Right, meaning:
   --   For all i: Left(i) <= Right(i)
   --
   -- This indicates that all events represented in Left have also
   -- occurred in Right's timeline (from Right's perspective).
   --
   -- Parameters:
   --   Left  : Vector_Clock - The first vector clock
   --   Right : Vector_Clock - The second vector clock
   --
   -- Returns:
   --   Boolean - True if Left <= Right (non-strict happens-before)
   --
   -- Raises:
   --   Mismatched_Dimensions if Left'Length /= Right'Length
   --
   -- Example:
   --   Vector_Clock'(1, 0) <= Vector_Clock'(1, 1)  -- True
   --   Vector_Clock'(1, 2) <= Vector_Clock'(1, 1)  -- False
   function "<=" (Left, Right : Vector_Clock) return Boolean;

   -- "<" (Less-than): Determines strict happens-before.
   -- 
   -- Returns True if Left strictly happens before Right, meaning:
   --   Left <= Right AND Left /= Right
   --
   -- This indicates that all events in Left have occurred in Right's
   -- timeline, and Right has experienced at least one additional event.
   --
   -- Parameters:
   --   Left  : Vector_Clock - The first vector clock
   --   Right : Vector_Clock - The second vector clock
   --
   -- Returns:
   --   Boolean - True if Left < Right (strict happens-before)
   --
   -- Raises:
   --   Mismatched_Dimensions if Left'Length /= Right'Length
   --
   -- Example:
   --   Vector_Clock'(1, 0) < Vector_Clock'(1, 1)   -- True
   --   Vector_Clock'(1, 1) < Vector_Clock'(1, 1)   -- False (not strict)
   function "<" (Left, Right : Vector_Clock) return Boolean;

   -- Are_Concurrent: Determines if two events are concurrent.
   -- 
   -- Two events are concurrent if neither happens before the other.
   -- This is equivalent to: NOT (Left <= Right OR Right <= Left)
   --
   -- Concurrent events represent independent timelines that have not
   -- communicated with each other. This is a key feature of vector
   -- clocks - they can detect true concurrency, which Lamport timestamps
   -- cannot.
   --
   -- Parameters:
   --   Left  : Vector_Clock - The first vector clock
   --   Right : Vector_Clock - The second vector clock
   --
   -- Returns:
   --   Boolean - True if Left and Right are concurrent (no causal relationship)
   --
   -- Raises:
   --   Mismatched_Dimensions if Left'Length /= Right'Length
   --
   -- Example:
   --   Are_Concurrent(Vector_Clock'(1, 0), Vector_Clock'(0, 1))  -- True
   --   Are_Concurrent(Vector_Clock'(1, 0), Vector_Clock'(1, 1))  -- False
   function Are_Concurrent (Left, Right : Vector_Clock) return Boolean;

end Vector_Clocks;
