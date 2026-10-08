-- src/lamport_ordering.ads
-- Specification for Lamport Ordering (Logical Clocks)
-- Implements local, send, and receive events, plus partial/total order comparisons.

package Lamport_Ordering is

   -- Strong typing for algorithm-specific data
   type Logical_Clock is new Natural;
   type Process_Identifier is new Positive;

   -- Represents the state of a process in the distributed system
   type Process_State is record
      ID    : Process_Identifier;
      Clock : Logical_Clock := 0;
   end record;

   -- Represents a message sent between processes, carrying the Lamport timestamp
   type Message is record
      Sender    : Process_Identifier;
      Timestamp : Logical_Clock;
   end record;

   -- Exception raised when a logical clock reaches its maximum capacity
   Clock_Overflow : exception;

   -- Initialize a process with a specific ID and optional starting time
   procedure Initialize (Process : out Process_State; ID : Process_Identifier; Initial_Time : Logical_Clock := 0);

   -- VARIANT 1: Local Event
   -- A process performs an internal event. The clock is incremented by 1.
   procedure Local_Event (Process : in out Process_State);

   -- VARIANT 2: Send Message Event
   -- A process prepares to send a message. Clock increments by 1, and 
   -- the current clock value is attached to the outgoing message.
   function Send_Event (Process : in out Process_State) return Message;

   -- VARIANT 3: Receive Message Event
   -- A process receives a message. The clock is updated to the maximum of 
   -- its current value and the message's timestamp, then incremented by 1.
   procedure Receive_Event (Process : in out Process_State; Msg : Message);

   -- TOTAL ORDERING: Extends Lamport's partial ordering to a total ordering
   -- Tie-breaker: If timestamps are identical, the lower Process ID happened first.
   -- Returns True if Event A happened before Event B.
   function Happens_Before (Clock_A : Logical_Clock; ID_A : Process_Identifier;
                            Clock_B : Logical_Clock; ID_B : Process_Identifier) return Boolean;

end Lamport_Ordering;
