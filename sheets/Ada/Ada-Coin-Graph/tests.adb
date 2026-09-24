--  Standalone test suite for Coin_Graph (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Coin_Graph; use Coin_Graph;

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
   function Int (X : Integer) return Integer is (X);
   function LF (X : Long_Float) return Long_Float is (X);

   function Approx
     (A, B : Long_Float; Tol : Long_Float := 1.0E-9) return Boolean
   is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   type Local_Circles is array (Positive range <>) of Circle;

   procedure Fill (P : in out Packing; Cs : Local_Circles) is
   begin
      Clear (P);
      for C of Cs loop
         Add_Circle (P, C);
      end loop;
   end Fill;

   function Has_Edge
     (Edges : Edge_List; Count : Natural; A, B : Circle_Index)
      return Boolean
   is
      Lo : Circle_Index := A;
      Hi : Circle_Index := B;
      T  : Circle_Index;
   begin
      if Lo > Hi then
         T := Lo;
         Lo := Hi;
         Hi := T;
      end if;
      for K in 1 .. Count loop
         if Edges (K).U = Lo and then Edges (K).V = Hi then
            return True;
         end if;
      end loop;
      return False;
   end Has_Edge;

   function Add_Raises (P : in out Packing; C : Circle) return Boolean is
   begin
      Add_Circle (P, C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Get_Raises
     (P : Packing; Index : Circle_Index) return Boolean
   is
      C : Circle;
   begin
      C := Get_Circle (P, Index);
      pragma Unreferenced (C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Get_Raises;

   function Tangent_Raises
     (P : Packing; I, J : Circle_Index) return Boolean
   is
      B : Boolean;
   begin
      B := Are_Tangent (P, I, J);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Tangent_Raises;

   function Build_Raises
     (P : Packing; Buf_Last : Natural; Bad_First : Boolean := False)
      return Boolean
   is
      Count : Natural;
   begin
      if Bad_First then
         declare
            Edges : Edge_List (2 .. Positive'Max (2, Buf_Last + 1));
         begin
            Build_Contact_Graph (P, Edges, Count);
         end;
      elsif Buf_Last = 0 then
         declare
            Edges : Edge_List (1 .. 0);
         begin
            Build_Contact_Graph (P, Edges, Count);
         end;
      else
         declare
            Edges : Edge_List (1 .. Buf_Last);
         begin
            Build_Contact_Graph (P, Edges, Count);
         end;
      end if;
      pragma Unreferenced (Count);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Build_Raises;

   function Grid_Raises
     (Rows, Cols, Radius : Positive; Already : Natural) return Boolean
   is
      P : Packing;
   begin
      Clear (P);
      for K in 1 .. Already loop
         Add_Circle (P, (X => K * 1000, Y => 0, R => 1));
      end loop;
      Add_Equal_Radius_Grid (P, Rows, Cols, Radius);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Grid_Raises;

   P : Packing;
   Edges : Edge_List (1 .. Max_Edges);
   Count : Natural;
   C : Circle;

begin
   ------------------------------------------------------------------
   Section ("1. Empty packing / Clear / Circle_Count");
   ------------------------------------------------------------------
   Clear (P);
   Check (Circle_Count (P) = Nat (0), "empty count 0");
   Check (Is_Valid_Packing (P), "empty is valid packing");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (0), "empty contact count 0");
   Contact_Edges (P, Edges, Count);
   Check (Count = Nat (0), "Contact_Edges synonym empty");
   Add_Circle (P, (0, 0, 5));
   Check (Circle_Count (P) = Nat (1), "one circle");
   Clear (P);
   Check (Circle_Count (P) = Nat (0), "clear resets");
   Check (Is_Valid_Packing (P), "cleared packing valid");

   ------------------------------------------------------------------
   Section ("2. Add_Circle / Get_Circle / radii");
   ------------------------------------------------------------------
   Clear (P);
   Add_Circle (P, (X => 10, Y => -3, R => 7));
   C := Get_Circle (P, 1);
   Check (C.X = Int (10), "get X");
   Check (C.Y = Int (-3), "get Y");
   Check (C.R = Int (7), "get R");
   Add_Circle (P, (0, 0, 1));
   Check (Circle_Count (P) = Nat (2), "two circles");
   C := Get_Circle (P, 2);
   Check (C.R = Int (1), "second radius");
   Check (Add_Raises (P, (0, 0, 0)), "radius 0 raises");
   Check (Add_Raises (P, (0, 0, -1)), "negative radius raises");
   Check (Add_Raises (P, (0, 0, Integer'First)), "Integer'First radius raises");
   Check (Get_Raises (P, 3), "Get_Circle out of range");
   Check (Get_Raises (P, Circle_Index (Max_Circles)),
          "Get_Circle far out of range");

   ------------------------------------------------------------------
   Section ("3. Euclidean_Distance / Sum_Of_Radii helpers");
   ------------------------------------------------------------------
   Check (Approx (Euclidean_Distance ((0, 0, 1), (3, 4, 1)), LF (5.0)),
          "3-4-5 distance");
   Check (Approx (Euclidean_Distance ((0, 0, 1), (0, 0, 2)), LF (0.0)),
          "coincident centers");
   Check (Approx (Euclidean_Distance ((1, 1, 2), (1, 4, 3)), LF (3.0)),
          "vertical distance 3");
   Check (Approx (Sum_Of_Radii ((0, 0, 2), (0, 0, 5)), LF (7.0)),
          "sum of radii 7");
   Check (Approx (Sum_Of_Radii ((0, 0, 1), (0, 0, 1)), LF (2.0)),
          "unit pair sum 2");
   Check (Are_Externally_Tangent ((0, 0, 1), (2, 0, 1)),
          "helper tangent unit pair");
   Check (not Are_Externally_Tangent ((0, 0, 1), (5, 0, 1)),
          "helper not tangent far");
   Check (Interiors_Overlap ((0, 0, 2), (1, 0, 2)),
          "helper overlap");
   Check (not Interiors_Overlap ((0, 0, 1), (2, 0, 1)),
          "helper touch no overlap");
   Check (not Interiors_Overlap ((0, 0, 1), (10, 0, 1)),
          "helper separated no overlap");

   ------------------------------------------------------------------
   Section ("4. Two touching disks → one edge");
   ------------------------------------------------------------------
   Fill (P, [(0, 0, 1), (2, 0, 1)]);
   Check (Is_Valid_Packing (P), "two touching valid");
   Check (Are_Tangent (P, 1, 2), "two touching Are_Tangent");
   Check (Are_Tangent (P, 2, 1), "Are_Tangent symmetric");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (1), "two touching one edge");
   Check (Has_Edge (Edges, Count, 1, 2), "edge {1,2} present");
   Contact_Edges (P, Edges, Count);
   Check (Count = Nat (1), "Contact_Edges synonym count 1");

   Fill (P, [(0, 0, 5), (15, 0, 10)]);
   Check (Are_Tangent (P, 1, 2), "unequal radii tangent 5+10");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (1), "unequal radii one edge");
   Check (Is_Valid_Packing (P), "unequal radii valid");

   Fill (P, [(0, 0, 3), (0, 7, 4)]);
   Check (Are_Tangent (P, 1, 2), "vertical tangent 3+4");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (1), "vertical one edge");

   ------------------------------------------------------------------
   Section ("5. Separated disks → no edges");
   ------------------------------------------------------------------
   Fill (P, [(0, 0, 1), (10, 0, 1)]);
   Check (Is_Valid_Packing (P), "separated valid");
   Check (not Are_Tangent (P, 1, 2), "separated not tangent");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (0), "separated zero edges");

   Fill (P, [(0, 0, 2), (100, 100, 3)]);
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (0), "far pair zero edges");
   Check (Is_Valid_Packing (P), "far pair valid");

   Fill (P, [(0, 0, 1), (3, 0, 1)]);
   Check (not Are_Tangent (P, 1, 2), "gap of 1 not tangent");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (0), "gap zero edges");
   Check (Is_Valid_Packing (P), "gap still valid packing");

   ------------------------------------------------------------------
   Section ("6. Overlapping interiors → invalid packing");
   ------------------------------------------------------------------
   Fill (P, [(0, 0, 2), (1, 0, 2)]);
   Check (not Is_Valid_Packing (P), "overlap invalid");
   Check (not Are_Tangent (P, 1, 2), "overlap not tangent");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (0), "overlap no contact edge");

   Fill (P, [(0, 0, 5), (0, 0, 3)]);
   Check (not Is_Valid_Packing (P), "concentric nested invalid");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (0), "concentric no contact");

   Fill (P, [(0, 0, 10), (5, 0, 10)]);
   Check (not Is_Valid_Packing (P), "heavy overlap invalid");

   Fill (P, [(0, 0, 1), (2, 0, 1), (1, 0, 2)]);
   Check (not Is_Valid_Packing (P), "third overlaps both");

   ------------------------------------------------------------------
   Section ("7. Triangle of mutually tangent coins");
   ------------------------------------------------------------------
   --  Equilateral centers at distance 2 for unit coins:
   --  (0,0), (2,0), (1, round(sqrt(3))) ≈ (1,2) is NOT exact.
   --  Exact integer: three unit coins? Need centers at distance 2.
   --  Use (0,0,1), (2,0,1), and for exact: place third with float —
   --  integer: radii 5 with 3-4-5? Centers (0,0), (10,0), (0,10) with r=5
   --  give distances 10,10,10*sqrt(2) — only two tangencies.
   --  Mutual: three equal radius R with centers forming equilateral of
   --  side 2R. Exact integer example with unequal radii via Descartes
   --  is harder; use three pairwise externally tangent with integer
   --  centers: (0,0,r=5), (10,0,r=5), (5,12,r=8)? Check:
   --  d12=10=5+5, d13=sqrt(25+144)=13, 5+8=13, d23=sqrt(25+144)=13, 5+8=13.
   --  Yes: triangle of three mutually tangent coins.
   Fill (P, [(0, 0, 5), (10, 0, 5), (5, 12, 8)]);
   Check (Is_Valid_Packing (P), "mutual triangle valid");
   Check (Are_Tangent (P, 1, 2), "triangle edge 1-2");
   Check (Are_Tangent (P, 1, 3), "triangle edge 1-3");
   Check (Are_Tangent (P, 2, 3), "triangle edge 2-3");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (3), "triangle three edges");
   Check (Has_Edge (Edges, Count, 1, 2), "triangle has 1-2");
   Check (Has_Edge (Edges, Count, 1, 3), "triangle has 1-3");
   Check (Has_Edge (Edges, Count, 2, 3), "triangle has 2-3");

   --  Unit equilateral using approximate height: not exact on integers.
   --  Path of three unit coins in a line: two edges.
   Fill (P, [(0, 0, 1), (2, 0, 1), (4, 0, 1)]);
   Check (Is_Valid_Packing (P), "line of three valid");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (2), "line of three two edges");
   Check (Has_Edge (Edges, Count, 1, 2) and then Has_Edge (Edges, Count, 2, 3),
          "line edges consecutive");
   Check (not Has_Edge (Edges, Count, 1, 3), "line no skip edge");

   ------------------------------------------------------------------
   Section ("8. Invalid_Argument guards");
   ------------------------------------------------------------------
   Clear (P);
   Check (Tangent_Raises (P, 1, 2), "Are_Tangent empty raises");
   Add_Circle (P, (0, 0, 1));
   Check (Tangent_Raises (P, 1, 1), "Are_Tangent I=J raises");
   Check (Tangent_Raises (P, 1, 2), "Are_Tangent J out of range");
   Check (Tangent_Raises (P, 2, 1), "Are_Tangent I out of range");
   Add_Circle (P, (2, 0, 1));
   Check (not Tangent_Raises (P, 1, 2), "Are_Tangent valid ok");

   --  Buffer First /= 1
   Check (Build_Raises (P, 10, Bad_First => True),
          "Build bad First raises");

   --  Buffer too small for N=2 need 1
   Clear (P);
   Add_Circle (P, (0, 0, 1));
   Add_Circle (P, (2, 0, 1));
   Check (Build_Raises (P, 0), "Build Last=0 for N=2 raises");

   --  N=3 needs Last >= 3
   Add_Circle (P, (4, 0, 1));
   Check (Build_Raises (P, 2), "Build Last=2 for N=3 raises");
   Check (not Build_Raises (P, 3), "Build Last=3 for N=3 ok");

   --  Capacity overflow
   Clear (P);
   for K in 1 .. Max_Circles loop
      Add_Circle (P, (X => K, Y => 0, R => 1));
   end loop;
   Check (Circle_Count (P) = Nat (Max_Circles), "filled to Max_Circles");
   Check (Add_Raises (P, (0, 0, 1)), "overflow raises");

   ------------------------------------------------------------------
   Section ("9. Single disk / two non-edge cases");
   ------------------------------------------------------------------
   Clear (P);
   Add_Circle (P, (7, 8, 9));
   Check (Circle_Count (P) = Nat (1), "single count");
   Check (Is_Valid_Packing (P), "single valid");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (0), "single zero edges");
   Check (Tangent_Raises (P, 1, 1), "single I=J raises");

   ------------------------------------------------------------------
   Section ("10. Equal-radius grid helper (penny lattice)");
   ------------------------------------------------------------------
   Clear (P);
   Add_Equal_Radius_Grid (P, 1, 1, 3);
   Check (Circle_Count (P) = Nat (1), "1x1 grid count");
   C := Get_Circle (P, 1);
   Check (C.X = Int (0) and then C.Y = Int (0) and then C.R = Int (3),
          "1x1 origin radius");

   Clear (P);
   Add_Equal_Radius_Grid (P, 1, 3, 1);
   Check (Circle_Count (P) = Nat (3), "1x3 count");
   Check (Is_Valid_Packing (P), "1x3 valid");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (2), "1x3 two contacts");
   Check (Are_Tangent (P, 1, 2) and then Are_Tangent (P, 2, 3),
          "1x3 consecutive tangent");

   Clear (P);
   Add_Equal_Radius_Grid (P, 2, 2, 1);
   Check (Circle_Count (P) = Nat (4), "2x2 count");
   Check (Is_Valid_Packing (P), "2x2 valid");
   Build_Contact_Graph (P, Edges, Count);
   --  Horizontal: 2, Vertical: 2, Diagonal: distance 2√2 ≠ 2 → 4 edges
   Check (Count = Nat (4), "2x2 four axis contacts");
   Check (Are_Tangent (P, 1, 2), "2x2 row1 horizontal");
   Check (Are_Tangent (P, 1, 3), "2x2 col1 vertical");
   Check (not Are_Tangent (P, 1, 4), "2x2 diagonal not tangent");

   Clear (P);
   Add_Equal_Radius_Grid (P, 3, 3, 2, Origin_X => 10, Origin_Y => -4);
   Check (Circle_Count (P) = Nat (9), "3x3 count");
   Check (Is_Valid_Packing (P), "3x3 valid");
   Build_Contact_Graph (P, Edges, Count);
   --  Horiz: 3 rows * 2 = 6; Vert: 3 cols * 2 = 6; total 12
   Check (Count = Nat (12), "3x3 twelve contacts");
   C := Get_Circle (P, 1);
   Check (C.X = Int (10) and then C.Y = Int (-4), "3x3 origin offset");

   Check (Grid_Raises (20, 20, 1, 0), "20x20 grid overflow raises");
   Clear (P);
   for K in 1 .. Max_Circles - 1 loop
      Add_Circle (P, (X => K * 3, Y => 0, R => 1));
   end loop;
   Check (Grid_Raises (1, 2, 1, Max_Circles - 1),
          "grid overflow near full raises");

   ------------------------------------------------------------------
   Section ("11. Square of four mutually adjacent coins");
   ------------------------------------------------------------------
   Fill (P, [(0, 0, 1), (2, 0, 1), (0, 2, 1), (2, 2, 1)]);
   Check (Is_Valid_Packing (P), "square packing valid");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (4), "square four contacts");
   Check (Has_Edge (Edges, Count, 1, 2), "square top/bottom edge");
   Check (Has_Edge (Edges, Count, 1, 3), "square left edge");
   Check (Has_Edge (Edges, Count, 2, 4), "square right edge");
   Check (Has_Edge (Edges, Count, 3, 4), "square bottom edge");
   Check (not Has_Edge (Edges, Count, 1, 4), "square no diagonal");
   Check (not Has_Edge (Edges, Count, 2, 3), "square no other diagonal");

   ------------------------------------------------------------------
   Section ("12. Chain / star / path patterns");
   ------------------------------------------------------------------
   Fill (P, [(0, 0, 2), (5, 0, 3), (12, 0, 4)]);
   --  2+3=5, 3+4=7 → d23 = 7; 2+4=6 but d13=12 → not tangent
   Check (Is_Valid_Packing (P), "chain valid");
   Check (Are_Tangent (P, 1, 2), "chain 1-2");
   Check (Are_Tangent (P, 2, 3), "chain 2-3");
   Check (not Are_Tangent (P, 1, 3), "chain no 1-3");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (2), "chain two edges");

   --  Star: center + 4 satellites (axis)
   Fill (P,
     [(0, 0, 2),
      (5, 0, 3),
      (-5, 0, 3),
      (0, 5, 3),
      (0, -5, 3)]);
   Check (Is_Valid_Packing (P), "star valid");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (4), "star four spokes");
   Check (Are_Tangent (P, 1, 2) and then Are_Tangent (P, 1, 3)
            and then Are_Tangent (P, 1, 4) and then Are_Tangent (P, 1, 5),
          "star all spokes");
   Check (not Are_Tangent (P, 2, 3), "star opposite not tangent");

   ------------------------------------------------------------------
   Section ("13. Rebuild / Clear stability");
   ------------------------------------------------------------------
   Clear (P);
   Add_Circle (P, (0, 0, 1));
   Add_Circle (P, (2, 0, 1));
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (1), "before clear one edge");
   Clear (P);
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (0) and then Circle_Count (P) = Nat (0),
          "after clear empty graph");
   Fill (P, [(0, 0, 1), (2, 0, 1), (4, 0, 1), (6, 0, 1)]);
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (3), "path4 three edges");
   Contact_Edges (P, Edges, Count);
   Check (Count = Nat (3), "path4 synonym");

   ------------------------------------------------------------------
   Section ("14. Many pairwise checks (grid micro-suite)");
   ------------------------------------------------------------------
   Clear (P);
   Add_Equal_Radius_Grid (P, 4, 5, 1);
   Check (Circle_Count (P) = Nat (20), "4x5 = 20");
   Check (Is_Valid_Packing (P), "4x5 valid");
   Build_Contact_Graph (P, Edges, Count);
   --  Horiz: 4*4=16; Vert: 5*3=15; total 31
   Check (Count = Nat (31), "4x5 thirty-one contacts");

   --  Spot-check several Are_Tangent / non-tangent pairs
   Check (Are_Tangent (P, 1, 2), "4x5 (1,2) row");
   Check (Are_Tangent (P, 1, 6), "4x5 (1,6) down");  -- col-major? row-major:
   --  Order: row R, col C → index = (R-1)*Cols + C
   --  index 1 = (1,1), 2=(1,2), 6=(2,1) for Cols=5
   Check (not Are_Tangent (P, 1, 3), "4x5 skip not tangent");
   Check (not Are_Tangent (P, 1, 7), "4x5 diagonal-ish not");

   ------------------------------------------------------------------
   Section ("15. Disconnected valid packing (two components)");
   ------------------------------------------------------------------
   Fill (P, [(0, 0, 1), (2, 0, 1), (100, 0, 1), (102, 0, 1)]);
   Check (Is_Valid_Packing (P), "two pairs valid");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (2), "two components two edges");
   Check (Has_Edge (Edges, Count, 1, 2) and then Has_Edge (Edges, Count, 3, 4),
          "component edges");
   Check (not Has_Edge (Edges, Count, 1, 3), "no cross edge");

   ------------------------------------------------------------------
   Section ("16. Nested internal-distance not counted as coin edge");
   ------------------------------------------------------------------
   --  Internal tangency: small inside large touching from inside.
   --  d = |R_big - R_small|. Interiors of the *disks* overlap (small
   --  interior ⊂ large interior), so packing is invalid; coin graphs
   --  use external tangency only.
   Fill (P, [(0, 0, 10), (5, 0, 5)]);  -- d=5 = 10-5, internal
   Check (not Is_Valid_Packing (P), "internal nest invalid packing");
   Check (not Are_Tangent (P, 1, 2), "internal not external tangent");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (0), "internal no coin edge");

   ------------------------------------------------------------------
   Section ("17. Edge list U < V invariant");
   ------------------------------------------------------------------
   Fill (P, [(0, 0, 5), (10, 0, 5), (5, 12, 8)]);
   Build_Contact_Graph (P, Edges, Count);
   declare
      Ok : Boolean := True;
   begin
      for K in 1 .. Count loop
         if Edges (K).U >= Edges (K).V then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "all edges have U < V");
   end;

   ------------------------------------------------------------------
   Section ("18. Large sparse cloud — no false contacts");
   ------------------------------------------------------------------
   Clear (P);
   for K in 1 .. 30 loop
      Add_Circle (P, (X => K * 20, Y => (K mod 5) * 20, R => 2));
   end loop;
   Check (Circle_Count (P) = Nat (30), "cloud 30");
   Check (Is_Valid_Packing (P), "cloud valid (sparse)");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (0), "sparse cloud zero contacts");

   ------------------------------------------------------------------
   Section ("19. Mixed radii Apollonian-style triple + outer");
   ------------------------------------------------------------------
   --  Reuse exact triangle; add a fourth coin far away (no new edge)
   Fill (P, [(0, 0, 5), (10, 0, 5), (5, 12, 8), (100, 100, 1)]);
   Check (Is_Valid_Packing (P), "triple+isolated valid");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (3), "triple+isolated still 3 edges");

   ------------------------------------------------------------------
   Section ("20. Stress: fill many tangent unit pairs");
   ------------------------------------------------------------------
   Clear (P);
   --  40 disjoint tangent pairs along x
   for K in 0 .. 39 loop
      Add_Circle (P, (X => K * 10, Y => 0, R => 1));
      Add_Circle (P, (X => K * 10 + 2, Y => 0, R => 1));
   end loop;
   Check (Circle_Count (P) = Nat (80), "80 disks");
   Check (Is_Valid_Packing (P), "40 pairs valid");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (40), "40 contact edges");

   ------------------------------------------------------------------
   Section ("21. Geometry helper battery");
   ------------------------------------------------------------------
   Check (Approx (Euclidean_Distance ((-3, 4, 1), (0, 0, 1)), LF (5.0)),
          "distance from origin 5");
   Check (Approx (Euclidean_Distance ((0, 0, 1), (6, 8, 1)), LF (10.0)),
          "6-8-10");
   Check (Are_Externally_Tangent ((0, 0, 6), (10, 0, 4)), "6+4=10");
   Check (not Are_Externally_Tangent ((0, 0, 6), (10, 0, 3)), "6+3≠10");
   Check (Interiors_Overlap ((0, 0, 6), (10, 0, 5)), "6+5>10 overlap");
   Check (not Interiors_Overlap ((0, 0, 6), (10, 0, 4)), "exact touch ok");
   Check (not Interiors_Overlap ((0, 0, 1), (100, 0, 1)), "far ok");
   Check (Approx (Sum_Of_Radii ((0, 0, 100), (0, 0, 23)), LF (123.0)),
          "sum 123");

   ------------------------------------------------------------------
   Section ("22. More Invalid_Argument / API counters");
   ------------------------------------------------------------------
   Clear (P);
   Check (Circle_Count (P) = Nat (0), "recount empty");
   Check (Get_Raises (P, 1), "get on empty");
   Add_Circle (P, (1, 2, 3));
   Check (not Get_Raises (P, 1), "get valid");
   Check (Get_Circle (P, 1).X = Int (1), "x=1");
   Check (Get_Circle (P, 1).Y = Int (2), "y=2");
   Check (Get_Circle (P, 1).R = Int (3), "r=3");
   Check (Add_Raises (P, (0, 0, 0)), "zero radius again");
   Check (Add_Raises (P, (0, 0, -5)), "neg radius again");

   --  Build on N=0 with empty buffer First=1 Last=0 is OK
   Clear (P);
   declare
      Empty_Buf : Edge_List (1 .. 0);
      Cnt       : Natural;
   begin
      Build_Contact_Graph (P, Empty_Buf, Cnt);
      Check (Cnt = Nat (0), "N=0 empty buf ok");
   end;

   --  N=1 empty buf ok
   Add_Circle (P, (0, 0, 1));
   declare
      Empty_Buf : Edge_List (1 .. 0);
      Cnt       : Natural;
   begin
      Build_Contact_Graph (P, Empty_Buf, Cnt);
      Check (Cnt = Nat (0), "N=1 empty buf ok");
   end;

   ------------------------------------------------------------------
   Section ("23. Path of 10 unit coins");
   ------------------------------------------------------------------
   Clear (P);
   for K in 0 .. 9 loop
      Add_Circle (P, (X => K * 2, Y => 0, R => 1));
   end loop;
   Check (Circle_Count (P) = Nat (10), "path10 count");
   Check (Is_Valid_Packing (P), "path10 valid");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (9), "path10 nine edges");
   for K in 1 .. 9 loop
      Check (Are_Tangent (P, Circle_Index (K), Circle_Index (K + 1)),
             "path10 edge" & Integer'Image (K));
   end loop;
   Check (not Are_Tangent (P, 1, 3), "path10 no skip");

   ------------------------------------------------------------------
   Section ("24. 2x3 grid detailed");
   ------------------------------------------------------------------
   Clear (P);
   Add_Equal_Radius_Grid (P, 2, 3, 5);
   Check (Circle_Count (P) = Nat (6), "2x3 count");
   Build_Contact_Graph (P, Edges, Count);
   --  H: 2*2=4; V: 3*1=3; total 7
   Check (Count = Nat (7), "2x3 seven contacts");
   Check (Is_Valid_Packing (P), "2x3 valid");
   C := Get_Circle (P, 2);
   Check (C.X = Int (10) and then C.R = Int (5), "2x3 second center");
   C := Get_Circle (P, 4);
   Check (C.Y = Int (10), "2x3 row2 y");

   ------------------------------------------------------------------
   Section ("25. Synonym Contact_Edges matches Build");
   ------------------------------------------------------------------
   Fill (P, [(0, 0, 5), (10, 0, 5), (5, 12, 8)]);
   declare
      E1, E2 : Edge_List (1 .. Max_Edges);
      C1, C2 : Natural;
      Match  : Boolean := True;
   begin
      Build_Contact_Graph (P, E1, C1);
      Contact_Edges (P, E2, C2);
      Check (C1 = C2, "synonym same count");
      for K in 1 .. C1 loop
         if E1 (K).U /= E2 (K).U or else E1 (K).V /= E2 (K).V then
            Match := False;
         end if;
      end loop;
      Check (Match, "synonym same edges");
   end;

   ------------------------------------------------------------------
   Section ("26. Near-miss distances");
   ------------------------------------------------------------------
   Fill (P, [(0, 0, 1), (2, 1, 1)]);  -- d=sqrt(4+1)=sqrt(5)≈2.236 ≠ 2
   Check (not Are_Tangent (P, 1, 2), "sqrt5 near-miss");
   Check (Is_Valid_Packing (P), "near-miss still valid");
   Build_Contact_Graph (P, Edges, Count);
   Check (Count = Nat (0), "near-miss no edge");

   Fill (P, [(0, 0, 1), (1, 0, 1)]);  -- d=1 < 2 overlap
   Check (not Is_Valid_Packing (P), "d=1 unit overlap");
   Check (Interiors_Overlap ((0, 0, 1), (1, 0, 1)), "helper d=1");

   ------------------------------------------------------------------
   Section ("27. Batch validity / tangent matrix on triangle");
   ------------------------------------------------------------------
   Fill (P, [(0, 0, 5), (10, 0, 5), (5, 12, 8)]);
   Check (Is_Valid_Packing (P), "batch triangle valid");
   for I in 1 .. 3 loop
      for J in 1 .. 3 loop
         if I /= J then
            Check (Are_Tangent (P, Circle_Index (I), Circle_Index (J)),
                   "batch tangent" & Integer'Image (I) & Integer'Image (J));
         end if;
      end loop;
   end loop;

   ------------------------------------------------------------------
   Section ("28. Capacity Max_Circles constant");
   ------------------------------------------------------------------
   Check (Max_Circles = Nat (256), "Max_Circles 256");
   Check (Max_Edges = Nat (256 * 255 / 2), "Max_Edges binom");
   Check (Epsilon > LF (0.0), "Epsilon positive");

   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " PASS," &
             Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
