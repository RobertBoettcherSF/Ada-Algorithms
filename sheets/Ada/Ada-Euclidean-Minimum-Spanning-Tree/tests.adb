--  Standalone test suite for Euclidean_Minimum_Spanning_Tree (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Euclidean_Minimum_Spanning_Tree; use Euclidean_Minimum_Spanning_Tree;

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

   type Local_Points is array (Positive range <>) of Point;

   procedure Fill (S : in out Point_Set; Pts : Local_Points) is
   begin
      Clear (S);
      for P of Pts loop
         Add_Point (S, P);
      end loop;
   end Fill;

   function Method_Raises
     (S : Point_Set; Buf_Last : Natural; Which : Character) return Boolean
   is
      Tree : Edge_List (1 .. Positive'Max (1, Buf_Last));
      C    : Natural;
      L    : Length_Sum;
   begin
      if Buf_Last = 0 then
         declare
            Empty_Buf : Edge_List (1 .. 0);
         begin
            case Which is
               when 'P' => Prim (S, Empty_Buf, C, L);
               when 'K' => Kruskal (S, Empty_Buf, C, L);
               when 'C' => Compute (S, Empty_Buf, C, L);
               when others => EMST (S, Empty_Buf, C, L);
            end case;
         end;
      else
         case Which is
            when 'P' => Prim (S, Tree (1 .. Buf_Last), C, L);
            when 'K' => Kruskal (S, Tree (1 .. Buf_Last), C, L);
            when 'C' => Compute (S, Tree (1 .. Buf_Last), C, L);
            when others => EMST (S, Tree (1 .. Buf_Last), C, L);
         end case;
      end if;
      pragma Unreferenced (C, L);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Method_Raises;

   function Method_Raises_Bad_First
     (S : Point_Set; Which : Character) return Boolean
   is
      Tree : Edge_List (2 .. Max_Points);
      C    : Natural;
      L    : Length_Sum;
   begin
      case Which is
         when 'P' => Prim (S, Tree, C, L);
         when 'K' => Kruskal (S, Tree, C, L);
         when 'C' => Compute (S, Tree, C, L);
         when others => EMST (S, Tree, C, L);
      end case;
      pragma Unreferenced (C, L);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Method_Raises_Bad_First;

   function Add_Raises (S : in out Point_Set; P : Point) return Boolean is
   begin
      Add_Point (S, P);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Get_Raises (S : Point_Set; Index : Point_Index) return Boolean is
      P : Point;
   begin
      P := Get_Point (S, Index);
      pragma Unreferenced (P);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Get_Raises;

   procedure Agree_PK
     (S            : Point_Set;
      Expect_Count : Natural;
      Expect_Len   : Length_Sum;
      Label        : String)
   is
      N          : constant Natural := Point_Count (S);
      Cap        : constant Positive := Positive'Max (1, N);
      TP, TK, TC, TE : Edge_List (1 .. Cap);
      CP, CK, CC, CE : Natural;
      LP, LK, LC, LE : Length_Sum;
   begin
      Prim (S, TP, CP, LP);
      Kruskal (S, TK, CK, LK);
      Compute (S, TC, CC, LC);
      EMST (S, TE, CE, LE);
      Check (CP = Expect_Count, Label & " Prim count");
      Check (CK = Expect_Count, Label & " Kruskal count");
      Check (LP = Expect_Len, Label & " Prim length");
      Check (LK = Expect_Len, Label & " Kruskal length");
      Check (CP = CK and then LP = LK, Label & " Prim=Kruskal");
      Check (CC = CP and then LC = LP, Label & " Compute=Prim");
      Check (CE = CP and then LE = LP, Label & " EMST=Prim");
   end Agree_PK;

   procedure Check_Connected
     (S : Point_Set; Tree : Edge_List; Count : Natural; Label : String)
   is
      N : constant Natural := Point_Count (S);
      Parent : array (0 .. Max_Points) of Natural := [others => 0];
      Rank   : array (0 .. Max_Points) of Natural := [others => 0];

      function Find (X : Natural) return Natural is
         R : Natural := X;
         Y, Next : Natural;
      begin
         while Parent (R) /= R loop
            R := Parent (R);
         end loop;
         Y := X;
         while Parent (Y) /= Y loop
            Next := Parent (Y);
            Parent (Y) := R;
            Y := Next;
         end loop;
         return R;
      end Find;

      procedure Union (A, B : Natural) is
         RA : constant Natural := Find (A);
         RB : constant Natural := Find (B);
      begin
         if RA = RB then
            return;
         end if;
         if Rank (RA) < Rank (RB) then
            Parent (RA) := RB;
         elsif Rank (RA) > Rank (RB) then
            Parent (RB) := RA;
         else
            Parent (RB) := RA;
            Rank (RA) := Rank (RA) + 1;
         end if;
      end Union;

      Root : Natural;
      Ok   : Boolean := True;
      Seen : Natural := 0;
   begin
      for I in 1 .. N loop
         Parent (I) := I;
      end loop;
      for K in 1 .. Count loop
         if Natural (Tree (K).U) > N or else Natural (Tree (K).V) > N then
            Ok := False;
         elsif Tree (K).U = Tree (K).V then
            Ok := False;
         else
            if Find (Natural (Tree (K).U)) = Find (Natural (Tree (K).V)) then
               Ok := False;  -- cycle
            else
               Union (Natural (Tree (K).U), Natural (Tree (K).V));
               Seen := Seen + 1;
            end if;
         end if;
      end loop;
      if N >= 1 then
         Root := Find (1);
         for I in 2 .. N loop
            if Find (I) /= Root then
               Ok := False;
            end if;
         end loop;
      end if;
      Check (Ok and then Count = N - 1 and then Seen = Count,
             Label & " connected acyclic tree");
   end Check_Connected;

   S     : Point_Set;
   Tree  : Edge_List (1 .. Max_Points);
   Count : Natural;
   Len   : Length_Sum;
   P     : Point;

begin
   ------------------------------------------------------------------
   Section ("1. Rounded Euclidean");
   ------------------------------------------------------------------
   Check (Rounded_Euclidean ((0, 0), (0, 0)) = 0, "dist identical");
   Check (Rounded_Euclidean ((0, 0), (3, 0)) = 3, "dist axis-x 3");
   Check (Rounded_Euclidean ((0, 0), (0, 4)) = 4, "dist axis-y 4");
   Check (Rounded_Euclidean ((0, 0), (3, 4)) = 5, "dist 3-4-5");
   Check (Rounded_Euclidean ((1, 1), (4, 5)) = 5, "dist shifted 3-4-5");
   Check (Rounded_Euclidean ((0, 0), (1, 1)) = 1, "dist diag ~1.414 -> 1");
   Check (Rounded_Euclidean ((0, 0), (2, 2)) = 3, "dist diag ~2.828 -> 3");
   Check (Rounded_Euclidean ((0, 0), (5, 12)) = 13, "dist 5-12-13");
   Check (Rounded_Euclidean ((-2, -3), (1, 1)) = 5, "dist negative coords");
   Check (Rounded_Euclidean ((10, 0), (0, 0)) = 10, "dist reverse order");
   Check (Rounded_Euclidean ((0, 0), (1, 0)) =
            Rounded_Euclidean ((1, 0), (0, 0)), "dist symmetric");
   Check (Rounded_Euclidean ((0, 0), (7, 0)) = Length_Type (Int (7)),
          "dist non-static 7");

   ------------------------------------------------------------------
   Section ("2. Clear / Add_Point / Point_Count / Get_Point");
   ------------------------------------------------------------------
   Clear (S);
   Check (Point_Count (S) = Nat (0), "empty count 0");
   Add_Point (S, (1, 2));
   Check (Point_Count (S) = 1, "count after 1 add");
   Check (Get_Point (S, 1) = (1, 2), "get point 1");
   Add_Point (S, (3, 4));
   Check (Point_Count (S) = 2, "count after 2 adds");
   Check (Get_Point (S, 2) = (3, 4), "get point 2");
   Clear (S);
   Check (Point_Count (S) = 0, "clear resets");
   Check (Get_Raises (S, 1), "get on empty raises");
   Fill (S, [(0, 0), (1, 0), (0, 1)]);
   Check (Point_Count (S) = 3, "fill 3");
   Check (Get_Raises (S, 4), "get past end raises");
   Check (not Get_Raises (S, 3), "get last ok");

   ------------------------------------------------------------------
   Section ("3. Too few points / Invalid_Argument");
   ------------------------------------------------------------------
   Clear (S);
   Check (Method_Raises (S, 1, 'P'), "Prim N=0 raises");
   Check (Method_Raises (S, 1, 'K'), "Kruskal N=0 raises");
   Check (Method_Raises (S, 1, 'C'), "Compute N=0 raises");
   Check (Method_Raises (S, 1, 'E'), "EMST N=0 raises");
   Add_Point (S, (0, 0));
   Check (Method_Raises (S, 1, 'P'), "Prim N=1 raises");
   Check (Method_Raises (S, 1, 'K'), "Kruskal N=1 raises");
   Check (Method_Raises (S, 1, 'C'), "Compute N=1 raises");
   Check (Method_Raises (S, 1, 'E'), "EMST N=1 raises");
   Add_Point (S, (1, 0));
   Check (Method_Raises (S, 0, 'P'), "Prim buf 0 raises");
   Check (Method_Raises (S, 0, 'K'), "Kruskal buf 0 raises");
   Check (Method_Raises_Bad_First (S, 'P'), "Prim bad First raises");
   Check (Method_Raises_Bad_First (S, 'K'), "Kruskal bad First raises");
   Check (Method_Raises_Bad_First (S, 'C'), "Compute bad First raises");
   Check (Method_Raises_Bad_First (S, 'E'), "EMST bad First raises");

   ------------------------------------------------------------------
   Section ("4. Two points");
   ------------------------------------------------------------------
   Fill (S, [(0, 0), (5, 0)]);
   Agree_PK (S, 1, 5, "two pts axis");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "two pts");
   Check (Tree (1).Length = 5, "two pts edge length");

   Fill (S, [(0, 0), (3, 4)]);
   Agree_PK (S, 1, 5, "two pts 3-4-5");

   Fill (S, [(2, 2), (2, 2)]);
   Agree_PK (S, 1, 0, "two coincident");

   ------------------------------------------------------------------
   Section ("5. Hand-checked triangle (3-4-5)");
   ------------------------------------------------------------------
   Fill (S, [(0, 0), (3, 0), (0, 4)]);
   Agree_PK (S, 2, 7, "triangle 3-4-5");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "triangle");
   --  Edges must be the two legs (lengths 3 and 4), not hypotenuse 5.
   declare
      Sum_Check : Length_Sum := 0;
      Has_Hyp   : Boolean := False;
   begin
      for I in 1 .. Count loop
         Sum_Check := Sum_Check + Length_Sum (Tree (I).Length);
         if Tree (I).Length = 5 then
            Has_Hyp := True;
         end if;
      end loop;
      Check (Sum_Check = 7, "triangle sum edges 7");
      Check (not Has_Hyp, "triangle excludes hypotenuse");
   end;

   ------------------------------------------------------------------
   Section ("6. Hand-checked unit square");
   ------------------------------------------------------------------
   Fill (S, [(0, 0), (1, 0), (1, 1), (0, 1)]);
   Agree_PK (S, 3, 3, "unit square");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "square");
   for I in 1 .. Count loop
      Check (Tree (I).Length = 1, "square edge unit #" & Integer'Image (I));
   end loop;

   ------------------------------------------------------------------
   Section ("7. Hand-checked collinear line");
   ------------------------------------------------------------------
   Fill (S, [(0, 0), (1, 0), (2, 0), (3, 0)]);
   Agree_PK (S, 3, 3, "collinear 4");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "line");
   for I in 1 .. Count loop
      Check (Tree (I).Length = 1, "line unit edge #" & Integer'Image (I));
   end loop;

   Fill (S, [(0, 0), (2, 0), (5, 0), (9, 0)]);
   --  gaps 2,3,4 => MST total 2+3+4=9
   Agree_PK (S, 3, 9, "collinear uneven");

   ------------------------------------------------------------------
   Section ("8. Stars and paths");
   ------------------------------------------------------------------
   Fill (S, [(0, 0), (1, 0), (0, 1), (-1, 0), (0, -1)]);
   Agree_PK (S, 4, 4, "plus star");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "star");

   Fill (S, [(0, 0), (10, 0), (20, 0), (30, 0), (40, 0)]);
   Agree_PK (S, 4, 40, "path step 10");

   Fill (S, [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]);
   Agree_PK (S, 5, 5, "vertical path");

   ------------------------------------------------------------------
   Section ("9. Grids");
   ------------------------------------------------------------------
   --  2x2 already covered; 2x3 grid of unit spacing
   Fill (S, [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)]);
   Agree_PK (S, 5, 5, "2x3 grid");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "2x3");

   Fill (S, [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1),
             (0, 2), (1, 2), (2, 2)]);
   Agree_PK (S, 8, 8, "3x3 grid");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "3x3");

   ------------------------------------------------------------------
   Section ("10. Regular-ish polygons / cycles");
   ------------------------------------------------------------------
   --  Equilateral-ish integer: (0,0),(4,0),(2,3) — sides 4, ~3.606->4, ~3.606->4
   Fill (S, [(0, 0), (4, 0), (2, 3)]);
   Agree_PK (S, 2, 8, "near-equilateral");

   --  Regular pentagon approximation on circle radius 10
   Fill (S, [(10, 0), (3, 9), (-8, 6), (-8, -6), (3, -9)]);
   Prim (S, Tree, Count, Len);
   Kruskal (S, Tree, Count, Len);
   declare
      TP : Edge_List (1 .. 5);
      TK : Edge_List (1 .. 5);
      CP, CK : Natural;
      LP, LK : Length_Sum;
   begin
      Prim (S, TP, CP, LP);
      Kruskal (S, TK, CK, LK);
      Check (CP = 4 and then CK = 4, "pentagon count 4");
      Check (LP = LK, "pentagon Prim=Kruskal len");
      Check_Connected (S, TP, CP, "pentagon");
   end;

   ------------------------------------------------------------------
   Section ("11. Duplicate / clustered points");
   ------------------------------------------------------------------
   Fill (S, [(0, 0), (0, 0), (5, 0)]);
   Agree_PK (S, 2, 5, "dup + far");
   Fill (S, [(1, 1), (1, 1), (1, 1), (1, 1)]);
   Agree_PK (S, 3, 0, "all coincident");
   Fill (S, [(0, 0), (0, 0), (1, 0), (1, 0)]);
   Agree_PK (S, 3, 1, "two pairs");

   ------------------------------------------------------------------
   Section ("12. Larger clouds + agreement");
   ------------------------------------------------------------------
   Clear (S);
   for I in 0 .. 9 loop
      for J in 0 .. 9 loop
         Add_Point (S, (I * 3, J * 3));
      end loop;
   end loop;
   Check (Point_Count (S) = 100, "10x10 cloud count");
   declare
      TP : Edge_List (1 .. 100);
      TK : Edge_List (1 .. 100);
      CP, CK : Natural;
      LP, LK : Length_Sum;
   begin
      Prim (S, TP, CP, LP);
      Kruskal (S, TK, CK, LK);
      Check (CP = 99 and then CK = 99, "10x10 edge count");
      Check (LP = LK, "10x10 Prim=Kruskal");
      --  Unit spacing 3: MST of 10x10 lattice is 99 edges of length 3
      Check (LP = 297, "10x10 lattice length 297");
      Check_Connected (S, TP, CP, "10x10");
   end;

   --  Random-ish deterministic cloud
   Clear (S);
   declare
      X : Integer := 1;
      Y : Integer := 7;
   begin
      for K in 1 .. 40 loop
         Add_Point (S, (X mod 50, Y mod 50));
         X := (X * 17 + 3) mod 97;
         Y := (Y * 13 + 5) mod 89;
      end loop;
   end;
   declare
      TP : Edge_List (1 .. 40);
      TK : Edge_List (1 .. 40);
      CP, CK : Natural;
      LP, LK : Length_Sum;
   begin
      Prim (S, TP, CP, LP);
      Kruskal (S, TK, CK, LK);
      Check (CP = 39 and then CK = 39, "cloud40 count");
      Check (LP = LK, "cloud40 Prim=Kruskal");
      Check_Connected (S, TP, CP, "cloud40");
   end;

   ------------------------------------------------------------------
   Section ("13. Compute / EMST synonyms");
   ------------------------------------------------------------------
   Fill (S, [(0, 0), (1, 0), (0, 1)]);
   declare
      T1, T2, T3 : Edge_List (1 .. 3);
      C1, C2, C3 : Natural;
      L1, L2, L3 : Length_Sum;
   begin
      Compute (S, T1, C1, L1);
      EMST (S, T2, C2, L2);
      Prim (S, T3, C3, L3);
      Check (C1 = 2 and then C2 = 2 and then C3 = 2, "synonym counts");
      Check (L1 = L2 and then L2 = L3, "synonym lengths");
      Check (L1 = 2, "right angle legs total 2");
   end;

   ------------------------------------------------------------------
   Section ("14. Capacity overflow");
   ------------------------------------------------------------------
   Clear (S);
   for I in 1 .. Max_Points loop
      Add_Point (S, (I, 0));
   end loop;
   Check (Point_Count (S) = Max_Points, "filled to Max_Points");
   Check (Add_Raises (S, (0, 0)), "Add beyond Max raises");
   --  EMST on Max_Points is heavy (O(N^2)); smoke-check small buffer raise
   Check (Method_Raises (S, Max_Points - 2, 'P'),
          "Prim undersized buffer raises");

   ------------------------------------------------------------------
   Section ("15. Edge length consistency");
   ------------------------------------------------------------------
   Fill (S, [(0, 0), (6, 8), (0, 9)]);
   Prim (S, Tree, Count, Len);
   declare
      Sum : Length_Sum := 0;
   begin
      for I in 1 .. Count loop
         declare
            A : constant Point := Get_Point (S, Tree (I).U);
            B : constant Point := Get_Point (S, Tree (I).V);
         begin
            Check (Tree (I).Length = Rounded_Euclidean (A, B),
                   "edge length matches Rounded #" & Integer'Image (I));
            Sum := Sum + Length_Sum (Tree (I).Length);
         end;
      end loop;
      Check (Sum = Len, "sum equals Total_Length");
   end;

   ------------------------------------------------------------------
   Section ("16. Many small hand cases");
   ------------------------------------------------------------------
   Fill (S, [(0, 0), (1, 0)]);
   Agree_PK (S, 1, 1, "seg1");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "seg1");

   Fill (S, [(0, 0), (0, 5)]);
   Agree_PK (S, 1, 5, "seg5");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "seg5");

   Fill (S, [(0, 0), (1, 0), (2, 0)]);
   Agree_PK (S, 2, 2, "line3");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "line3");

   Fill (S, [(0, 0), (1, 0), (2, 0), (3, 0), (4, 0)]);
   Agree_PK (S, 4, 4, "line5");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "line5");

   Fill (S, [(0, 0), (1, 0), (0, 1)]);
   Agree_PK (S, 2, 2, "L-tri");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "L-tri");

   Fill (S, [(0, 0), (2, 0), (0, 2)]);
   Agree_PK (S, 2, 4, "L-wide");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "L-wide");

   Fill (S, [(0, 0), (1, 0), (1, 1), (0, 1), (2, 0)]);
   Agree_PK (S, 4, 4, "square+");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "square+");

   Fill (S, [(0, 0), (10, 0), (0, 10)]);
   Agree_PK (S, 2, 20, "big L");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "big L");

   Fill (S, [(5, 5), (5, 6), (6, 5), (6, 6)]);
   Agree_PK (S, 3, 3, "unit sq shift");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "unit sq shift");

   Fill (S, [(0, 0), (0, 0), (0, 1)]);
   Agree_PK (S, 2, 1, "dup+up");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "dup+up");

   Fill (S, [(-1, -1), (1, 1)]);
   Agree_PK (S, 1, 3, "diag -1..1");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "diag -1..1");

   Fill (S, [(0, 0), (8, 0), (0, 15)]);
   Agree_PK (S, 2, 23, "8-15-17 legs");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "8-15-17 legs");

   Fill (S, [(0, 0), (1, 0), (2, 1), (3, 0), (4, 0)]);
   declare
      TP : Edge_List (1 .. 16);
      TK : Edge_List (1 .. 16);
      CP, CK : Natural;
      LP, LK : Length_Sum;
   begin
      Prim (S, TP, CP, LP);
      Kruskal (S, TK, CK, LK);
      Check (CP = 4 and then CK = 4, "zigzag count");
      Check (LP = LK, "zigzag Prim=Kruskal");
      Check_Connected (S, TP, CP, "zigzag");
   end;

   Fill (S, [(0, 0), (3, 4), (6, 0)]);
   Agree_PK (S, 2, 10, "two 3-4-5");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "two 3-4-5");

   Fill (S, [(0, 0), (1, 0), (2, 0), (1, 1)]);
   Agree_PK (S, 3, 3, "tee");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "tee");

   Fill (S, [(0, 0), (2, 0), (4, 0), (1, 1), (3, 1)]);
   declare
      TP : Edge_List (1 .. 16);
      TK : Edge_List (1 .. 16);
      CP, CK : Natural;
      LP, LK : Length_Sum;
   begin
      Prim (S, TP, CP, LP);
      Kruskal (S, TK, CK, LK);
      Check (CP = 4 and then CK = 4, "house count");
      Check (LP = LK, "house Prim=Kruskal");
      Check_Connected (S, TP, CP, "house");
   end;

   Fill (S, [(0, 0), (0, 2), (2, 0), (2, 2), (1, 1)]);
   declare
      TP : Edge_List (1 .. 16);
      TK : Edge_List (1 .. 16);
      CP, CK : Natural;
      LP, LK : Length_Sum;
   begin
      Prim (S, TP, CP, LP);
      Kruskal (S, TK, CK, LK);
      Check (CP = 4 and then CK = 4, "diamond+c count");
      Check (LP = LK, "diamond+c Prim=Kruskal");
      Check_Connected (S, TP, CP, "diamond+c");
   end;

   Fill (S, [(0, 0), (5, 0), (5, 5), (0, 5)]);
   Agree_PK (S, 3, 15, "5-square");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "5-square");

   Fill (S, [(1, 2), (3, 4), (5, 6), (7, 8)]);
   declare
      TP : Edge_List (1 .. 16);
      TK : Edge_List (1 .. 16);
      CP, CK : Natural;
      LP, LK : Length_Sum;
   begin
      Prim (S, TP, CP, LP);
      Kruskal (S, TK, CK, LK);
      Check (CP = 3 and then CK = 3, "diag chain count");
      Check (LP = LK, "diag chain Prim=Kruskal");
      Check_Connected (S, TP, CP, "diag chain");
   end;

   Fill (S, [(0, 0), (0, 1), (1, 0), (1, 1), (2, 0), (2, 1)]);
   Agree_PK (S, 5, 5, "2x3 again");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "2x3 again");

   ------------------------------------------------------------------
   Section ("17. Negative and mixed coordinates");
   ------------------------------------------------------------------
   Fill (S, [(-5, -5), (-5, 5), (5, -5), (5, 5)]);
   Agree_PK (S, 3, 30, "signed square side 10");
   Prim (S, Tree, Count, Len);
   Check_Connected (S, Tree, Count, "signed sq");

   Fill (S, [(-3, 0), (0, 0), (4, 0)]);
   Agree_PK (S, 2, 7, "signed line");

   ------------------------------------------------------------------
   Section ("18. Buffer exact sizing");
   ------------------------------------------------------------------
   Fill (S, [(0, 0), (1, 0), (2, 0), (3, 0)]);
   declare
      Exact : Edge_List (1 .. 3);
      C : Natural;
      L : Length_Sum;
   begin
      Prim (S, Exact, C, L);
      Check (C = 3 and then L = 3, "exact buffer Prim");
      Kruskal (S, Exact, C, L);
      Check (C = 3 and then L = 3, "exact buffer Kruskal");
   end;
   Check (Method_Raises (S, 2, 'P'), "buf N-2 Prim raises");
   Check (Method_Raises (S, 2, 'K'), "buf N-2 Kruskal raises");

   ------------------------------------------------------------------
   Section ("19. Rebuild after Clear");
   ------------------------------------------------------------------
   Fill (S, [(0, 0), (1, 0)]);
   Prim (S, Tree, Count, Len);
   Check (Count = 1 and then Len = 1, "first build");
   Clear (S);
   Check (Point_Count (S) = 0, "cleared");
   Fill (S, [(0, 0), (3, 0), (0, 4)]);
   Agree_PK (S, 2, 7, "rebuild triangle");

   ------------------------------------------------------------------
   Section ("20. Extra distance / API micro-checks");
   ------------------------------------------------------------------
   Check (Rounded_Euclidean ((0, 0), (9, 12)) = 15, "9-12-15");
   Check (Rounded_Euclidean ((0, 0), (8, 15)) = 17, "8-15-17");
   Check (Rounded_Euclidean ((0, 0), (7, 24)) = 25, "7-24-25");
   Check (Rounded_Euclidean ((0, 0), (20, 21)) = 29, "20-21-29");
   Check (Rounded_Euclidean ((100, 100), (103, 104)) = 5, "offset 3-4-5");
   Clear (S);
   Add_Point (S, (0, 0));
   Add_Point (S, (0, 0));
   Check (Point_Count (S) = Nat (2), "dup count");
   P := Get_Point (S, 1);
   Check (P.X = 0 and then P.Y = 0, "get after dup");

   --  More agreement micro-sets
   Fill (S, [(0, 0), (1, 0), (0, 1)]);
   Agree_PK (S, 2, Length_Sum (1 + 1), "L-arm 1");
   Fill (S, [(0, 0), (2, 0), (0, 2)]);
   Agree_PK (S, 2, Length_Sum (2 + 2), "L-arm 2");
   Fill (S, [(0, 0), (3, 0), (0, 3)]);
   Agree_PK (S, 2, Length_Sum (3 + 3), "L-arm 3");
   Fill (S, [(0, 0), (4, 0), (0, 4)]);
   Agree_PK (S, 2, Length_Sum (4 + 4), "L-arm 4");
   Fill (S, [(0, 0), (5, 0), (0, 5)]);
   Agree_PK (S, 2, Length_Sum (5 + 5), "L-arm 5");
   Fill (S, [(0, 0), (6, 0), (0, 6)]);
   Agree_PK (S, 2, Length_Sum (6 + 6), "L-arm 6");
   Fill (S, [(0, 0), (7, 0), (0, 7)]);
   Agree_PK (S, 2, Length_Sum (7 + 7), "L-arm 7");
   Fill (S, [(0, 0), (8, 0), (0, 8)]);
   Agree_PK (S, 2, Length_Sum (8 + 8), "L-arm 8");
   Fill (S, [(0, 0), (9, 0), (0, 9)]);
   Agree_PK (S, 2, Length_Sum (9 + 9), "L-arm 9");
   Fill (S, [(0, 0), (10, 0), (0, 10)]);
   Agree_PK (S, 2, Length_Sum (10 + 10), "L-arm 10");
   Fill (S, [(0, 0), (11, 0), (0, 11)]);
   Agree_PK (S, 2, Length_Sum (11 + 11), "L-arm 11");
   Fill (S, [(0, 0), (12, 0), (0, 12)]);
   Agree_PK (S, 2, Length_Sum (12 + 12), "L-arm 12");
   Fill (S, [(0, 0), (13, 0), (0, 13)]);
   Agree_PK (S, 2, Length_Sum (13 + 13), "L-arm 13");
   Fill (S, [(0, 0), (14, 0), (0, 14)]);
   Agree_PK (S, 2, Length_Sum (14 + 14), "L-arm 14");
   Fill (S, [(0, 0), (15, 0), (0, 15)]);
   Agree_PK (S, 2, Length_Sum (15 + 15), "L-arm 15");
   Fill (S, [(0, 0), (16, 0), (0, 16)]);
   Agree_PK (S, 2, Length_Sum (16 + 16), "L-arm 16");
   Fill (S, [(0, 0), (17, 0), (0, 17)]);
   Agree_PK (S, 2, Length_Sum (17 + 17), "L-arm 17");
   Fill (S, [(0, 0), (18, 0), (0, 18)]);
   Agree_PK (S, 2, Length_Sum (18 + 18), "L-arm 18");
   Fill (S, [(0, 0), (19, 0), (0, 19)]);
   Agree_PK (S, 2, Length_Sum (19 + 19), "L-arm 19");
   Fill (S, [(0, 0), (20, 0), (0, 20)]);
   Agree_PK (S, 2, Length_Sum (20 + 20), "L-arm 20");

   Fill (S, [(0, 0), (1, 2), (3, 1), (4, 4), (2, 3)]);
   declare
      TP : Edge_List (1 .. 5);
      TK : Edge_List (1 .. 5);
      CP, CK : Natural;
      LP, LK : Length_Sum;
   begin
      Prim (S, TP, CP, LP);
      Kruskal (S, TK, CK, LK);
      Check (CP = 4 and then CK = 4, "micro5 count");
      Check (LP = LK, "micro5 agree");
      Check_Connected (S, TP, CP, "micro5");
   end;

   Fill (S, [(0, 0), (2, 0), (4, 0), (6, 0), (1, 2), (3, 2), (5, 2)]);
   declare
      TP : Edge_List (1 .. 7);
      TK : Edge_List (1 .. 7);
      CP, CK : Natural;
      LP, LK : Length_Sum;
   begin
      Prim (S, TP, CP, LP);
      Kruskal (S, TK, CK, LK);
      Check (CP = 6 and then CK = 6, "two-row count");
      Check (LP = LK, "two-row agree");
      Check_Connected (S, TP, CP, "two-row");
   end;

   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " PASS," &
             Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
