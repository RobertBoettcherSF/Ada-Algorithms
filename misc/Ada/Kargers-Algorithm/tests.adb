--  Standalone test suite for Kargers_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Kargers_Algorithm; use Kargers_Algorithm;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Clear_Raises (Vertex_Count : Natural) return Boolean is
      G : Graph;
   begin
      Clear (G, Vertex_Count);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Add_Raises
     (G : in out Graph; U, V : Vertex_Id) return Boolean
   is
   begin
      Add_Edge (G, U, V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Contract_Raises (G : Graph; Seed : Natural) return Boolean is
      C : Cut_Size;
   begin
      C := Contract_Once (G, Seed);
      pragma Unreferenced (C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Contract_Raises;

   function Min_Cut_Raises
     (G : Graph; Trials : Positive; Seed : Natural) return Boolean
   is
      C : Cut_Size;
   begin
      C := Min_Cut (G, Trials, Seed);
      pragma Unreferenced (C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Min_Cut_Raises;

   function Exact_Raises (G : Graph) return Boolean is
      C : Cut_Size;
   begin
      C := Exact_Min_Cut (G);
      pragma Unreferenced (C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Exact_Raises;

   procedure Make_Cycle (G : in out Graph; N : Positive) is
   begin
      Clear (G, N);
      for I in 1 .. N - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
      end loop;
      Add_Edge (G, Vertex_Id (N), Vertex_Id (1));
   end Make_Cycle;

   procedure Make_Complete (G : in out Graph; N : Positive) is
   begin
      Clear (G, N);
      for I in 1 .. N - 1 loop
         for J in I + 1 .. N loop
            Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
         end loop;
      end loop;
   end Make_Complete;

   procedure Make_Path (G : in out Graph; N : Positive) is
   begin
      Clear (G, N);
      for I in 1 .. N - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
      end loop;
   end Make_Path;

   G : Graph;
   C, C2, Exact : Cut_Size;

begin
   ------------------------------------------------------------------
   Section ("1. Clear / Add_Edge / counts");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty N=0");
   Check (Edge_Count (G) = 0, "empty M=0");
   Check (Clear_Raises (Max_Vertices + 1), "Clear overflow");

   Clear (G, 4);
   Check (Vertex_Count (G) = 4, "N=4");
   Check (Edge_Count (G) = 0, "M=0 after Clear");
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 1, 2);  -- parallel
   Check (Edge_Count (G) = 3, "three edges with parallel");
   Check (Add_Raises (G, 1, 1), "self-loop rejected");
   Check (Add_Raises (G, 5, 1), "U out of range");
   Check (Add_Raises (G, 1, 5), "V out of range");

   ------------------------------------------------------------------
   Section ("2. Invalid_Argument on cut APIs");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Contract_Raises (G, 1), "Contract N=0");
   Check (Min_Cut_Raises (G, 1, 1), "Min_Cut N=0");
   Check (Exact_Raises (G), "Exact N=0");

   Clear (G, 1);
   Check (Contract_Raises (G, 1), "Contract N=1");
   Check (Min_Cut_Raises (G, 3, 0), "Min_Cut N=1");
   Check (Exact_Raises (G), "Exact N=1");

   Clear (G, 11);
   for I in 1 .. 10 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
   end loop;
   Check (Exact_Raises (G), "Exact N=11 too large");
   Check (not Contract_Raises (G, 7), "Contract N=11 ok");

   ------------------------------------------------------------------
   Section ("3. Two-vertex graphs");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2);
   Exact := Exact_Min_Cut (G);
   Check (Exact = 1, "K2 exact cut=1");
   C := Contract_Once (G, 42);
   Check (C = 1, "K2 contract=1");
   C := Min_Cut (G, 5, 1);
   Check (C = 1, "K2 mincut=1");
   Check (Min_Cut (G, 1, 99) = Contract_Once (G, 99), "Min_Cut 1-trial = Contract");

   Clear (G, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Check (Exact_Min_Cut (G) = 3, "multiplicity 3 exact");
   Check (Contract_Once (G, 0) = 3, "multiplicity 3 contract");
   Check (Min_Cut (G, 10, 5) = 3, "multiplicity 3 mincut");

   ------------------------------------------------------------------
   Section ("4. Cycle graphs: min-cut = 2");
   ------------------------------------------------------------------
   for N in 3 .. 10 loop
      Make_Cycle (G, N);
      Exact := Exact_Min_Cut (G);
      Check (Exact = 2, "C" & Integer'Image (N) & " exact=2");
      C := Min_Cut (G, 200, 17);
      Check (C = 2, "C" & Integer'Image (N) & " mincut=2");
   end loop;

   for N in 11 .. 20 loop
      Make_Cycle (G, N);
      C := Min_Cut (G, 500, 3);
      Check (C = 2, "C" & Integer'Image (N) & " mincut=2 many trials");
   end loop;

   ------------------------------------------------------------------
   Section ("5. Complete graphs Kn: min-cut = n-1");
   ------------------------------------------------------------------
   for N in 2 .. 8 loop
      Make_Complete (G, N);
      Exact := Exact_Min_Cut (G);
      Check (Exact = Cut_Size (N - 1),
             "K" & Integer'Image (N) & " exact=n-1");
      C := Min_Cut (G, 300, 11);
      Check (C = Cut_Size (N - 1),
             "K" & Integer'Image (N) & " mincut=n-1");
   end loop;

   Make_Complete (G, 9);
   Check (Exact_Min_Cut (G) = 8, "K9 exact=8");
   Check (Min_Cut (G, 400, 2) = 8, "K9 mincut=8");

   Make_Complete (G, 10);
   Check (Exact_Min_Cut (G) = 9, "K10 exact=9");
   Check (Min_Cut (G, 500, 1) = 9, "K10 mincut=9");

   ------------------------------------------------------------------
   Section ("6. Path graphs: min-cut = 1");
   ------------------------------------------------------------------
   for N in 2 .. 10 loop
      Make_Path (G, N);
      Exact := Exact_Min_Cut (G);
      Check (Exact = 1, "P" & Integer'Image (N) & " exact=1");
      C := Min_Cut (G, 100, 8);
      Check (C = 1, "P" & Integer'Image (N) & " mincut=1");
   end loop;

   ------------------------------------------------------------------
   Section ("7. Disconnected graphs: min-cut = 0");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 4);
   Check (Exact_Min_Cut (G) = 0, "two components exact=0");
   Check (Min_Cut (G, 50, 1) = 0, "two components mincut=0");
   Check (Contract_Once (G, 7) = 0, "two components contract=0");

   Clear (G, 5);
   Check (Exact_Min_Cut (G) = 0, "edgeless exact=0");
   Check (Contract_Once (G, 1) = 0, "edgeless contract=0");

   ------------------------------------------------------------------
   Section ("8. Seeded reproducibility");
   ------------------------------------------------------------------
   Make_Cycle (G, 6);
   C := Contract_Once (G, 12345);
   C2 := Contract_Once (G, 12345);
   Check (C = C2, "same seed same Contract_Once");
   C := Min_Cut (G, 20, 99);
   C2 := Min_Cut (G, 20, 99);
   Check (C = C2, "same seed same Min_Cut");
   Check (Min_Cut (G, 1, 55) = Contract_Once (G, 55),
          "Min_Cut(1,S)=Contract_Once(S)");

   --  Different seeds may differ; at least record both run without crash
   C := Contract_Once (G, 1);
   C2 := Contract_Once (G, 2);
   Check (C >= 2 and then C2 >= 2, "cycle trials >= 2");
   Check (C <= Edge_Count (G) and then C2 <= Edge_Count (G),
          "cut <= edge count");

   ------------------------------------------------------------------
   Section ("9. Exact vs multi-trial on tiny graphs");
   ------------------------------------------------------------------
   --  Bridge graph: two triangles joined by a bridge
   Clear (G, 6);
   Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
   Add_Edge (G, 4, 5); Add_Edge (G, 5, 6); Add_Edge (G, 6, 4);
   Add_Edge (G, 3, 4);  -- bridge
   Exact := Exact_Min_Cut (G);
   Check (Exact = 1, "bridge exact=1");
   C := Min_Cut (G, 200, 42);
   Check (C = Exact, "bridge Min_Cut matches Exact");

   --  Two parallel bridges
   Clear (G, 4);
   Add_Edge (G, 1, 2); Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 4); Add_Edge (G, 3, 4);
   Add_Edge (G, 2, 3); Add_Edge (G, 2, 3);
   Exact := Exact_Min_Cut (G);
   Check (Exact = 2, "double bridge exact=2");
   Check (Min_Cut (G, 150, 7) = Exact, "double bridge match");

   --  Star
   Clear (G, 5);
   Add_Edge (G, 1, 2); Add_Edge (G, 1, 3);
   Add_Edge (G, 1, 4); Add_Edge (G, 1, 5);
   Exact := Exact_Min_Cut (G);
   Check (Exact = 1, "star exact=1");
   Check (Min_Cut (G, 100, 3) = 1, "star mincut=1");

   ------------------------------------------------------------------
   Section ("10. Parallel multiplicity");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 1, 3);
   Exact := Exact_Min_Cut (G);
   Check (Exact = 3, "triangle multi exact=3");
   --  Cuts: {1}|{2,3}=2+1=3; {2}|{1,3}=2+3=5; {3}|{1,2}=3+1=4 → min 3
   Check (Min_Cut (G, 200, 9) = 3, "triangle multi mincut=3");

   ------------------------------------------------------------------
   Section ("11. Capacity: fill Max_Edges");
   ------------------------------------------------------------------
   Clear (G, 3);
   declare
      Filled : Natural := 0;
   begin
      for I in 1 .. Max_Edges loop
         Add_Edge (G, 1, 2);
         Filled := Filled + 1;
      end loop;
      Check (Edge_Count (G) = Max_Edges, "filled Max_Edges");
      Check (Add_Raises (G, 1, 3), "Add beyond Max_Edges");
      Check (Exact_Min_Cut (G) = 0, "parallels 1-2 with isolated 3 => cut 0");
      --  Cut isolating 3 has 0 edges if no edges to 3; wait we only added 1-2.
      --  Exact: S={1} T={2,3}: Max_Edges; S={1,2}T={3}: 0; S={1,3}T={2}: Max_Edges
      --  So min is 0 (vertex 3 isolated).
      pragma Assert (Filled = Max_Edges);
   end;

   ------------------------------------------------------------------
   Section ("12. Volume: cycles / complete / paths");
   ------------------------------------------------------------------
   for N in 3 .. 8 loop
      Make_Cycle (G, N);
      for S in 1 .. 5 loop
         C := Contract_Once (G, S * 17 + N);
         Check (C >= 2, "vol-cycle cut>=2 n=" & Integer'Image (N)
                & " s=" & Integer'Image (S));
      end loop;
   end loop;

   for N in 3 .. 6 loop
      Make_Complete (G, N);
      for S in 1 .. 4 loop
         C := Contract_Once (G, S + N * 10);
         Check (C >= Cut_Size (N - 1),
                "vol-Kn cut>=n-1 n=" & Integer'Image (N)
                & " s=" & Integer'Image (S));
      end loop;
      Check (Min_Cut (G, 80, N) = Cut_Size (N - 1),
             "vol-Kn min n=" & Integer'Image (N));
   end loop;

   for N in 4 .. 9 loop
      Make_Path (G, N);
      Check (Min_Cut (G, 40, N) = 1, "vol-path n=" & Integer'Image (N));
   end loop;

   ------------------------------------------------------------------
   Section ("13. Seed 0 and varied seeds");
   ------------------------------------------------------------------
   Make_Cycle (G, 5);
   C := Contract_Once (G, 0);
   C2 := Contract_Once (G, 0);
   Check (C = C2, "seed 0 reproducible");
   Check (C >= 2, "seed 0 cycle cut>=2");

   for S in 0 .. 19 loop
      Make_Complete (G, 4);
      C := Contract_Once (G, S);
      Check (C >= 3, "K4 seed" & Integer'Image (S) & " >=3");
   end loop;

   ------------------------------------------------------------------
   Section ("14. Exact vs Min_Cut agreement battery");
   ------------------------------------------------------------------
   for N in 3 .. 7 loop
      Make_Cycle (G, N);
      Exact := Exact_Min_Cut (G);
      C := Min_Cut (G, 250, 13);
      Check (C = Exact, "agree cycle n=" & Integer'Image (N));

      Make_Complete (G, N);
      Exact := Exact_Min_Cut (G);
      C := Min_Cut (G, 250, 19);
      Check (C = Exact, "agree Kn n=" & Integer'Image (N));

      Make_Path (G, N);
      Exact := Exact_Min_Cut (G);
      C := Min_Cut (G, 100, 23);
      Check (C = Exact, "agree path n=" & Integer'Image (N));
   end loop;

   ------------------------------------------------------------------
   Section ("15. Clear resets edges");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Clear (G, 4);
   Check (Edge_Count (G) = 0, "Clear empties edges");
   Check (Exact_Min_Cut (G) = 0, "cleared edgeless cut=0");

   Clear (G, Max_Vertices);
   Check (Vertex_Count (G) = Max_Vertices, "Clear Max_Vertices ok");
   Add_Edge (G, 1, Vertex_Id (Max_Vertices));
   Check (Edge_Count (G) = 1, "edge across max ids");
   C := Contract_Once (G, 5);
   Check (C = 0 or else C = 1, "large sparse contract ok");

   ------------------------------------------------------------------
   New_Line;
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
