--  Standalone test suite for Coloring_Algorithm.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Coloring_Algorithm; use Coloring_Algorithm;

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

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function V_Id (X : Positive) return Vertex_Id is (Vertex_Id (X));

   function Clear_Raises (N : Natural) return Boolean is
      G : Graph;
   begin
      Clear (G, N);
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

   function Degree_Raises (G : Graph; V : Vertex_Id) return Boolean is
      D : Natural;
   begin
      D := Degree (G, V);
      pragma Unreferenced (D);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Degree_Raises;

   function Exact_Raises (G : Graph) return Boolean is
      X : Natural;
   begin
      X := Chromatic_Number_Exact (G);
      pragma Unreferenced (X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Exact_Raises;

   function Colors_Used_Raises
     (Colors : Color_Array; N : Natural) return Boolean
   is
      X : Natural;
   begin
      X := Colors_Used (Colors, N);
      pragma Unreferenced (X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Colors_Used_Raises;

   function Greedy_Raises_Bounds (G : Graph) return Boolean is
      Colors : Color_Array (Vertex_Id (2) .. Vertex_Id (10));
      Num    : Natural;
   begin
      Greedy_Color (G, Colors, Num);
      pragma Unreferenced (Num);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Greedy_Raises_Bounds;

   procedure Expect_Greedy
     (G        : Graph;
      At_Least : Natural;
      Label    : String;
      Order    : Order_Kind := Natural_Order)
   is
      N      : constant Natural := Vertex_Count (G);
      Colors : Color_Array (1 .. Vertex_Id'Last);
      Num    : Natural;
   begin
      if N = 0 then
         Greedy_Color (G, Colors (1 .. V_Id (1)), Num, Order);
         Check (Num = 0, Label & " empty greedy 0");
         return;
      end if;
      Greedy_Color (G, Colors (1 .. V_Id (N)), Num, Order);
      Check (Is_Proper_Coloring (G, Colors (1 .. V_Id (N))),
             Label & " proper");
      Check (Num >= At_Least, Label & " >= lower");
      Check (Colors_Used (Colors (1 .. V_Id (N)), N) = Num,
             Label & " used=num");
   end Expect_Greedy;

   procedure Expect_Exact (G : Graph; Expected : Natural; Label : String) is
      X : Natural;
   begin
      X := Chromatic_Number_Exact (G);
      Check (X = Expected, Label & " chi=" & Natural'Image (Expected));
   end Expect_Exact;

   procedure Expect_Bipartite (G : Graph; Expected : Boolean; Label : String)
   is
      Colors  : Color_Array (1 .. Vertex_Id'Last);
      Success : Boolean;
      N       : constant Natural := Vertex_Count (G);
   begin
      Check (Is_Bipartite (G) = Expected, Label & " Is_Bipartite");
      if N = 0 then
         Two_Color (G, Colors (1 .. V_Id (1)), Success);
      else
         Two_Color (G, Colors (1 .. V_Id (N)), Success);
      end if;
      Check (Success = Expected, Label & " Two_Color");
      if Expected and then N > 0 then
         Check (Is_Proper_Coloring (G, Colors (1 .. V_Id (N))),
                Label & " 2-color proper");
      end if;
   end Expect_Bipartite;

   procedure Make_Complete (G : in out Graph; N : Natural) is
   begin
      Clear (G, N);
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            Add_Edge (G, V_Id (I), V_Id (J));
         end loop;
      end loop;
   end Make_Complete;

   procedure Make_Path (G : in out Graph; N : Natural) is
   begin
      Clear (G, N);
      for I in 1 .. N - 1 loop
         Add_Edge (G, V_Id (I), V_Id (I + 1));
      end loop;
   end Make_Path;

   procedure Make_Cycle (G : in out Graph; N : Natural) is
   begin
      Make_Path (G, N);
      if N >= 3 then
         Add_Edge (G, V_Id (1), V_Id (N));
      end if;
   end Make_Cycle;

   procedure Make_Star (G : in out Graph; N : Natural) is
   begin
      Clear (G, N);
      for I in 2 .. N loop
         Add_Edge (G, V_Id (1), V_Id (I));
      end loop;
   end Make_Star;

   procedure Make_Bipartite_Complete
     (G : in out Graph; L, R : Natural)
   is
      N : constant Natural := L + R;
   begin
      Clear (G, N);
      for I in 1 .. L loop
         for J in 1 .. R loop
            Add_Edge (G, V_Id (I), V_Id (L + J));
         end loop;
      end loop;
   end Make_Bipartite_Complete;

   G      : Graph;
   Colors : Color_Array (1 .. Vertex_Id'Last);
   Num    : Natural;
   Success : Boolean;
   X      : Natural;

begin
   Put_Line ("Coloring_Algorithm test suite");
   Put_Line ("=============================");

   ---------------------------------------------------------------------
   Section ("1. Empty / edgeless");
   ---------------------------------------------------------------------
   Clear (G, Nat (0));
   Check (Vertex_Count (G) = 0, "N=0");
   Check (Edge_Count (G) = 0, "M=0");
   Expect_Bipartite (G, True, "empty");
   Expect_Exact (G, Nat (0), "empty");
   Expect_Greedy (G, Nat (0), "empty");

   Clear (G, Nat (1));
   Check (Vertex_Count (G) = 1, "N=1");
   Check (Edge_Count (G) = 0, "N=1 M=0");
   Expect_Bipartite (G, True, "K1");
   Expect_Exact (G, Nat (1), "K1");
   Expect_Greedy (G, Nat (1), "K1");
   Check (Degree (G, 1) = 0, "K1 deg0");

   Clear (G, Nat (5));
   Expect_Exact (G, Nat (1), "edgeless5");
   Expect_Bipartite (G, True, "edgeless5");
   Expect_Greedy (G, Nat (1), "edgeless5");
   Greedy_Color (G, Colors (1 .. V_Id (5)), Num, Natural_Order);
   Check (Num = 1, "edgeless5 uses1");
   Check (Colors_Used (Colors (1 .. V_Id (5)), 5) = 1, "edgeless5 used1");

   Clear (G, Nat (10));
   Expect_Exact (G, Nat (1), "edgeless10");
   Expect_Greedy (G, Nat (1), "edgeless10 deg", Degree_Descending);

   ---------------------------------------------------------------------
   Section ("2. Complete graphs Kn");
   ---------------------------------------------------------------------
   for N in 2 .. 8 loop
      Make_Complete (G, Nat (N));
      Check (Edge_Count (G) = N * (N - 1) / 2,
             "K" & Natural'Image (N) & " edges");
      Expect_Exact (G, Nat (N), "K" & Natural'Image (N));
      Expect_Greedy (G, Nat (N), "K" & Natural'Image (N) & " nat");
      Expect_Greedy (G, Nat (N), "K" & Natural'Image (N) & " deg",
                     Degree_Descending);
      Expect_Bipartite (G, N = 2, "K" & Natural'Image (N));
   end loop;

   Make_Complete (G, Nat (12));
   Expect_Exact (G, Nat (12), "K12");
   Expect_Greedy (G, Nat (12), "K12");

   ---------------------------------------------------------------------
   Section ("3. Paths and cycles");
   ---------------------------------------------------------------------
   Make_Path (G, Nat (2));
   Expect_Exact (G, Nat (2), "P2");
   Expect_Bipartite (G, True, "P2");

   Make_Path (G, Nat (5));
   Expect_Exact (G, Nat (2), "P5");
   Expect_Bipartite (G, True, "P5");
   Expect_Greedy (G, Nat (2), "P5");

   Make_Path (G, Nat (16));
   Expect_Exact (G, Nat (2), "P16");
   Expect_Bipartite (G, True, "P16");

   Make_Cycle (G, Nat (3));
   Expect_Exact (G, Nat (3), "C3");
   Expect_Bipartite (G, False, "C3");
   Expect_Greedy (G, Nat (3), "C3");

   Make_Cycle (G, Nat (4));
   Expect_Exact (G, Nat (2), "C4");
   Expect_Bipartite (G, True, "C4");

   Make_Cycle (G, Nat (5));
   Expect_Exact (G, Nat (3), "C5");
   Expect_Bipartite (G, False, "C5");

   Make_Cycle (G, Nat (6));
   Expect_Exact (G, Nat (2), "C6");
   Expect_Bipartite (G, True, "C6");

   Make_Cycle (G, Nat (7));
   Expect_Exact (G, Nat (3), "C7");
   Expect_Bipartite (G, False, "C7");

   Make_Cycle (G, Nat (8));
   Expect_Exact (G, Nat (2), "C8");

   Make_Cycle (G, Nat (15));
   Expect_Exact (G, Nat (3), "C15 odd");
   Expect_Bipartite (G, False, "C15");

   Make_Cycle (G, Nat (16));
   Expect_Exact (G, Nat (2), "C16 even");
   Expect_Bipartite (G, True, "C16");

   ---------------------------------------------------------------------
   Section ("4. Stars and trees");
   ---------------------------------------------------------------------
   Make_Star (G, Nat (2));
   Expect_Exact (G, Nat (2), "star2");
   Expect_Bipartite (G, True, "star2");

   Make_Star (G, Nat (5));
   Expect_Exact (G, Nat (2), "star5");
   Expect_Bipartite (G, True, "star5");
   Expect_Greedy (G, Nat (2), "star5");
   Check (Degree (G, 1) = 4, "star5 center deg");
   Check (Degree (G, 2) = 1, "star5 leaf deg");

   Make_Star (G, Nat (16));
   Expect_Exact (G, Nat (2), "star16");
   Expect_Bipartite (G, True, "star16");

   --  Binary-ish tree
   Clear (G, Nat (7));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 2, 5);
   Add_Edge (G, 3, 6);
   Add_Edge (G, 3, 7);
   Expect_Exact (G, Nat (2), "tree7");
   Expect_Bipartite (G, True, "tree7");

   ---------------------------------------------------------------------
   Section ("5. Complete bipartite");
   ---------------------------------------------------------------------
   Make_Bipartite_Complete (G, Nat (1), Nat (1));
   Expect_Exact (G, Nat (2), "K1,1");
   Expect_Bipartite (G, True, "K1,1");

   Make_Bipartite_Complete (G, Nat (2), Nat (3));
   Expect_Exact (G, Nat (2), "K2,3");
   Expect_Bipartite (G, True, "K2,3");
   Expect_Greedy (G, Nat (2), "K2,3");

   Make_Bipartite_Complete (G, Nat (3), Nat (3));
   Expect_Exact (G, Nat (2), "K3,3");
   Expect_Bipartite (G, True, "K3,3");

   Make_Bipartite_Complete (G, Nat (4), Nat (5));
   Expect_Exact (G, Nat (2), "K4,5");
   Expect_Bipartite (G, True, "K4,5");

   Make_Bipartite_Complete (G, Nat (1), Nat (10));
   Expect_Exact (G, Nat (2), "K1,10");

   ---------------------------------------------------------------------
   Section ("6. Greedy vs exact on tiny");
   ---------------------------------------------------------------------
   --  Greedy may use more than χ; exact is tight.
   Clear (G, Nat (6));
   --  Mycielski Grötzsch-ish small: odd wheel-ish
   --  Two triangles sharing a vertex is χ=3
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 1);
   Expect_Exact (G, Nat (3), "two triangles");
   Greedy_Color (G, Colors (1 .. V_Id (6)), Num, Natural_Order);
   Check (Is_Proper_Coloring (G, Colors (1 .. V_Id (6))), "two tri greedy proper");
   Check (Num >= 3, "two tri greedy >=3");
   Check (Num >= Chromatic_Number_Exact (G), "greedy >= exact");

   Make_Cycle (G, Nat (5));
   Greedy_Color (G, Colors (1 .. V_Id (5)), Num, Natural_Order);
   X := Chromatic_Number_Exact (G);
   Check (X = 3, "C5 exact3");
   Check (Num >= X, "C5 greedy>=exact");
   Greedy_Color (G, Colors (1 .. V_Id (5)), Num, Degree_Descending);
   Check (Is_Proper_Coloring (G, Colors (1 .. V_Id (5))), "C5 deg proper");
   Check (Num >= X, "C5 deg>=exact");

   Make_Complete (G, Nat (4));
   Greedy_Color (G, Colors (1 .. V_Id (4)), Num, Natural_Order);
   Check (Num = 4, "K4 greedy=4");
   Check (Chromatic_Number_Exact (G) = 4, "K4 exact=4");

   --  Bipartite where natural greedy still gets 2
   Make_Path (G, Nat (8));
   Greedy_Color (G, Colors (1 .. V_Id (8)), Num, Natural_Order);
   Check (Num = 2, "P8 greedy2");
   Check (Chromatic_Number_Exact (G) = 2, "P8 exact2");

   ---------------------------------------------------------------------
   Section ("7. Disconnected / mixed components");
   ---------------------------------------------------------------------
   Clear (G, Nat (6));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 3);  -- triangle + edge + isolate
   Expect_Exact (G, Nat (3), "tri+edge+iso");
   Expect_Bipartite (G, False, "tri+edge+iso");

   Clear (G, Nat (6));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 4);
   Expect_Exact (G, Nat (2), "two edges");
   Expect_Bipartite (G, True, "two edges");

   Clear (G, Nat (4));
   Make_Cycle (G, Nat (4));
   Expect_Bipartite (G, True, "C4 alone");

   ---------------------------------------------------------------------
   Section ("8. Odd wheels / high chromatic");
   ---------------------------------------------------------------------
   --  Wheel W_n: hub + cycle of n-1. Odd cycle ⇒ χ=4 for wheel on even
   --  outer? W_n often means n vertices total = hub + C_{n-1}.
   --  Hub + C5 (6 verts): outer odd ⇒ needs 3 + hub conflicts all ⇒ 4.
   Clear (G, Nat (6));
   for I in 2 .. 6 loop
      Add_Edge (G, 1, V_Id (I));
   end loop;
   for I in 2 .. 5 loop
      Add_Edge (G, V_Id (I), V_Id (I + 1));
   end loop;
   Add_Edge (G, 6, 2);
   Expect_Exact (G, Nat (4), "W6 hub+C5");
   Expect_Bipartite (G, False, "W6");
   Expect_Greedy (G, Nat (4), "W6");

   --  Hub + C4 (5 verts): outer even ⇒ χ=3
   Clear (G, Nat (5));
   for I in 2 .. 5 loop
      Add_Edge (G, 1, V_Id (I));
   end loop;
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 2);
   Expect_Exact (G, Nat (3), "W5 hub+C4");

   ---------------------------------------------------------------------
   Section ("9. Parallel edges");
   ---------------------------------------------------------------------
   Clear (G, Nat (3));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Check (Edge_Count (G) = 3, "parallels count");
   Expect_Exact (G, Nat (2), "parallels path");
   Expect_Bipartite (G, True, "parallels");
   Check (Degree (G, 1) = 2, "parallel deg");

   ---------------------------------------------------------------------
   Section ("10. Is_Proper_Coloring / Colors_Used");
   ---------------------------------------------------------------------
   Make_Complete (G, Nat (3));
   Colors (1) := 1;
   Colors (2) := 2;
   Colors (3) := 3;
   Check (Is_Proper_Coloring (G, Colors (1 .. V_Id (3))), "K3 proper 123");
   Check (Colors_Used (Colors (1 .. V_Id (3)), 3) = 3, "K3 used3");

   Colors (3) := 1;
   Check (not Is_Proper_Coloring (G, Colors (1 .. V_Id (3))), "K3 bad 121");

   Colors (1) := 0;
   Colors (2) := 1;
   Colors (3) := 2;
   Check (not Is_Proper_Coloring (G, Colors (1 .. V_Id (3))), "K3 zero color");

   Clear (G, Nat (0));
   Check (Is_Proper_Coloring (G, Colors (1 .. V_Id (1))), "empty proper");
   Check (Colors_Used (Colors (1 .. V_Id (1)), 0) = 0, "used N=0");

   --  Bound mismatch → False, not raise
   Make_Path (G, Nat (3));
   declare
      Small : constant Color_Array (1 .. V_Id (2)) := [1, 2];
   begin
      Check (not Is_Proper_Coloring (G, Small), "short colors false");
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid_Argument");
   ---------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "Clear overflow");
   Check (not Clear_Raises (Nat (Max_Vertices)), "Clear max ok");

   Clear (G, Nat (3));
   Check (Add_Raises (G, 1, 1), "self-loop");
   Check (Add_Raises (G, V_Id (1), V_Id (4)), "V OOB");
   Check (Add_Raises (G, V_Id (4), V_Id (1)), "U OOB");

   Clear (G, Nat (0));
   Check (Add_Raises (G, 1, 2), "add on empty");
   Check (Degree_Raises (G, 1), "deg on empty");

   Clear (G, Nat (2));
   Check (Degree_Raises (G, V_Id (3)), "deg OOB");

   Clear (G, Nat (Max_Exact + 1));
   Check (Exact_Raises (G), "exact N>Max_Exact");

   Clear (G, Nat (Max_Exact));
   Check (not Exact_Raises (G), "exact N=Max_Exact ok");

   Clear (G, Nat (5));
   Check (Greedy_Raises_Bounds (G), "greedy bad First");

   declare
      Bad : constant Color_Array (1 .. V_Id (2)) := [1, 2];
   begin
      Check (Colors_Used_Raises (Bad, Nat (5)), "Colors_Used short");
   end;

   --  Edge capacity overflow
   Clear (G, Nat (3));
   declare
      Overflowed : Boolean := False;
   begin
      for K in 1 .. Max_Edges loop
         Add_Edge (G, 1, 2);
      end loop;
      begin
         Add_Edge (G, 1, 2);
      exception
         when Invalid_Argument =>
            Overflowed := True;
      end;
      Check (Overflowed, "Max_Edges overflow");
      Check (Edge_Count (G) = Max_Edges, "at Max_Edges");
   end;

   ---------------------------------------------------------------------
   Section ("12. Larger greedy-only graphs");
   ---------------------------------------------------------------------
   Make_Complete (G, Nat (20));
   Expect_Greedy (G, Nat (20), "K20");
   Expect_Bipartite (G, False, "K20");

   Make_Path (G, Nat (100));
   Expect_Greedy (G, Nat (2), "P100");
   Expect_Bipartite (G, True, "P100");

   Make_Star (G, Nat (64));
   Expect_Greedy (G, Nat (2), "star64");
   Expect_Bipartite (G, True, "star64");

   Make_Bipartite_Complete (G, Nat (10), Nat (10));
   Expect_Greedy (G, Nat (2), "K10,10");
   Expect_Bipartite (G, True, "K10,10");

   Make_Cycle (G, Nat (50));
   Expect_Greedy (G, Nat (2), "C50");
   Expect_Bipartite (G, True, "C50");

   Make_Cycle (G, Nat (51));
   Expect_Greedy (G, Nat (3), "C51");
   Expect_Bipartite (G, False, "C51");

   Clear (G, Nat (200));
   Expect_Greedy (G, Nat (1), "edgeless200");
   Expect_Bipartite (G, True, "edgeless200");

   Make_Path (G, Nat (256));
   Expect_Greedy (G, Nat (2), "P256");
   Expect_Bipartite (G, True, "P256");

   ---------------------------------------------------------------------
   Section ("13. Degree-descending vs natural");
   ---------------------------------------------------------------------
   --  Graph where order can matter for colour count (bipartite still 2).
   Clear (G, Nat (8));
   --  Crown-ish
   for I in 1 .. 4 loop
      Add_Edge (G, V_Id (I), V_Id (I + 4));
   end loop;
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Greedy_Color (G, Colors (1 .. V_Id (8)), Num, Natural_Order);
   Check (Is_Proper_Coloring (G, Colors (1 .. V_Id (8))), "crown nat proper");
   Check (Num >= 2, "crown nat >=2");
   Greedy_Color (G, Colors (1 .. V_Id (8)), Num, Degree_Descending);
   Check (Is_Proper_Coloring (G, Colors (1 .. V_Id (8))), "crown deg proper");
   Check (Num >= Chromatic_Number_Exact (G), "crown deg>=chi");

   ---------------------------------------------------------------------
   Section ("14. Exact boundary Max_Exact");
   ---------------------------------------------------------------------
   Make_Path (G, Nat (Max_Exact));
   Expect_Exact (G, Nat (2), "P_MaxExact");

   Make_Complete (G, Nat (Max_Exact));
   Expect_Exact (G, Nat (Max_Exact), "K_MaxExact");

   Make_Cycle (G, Nat (Max_Exact));
   Expect_Exact (G, Nat (2), "C16 even exact");

   Make_Star (G, Nat (Max_Exact));
   Expect_Exact (G, Nat (2), "star_MaxExact");

   ---------------------------------------------------------------------
   Section ("15. Two_Color colour values");
   ---------------------------------------------------------------------
   Make_Path (G, Nat (4));
   Two_Color (G, Colors (1 .. V_Id (4)), Success);
   Check (Success, "P4 two ok");
   Check (Colors (1) = 1 or Colors (1) = 2, "P4 c1 in{1,2}");
   Check (Colors (1) /= Colors (2), "P4 adj differ");
   Check (Colors (2) /= Colors (3), "P4 adj23");
   Check (Colors (3) /= Colors (4), "P4 adj34");
   Check (Colors (1) = Colors (3), "P4 same class");

   Clear (G, Nat (3));
   Two_Color (G, Colors (1 .. V_Id (3)), Success);
   Check (Success, "edgeless3 two");
   Check (Colors_Used (Colors (1 .. V_Id (3)), 3) = 1, "edgeless3 one colour");

   Make_Cycle (G, Nat (3));
   Two_Color (G, Colors (1 .. V_Id (3)), Success);
   Check (not Success, "C3 two fail");

   ---------------------------------------------------------------------
   Section ("16. Capacity smoke Max_Vertices");
   ---------------------------------------------------------------------
   Clear (G, Nat (Max_Vertices));
   Check (Vertex_Count (G) = Max_Vertices, "max N");
   Add_Edge (G, 1, 2);
   Check (Edge_Count (G) = 1, "max N one edge");
   Expect_Greedy (G, Nat (2), "maxN pathish");
   Expect_Bipartite (G, True, "maxN nearly empty");
   Check (Degree (G, 1) = 1, "maxN deg");

   ---------------------------------------------------------------------
   Section ("17. More exact families");
   ---------------------------------------------------------------------
   --  Petersen is 10 verts, χ=3 — build via known edges
   Clear (G, Nat (10));
   --  Outer pentagon
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 1);
   --  Spokes
   Add_Edge (G, 1, 6);
   Add_Edge (G, 2, 7);
   Add_Edge (G, 3, 8);
   Add_Edge (G, 4, 9);
   Add_Edge (G, 5, 10);
   --  Inner star
   Add_Edge (G, 6, 8);
   Add_Edge (G, 8, 10);
   Add_Edge (G, 10, 7);
   Add_Edge (G, 7, 9);
   Add_Edge (G, 9, 6);
   Expect_Exact (G, Nat (3), "Petersen");
   Expect_Bipartite (G, False, "Petersen");
   Expect_Greedy (G, Nat (3), "Petersen");

   --  Chvátal-ish small: K4 minus edge then attach — just use odd wheel again
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 1);
   Add_Edge (G, 1, 3);
   Expect_Exact (G, Nat (3), "C4+diag");

   Clear (G, Nat (4));
   Make_Complete (G, Nat (4));
   Expect_Exact (G, Nat (4), "K4 again");

   ---------------------------------------------------------------------
   Section ("18. Inspectors after Clear");
   ---------------------------------------------------------------------
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 4);
   Check (Edge_Count (G) = 2, "before clear M");
   Clear (G, Nat (2));
   Check (Vertex_Count (G) = 2, "after clear N");
   Check (Edge_Count (G) = 0, "after clear M");
   Check (Degree (G, 1) = 0, "after clear deg");

   ---------------------------------------------------------------------
   Section ("19. Greedy upper bound Δ+1");
   ---------------------------------------------------------------------
   Make_Star (G, Nat (10));
   Greedy_Color (G, Colors (1 .. V_Id (10)), Num, Degree_Descending);
   Check (Num <= 2, "star Delta+1 =>2");
   Check (Is_Proper_Coloring (G, Colors (1 .. V_Id (10))), "star deg proper");

   Make_Complete (G, Nat (7));
   Greedy_Color (G, Colors (1 .. V_Id (7)), Num, Degree_Descending);
   Check (Num = 7, "K7 deg=7");

   ---------------------------------------------------------------------
   Section ("20. Randomish small exact batch");
   ---------------------------------------------------------------------
   for Seed in 1 .. 12 loop
      Clear (G, Nat (8));
      for I in 1 .. 8 loop
         declare
            J : constant Natural :=
              1 + (I * Seed * 3) mod 8;
         begin
            if J /= I then
               Add_Edge (G, V_Id (I), V_Id (J));
            end if;
         end;
      end loop;
      X := Chromatic_Number_Exact (G);
      Greedy_Color (G, Colors (1 .. V_Id (8)), Num, Natural_Order);
      Check (Is_Proper_Coloring (G, Colors (1 .. V_Id (8))),
             "batch" & Natural'Image (Seed) & " proper");
      Check (Num >= X,
             "batch" & Natural'Image (Seed) & " greedy>=chi");
      Check (X >= 1, "batch" & Natural'Image (Seed) & " chi>=1");
      if Is_Bipartite (G) then
         Check (X <= 2, "batch" & Natural'Image (Seed) & " bip chi<=2");
      end if;
   end loop;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
