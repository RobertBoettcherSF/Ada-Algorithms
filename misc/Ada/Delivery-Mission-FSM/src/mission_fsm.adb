pragma SPARK_Mode (On);

package body Mission_FSM
  with SPARK_Mode => On
is
   function Legal (From, To : State) return Boolean is
   begin
      if To = Fault then
         return From /= Idle and then From /= Fault;
      end if;
      if To = Remote then
         return From /= Fault and then From /= Remote;
      end if;
      case From is
         when Idle =>
            return To = Pickup;
         when Pickup =>
            return To = Transit or else To = Idle;
         when Transit =>
            return To = Last_Yards or else To = Fault;
         when Last_Yards =>
            return To = Doorstep or else To = Transit;
         when Doorstep =>
            return To = Unlock or else To = Last_Yards;
         when Unlock =>
            return To = Return_Home;
         when Return_Home =>
            return To = Idle;
         when Fault =>
            return To = Idle;
         when Remote =>
            -- Resume handled specially; Remote->same prior via Request
            return False;
      end case;
   end Legal;

   procedure Init (M : out Machine) is
   begin
      M := (Cur => Idle, Pre_Remote => Idle, In_Remote => False);
   end Init;

   procedure Request (M : in out Machine; Next : State; Result : out Status) is
   begin
      -- Resume from Remote: Next is the state to resume to (must be Pre_Remote)
      if M.Cur = Remote then
         if Next = M.Pre_Remote then
            M.Cur := M.Pre_Remote;
            M.In_Remote := False;
            Result := Ok;
         else
            Result := Rejected;
         end if;
         return;
      end if;

      if Next = Remote and then Legal (M.Cur, Remote) then
         M.Pre_Remote := M.Cur;
         M.Cur := Remote;
         M.In_Remote := True;
         Result := Ok;
         return;
      end if;

      if Legal (M.Cur, Next) then
         M.Cur := Next;
         if Next = Fault then
            Result := Faulted;
         else
            Result := Ok;
         end if;
      else
         Result := Rejected;
      end if;
   end Request;

end Mission_FSM;
