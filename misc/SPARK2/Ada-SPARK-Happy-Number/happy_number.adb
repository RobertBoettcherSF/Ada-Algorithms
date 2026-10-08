pragma SPARK_Mode (On);

package body Happy_Number is
   subtype Digit_Sum is Natural range 0 .. 810;

   function Square (Digit : Natural) return Natural is
   begin
      case Digit is
         when 0 => return 0;
         when 1 => return 1;
         when 2 => return 4;
         when 3 => return 9;
         when 4 => return 16;
         when 5 => return 25;
         when 6 => return 36;
         when 7 => return 49;
         when 8 => return 64;
         when others => return 81;
      end case;
   end Square;

   function Next_Value (N : Natural) return Digit_Sum is
      Value : Natural := N;
      Sum   : Digit_Sum := 0;
   begin
      for Step in 1 .. 10 loop
         pragma Loop_Invariant (Sum <= (Step - 1) * 81);
         declare
            Digit : constant Natural := Value mod 10;
         begin
            Sum := Sum + Square (Digit);
            Value := Value / 10;
         end;
      end loop;
      return Sum;
   end Next_Value;

   function Is_Happy (N : Number) return Boolean is
      Current : Natural := N;
   begin
      for Step in 1 .. 20 loop
         if Current = 1 then
            return True;
         elsif Current = 4 then
            return False;
         else
            Current := Next_Value (Current);
         end if;
      end loop;
      return Current = 1;
   end Is_Happy;
end Happy_Number;
