pragma SPARK_Mode (On);

package body Excel_Sheet_Column_Title is
   subtype Letter_Index is Positive range 1 .. 26;

   function To_Letter (Index : Letter_Index) return Character is
   begin
      return Character'Val (Character'Pos ('A') + Index - 1);
   end To_Letter;

   function Title (Value : Column_Number) return Column_Title is
   begin
      if Value <= 26 then
         return (1 => ' ', 2 => To_Letter (Letter_Index (Value)));
      else
         declare
            High : constant Letter_Index :=
              Letter_Index ((Value - 1) / 26);
            Low : constant Letter_Index :=
              Letter_Index ((Value - 1) mod 26 + 1);
         begin
            return (1 => To_Letter (High), 2 => To_Letter (Low));
         end;
      end if;
   end Title;
end Excel_Sheet_Column_Title;
