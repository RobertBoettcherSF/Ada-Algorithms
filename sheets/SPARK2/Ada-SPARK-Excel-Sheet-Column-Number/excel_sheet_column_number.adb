pragma SPARK_Mode (On);

package body Excel_Sheet_Column_Number is
   function Letter_Value (Letter : Character) return Natural is
   begin
      if Letter in 'A' .. 'Z' then
         return Natural (Character'Pos (Letter) - Character'Pos ('A') + 1);
      else
         return 0;
      end if;
   end Letter_Value;

   function Number (Title : Column_Title) return Column_Number is
      First  : constant Natural := Letter_Value (Title (1));
      Second : constant Natural := Letter_Value (Title (2));
   begin
      if Title (1) = ' ' then
         return Column_Number (Second);
      else
         return Column_Number (26 * First + Second);
      end if;
   end Number;
end Excel_Sheet_Column_Number;
