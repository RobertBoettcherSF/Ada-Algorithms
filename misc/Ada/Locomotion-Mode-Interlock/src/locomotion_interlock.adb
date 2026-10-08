pragma SPARK_Mode (On);

package body Locomotion_Interlock
  with SPARK_Mode => On
is
   function Mode_Legal (I : Interlock; Next : Mode) return Boolean is
   begin
      if Next = Safe_Stop then
         return True;
      end if;
      -- Cannot enter Legs while Wheels_Armed without Hybrid_Transition.
      if Next = Legs and then I.Wheels_Arm and then I.Cur /= Hybrid_Transition then
         return False;
      end if;
      case I.Cur is
         when Safe_Stop =>
            return Next = Wheels or else Next = Hybrid_Transition;
         when Wheels =>
            return Next = Hybrid_Transition or else Next = Wheels;
         when Hybrid_Transition =>
            return Next = Legs or else Next = Wheels or else Next = Hybrid_Transition;
         when Legs =>
            return Next = Hybrid_Transition or else Next = Legs;
      end case;
   end Mode_Legal;

   procedure Init (I : out Interlock) is
   begin
      I := (Cur => Safe_Stop, Wheels_Arm => False, Stairs_Req => False);
   end Init;

   procedure Set_Wheels_Armed (I : in out Interlock; Armed : Boolean) is
   begin
      I.Wheels_Arm := Armed;
   end Set_Wheels_Armed;

   procedure Request_Mode
     (I      : in out Interlock;
      Next   : Mode;
      Result : out Status)
   is
   begin
      if Mode_Legal (I, Next) then
         I.Cur := Next;
         if Next = Safe_Stop then
            I.Stairs_Req := False;
         end if;
         Result := Ok;
      else
         Result := Rejected;
      end if;
   end Request_Mode;

   procedure Request_Stairs
     (I      : in out Interlock;
      Result : out Status)
   is
   begin
      if I.Cur = Legs or else I.Cur = Hybrid_Transition then
         I.Stairs_Req := True;
         Result := Ok;
      else
         Result := Rejected;
      end if;
   end Request_Stairs;

end Locomotion_Interlock;
