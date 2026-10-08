pragma Ada_2022;
--  Own tests for Breadth_First_Search (see tests/SOURCES.txt).
--  Shortest_Paths: Dist (V) = fewest arcs from Start, Infinity if unreachable; Prev (V) is a
--  predecessor on a shortest path. Own reference: unit-weight relaxation until nothing changes.
with Ada.Text_IO; use Ada.Text_IO;
with Breadth_First_Search; use Breadth_First_Search;

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
begin
   for Run in 1 .. 3000 loop
      declare
         N : constant Positive := Next (1, 8);
         M : constant Natural := Next (0, 16);
         type Arc is record F, T : Positive; end record;
         A : array (1 .. M) of Arc;
         G : Graph;
         S : constant Vertex_Id := Vertex_Id (Next (1, N));
         D : Distance_Array (1 .. Vertex_Id (N));
         P : Prev_Array (1 .. Vertex_Id (N));
         R : array (1 .. N) of Natural := [others => Infinity];
         Changed : Boolean := True;
         Ok : Boolean := True;
      begin
         Clear (G, N);
         for K in A'Range loop
            A (K) := (Next (1, N), Next (1, N));
            Add_Edge (G, Vertex_Id (A (K).F), Vertex_Id (A (K).T));
         end loop;
         R (Positive (S)) := 0;
         while Changed loop
            Changed := False;
            for K in A'Range loop
               if R (A (K).F) /= Infinity and then R (A (K).F) + 1 < R (A (K).T) then
                  R (A (K).T) := R (A (K).F) + 1; Changed := True;
               end if;
            end loop;
         end loop;
         Shortest_Paths (G, S, D, P);
         for V in 1 .. N loop
            Ok := Ok and then D (Vertex_Id (V)) = R (V);
            if R (V) /= Infinity and then R (V) > 0 then   --  Prev must be a real arc one level up
               declare Has : Boolean := False; begin
                  for K in A'Range loop
                     if A (K).T = V and then A (K).F = P (Vertex_Id (V)) and then R (A (K).F) = R (V) - 1 then Has := True; end if;
                  end loop;
                  Ok := Ok and then Has;
               end;
            end if;
         end loop;
         Report (Ok, "run" & Integer'Image (Run));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
