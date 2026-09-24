-- src/lamport_ordering.adb
-- Implementation body for Lamport Ordering

package body Lamport_Ordering is

   -- Helper Function: Safely increments the clock, checking for overflow boundary limits
   procedure Increment_Clock (Clock : in out Logical_Clock) is
   begin
      if Clock = Logical_Clock'Last then
         raise Clock_Overflow;
      end if;
      Clock := Clock + 1;
   end Increment_Clock;

   procedure Initialize (Process : out Process_State; ID : Process_Identifier; Initial_Time : Logical_Clock := 0) is
   begin
      Process.ID := ID;
      Process.Clock := Initial_Time;
   end Initialize;

   procedure Local_Event (Process : in out Process_State) is
   begin
      Increment_Clock (Process.Clock);
   end Local_Event;

   function Send_Event (Process : in out Process_State) return Message is
      Msg : Message;
   begin
      Increment_Clock (Process.Clock);
      Msg.Sender := Process.ID;
      Msg.Timestamp := Process.Clock;
      return Msg;
   end Send_Event;

   procedure Receive_Event (Process : in out Process_State; Msg : Message) is
   begin
      -- Standard Lamport logic: max(local_clock, message_clock)
      if Msg.Timestamp > Process.Clock then
         Process.Clock := Msg.Timestamp;
      end if;
      -- Increment after synchronizing with the max
      Increment_Clock (Process.Clock);
   end Receive_Event;

   function Happens_Before (Clock_A : Logical_Clock; ID_A : Process_Identifier;
                            Clock_B : Logical_Clock; ID_B : Process_Identifier) return Boolean is
   begin
      -- Standard partial ordering check
      if Clock_A < Clock_B then
         return True;
      elsif Clock_A > Clock_B then
         return False;
      else
         -- Tie-breaker: timestamps are identical, enforce total ordering via ID
         return ID_A < ID_B;
      end if;
   end Happens_Before;

end Lamport_Ordering;
