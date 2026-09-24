pragma Ada_2022;

package body Minimum_ASCII_Delete_Sum with SPARK_Mode => On is
   type Table is array (Length, Length) of Cost;

   function Add (Left, Right : Cost) return Cost is
   begin
      if Left > Cost'Last - Right then
         return Cost'Last;
      else
         return Left + Right;
      end if;
   end Add;

   function Delete_Sum
     (Left, Right : Text; NL, NR : Length) return Cost
   is
      D : Table := (others => (others => 0));
      LC, RC : Cost;
   begin
      for I in 1 .. NL loop
         D (I, 0) := Add (D (I - 1, 0), Cost (Character'Pos (Left (I))));
      end loop;
      for J in 1 .. NR loop
         D (0, J) := Add (D (0, J - 1), Cost (Character'Pos (Right (J))));
      end loop;
      for I in 1 .. NL loop
         for J in 1 .. NR loop
            if Left (I) = Right (J) then
               D (I, J) := D (I - 1, J - 1);
            else
               LC := Add (D (I - 1, J), Cost (Character'Pos (Left (I))));
               RC := Add (D (I, J - 1), Cost (Character'Pos (Right (J))));
               if LC <= RC then
                  D (I, J) := LC;
               else
                  D (I, J) := RC;
               end if;
            end if;
         end loop;
      end loop;
      return D (NL, NR);
   end Delete_Sum;
end Minimum_ASCII_Delete_Sum;
