pragma Ada_2022;
--  Own tests for Bellman_Ford_Algorithm (see tests/SOURCES.txt).
--  Bellman-Ford on random small digraphs with negative weights (n <= 6, weights -4 .. 20) against an
--  own exhaustive reference: the status must report Negative_Cycle exactly when a simple cycle of negative
--  cost is reachable from the source; otherwise the distances are the minimum over every simple path.
with Ada.Text_IO; use Ada.Text_IO;
with Bellman_Ford_Algorithm; use Bellman_Ford_Algorithm;

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
   Max_N : constant := 6;
   type W_Mat is array (1 .. Max_N, 1 .. Max_N) of Integer;   --  minimum weight per ordered pair; Absent = no edge
   Absent : constant Integer := Integer'Last;
   type GP is access Graph;
   --  own reference: depth-first enumeration of every simple path / simple cycle
   procedure Brute (W : W_Mat; N, S : Positive; Best : out W_Mat; Neg_Cycle : out Boolean) is
      Seen : array (1 .. Max_N) of Boolean := [others => False];
      procedure Walk (V : Positive; Cost : Integer) is
      begin
         if Cost < Best (S, V) then Best (S, V) := Cost; end if;
         Seen (V) := True;
         for U in 1 .. N loop
            if W (V, U) /= Absent then
               if not Seen (U) then Walk (U, Cost + W (V, U));
               end if;
            end if;
         end loop;
         Seen (V) := False;
      end Walk;
      Reach : array (1 .. Max_N) of Boolean := [others => False];
      procedure Cycle (Start, V : Positive; Cost : Integer) is   --  simple cycles through Start
      begin
         Seen (V) := True;
         for U in 1 .. N loop
            if W (V, U) /= Absent then
               if U = Start then
                  if Cost + W (V, U) < 0 then Neg_Cycle := True; end if;
               elsif not Seen (U) then Cycle (Start, U, Cost + W (V, U));
               end if;
            end if;
         end loop;
         Seen (V) := False;
      end Cycle;
   begin
      Best := [others => [others => Absent]];
      Neg_Cycle := False;
      Walk (S, 0);
      for V in 1 .. N loop Reach (V) := Best (S, V) /= Absent; end loop;
      for V in 1 .. N loop
         if Reach (V) then Seen := [others => False]; Cycle (V, V, 0); end if;
      end loop;
   end Brute;
begin
   for Run in 1 .. 4000 loop
      declare
         N : constant Positive := Next (1, Max_N);
         S : constant Positive := Next (1, N);
         W, Best : W_Mat := [others => [others => Absent]];
         Neg : Boolean;
         G : constant GP := new Graph;
         M : constant Natural := Next (0, 3 * N);
      begin
         Clear (G.all, N);
         for E in 1 .. M loop
            declare
               A : constant Positive := Next (1, N);
               B : constant Positive := Next (1, N);
               X : constant Integer := Next (-4, 20);
            begin
               if A /= B or else X >= 0 then   --  negative self-loops are left out (trivial cycles)
                  Add_Edge (G.all, Vertex_Id (A), Vertex_Id (B), X);
                  if A /= B and then X < W (A, B) then W (A, B) := X; end if;
               end if;
            end;
         end loop;
         Brute (W, N, S, Best, Neg);
         declare
            D : Distance_Array (1 .. Vertex_Id (N));
            P : Prev_Array (1 .. Vertex_Id (N));
            St : Run_Status;
         begin
            Shortest_Paths (G.all, Vertex_Id (S), D, P, St);
            Report ((St = Negative_Cycle) = Neg, "Negative_Cycle status" & Boolean'Image (St = Negative_Cycle) & ", own" & Neg'Image & ", run" & Run'Image);
            Report (Has_Negative_Cycle (G.all, Vertex_Id (S)) = Neg, "Has_Negative_Cycle, run" & Run'Image);
            if not Neg then
               for V in 1 .. N loop
                  if Best (S, V) = Absent then
                     Report (D (Vertex_Id (V)) = Infinity, "unreachable vertex" & V'Image & " not Infinity, run" & Run'Image);
                  else
                     Report (D (Vertex_Id (V)) = Distance_Value (Best (S, V)),
                             "distance to" & V'Image & " =" & D (Vertex_Id (V))'Image & ", own" & Best (S, V)'Image & ", run" & Run'Image);
                     declare   --  the Prev tree must give a path of exactly that cost
                        Cur : Positive := V;
                        Cost : Integer := 0;
                        Steps : Natural := 0;
                     begin
                        while Cur /= S and then Steps <= N loop
                           exit when P (Vertex_Id (Cur)) not in 1 .. N or else W (P (Vertex_Id (Cur)), Cur) = Absent;
                           Cost := Cost + W (P (Vertex_Id (Cur)), Cur);
                           Cur := P (Vertex_Id (Cur));
                           Steps := Steps + 1;
                        end loop;
                        Report (Cur = S and then Cost = Best (S, V), "Prev path to" & V'Image & " invalid or not shortest, run" & Run'Image);
                     end;
                  end if;
               end loop;
            end if;
         end;
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
