pragma Ada_2022;

package body Word_Search_II_Lite with SPARK_Mode => On is
   function Appears_Horizontally (B : Board; W : Pattern) return Boolean is
   begin
      for R in Row loop
         for S in Column range 1 .. 2 loop
            if B (R, S) = W (1) and then B (R, S + 1) = W (2) and then B (R, S + 2) = W (3) then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Appears_Horizontally;

   function Count_Found (B : Board; Words : Pattern_List) return Natural is
      Result : Natural := 0;
   begin
      for I in Words'Range loop
         if Appears_Horizontally (B, Words (I)) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Found;
end Word_Search_II_Lite;
