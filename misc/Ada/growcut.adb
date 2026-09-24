package body GrowCut is

   function Calculate_Similarity (Pixel_1_Val : Float; Pixel_2_Val : Float) return Float is
   begin
      return 1.0 - abs(Pixel_1_Val - Pixel_2_Val);
   end Calculate_Similarity;

   procedure Run_Synchronous_Iteration (Grid : in out Grid_Type) is
      New_Grid : Grid_Type := Grid; -- Snapshot of current state
      Rows     : constant Integer := Grid'Length(1);
      Cols     : constant Integer := Grid'Length(2);
   begin
      for R in Grid'Range(1) loop
         for C in Grid'Range(2) loop
            -- Check neighbors in New_Grid (the snapshot)
            for DR in -1 .. 1 loop
               for DC in -1 .. 1 loop
                  if DR /= 0 or DC /= 0 then
                     declare
                        NR : constant Integer := R + DR;
                        NC : constant Integer := C + DC;
                     begin
                        if NR >= Grid'First(1) and NR <= Grid'Last(1) and
                           NC >= Grid'First(2) and NC <= Grid'Last(2) then
                           
                           -- Attack Logic: Neighbor attacks current cell
                           declare
                              Attack_Strength : Float := Grid(NR, NC).Strength * 0.9; -- 0.9 is distance penalty
                           begin
                              if Attack_Strength > Grid(R, C).Strength then
                                 New_Grid(R, C).Label := Grid(NR, NC).Label;
                                 New_Grid(R, C).Strength := Attack_Strength;
                              end if;
                           end;
                        end if;
                     end;
                  end if;
               end loop;
            end loop;
         end loop;
      end loop;
      Grid := New_Grid;
   end Run_Synchronous_Iteration;

   procedure Run_Asynchronous_Iteration (Grid : in out Grid_Type) is
      -- In Asynchronous, we update the Grid in place immediately
   begin
      for R in Grid'Range(1) loop
         for C in Grid'Range(2) loop
            for DR in -1 .. 1 loop
               for DC in -1 .. 1 loop
                  if DR /= 0 or DC /= 0 then
                     declare
                        NR : constant Integer := R + DR;
                        NC : constant Integer := C + DC;
                     begin
                        if NR >= Grid'First(1) and NR <= Grid'Last(1) and
                           NC >= Grid'First(2) and NC <= Grid'Last(2) then
                           
                           -- Attack Logic: Neighbor attacks current cell (uses CURRENT state)
                           declare
                              Attack_Strength : Float := Grid(NR, NC).Strength * 0.9;
                           begin
                              if Attack_Strength > Grid(R, C).Strength then
                                 Grid(R, C).Label := Grid(NR, NC).Label;
                                 Grid(R, C).Strength := Attack_Strength;
                              end if;
                           end;
                        end if;
                     end;
                  end if;
               end loop;
            end loop;
         end loop;
      end loop;
   end Run_Asynchronous_Iteration;

end GrowCut;
