-- Clean-room educational mission FSM (not Rivr proprietary).
pragma SPARK_Mode (On);

package Mission_FSM
  with SPARK_Mode => On
is
   type State is
     (Idle, Pickup, Transit, Last_Yards, Doorstep, Unlock, Return_Home, Fault, Remote);

   type Status is (Ok, Rejected, Faulted);

   type Machine is private;

   procedure Init (M : out Machine)
     with Global => null,
          Post   => Current (M) = Idle;

   function Current (M : Machine) return State
     with Global => null;

   procedure Request (M : in out Machine; Next : State; Result : out Status)
     with Global => null;

   function Legal (From, To : State) return Boolean
     with Global => null;

private
   type Machine is record
      Cur           : State := Idle;
      Pre_Remote    : State := Idle;
      In_Remote     : Boolean := False;
   end record;

   function Current (M : Machine) return State is (M.Cur);

end Mission_FSM;
