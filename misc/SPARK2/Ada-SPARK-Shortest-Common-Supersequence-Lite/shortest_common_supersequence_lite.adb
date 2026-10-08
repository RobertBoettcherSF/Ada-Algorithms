pragma Ada_2022;

package body Shortest_Common_Supersequence_Lite with SPARK_Mode => On is
   type Table is array (Length, Length) of Length;

   function Increment (Value : Length) return Length is
   begin
      if Value < Length'Last then
         return Value + 1;
      else
         return Length'Last;
      end if;
   end Increment;

   function Length_Of
     (Left, Right : Text; NL, NR : Length) return Integer
   is
      LCS : Table := (others => (others => 0));
   begin
      for I in 1 .. NL loop
         for J in 1 .. NR loop
            if Left (I) = Right (J) then
               LCS (I, J) := Increment (LCS (I - 1, J - 1));
            elsif LCS (I - 1, J) >= LCS (I, J - 1) then
               LCS (I, J) := LCS (I - 1, J);
            else
               LCS (I, J) := LCS (I, J - 1);
            end if;
         end loop;
      end loop;
      return Integer (NL) + Integer (NR) - Integer (LCS (NL, NR));
   end Length_Of;
end Shortest_Common_Supersequence_Lite;
