--  Own tests for Find_If_Path_Exists_In_Graph (see tests/SOURCES.txt).
--  Path_Exists (Edges, Start, Goal): Goal is reachable from Start along directed edges (Start = Goal
--  counts as reachable); reference: own transitive closure (Warshall).
with Ada.Text_IO; use Ada.Text_IO;
with Find_If_Path_Exists_In_Graph; use Find_If_Path_Exists_In_Graph;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   Seed : Long_Long_Integer := 20261008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   G : Graph;
   Reach : Graph;
begin
   for Trial in 1 .. 600 loop
      declare
         Density : constant Integer := Next (0, 30);   --  percent
      begin
         for A in Vertex loop
            for B in Vertex loop
               G (A, B) := Next (0, 99) < Density;
            end loop;
         end loop;
         if Trial mod 2 = 0 then   --  undirected version of the exercise: symmetric matrix
            for A in Vertex loop
               for B in Vertex loop
                  if G (A, B) then G (B, A) := True; end if;
               end loop;
            end loop;
         end if;
      end;
      Reach := G;
      for A in Vertex loop
         Reach (A, A) := True;
      end loop;
      for K in Vertex loop
         for A in Vertex loop
            for B in Vertex loop
               if Reach (A, K) and then Reach (K, B) then Reach (A, B) := True; end if;
            end loop;
         end loop;
      end loop;
      for S in Vertex loop
         for T in Vertex loop
            Report (Path_Exists (G, S, T) = Reach (S, T), "path");
         end loop;
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
