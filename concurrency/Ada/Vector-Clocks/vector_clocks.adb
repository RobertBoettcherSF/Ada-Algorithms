-- vector_clocks.adb
-- 
-- Vector Clocks Algorithm Implementation
-- 
-- This package body implements the Vector Clocks algorithm operations
-- as declared in vector_clocks.ads. See the specification file for
-- detailed documentation of each subprogram.
--
-- Implementation Notes:
--   - All operations maintain the invariant that a process only modifies
--     its own clock component (indexed by P.ID)
--   - Element-wise max operations ensure causality is preserved across
--     message passing
--   - Exception checks prevent out-of-bounds access and dimension mismatches
--
-- Author: Robert Boettcher
-- License: MIT

package body Vector_Clocks is

   -- =========================================================================
   -- SETUP
   -- =========================================================================

   procedure Setup (P : in out Process_Node; ID : Positive) is
   begin
      -- Validate that the ID is within the allowed range for this process node.
      -- The discriminant Num_Processes defines the maximum valid ID.
      if ID > P.Num_Processes then
         raise Invalid_Process_ID with "Process ID exceeds total system processes.";
      end if;
      
      -- Set the process ID and zero out the clock vector.
      -- Initializing to all zeros represents the initial state where
      -- no events have occurred at any process.
      P.ID := ID;
      P.Clock := (others => 0);
   end Setup;

   -- =========================================================================
   -- INTERNAL EVENT
   -- =========================================================================

   procedure Internal_Event (P : in out Process_Node) is
   begin
      -- Increment the clock component corresponding to this process's ID.
      -- This is the only component this process is allowed to modify directly.
      --
      -- Per the vector clock algorithm, each process maintains a counter
      -- for each process in the system. When an internal event occurs,
      -- only the local counter (at index P.ID) is incremented.
      P.Clock (P.ID) := P.Clock (P.ID) + 1;
   end Internal_Event;

   -- =========================================================================
   -- SEND MESSAGE
   -- =========================================================================

   function Send_Message (P : in out Process_Node) return Vector_Clock is
   begin
      -- A send event is fundamentally an internal event that also produces
      -- a clock payload. The process increments its own clock to record
      -- the send event, then returns a copy of its current state.
      --
      -- This follows the vector clock algorithm specification:
      --   1. Increment local clock (via Internal_Event)
      --   2. Return current clock state as part of the message
      --
      -- The returned clock allows the receiver to synchronize its view
      -- of the sender's timeline.
      Internal_Event (P);
      return P.Clock;
   end Send_Message;

   -- =========================================================================
   -- RECEIVE MESSAGE
   -- =========================================================================

   procedure Receive_Message (P : in out Process_Node; Msg_Clock : Vector_Clock) is
   begin
      -- Safety check: Ensure the received clock has the same dimensions
      -- as the local clock. This prevents out-of-bounds errors and ensures
      -- we're comparing compatible system configurations.
      if P.Clock'Length /= Msg_Clock'Length then
         raise Mismatched_Dimensions with "Cannot merge vector clocks of different sizes.";
      end if;

      -- Step 1: Merge the clocks using element-wise maximum.
      -- 
      -- For each index i in the vector:
      --   P.Clock(i) := max(P.Clock(i), Msg_Clock(i))
      --
      -- This ensures that P's clock now reflects the maximum knowledge
      -- from both its own timeline and the sender's timeline.
      --
      -- The element-wise max is the core of the vector clock algorithm:
      -- it captures the "happens-before" relationship by taking the
      -- most advanced state for each process.
      for I in P.Clock'Range loop
         P.Clock (I) := Natural'Max (P.Clock (I), Msg_Clock (I));
      end loop;

      -- Step 2: Increment the local clock component.
      -- 
      -- The act of receiving a message is itself an event, so we
      -- increment P.Clock(P.ID) to record this.
      --
      -- This ensures that if process P receives two messages, the
      -- second receive event will have a higher clock value than the first,
      -- maintaining proper causality tracking.
      P.Clock (P.ID) := P.Clock (P.ID) + 1;
   end Receive_Message;

   -- =========================================================================
   -- LESS-THAN-OR-EQUAL (<=)
   -- =========================================================================

   function "<=" (Left, Right : Vector_Clock) return Boolean is
   begin
      -- Safety check: Ensure both clocks have the same dimensions.
      -- Comparing clocks of different sizes is undefined.
      if Left'Length /= Right'Length then
         raise Mismatched_Dimensions with "Comparison requires identical clock sizes.";
      end if;

      -- Check if all elements of Left are <= corresponding elements of Right.
      --
      -- If Left <= Right, then from Right's perspective, all events
      -- that occurred in Left's timeline have also occurred in Right's
      -- timeline. This means Left's state is "contained within" Right's state.
      --
      -- This is the non-strict happens-before relation: Left may have
      -- happened before Right, or they may be equal.
      for I in Left'Range loop
         if Left (I) > Right (I) then
            return False;
         end if;
      end loop;
      return True;
   end "<=";

   -- =========================================================================
   -- LESS-THAN (<)
   -- =========================================================================

   function "<" (Left, Right : Vector_Clock) return Boolean is
   begin
      -- Safety check: Ensure both clocks have the same dimensions.
      if Left'Length /= Right'Length then
         raise Mismatched_Dimensions;
      end if;

      -- Strict happens-before: Left < Right iff Left <= Right AND Left /= Right
      --
      -- This means all events in Left have occurred in Right's timeline,
      -- AND Right has experienced at least one additional event that Left
      -- has not.
      --
      -- We use "and then" for short-circuit evaluation: if Left <= Right
      -- is false, we don't need to check for inequality.
      return (Left <= Right) and then (Left /= Right);
   end "<";

   -- =========================================================================
   -- ARE_CONCURRENT
   -- =========================================================================

   function Are_Concurrent (Left, Right : Vector_Clock) return Boolean is
   begin
      -- Safety check: Ensure both clocks have the same dimensions.
      if Left'Length /= Right'Length then
         raise Mismatched_Dimensions;
      end if;

      -- Two events are concurrent if neither happens before the other.
      --
      -- This is equivalent to: NOT (Left <= Right OR Right <= Left)
      --
      -- In a distributed system, concurrent events represent independent
      -- timelines that have not communicated with each other. This is
      -- a key advantage of vector clocks over Lamport timestamps - they
      -- can detect true concurrency.
      --
      -- We use "and then" for short-circuit evaluation:
      --   - First check: not (Left <= Right)
      --   - Only if true, check: not (Right <= Left)
      return not (Left <= Right) and then not (Right <= Left);
   end Are_Concurrent;

end Vector_Clocks;
