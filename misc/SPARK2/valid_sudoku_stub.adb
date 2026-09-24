pragma Ada_2022;

package body Valid_Sudoku_Stub with SPARK_Mode => On is
   function Is_Valid (Input : Board) return Boolean is
   begin
      for R in Index loop
         for C1 in Index loop
            for C2 in Index loop
               if C1 < C2 and then Input (R, C1) /= 0
                 and then Input (R, C1) = Input (R, C2)
               then
                  return False;
               end if;
               if C1 < C2 and then Input (C1, R) /= 0
                 and then Input (C1, R) = Input (C2, R)
               then
                  return False;
               end if;
            end loop;
         end loop;
      end loop;
      return True;
   end Is_Valid;
end Valid_Sudoku_Stub;
