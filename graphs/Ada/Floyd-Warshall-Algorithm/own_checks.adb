pragma Ada_2022;
--  Own tests for Floyd_Warshall_Algorithm (see tests/SOURCES.txt).
--  All_Pairs on random small digraphs with negative weights (n <= 6, weights -4 .. 20) against an own
--  exhaustive reference: Negative_Cycle exactly when some simple cycle has negative cost; otherwise every
--  Dist entry is the minimum over all simple paths and the Next matrix gives a path of exactly that cost.
with Ada.Text_IO; use Ada.Text_IO;
with Floyd_Warshall_Algorithm; use Floyd_Warshall_Algorithm;

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
   for Run in 1 .. 3000 loop
      declare
         N : constant Positive := Next (1, Max_N);
         W, Best, B1 : W_Mat := [others => [others => Absent]];
         Neg, N1 : Boolean := False;
         G : constant GP := new Graph;
         M : constant Natural := Next (0, 3 * N);
         D : Dist_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N));
         Nx : Next_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N));
         St : Run_Status;
      begin
         Clear (G.all, N);
         for E in 1 .. M loop
            declare
               A : constant Positive := Next (1, N);
               B : constant Positive := Next (1, N);
               X : constant Integer := Next (-4, 20);
            begin
               if A /= B or else X >= 0 then
                  Add_Edge (G.all, Vertex_Id (A), Vertex_Id (B), X);
                  if A /= B and then X < W (A, B) then W (A, B) := X; end if;
               end if;
            end;
         end loop;
         for S in 1 .. N loop   --  every vertex reaches itself, so every negative cycle is seen from one of its vertices
            Brute (W, N, S, B1, N1);
            for V in 1 .. N loop Best (S, V) := B1 (S, V); end loop;
            Neg := Neg or else N1;
         end loop;
         All_Pairs (G.all, D, Nx, St);
         Report ((St = Negative_Cycle) = Neg, "Negative_Cycle status, own" & Neg'Image & ", run" & Run'Image);
         if not Neg then
            for I in 1 .. N loop
               for J in 1 .. N loop
                  if Best (I, J) = Absent then
                     Report (D (Vertex_Id (I), Vertex_Id (J)) = Infinity, "unreachable pair not Infinity, run" & Run'Image);
                  else
                     Report (D (Vertex_Id (I), Vertex_Id (J)) = Distance_Value (Best (I, J)),
                             "Dist (" & I'Image & "," & J'Image & ") =" & D (Vertex_Id (I), Vertex_Id (J))'Image
                             & ", own" & Best (I, J)'Image & ", run" & Run'Image);
                     if I /= J then
                        declare   --  the Next matrix must give a path of exactly that cost
                           Cur : Positive := I;
                           Cost : Integer := 0;
                           Steps : Natural := 0;
                           Nv : Natural;
                        begin
                           while Cur /= J and then Steps <= N loop
                              Nv := Nx (Vertex_Id (Cur), Vertex_Id (J));
                              exit when Nv not in 1 .. N or else W (Cur, Nv) = Absent;
                              Cost := Cost + W (Cur, Nv);
                              Cur := Nv;
                              Steps := Steps + 1;
                           end loop;
                           Report (Cur = J and then Cost = Best (I, J), "Next path invalid or not shortest, run" & Run'Image);
                        end;
                     end if;
                  end if;
               end loop;
            end loop;
         end if;
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
