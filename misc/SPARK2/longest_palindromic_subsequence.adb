pragma Ada_2022;

package body Longest_Palindromic_Subsequence with SPARK_Mode => On is
   type Table is array (Length, Length) of Length;

   function Increment (Value : Length) return Length is
   begin
      if Value < Length'Last then
         return Value + 1;
      else
         return Length'Last;
      end if;
   end Increment;

   function Longest_Length (Input : Text; N : Length) return Length is
      D : Table := (others => (others => 0));
   begin
      for I in reverse 1 .. N loop
         D (I, I) := 1;
         for J in I + 1 .. N loop
            if Input (I) = Input (J) then
               D (I, J) := Increment (Increment (D (I + 1, J - 1)));
            elsif D (I + 1, J) >= D (I, J - 1) then
               D (I, J) := D (I + 1, J);
            else
               D (I, J) := D (I, J - 1);
            end if;
         end loop;
      end loop;
      return D (1, N);
   end Longest_Length;
end Longest_Palindromic_Subsequence;
