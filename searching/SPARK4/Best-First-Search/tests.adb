--  Standalone test suite for Best_First_Search (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  Optimality is NOT claimed — tests illustrate guiding H and non-optimality.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Best_First_Search; use Best_First_Search;

procedure Tests
  with SPARK_Mode => Off
is

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

   function Nat (X : Natural) return Natural is (X);

   function Zero_H (N : Vertex_Count_T) return Heuristic_Array is
      H : constant Heuristic_Array (1 .. Vertex_Id (N)) := [others => 0];
   begin
      return H;
   end Zero_H;

   G     : Graph;
   Prev  : Prev_Array (1 .. Max_Vertices);
   Path  : Path_Array (1 .. Max_Vertices);
   Len   : Natural;
   Ok    : Boolean;
   Found : Boolean;
   Exp   : Natural;
   Exp0  : Natural;
   H     : Heuristic_Array (1 .. Max_Vertices);

begin
   ------------------------------------------------------------------
   Section ("1. Empty / single / self");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty vertex count");
   Check (Edge_Count (G) = 0, "empty edge count");
   Check (Well_Formed (G), "empty well-formed");

   Clear (G, 1);
   Check (Vertex_Count (G) = 1, "single vertex count");
   Check (Edge_Count (G) = 0, "single no edges");
   H (1) := 0;
   Search (G, 1, 1, H (1 .. 1), Prev, Path, Len, Found, Exp);
   Check (Found and then Len = 1 and then Path (1) = 1, "single path");
   Check (Prev (1) = 0, "single Prev(1)=0");
   Check (Exp = 0, "single zero expansions");

   Add_Edge (G, 1, 1);
   Check (Edge_Count (G) = 1, "self-loop edge count");
   Search (G, 1, 1, H (1 .. 1), Prev, Path, Len, Found, Exp);
   Check (Found and then Len = 1, "self-loop Start=Goal");

   ------------------------------------------------------------------
   Section ("2. Two-vertex digraphs");
   ------------------------------------------------------------------
   Clear (G, 2);
   H (1) := 1; H (2) := 0;
   Search (G, 1, 2, H (1 .. 2), Prev, Path, Len, Found, Exp);
   Check (not Found and then Len = 0, "2 isolated not found");

   Add_Edge (G, 1, 2);
   Search (G, 1, 2, H (1 .. 2), Prev, Path, Len, Found, Exp);
   Check (Found and then Len = 2, "2 direct found");
   Check (Path (1) = 1 and then Path (2) = 2, "2 direct path");
   Check (Prev (2) = 1, "2 direct Prev");
   Check (Exp >= 1, "2 direct expanded start");

   Search (G, 2, 1, H (1 .. 2), Prev, Path, Len, Found, Exp);
   Check (not Found, "reverse-only unreachable");

   Clear (G, 2);
   Add_Edge (G, 2, 1);
   H (1) := 0; H (2) := 1;
   Search (G, 2, 1, H (1 .. 2), Prev, Path, Len, Found, Exp);
   Check (Found and then Len = 2 and then Path (1) = 2, "reverse source ok");

   ------------------------------------------------------------------
   Section ("3. Undirected 2-cycle");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 1);
   H (1) := 1; H (2) := 0;
   Search (G, 1, 2, H (1 .. 2), Prev, Path, Len, Found, Exp);
   Check (Found and then Len = 2, "undirected 1->2");
   H (1) := 0; H (2) := 1;
   Search (G, 2, 1, H (1 .. 2), Prev, Path, Len, Found, Exp);
   Check (Found and then Len = 2 and then Path (1) = 2, "undirected 2->1");

   ------------------------------------------------------------------
   Section ("4. Directed chain guided by decreasing H");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   for V in Vertex_Id range 1 .. 5 loop
      H (V) := Heuristic_Value (5 - V);
   end loop;
   Search (G, 1, 5, H (1 .. 5), Prev, Path, Len, Found, Exp);
   Check (Found, "chain found");
   Check (Len = 5, "chain length 5");
   Check (Path (1) = 1 and then Path (5) = 5, "chain ends");
   Check (Path (2) = 2 and then Path (3) = 3 and then Path (4) = 4,
          "chain middle");

   ------------------------------------------------------------------
   Section ("5. Heuristic guides preferred branch");
   ------------------------------------------------------------------
   --  1 -> 2 -> 4
   --  1 -> 3 -> 4
   --  Prefer 3 via low H.
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 4);
   H (1) := 3; H (2) := 100; H (3) := 1; H (4) := 0;
   Search (G, 1, 4, H (1 .. 4), Prev, Path, Len, Found, Exp);
   Check (Found, "guide found");
   Check (Len = 3, "guide length 3");
   Check (Path (1) = 1 and then Path (2) = 3 and then Path (3) = 4,
          "guide path via 3");

   ------------------------------------------------------------------
   Section ("6. Zero heuristic: still finds a path");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 4);
   declare
      HZ : constant Heuristic_Array := Zero_H (4);
   begin
      H (1 .. 4) := HZ;
   end;
   Search (G, 1, 4, H (1 .. 4), Prev, Path, Len, Found, Exp);
   Check (Found and then Len = 3, "zero-H found len 3");
   Check (Path (1) = 1 and then Path (3) = 4, "zero-H ends");
   Check (Path (2) = 2 or else Path (2) = 3, "zero-H via 2 or 3");

   ------------------------------------------------------------------
   Section ("7. Non-optimality illustration");
   ------------------------------------------------------------------
   --  Short path 1→3→4 (2 arcs). Long detour 1→2→5→6→4 (4 arcs).
   --  Misleading H(2)=0 draws greedy onto the long path.
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 2, 5);
   Add_Edge (G, 5, 6);
   Add_Edge (G, 6, 4);
   H (1) := 10; H (2) := 0; H (3) := 50; H (4) := 0;
   H (5) := 1;  H (6) := 1;
   Search (G, 1, 4, H (1 .. 6), Prev, Path, Len, Found, Exp);
   Check (Found, "nonopt found");
   Check (Len = 5, "nonopt took long path len 5");
   Check (Path (1) = 1 and then Path (2) = 2 and then Path (5) = 4,
          "nonopt via 2");

   --  Guiding H prefers the short branch.
   H (1) := 3; H (2) := 100; H (3) := 1; H (4) := 0;
   H (5) := 90; H (6) := 80;
   Search (G, 1, 4, H (1 .. 6), Prev, Path, Len, Found, Exp);
   Check (Found and then Len = 3, "guiding short len 3");
   Check (Path (2) = 3, "guiding via 3");

   ------------------------------------------------------------------
   Section ("8. Disconnected / unreachable");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 4, 5);
   for V in Vertex_Id range 1 .. 5 loop
      H (V) := 0;
   end loop;
   Search (G, 1, 5, H (1 .. 5), Prev, Path, Len, Found, Exp);
   Check (not Found and then Len = 0, "disconnected not found");
   Search (G, 1, 3, H (1 .. 5), Prev, Path, Len, Found, Exp);
   Check (Found and then Len = 3, "connected component ok");

   ------------------------------------------------------------------
   Section ("9. Guiding H expands fewer nodes");
   ------------------------------------------------------------------
   --  Star: 1→2..8, 8→9. Flat H vs guiding toward 8.
   Clear (G, 9);
   for V in Vertex_Id range 2 .. 8 loop
      Add_Edge (G, 1, V);
   end loop;
   Add_Edge (G, 8, 9);
   for V in Vertex_Id range 1 .. 9 loop
      H (V) := 0;
   end loop;
   Search (G, 1, 9, H (1 .. 9), Prev, Path, Len, Found, Exp0);
   Check (Found and then Len = 3, "star zero-H found");
   Check (Path (1) = 1 and then Path (2) = 8 and then Path (3) = 9,
          "star zero-H via 8");

   H (1) := 2;
   for V in Vertex_Id range 2 .. 7 loop
      H (V) := 100;
   end loop;
   H (8) := 1; H (9) := 0;
   Search (G, 1, 9, H (1 .. 9), Prev, Path, Len, Found, Exp);
   Check (Found and then Len = 3, "star guide found");
   Check (Path (2) = 8, "star guide via 8");
   Check (Exp <= Exp0, "star guide expands <= zero-H");

   ------------------------------------------------------------------
   Section ("10. Grid 3x3 corner to corner");
   ------------------------------------------------------------------
   Clear (G, 9);
   declare
      procedure Link (A, B : Vertex_Id) is
      begin
         Add_Edge (G, A, B);
         Add_Edge (G, B, A);
      end Link;
   begin
      Link (1, 2); Link (2, 3);
      Link (4, 5); Link (5, 6);
      Link (7, 8); Link (8, 9);
      Link (1, 4); Link (4, 7);
      Link (2, 5); Link (5, 8);
      Link (3, 6); Link (6, 9);
   end;
   --  Manhattan toward 9
   H (1) := 4; H (2) := 3; H (3) := 2;
   H (4) := 3; H (5) := 2; H (6) := 1;
   H (7) := 2; H (8) := 1; H (9) := 0;
   Search (G, 1, 9, H (1 .. 9), Prev, Path, Len, Found, Exp);
   Check (Found, "grid found");
   Check (Len = 5, "grid Manhattan path len 5");
   Check (Path (1) = 1 and then Path (5) = 9, "grid ends");

   ------------------------------------------------------------------
   Section ("11. Parallel edges / Clear rebuild");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Check (Edge_Count (G) = 3, "parallel edge count");
   H (1) := 2; H (2) := 1; H (3) := 0;
   Search (G, 1, 3, H (1 .. 3), Prev, Path, Len, Found, Exp);
   Check (Found and then Len = 3, "parallel found");

   Clear (G, 2);
   Check (Edge_Count (G) = 0 and then Well_Formed (G), "clear rebuild");
   Add_Edge (G, 1, 2);
   H (1) := 1; H (2) := 0;
   Search (G, 1, 2, H (1 .. 2), Prev, Path, Len, Found, Exp);
   Check (Found and then Len = 2, "after clear ok");

   ------------------------------------------------------------------
   Section ("12. Reconstruct_Path");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   H (1) := 3; H (2) := 2; H (3) := 1; H (4) := 0;
   Search (G, 1, 4, H (1 .. 4), Prev, Path, Len, Found, Exp);
   Check (Found, "recon search found");
   Reconstruct_Path (Prev, 1, 4, 4, Path, Len, Ok);
   Check (Ok and then Len = 4, "recon ok len 4");
   Check (Path (1) = 1 and then Path (4) = 4, "recon ends");

   Reconstruct_Path (Prev, 1, 1, 4, Path, Len, Ok);
   Check (Ok and then Len = 1 and then Path (1) = 1, "recon Start=Goal");

   declare
      Bad_Prev : constant Prev_Array (1 .. 4) := [others => 0];
   begin
      Reconstruct_Path (Bad_Prev, 1, 4, 4, Path, Len, Ok);
      Check (not Ok and then Len = 0, "recon broken tree fails");
   end;

   ------------------------------------------------------------------
   Section ("13. Max_Vertices chain");
   ------------------------------------------------------------------
   Clear (G, Max_Vertices);
   for V in Vertex_Id range 1 .. Vertex_Id (Max_Vertices - 1) loop
      Add_Edge (G, V, V + 1);
   end loop;
   for V in Vertex_Id range 1 .. Vertex_Id (Max_Vertices) loop
      H (V) := Heuristic_Value (Max_Vertices - V);
   end loop;
   Search
     (G, 1, Vertex_Id (Max_Vertices),
      H (1 .. Vertex_Id (Max_Vertices)),
      Prev, Path, Len, Found, Exp);
   Check (Found, "max chain found");
   Check (Len = Max_Vertices, "max chain full length");
   Check (Path (1) = 1
            and then Path (Len) = Vertex_Id (Max_Vertices),
          "max chain ends");

   ------------------------------------------------------------------
   Section ("14. Contract helpers");
   ------------------------------------------------------------------
   Clear (G, 3);
   Check (Well_Formed (G), "helpers well-formed");
   Check (Arrays_OK (3, Prev, Path), "helpers Arrays_OK");
   Check (Heuristic_OK (3, H (1 .. 3)), "helpers Heuristic_OK");
   Check (not Arrays_OK (0, Prev, Path), "helpers Arrays_OK N=0");
   Check (Nat (Vertex_Count (G)) = 3, "helpers Nat N");

   ------------------------------------------------------------------
   Section ("15. Diamond / layered DAG");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 4);
   H (1) := 2; H (2) := 1; H (3) := 1; H (4) := 0;
   Search (G, 1, 4, H (1 .. 4), Prev, Path, Len, Found, Exp);
   Check (Found and then Len = 3, "diamond found");
   Check (Path (1) = 1 and then Path (3) = 4, "diamond ends");
   --  Tie H(2)=H(3)=1 ⇒ smaller id wins ⇒ via 2
   Check (Path (2) = 2, "diamond tie-break smaller id");

   ------------------------------------------------------------------
   New_Line;
   Put_Line ("========================================");
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   Put_Line ("========================================");

   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
