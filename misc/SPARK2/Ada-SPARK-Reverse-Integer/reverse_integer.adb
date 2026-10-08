pragma SPARK_Mode (On);

package body Reverse_Integer is
   function Reversed (Value : Input) return Input is
      Magnitude : Integer := Value;
   begin
      if Magnitude < 0 then
         Magnitude := -Magnitude;
      end if;
      if Magnitude >= 10 then
         Magnitude := (Magnitude mod 10) * 10 + Magnitude / 10;
      end if;
      if Value < 0 then
         return -Input (Magnitude);
      else
         return Input (Magnitude);
      end if;
   end Reversed;
end Reverse_Integer;
