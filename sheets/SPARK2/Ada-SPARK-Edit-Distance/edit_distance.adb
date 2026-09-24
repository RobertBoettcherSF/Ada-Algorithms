pragma SPARK_Mode (On);

package body Edit_Distance is
   type Table is array (Length, Length) of Length;

   function Increment (Value : Length) return Length is
   begin
      if Value < Length'Last then
         return Value + 1;
      else
         return Length'Last;
      end if;
   end Increment;

   function Distance
     (Left, Right : Word;
      Left_Length, Right_Length : Length) return Length
   is
      D : Table := (others => (others => 0));
      Diagonal, Delete_Cost, Insert_Cost : Length;
   begin
      for I in 1 .. Left_Length loop
         D (I, 0) := I;
      end loop;
      for J in 1 .. Right_Length loop
         D (0, J) := J;
      end loop;
      for I in 1 .. Left_Length loop
         for J in 1 .. Right_Length loop
            if Left (I) = Right (J) then
               D (I, J) := D (I - 1, J - 1);
            else
               Diagonal := Increment (D (I - 1, J - 1));
               Delete_Cost := Increment (D (I - 1, J));
               Insert_Cost := Increment (D (I, J - 1));
               D (I, J) := Length'Min
                 (Diagonal, Length'Min (Delete_Cost, Insert_Cost));
            end if;
         end loop;
      end loop;
      return D (Left_Length, Right_Length);
   end Distance;
end Edit_Distance;
