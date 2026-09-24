pragma Ada_2022;

package body Distinct_Subsequences with SPARK_Mode => On is
   type Table is array (Length, Length) of Count;

   function Add (Left, Right : Count) return Count is
   begin
      if Left > Count'Last - Right then
         return Count'Last;
      else
         return Left + Right;
      end if;
   end Add;

   function Count_Of
     (Source, Target : Text; NS, NT : Length) return Count
   is
      D : Table := (others => (others => 0));
   begin
      D (0, 0) := 1;
      for I in 1 .. NS loop
         D (I, 0) := 1;
      end loop;
      for I in 1 .. NS loop
         for J in 1 .. NT loop
            D (I, J) := D (I - 1, J);
            if Source (I) = Target (J) then
               D (I, J) := Add (D (I, J), D (I - 1, J - 1));
            end if;
         end loop;
      end loop;
      return D (NS, NT);
   end Count_Of;
end Distinct_Subsequences;
