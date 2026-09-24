pragma Ada_2022;

package body Sudoku_Solver_Lite with SPARK_Mode => On is
   function Is_Valid (G : Grid) return Boolean is
   begin
      for R in Position loop
         for C1 in Position range 1 .. 3 loop
            for C2 in Position range C1 + 1 .. 4 loop
               if G (R, C1) = G (R, C2) then
                  return False;
               end if;
            end loop;
         end loop;
      end loop;
      for C in Position loop
         for R1 in Position range 1 .. 3 loop
            for R2 in Position range R1 + 1 .. 4 loop
               if G (R1, C) = G (R2, C) then
                  return False;
               end if;
            end loop;
         end loop;
      end loop;
      return True;
   end Is_Valid;
end Sudoku_Solver_Lite;
