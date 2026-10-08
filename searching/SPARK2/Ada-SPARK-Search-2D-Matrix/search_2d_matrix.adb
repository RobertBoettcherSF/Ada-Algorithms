pragma Ada_2022;

package body Search_2D_Matrix with SPARK_Mode => On is
   function Contains (Input : Matrix; Target : Value) return Boolean is
   begin
      for R in Index loop
         for C in Index loop
            if Input (R, C) = Target then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Contains;
end Search_2D_Matrix;
