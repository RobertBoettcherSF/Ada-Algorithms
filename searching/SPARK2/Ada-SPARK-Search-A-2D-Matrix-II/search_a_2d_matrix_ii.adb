pragma Ada_2022;

package body Search_A_2D_Matrix_II with SPARK_Mode => On is
   function Contains (Grid : Matrix; Target : Value) return Boolean is
      Found : Boolean := False;
   begin
      for I in Row loop
         for J in Column loop
            if Grid (I, J) = Target then
               Found := True;
            end if;
         end loop;
      end loop;
      return Found;
   end Contains;
end Search_A_2D_Matrix_II;
