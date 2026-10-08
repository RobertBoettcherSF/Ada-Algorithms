--  Own tests for Number_Of_Islands_DFS (see tests/SOURCES.txt).
--  Count (G) = number of 4-connected components of land cells; reference: own recursive flood fill.
with Ada.Text_IO; use Ada.Text_IO;
with Number_Of_Islands_DFS; use Number_Of_Islands_DFS;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   type Mark is array (Coordinate, Coordinate) of Boolean;

   procedure Fill (G : Grid; R, C : Integer; M : in out Mark) is
   begin
      if R in Coordinate and then C in Coordinate and then G (R, C) and then not M (R, C) then
         M (R, C) := True;
         Fill (G, R - 1, C, M); Fill (G, R + 1, C, M);
         Fill (G, R, C - 1, M); Fill (G, R, C + 1, M);
      end if;
   end Fill;

   function Reference (G : Grid) return Natural is
      M : Mark := [others => [others => False]];
      N : Natural := 0;
   begin
      for R in Coordinate loop
         for C in Coordinate loop
            if G (R, C) and then not M (R, C) then
               N := N + 1;
               Fill (G, R, C, M);
            end if;
         end loop;
      end loop;
      return N;
   end Reference;

   G : Grid;
begin
   --  every one of the 2**16 grids
   for Bits in 0 .. 2**16 - 1 loop
      for R in Coordinate loop
         for C in Coordinate loop
            G (R, C) := (Bits / 2**((R - 1) * Grid_Size + (C - 1))) mod 2 = 1;
         end loop;
      end loop;
      Report (Number_Of_Islands_DFS.Count (G) = Reference (G), "grid" & Integer'Image (Bits));
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
