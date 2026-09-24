--  Standalone test suite for Laplacian_Smoothing (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Laplacian_Smoothing; use Laplacian_Smoothing;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwc constant-condition warnings).
   function R (X : Real) return Real is (X);
   function Pos (X : Positive) return Positive is (X);
   function P (X, Y : Real) return Point is ((X => X, Y => Y));
   function V (X : Vertex_Index) return Vertex_Index is (X);

   function Raised_Invalid_Smooth_Once
     (Vertices : Point_Array;
      Adj      : Adjacency_Array;
      Lambda   : Real) return Boolean
   is
      Out_V : Point_Array (Vertices'Range);
   begin
      Out_V := Smooth_Once (Vertices, Adj, Lambda);
      pragma Unreferenced (Out_V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Smooth_Once;

   function Raised_Invalid_Smooth
     (Vertices   : Point_Array;
      Adj        : Adjacency_Array;
      Lambda     : Real;
      Iterations : Positive) return Boolean
   is
      Out_V : Point_Array (Vertices'Range);
   begin
      Out_V := Smooth (Vertices, Adj, Lambda, Iterations);
      pragma Unreferenced (Out_V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Smooth;

   function Raised_Invalid_Build
     (N : Vertex_Count; Edges : Edge_Array) return Boolean
   is
      A : Adjacency_Array (1 .. (if N = 0 then 1 else N));
   begin
      A := Build_Adjacency (N, Edges);
      pragma Unreferenced (A);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Build;

   function Raised_Invalid_Avg
     (Vertices : Point_Array; Adj : Adjacency) return Boolean
   is
      Q : Point;
   begin
      Q := Neighbor_Average (Vertices, Adj);
      pragma Unreferenced (Q);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Avg;

   function Raised_Invalid_MEL
     (Vertices : Point_Array; Adj : Adjacency_Array) return Boolean
   is
      L : Real;
   begin
      L := Mean_Edge_Length (Vertices, Adj);
      pragma Unreferenced (L);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_MEL;

begin
   Ada.Text_IO.Put_Line ("Laplacian_Smoothing — Ada 2023 test suite");
   Ada.Text_IO.Put_Line ("Max_Vertices =" & Positive'Image (Max_Vertices)
     & "  Max_Degree =" & Positive'Image (Max_Degree)
     & "  Max_Iters =" & Positive'Image (Max_Iters));

   ------------------------------------------------------------------
   Section ("1. Near / Near_Point / Dist / Lerp");
   ------------------------------------------------------------------
   Check (Near (R (1.0), R (1.0)), "Near equal");
   Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near within eps");
   Check (not Near (R (0.0), R (1.0)), "not Near 0,1");
   Check (Near_Point (P (0.0, 0.0), P (0.0, 0.0)), "Near_Point identical");
   Check (not Near_Point (P (0.0, 0.0), P (1.0, 0.0)), "not Near_Point");
   Check (Near (Dist2 (P (0.0, 0.0), P (3.0, 4.0)), R (25.0)), "Dist2 3-4-5");
   Check (Near (Dist (P (0.0, 0.0), P (3.0, 4.0)), R (5.0)), "Dist 3-4-5");
   Check (Near (Dist2 (P (1.0, 1.0), P (1.0, 1.0)), R (0.0)), "Dist2 zero");
   declare
      M : constant Point := Lerp (P (0.0, 0.0), P (10.0, 0.0), R (0.3));
   begin
      Check (Near_Point (M, P (3.0, 0.0)), "Lerp 0.3 along X");
   end;
   Check (Near_Point (Lerp (P (1.0, 2.0), P (5.0, 6.0), R (0.0)),
                      P (1.0, 2.0)), "Lerp T=0");
   Check (Near_Point (Lerp (P (1.0, 2.0), P (5.0, 6.0), R (1.0)),
                      P (5.0, 6.0)), "Lerp T=1");

   ------------------------------------------------------------------
   Section ("2. Empty_Adjacency / Add_Neighbor / Has_Neighbor");
   ------------------------------------------------------------------
   declare
      A : Adjacency := Empty_Adjacency;
   begin
      Check (A.Count = 0, "Empty_Adjacency Count=0");
      Check (not Has_Neighbor (A, V (1)), "no neighbour initially");
      Add_Neighbor (A, V (2));
      Check (A.Count = 1, "Count=1 after add");
      Check (Has_Neighbor (A, V (2)), "Has_Neighbor 2");
      Check (A.Neighbors (1) = 2, "Neighbors(1)=2");
      Add_Neighbor (A, V (2));
      Check (A.Count = 1, "duplicate add ignored");
      Add_Neighbor (A, V (3));
      Check (A.Count = 2, "Count=2 after second");
      Check (Has_Neighbor (A, V (3)), "Has_Neighbor 3");
   end;

   ------------------------------------------------------------------
   Section ("3. Build_Adjacency: polyline chain");
   ------------------------------------------------------------------
   declare
      --  1—2—3—4
      Edges : constant Edge_Array :=
        [(A => 1, B => 2), (A => 2, B => 3), (A => 3, B => 4)];
      Adj   : constant Adjacency_Array := Build_Adjacency (4, Edges);
   begin
      Check (Adj'Length = 4, "chain Adj length 4");
      Check (Adj (1).Count = 1 and then Adj (1).Neighbors (1) = 2,
             "v1 -> 2");
      Check (Adj (2).Count = 2, "v2 degree 2");
      Check (Has_Neighbor (Adj (2), V (1))
             and then Has_Neighbor (Adj (2), V (3)), "v2 -> 1,3");
      Check (Adj (4).Count = 1 and then Adj (4).Neighbors (1) = 3,
             "v4 -> 3");
   end;

   ------------------------------------------------------------------
   Section ("4. Build_Adjacency: triangle + duplicate edge");
   ------------------------------------------------------------------
   declare
      Edges : constant Edge_Array :=
        [(A => 1, B => 2), (A => 2, B => 3), (A => 3, B => 1),
         (A => 1, B => 2)];  -- duplicate
      Adj   : constant Adjacency_Array := Build_Adjacency (3, Edges);
   begin
      Check (Adj (1).Count = 2, "triangle v1 deg 2 (dup ignored)");
      Check (Adj (2).Count = 2, "triangle v2 deg 2");
      Check (Adj (3).Count = 2, "triangle v3 deg 2");
   end;

   ------------------------------------------------------------------
   Section ("5. Neighbor_Average");
   ------------------------------------------------------------------
   declare
      Verts : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (0.0, 2.0)];
      Adj   : Adjacency := Empty_Adjacency;
      Avg   : Point;
   begin
      Add_Neighbor (Adj, V (2));
      Add_Neighbor (Adj, V (3));
      Avg := Neighbor_Average (Verts, Adj);
      Check (Near_Point (Avg, P (1.0, 1.0)), "avg of (2,0) and (0,2)");
      Check (Raised_Invalid_Avg (Verts, Empty_Adjacency),
             "avg empty adj raises");
   end;

   ------------------------------------------------------------------
   Section ("6. Smooth_Once: two-point segment λ=1");
   ------------------------------------------------------------------
   declare
      Verts : constant Point_Array := [P (0.0, 0.0), P (10.0, 0.0)];
      Adj   : constant Adjacency_Array :=
        Build_Adjacency (2, [(A => 1, B => 2)]);
      Out_V : constant Point_Array :=
        Smooth_Once (Verts, Adj, R (1.0));
   begin
      --  Each becomes the other (λ=1).
      Check (Near_Point (Out_V (1), P (10.0, 0.0)), "v1 -> neighbour");
      Check (Near_Point (Out_V (2), P (0.0, 0.0)), "v2 -> neighbour");
   end;

   ------------------------------------------------------------------
   Section ("7. Smooth_Once: polyline mid moves toward neighbours");
   ------------------------------------------------------------------
   declare
      --  Chain: (0,0)—(0,10)—(10,0); mid should move toward avg of ends.
      Verts : constant Point_Array :=
        [P (0.0, 0.0), P (0.0, 10.0), P (10.0, 0.0)];
      Adj   : constant Adjacency_Array :=
        Build_Adjacency
          (3, [(A => 1, B => 2), (A => 2, B => 3)]);
      Out_V : constant Point_Array :=
        Smooth_Once (Verts, Adj, R (0.5));
      --  Mid avg = ((0,0)+(10,0))/2 = (5,0); λ=0.5 → (2.5, 5)
      Expected_Mid : constant Point := P (2.5, 5.0);
   begin
      Check (Near_Point (Out_V (2), Expected_Mid),
             "mid → (1-λ)p + λ avg");
      --  Ends move toward mid (degree 1).
      Check (Near_Point (Out_V (1), Lerp (Verts (1), Verts (2), R (0.5))),
             "end1 toward mid");
      Check (Near_Point (Out_V (3), Lerp (Verts (3), Verts (2), R (0.5))),
             "end3 toward mid");
      Check (Dist (Out_V (2), Expected_Mid) < Dist (Verts (2), Expected_Mid)
               or else Near_Point (Out_V (2), Expected_Mid),
             "mid not farther from target");
   end;

   ------------------------------------------------------------------
   Section ("8. Boundary pinned vs free (polyline)");
   ------------------------------------------------------------------
   declare
      Verts : constant Point_Array :=
        [P (0.0, 0.0), P (0.0, 10.0), P (10.0, 0.0)];
      Adj   : constant Adjacency_Array :=
        Build_Adjacency
          (3, [(A => 1, B => 2), (A => 2, B => 3)]);
      Fixed : constant Fixed_Flags (1 .. 3) := [True, False, True];
      Out_V : constant Point_Array :=
        Smooth_Once (Verts, Adj, R (1.0), Fixed);
   begin
      Check (Near_Point (Out_V (1), Verts (1)), "pinned end1 unchanged");
      Check (Near_Point (Out_V (3), Verts (3)), "pinned end3 unchanged");
      Check (Near_Point (Out_V (2), P (5.0, 0.0)),
             "free mid → exact neighbour avg (λ=1)");
   end;

   declare
      Verts : constant Point_Array :=
        [P (0.0, 0.0), P (0.0, 10.0), P (10.0, 0.0)];
      Adj   : constant Adjacency_Array :=
        Build_Adjacency
          (3, [(A => 1, B => 2), (A => 2, B => 3)]);
      Free  : constant Point_Array :=
        Smooth_Once (Verts, Adj, R (1.0));
   begin
      Check (not Near_Point (Free (1), Verts (1)),
             "unpinned end1 moves");
      Check (not Near_Point (Free (3), Verts (3)),
             "unpinned end3 moves");
   end;

   ------------------------------------------------------------------
   Section ("9. Smooth: multiple iterations shrink zig-zag");
   ------------------------------------------------------------------
   declare
      Verts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 5.0), P (2.0, 0.0), P (3.0, 5.0),
         P (4.0, 0.0)];
      Edges : constant Edge_Array :=
        [(A => 1, B => 2), (A => 2, B => 3), (A => 3, B => 4),
         (A => 4, B => 5)];
      Adj   : constant Adjacency_Array := Build_Adjacency (5, Edges);
      Fixed : constant Fixed_Flags (1 .. 5) :=
        [True, False, False, False, True];
      Out_V : constant Point_Array :=
        Smooth (Verts, Adj, R (0.5), Pos (20), Fixed);
      Amp0  : constant Real :=
        abs (Verts (2).Y) + abs (Verts (3).Y) + abs (Verts (4).Y);
      Amp1  : constant Real :=
        abs (Out_V (2).Y) + abs (Out_V (3).Y) + abs (Out_V (4).Y);
   begin
      Check (Near_Point (Out_V (1), Verts (1)), "iter: end1 pinned");
      Check (Near_Point (Out_V (5), Verts (5)), "iter: end5 pinned");
      Check (Amp1 < Amp0, "zig-zag amplitude decreases");
      Check (abs (Out_V (2).Y) < abs (Verts (2).Y), "v2 |Y| shrinks");
      Check (abs (Out_V (4).Y) < abs (Verts (4).Y), "v4 |Y| shrinks");
   end;

   ------------------------------------------------------------------
   Section ("10. Small 2×2 grid (4 verts, 4 edges cycle)");
   ------------------------------------------------------------------
   declare
      --  Square with one interior diagonal bump: actually 2x2 corner grid
      --  (0,0) (1,0) (0,1) (1,1) — cycle + no diagonals
      Verts : Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      --  Perturb one "interior-ish" by moving nothing; perturb v2 up
      Edges : constant Edge_Array :=
        [(A => 1, B => 2), (A => 2, B => 3), (A => 3, B => 4),
         (A => 4, B => 1)];
      Adj   : constant Adjacency_Array := Build_Adjacency (4, Edges);
      Fixed : constant Fixed_Flags (1 .. 4) := [True, False, True, True];
      Out_V : Point_Array (1 .. 4);
   begin
      Verts (2) := P (1.0, 0.5);  -- bump
      Out_V := Smooth_Once (Verts, Adj, R (0.5), Fixed);
      Check (Near_Point (Out_V (1), Verts (1)), "grid pinned v1");
      Check (Near_Point (Out_V (3), Verts (3)), "grid pinned v3");
      Check (Near_Point (Out_V (4), Verts (4)), "grid pinned v4");
      --  Free v2 neighbours are v1 and v3; avg = ((0,0)+(1,1))/2 = (0.5,0.5)
      --  λ=0.5: (1,0.5) → 0.5*(1,0.5)+0.5*(0.5,0.5) = (0.75, 0.5)
      Check (Near_Point (Out_V (2), P (0.75, 0.5)),
             "bumped v2 moves toward neighbour avg");
   end;

   ------------------------------------------------------------------
   Section ("11. 3×3 grid: centre moves, boundary pinned");
   ------------------------------------------------------------------
   declare
      --  Indices: 1 2 3
      --           4 5 6
      --           7 8 9
      Verts : Point_Array (1 .. 9);
      Edges : Edge_Array (1 .. 12);
      Adj   : Adjacency_Array (1 .. 9);
      Fixed : Fixed_Flags (1 .. 9);
      Out_V : Point_Array (1 .. 9);
      E     : Positive := 1;
      procedure Add_E (A, B : Vertex_Index) is
      begin
         Edges (E) := (A => A, B => B);
         E := E + 1;
      end Add_E;
   begin
      for Row in 0 .. 2 loop
         for Col in 0 .. 2 loop
            Verts (Vertex_Index (Row * 3 + Col + 1)) :=
              P (Real (Col), Real (Row));
         end loop;
      end loop;
      --  Horizontal edges
      Add_E (1, 2); Add_E (2, 3);
      Add_E (4, 5); Add_E (5, 6);
      Add_E (7, 8); Add_E (8, 9);
      --  Vertical edges
      Add_E (1, 4); Add_E (4, 7);
      Add_E (2, 5); Add_E (5, 8);
      Add_E (3, 6); Add_E (6, 9);
      Check (E = 13, "12 edges recorded (E=13)");
      Adj := Build_Adjacency (9, Edges);
      Check (Adj (5).Count = 4, "centre degree 4");
      Check (Adj (1).Count = 2, "corner degree 2");
      Check (Adj (2).Count = 3, "edge-mid degree 3");

      for I in Fixed'Range loop
         Fixed (I) := I /= 5;  -- only centre free
      end loop;
      --  Bump centre
      Verts (5) := P (1.0, 1.0 + 2.0);
      Out_V := Smooth_Once (Verts, Adj, R (1.0), Fixed);
      Check (Near_Point (Out_V (5), P (1.0, 1.0)),
             "centre λ=1 → avg of cross neighbours");
      for I in Fixed'Range loop
         if I /= 5 then
            Check (Near_Point (Out_V (I), Verts (I)),
                   "boundary " & Vertex_Index'Image (I) & " pinned");
         end if;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("12. Jacobi: simultaneous update (not Gauss–Seidel)");
   ------------------------------------------------------------------
   declare
      --  Three collinear: 0 — 10 — 20; free all; λ=1
      --  After one Jacobi step each becomes neighbour avg:
      --  v1→10, v2→(0+20)/2=10, v3→10
      Verts : constant Point_Array :=
        [P (0.0, 0.0), P (10.0, 0.0), P (20.0, 0.0)];
      Adj   : constant Adjacency_Array :=
        Build_Adjacency
          (3, [(A => 1, B => 2), (A => 2, B => 3)]);
      Out_V : constant Point_Array :=
        Smooth_Once (Verts, Adj, R (1.0));
   begin
      Check (Near_Point (Out_V (1), P (10.0, 0.0)), "Jacobi v1");
      Check (Near_Point (Out_V (2), P (10.0, 0.0)), "Jacobi v2");
      Check (Near_Point (Out_V (3), P (10.0, 0.0)), "Jacobi v3");
   end;

   ------------------------------------------------------------------
   Section ("13. Isolated vertex unchanged");
   ------------------------------------------------------------------
   declare
      Verts : constant Point_Array :=
        [P (1.0, 2.0), P (3.0, 4.0)];
      Adj   : constant Adjacency_Array (1 .. 2) :=
        [Empty_Adjacency, Empty_Adjacency];
      Out_V : constant Point_Array :=
        Smooth_Once (Verts, Adj, R (0.5));
   begin
      Check (Near_Point (Out_V (1), Verts (1)), "isolated v1");
      Check (Near_Point (Out_V (2), Verts (2)), "isolated v2");
   end;

   ------------------------------------------------------------------
   Section ("14. λ=1 vs λ small");
   ------------------------------------------------------------------
   declare
      Verts : constant Point_Array :=
        [P (0.0, 0.0), P (0.0, 10.0), P (10.0, 0.0)];
      Adj   : constant Adjacency_Array :=
        Build_Adjacency
          (3, [(A => 1, B => 2), (A => 2, B => 3)]);
      Fixed : constant Fixed_Flags (1 .. 3) := [True, False, True];
      Full  : constant Point_Array :=
        Smooth_Once (Verts, Adj, R (1.0), Fixed);
      Tiny  : constant Point_Array :=
        Smooth_Once (Verts, Adj, R (0.1), Fixed);
   begin
      Check (Near_Point (Full (2), P (5.0, 0.0)), "λ=1 full step");
      Check (Near_Point (Tiny (2),
                         Lerp (Verts (2), P (5.0, 0.0), R (0.1))),
             "λ=0.1 partial step");
      Check (Dist (Tiny (2), Verts (2)) < Dist (Full (2), Verts (2)),
             "smaller λ → smaller displacement");
   end;

   ------------------------------------------------------------------
   Section ("15. Mean_Edge_Length");
   ------------------------------------------------------------------
   declare
      Verts : constant Point_Array :=
        [P (0.0, 0.0), P (3.0, 0.0), P (3.0, 4.0)];
      Adj   : constant Adjacency_Array :=
        Build_Adjacency
          (3, [(A => 1, B => 2), (A => 2, B => 3)]);
      --  edges length 3 and 4 → mean 3.5
      L : constant Real := Mean_Edge_Length (Verts, Adj);
   begin
      Check (Near (L, R (3.5)), "mean edge 3.5");
   end;

   ------------------------------------------------------------------
   Section ("16. Invalid_Argument: lambda / empty / mismatch");
   ------------------------------------------------------------------
   declare
      Verts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0)];
      Adj   : constant Adjacency_Array :=
        Build_Adjacency (2, [(A => 1, B => 2)]);
   begin
      Check (Raised_Invalid_Smooth_Once (Verts, Adj, R (0.0)),
             "λ=0 raises");
      Check (Raised_Invalid_Smooth_Once (Verts, Adj, R (-0.5)),
             "λ<0 raises");
      Check (Raised_Invalid_Smooth_Once (Verts, Adj, R (1.5)),
             "λ>1 raises");
      Check (not Raised_Invalid_Smooth_Once (Verts, Adj, R (1.0)),
             "λ=1 ok");
      Check (not Raised_Invalid_Smooth_Once (Verts, Adj, R (0.01)),
             "λ small positive ok");
   end;

   declare
      Empty_V : Point_Array (1 .. 0);
      Empty_A : Adjacency_Array (1 .. 0);
   begin
      Check (Raised_Invalid_Smooth_Once (Empty_V, Empty_A, R (0.5)),
             "empty mesh raises");
   end;

   declare
      Verts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0)];
      Adj   : constant Adjacency_Array :=
        Build_Adjacency (2, [(A => 1, B => 2)]);
   begin
      Check (Raised_Invalid_Smooth (Verts, Adj, R (0.5), Pos (Max_Iters + 1)),
             "Iterations > Max_Iters raises");
      Check (not Raised_Invalid_Smooth (Verts, Adj, R (0.5), Pos (1)),
             "Iterations=1 ok");
   end;

   Check (Raised_Invalid_Build (0, [(A => 1, B => 2)]),
          "Build Num_Vertices=0 raises");
   Check (Raised_Invalid_Build (2, [(A => 1, B => 1)]),
          "self-loop raises");
   Check (Raised_Invalid_Build (2, [(A => 1, B => 3)]),
          "endpoint out of range raises");

   ------------------------------------------------------------------
   Section ("17. All_Free / Fixed length match");
   ------------------------------------------------------------------
   declare
      F : constant Fixed_Flags := All_Free (1, 4);
   begin
      Check (F'Length = 4, "All_Free length");
      Check (not F (1) and then not F (4), "All_Free all False");
   end;

   declare
      Verts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0)];
      Adj   : constant Adjacency_Array :=
        Build_Adjacency
          (3, [(A => 1, B => 2), (A => 2, B => 3)]);
      Bad_F : constant Fixed_Flags (1 .. 2) := [False, False];
      Ok    : Boolean := False;
      Tmp   : Point_Array (1 .. 3);
      pragma Unreferenced (Tmp);
   begin
      begin
         Tmp := Smooth_Once (Verts, Adj, R (0.5), Bad_F);
         Ok := False;
      exception
         when Invalid_Argument =>
            Ok := True;
         when others =>
            Ok := False;
      end;
      Check (Ok, "Fixed length mismatch raises");
   end;

   ------------------------------------------------------------------
   Section ("18. Smooth idempotent at Tutte-like equilibrium");
   ------------------------------------------------------------------
   declare
      --  Ends fixed at 0 and 10; mid already at average → stays.
      Verts : constant Point_Array :=
        [P (0.0, 0.0), P (5.0, 0.0), P (10.0, 0.0)];
      Adj   : constant Adjacency_Array :=
        Build_Adjacency
          (3, [(A => 1, B => 2), (A => 2, B => 3)]);
      Fixed : constant Fixed_Flags (1 .. 3) := [True, False, True];
      Out_V : constant Point_Array :=
        Smooth (Verts, Adj, R (0.5), Pos (10), Fixed);
   begin
      Check (Near_Point (Out_V (2), Verts (2)),
             "already-averaged mid stays");
      Check (Near_Point (Out_V (1), Verts (1)), "end1 stays");
      Check (Near_Point (Out_V (3), Verts (3)), "end3 stays");
   end;

   ------------------------------------------------------------------
   Section ("19. Repeated Smooth_Once equals Smooth");
   ------------------------------------------------------------------
   declare
      Verts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 4.0), P (2.0, 0.0)];
      Adj   : constant Adjacency_Array :=
        Build_Adjacency
          (3, [(A => 1, B => 2), (A => 2, B => 3)]);
      Fixed : constant Fixed_Flags (1 .. 3) := [True, False, True];
      A, B  : Point_Array (1 .. 3);
   begin
      A := Verts;
      for K in 1 .. 7 loop
         A := Smooth_Once (A, Adj, R (0.4), Fixed);
      end loop;
      B := Smooth (Verts, Adj, R (0.4), Pos (7), Fixed);
      Check (Near_Point (A (2), B (2)), "7×Once ≡ Smooth(7)");
      Check (Near_Point (A (1), B (1)), "ends match Once/Smooth");
   end;

   ------------------------------------------------------------------
   Section ("20. Capacity constants / Mean_Edge no edges");
   ------------------------------------------------------------------
   declare
      MV : constant Positive := Max_Vertices;
      MD : constant Positive := Max_Degree;
      MI : constant Positive := Max_Iters;
   begin
      Check (MV = Pos (64), "Max_Vertices=64");
      Check (MD = Pos (16), "Max_Degree=16");
      Check (MI = Pos (64), "Max_Iters=64");
   end;
   declare
      Verts : constant Point_Array := [P (0.0, 0.0), P (1.0, 0.0)];
      Adj   : constant Adjacency_Array (1 .. 2) :=
        [Empty_Adjacency, Empty_Adjacency];
   begin
      Check (Raised_Invalid_MEL (Verts, Adj), "MEL no edges raises");
   end;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("=================================");
   Ada.Text_IO.Put_Line
     ("Result:" & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   Ada.Text_IO.Put_Line ("=================================");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
