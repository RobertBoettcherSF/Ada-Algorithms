pragma Ada_2022;

package body Set_Matrix_Zeroes with SPARK_Mode => On is
   type Flags is array (Index) of Boolean;

   procedure Zero (Input : in out Matrix) is
      Rows : Flags := (others => False);
      Cols : Flags := (others => False);
   begin
      for R in Index loop
         for C in Index loop
            if Input (R, C) = 0 then
               Rows (R) := True;
               Cols (C) := True;
            end if;
         end loop;
      end loop;
      for R in Index loop
         for C in Index loop
            if Rows (R) or else Cols (C) then
               Input (R, C) := 0;
            end if;
         end loop;
      end loop;
   end Zero;
end Set_Matrix_Zeroes;
