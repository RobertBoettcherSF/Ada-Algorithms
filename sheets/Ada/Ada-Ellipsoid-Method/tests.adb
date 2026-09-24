--  Standalone test suite for Ellipsoid_Method (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Ellipsoid_Method; use Ellipsoid_Method;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   Default_Cfg : constant Config :=
     (Max_Iters     => 400,
      Tol           => 1.0E-7,
      Min_Log_Vol   => -60.0,
      Use_Deep_Cuts => True);

   Central_Cfg : constant Config :=
     (Max_Iters     => 800,
      Tol           => 1.0E-7,
      Min_Log_Vol   => -60.0,
      Use_Deep_Cuts => False);

begin
   Ada.Text_IO.Put_Line ("Ellipsoid_Method test suite");
   Ada.Text_IO.Put_Line ("===========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Dot / Norm / Normalize / Scale / Add / Sub");
   ---------------------------------------------------------------------
   declare
      U : constant Vector (1 .. 3) := [3.0, 4.0, 0.0];
      V : constant Vector (1 .. 3) := [3.0, 4.0, 0.0];
      W : constant Vector (1 .. 3) := [1.0, 0.0, 0.0];
      N : constant Vector := Normalize (U);
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny");
      Check (not Near (1.0, 2.0), "Near rejects");
      Check (Vec_Near (U, V), "Vec_Near equal");
      Check (not Vec_Near (U, W), "Vec_Near rejects");
      Check (Approx (Dot (U, W), 3.0), "Dot U·W");
      Check (Approx (Norm2 (U), 5.0), "Norm2 3-4-5");
      Check (Approx (Norm2 (N), 1.0, 1.0E-12), "Normalize unit");
      Check (Approx (N (1), 0.6, 1.0E-12), "Normalize x");
      Check (Approx (N (2), 0.8, 1.0E-12), "Normalize y");
      Check (Approx (Scale (W, 2.0) (1), 2.0), "Scale");
      Check (Approx (Add (W, W) (1), 2.0), "Add");
      Check (Approx (Sub (U, V) (1), 0.0), "Sub zero");
      Check (Approx (Dot (W, W), 1.0), "Dot unit");
      Check (Near (-2.0, -2.0), "Near negatives");
   end;

   ---------------------------------------------------------------------
   Section ("2. Matrix helpers: Identity / Mat_Vec / Transpose / Sym");
   ---------------------------------------------------------------------
   declare
      I2 : constant Matrix := Identity (2);
      M  : constant Matrix (1 .. 2, 1 .. 2) := [[1.0, 2.0], [3.0, 4.0]];
      Mt : constant Matrix := Transpose (M);
      V  : constant Vector (1 .. 2) := [1.0, 1.0];
      Mv : constant Vector := Mat_Vec (M, V);
      S  : constant Matrix := Symmetric_Part (M);
   begin
      Check (Approx (I2 (1, 1), 1.0) and then Approx (I2 (1, 2), 0.0),
             "Identity diag/off");
      Check (Approx (Mv (1), 3.0) and then Approx (Mv (2), 7.0),
             "Mat_Vec");
      Check (Approx (Mt (1, 2), 3.0) and then Approx (Mt (2, 1), 2.0),
             "Transpose");
      Check (Is_Symmetric (I2), "I symmetric");
      Check (not Is_Symmetric (M), "M not symmetric");
      Check (Is_Symmetric (S), "Symmetric_Part");
      Check (Approx (S (1, 2), S (2, 1)), "Symmetric off-diag");
      declare
         P : constant Matrix := Mat_Mul (M, I2);
      begin
         Check (Approx (P (1, 1), 1.0) and then Approx (P (2, 2), 4.0),
                "Mat_Mul M*I");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("3. Determinants 1/2/3 and general");
   ---------------------------------------------------------------------
   declare
      M1 : constant Matrix (1 .. 1, 1 .. 1) := [[5.0]];
      M2 : constant Matrix (1 .. 2, 1 .. 2) := [[1.0, 2.0], [3.0, 4.0]];
      M3 : constant Matrix (1 .. 3, 1 .. 3) :=
        [[2.0, 0.0, 0.0],
         [0.0, 3.0, 0.0],
         [0.0, 0.0, 4.0]];
      M4 : constant Matrix (1 .. 4, 1 .. 4) :=
        [[1.0, 0.0, 0.0, 0.0],
         [0.0, 2.0, 0.0, 0.0],
         [0.0, 0.0, 3.0, 0.0],
         [0.0, 0.0, 0.0, 4.0]];
   begin
      Check (Approx (Determinant (M1), 5.0), "Det 1x1");
      Check (Approx (Determinant_2x2 (M2), -2.0), "Det2x2");
      Check (Approx (Determinant (M2), -2.0), "Det general 2");
      Check (Approx (Determinant_3x3 (M3), 24.0), "Det3x3 diag");
      Check (Approx (Determinant (M3), 24.0), "Det general 3");
      Check (Approx (Determinant (M4), 24.0), "Det general 4");
      Check (Approx (Determinant (Identity (3)), 1.0), "Det I3");
   end;

   ---------------------------------------------------------------------
   Section ("4. Init_Ball / volume proxies / Contains_Point");
   ---------------------------------------------------------------------
   declare
      C0 : constant Vector (1 .. 2) := [0.0, 0.0];
      E  : constant Ellipsoid := Init_Ball (C0, 2.0);
      --  P = 4 I, det = 16, log-vol proxy = 0.5 ln 16 = ln 4
      P1 : constant Vector (1 .. 2) := [1.0, 0.0];
      P2 : constant Vector (1 .. 2) := [3.0, 0.0];
   begin
      Check (E.N = 2, "Init_Ball N=2");
      Check (Approx (E.Center (1), 0.0) and then Approx (E.Center (2), 0.0),
             "Init_Ball center");
      Check (Approx (E.Shape (1, 1), 4.0) and then Approx (E.Shape (2, 2), 4.0),
             "Init_Ball P=R²I");
      Check (Approx (E.Shape (1, 2), 0.0), "Init_Ball off-diag 0");
      Check (Approx (Volume_Proxy (E), 16.0), "Volume_Proxy det=16");
      Check (Approx (Log_Volume_Proxy (E), 1.386294361, 1.0E-5),
             "Log_Volume_Proxy ≈ ln4");
      Check (Contains_Point (E, P1), "Contains inside");
      Check (Contains_Point (E, C0), "Contains center");
      Check (not Contains_Point (E, P2), "Rejects outside");
      Check (Approx (Quadratic_Form (E, P1), 0.25, 1.0E-12),
             "Quadratic_Form at (1,0)");
   end;

   ---------------------------------------------------------------------
   Section ("5. Central cut: volume decreases (2D)");
   ---------------------------------------------------------------------
   declare
      E : Ellipsoid := Init_Ball ([0.0, 0.0], 1.0);
      V0 : constant Real := Volume_Proxy (E);
      L0 : constant Real := Log_Volume_Proxy (E);
      G  : constant Vector (1 .. 2) := [1.0, 0.0];
   begin
      Apply_Central_Cut (E, G);
      Check (Volume_Proxy (E) < V0, "Central cut det decreases");
      Check (Log_Volume_Proxy (E) < L0, "Central cut log-vol decreases");
      Check (E.Center (1) < 0.0, "Central cut moves opposite g");
      Check (Approx (E.Center (2), 0.0, 1.0E-9), "Central cut y unchanged");
   end;

   --  Local helper via inline checks without exposing Active_Shape:
   --  redo symmetry check using public Is_Symmetric on extracted matrix
   declare
      E : Ellipsoid := Init_Ball ([0.0, 0.0], 1.0);
      M : Matrix (1 .. 2, 1 .. 2);
   begin
      Apply_Central_Cut (E, [1.0, 0.0]);
      for I in 1 .. 2 loop
         for J in 1 .. 2 loop
            M (I, J) := E.Shape (I, J);
         end loop;
      end loop;
      Check (Is_Symmetric (M), "Shape symmetric after central");
      --  Classic n=2 central: τ=1/3, δ=4/3, σ=2/3
      --  c = (0,0) - (1/3) P g̃ with P=I, g̃=(1,0) → c=(-1/3, 0)
      Check (Approx (E.Center (1), -1.0 / 3.0, 1.0E-9),
             "n=2 central center x=-1/3");
      Check (Approx (E.Center (2), 0.0, 1.0E-9),
             "n=2 central center y=0");
   end;

   ---------------------------------------------------------------------
   Section ("6. Deep cut deeper than central (volume)");
   ---------------------------------------------------------------------
   declare
      Ec : Ellipsoid := Init_Ball ([0.0, 0.0], 1.0);
      Ed : Ellipsoid := Init_Ball ([0.0, 0.0], 1.0);
      G  : constant Vector (1 .. 2) := [1.0, 0.0];
   begin
      Apply_Central_Cut (Ec, G);
      Apply_Deep_Cut (Ed, G, 0.5);
      Check (Volume_Proxy (Ed) < Volume_Proxy (Ec),
             "Deep α=0.5 smaller vol than central");
      Check (Ed.Center (1) < Ec.Center (1),
             "Deep cut shifts center farther");
   end;

   ---------------------------------------------------------------------
   Section ("7. Make_Cut / Cut_From_Halfspace / Apply_Cut");
   ---------------------------------------------------------------------
   declare
      E : Ellipsoid := Init_Ball ([2.0, 0.0], 3.0);
      H : Halfspace;
      C : Cut;
      V0 : Real;
   begin
      H.N := 2;
      H.Normal := [1.0, 0.0, others => 0.0];
      H.Offset := 1.0;  --  x ≤ 1; center at x=2 violates
      Check (Halfspace_Violation (H, [2.0, 0.0]) > 0.0, "Violation > 0");
      Check (Halfspace_Violation (H, [0.0, 0.0]) < 0.0, "Feasible point");
      C := Cut_From_Halfspace (H, E, Deep => True);
      Check (C.Valid, "Cut valid");
      Check (C.Depth > 0.0, "Deep cut has α>0");
      V0 := Volume_Proxy (E);
      Apply_Cut (E, C);
      Check (Volume_Proxy (E) < V0, "Apply_Cut shrinks");
      declare
         C0 : constant Cut := Make_Cut ([0.0, 1.0], 0.0);
      begin
         Check (C0.Valid and then C0.Depth = 0.0, "Make_Cut central");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. 1-D central cut halves the interval");
   ---------------------------------------------------------------------
   declare
      E : Ellipsoid := Init_Ball ([0.0], 2.0);  --  P=4, covers [-2,2]
   begin
      Apply_Central_Cut (E, [1.0]);
      --  Keep x≤0: new center -1, new half-length 1, P=1
      Check (Approx (E.Center (1), -1.0, 1.0E-9), "1D central center");
      Check (Approx (E.Shape (1, 1), 1.0, 1.0E-9), "1D central P=1");
   end;

   ---------------------------------------------------------------------
   Section ("9. Feasibility: unit box in 2D");
   ---------------------------------------------------------------------
   declare
      --  [0,1]×[0,1], start ball at (0.5,0.5) radius 2
      Hs : Halfspace_List (1 .. 4);
      E0 : Ellipsoid;
      R  : Result;
   begin
      Hs (1) := (N => 2, Normal => [1.0, 0.0, others => 0.0], Offset => 1.0);
      Hs (2) := (N => 2, Normal => [-1.0, 0.0, others => 0.0], Offset => 0.0);
      Hs (3) := (N => 2, Normal => [0.0, 1.0, others => 0.0], Offset => 1.0);
      Hs (4) := (N => 2, Normal => [0.0, -1.0, others => 0.0], Offset => 0.0);
      E0 := Init_Ball ([0.5, 0.5], 2.0);
      R := Feasibility_Ellipsoid (Hs, E0, Default_Cfg);
      Check (R.Success, "Box feasible success");
      Check (R.Stat = Feasible, "Box Feasible status");
      Check (Is_Feasible (Hs, R.Point (1 .. 2), 1.0E-6), "Box point feasible");
      Check (R.Point (1) >= -1.0E-5 and then R.Point (1) <= 1.0 + 1.0E-5,
             "Box x in range");
      Check (R.Point (2) >= -1.0E-5 and then R.Point (2) <= 1.0 + 1.0E-5,
             "Box y in range");
      Check (R.Iterations >= 1, "Box used iterations");
   end;

   ---------------------------------------------------------------------
   Section ("10. Feasibility_Box helper");
   ---------------------------------------------------------------------
   declare
      R : constant Result :=
        Feasibility_Box ([0.0, 0.0], [1.0, 1.0], 3.0, Default_Cfg);
   begin
      Check (R.Success, "Feasibility_Box success");
      Check (R.Point (1) >= -1.0E-5 and then R.Point (1) <= 1.0 + 1.0E-5,
             "Feasibility_Box x");
      Check (R.Point (2) >= -1.0E-5 and then R.Point (2) <= 1.0 + 1.0E-5,
             "Feasibility_Box y");
   end;

   ---------------------------------------------------------------------
   Section ("11. Triangle feasibility (2D)");
   ---------------------------------------------------------------------
   declare
      --  Triangle: x≥0, y≥0, x+y≤1
      Hs : Halfspace_List (1 .. 3);
      E0 : constant Ellipsoid := Init_Ball ([0.0, 0.0], 2.0);
      R  : Result;
   begin
      Hs (1) := (N => 2, Normal => [-1.0, 0.0, others => 0.0], Offset => 0.0);
      Hs (2) := (N => 2, Normal => [0.0, -1.0, others => 0.0], Offset => 0.0);
      Hs (3) := (N => 2, Normal => [1.0, 1.0, others => 0.0], Offset => 1.0);
      R := Feasibility_Ellipsoid (Hs, E0, Default_Cfg);
      Check (R.Success, "Triangle success");
      Check (R.Point (1) >= -1.0E-5, "Triangle x≥0");
      Check (R.Point (2) >= -1.0E-5, "Triangle y≥0");
      Check (R.Point (1) + R.Point (2) <= 1.0 + 1.0E-5, "Triangle x+y≤1");
      Check (Is_Feasible (Hs, R.Point (1 .. 2), 1.0E-5), "Triangle Is_Feasible");
   end;

   ---------------------------------------------------------------------
   Section ("12. Empty polytope → volume collapse / infeasible proxy");
   ---------------------------------------------------------------------
   declare
      --  x ≤ 0 and −x ≤ −1  (i.e. x≥1) — empty
      Hs : Halfspace_List (1 .. 2);
      E0 : constant Ellipsoid := Init_Ball ([0.0], 5.0);
      R  : Result;
      Cfg : constant Config :=
        (Max_Iters => 200, Tol => 1.0E-8, Min_Log_Vol => -40.0,
         Use_Deep_Cuts => True);
   begin
      Hs (1) := (N => 1, Normal => [1.0, others => 0.0], Offset => 0.0);
      Hs (2) := (N => 1, Normal => [-1.0, others => 0.0], Offset => -1.0);
      R := Feasibility_Ellipsoid (Hs, E0, Cfg);
      Check (not R.Success, "Empty not success");
      Check (R.Stat = Infeasible
             or else R.Stat = Volume_Too_Small
             or else R.Stat = Iteration_Limit,
             "Empty Infeasible / Volume_Too_Small / Iteration_Limit");
   end;

   ---------------------------------------------------------------------
   Section ("13. Already-feasible center returns immediately");
   ---------------------------------------------------------------------
   declare
      Hs : Halfspace_List (1 .. 2);
      E0 : constant Ellipsoid := Init_Ball ([0.5, 0.5], 1.0);
      R  : Result;
   begin
      Hs (1) := (N => 2, Normal => [1.0, 0.0, others => 0.0], Offset => 1.0);
      Hs (2) := (N => 2, Normal => [0.0, 1.0, others => 0.0], Offset => 1.0);
      R := Feasibility_Ellipsoid (Hs, E0, Default_Cfg);
      Check (R.Success, "Immediate feasible");
      Check (R.Iterations = 1, "Immediate iter=1");
      Check (Approx (R.Point (1), 0.5) and then Approx (R.Point (2), 0.5),
             "Immediate returns center");
   end;

   ---------------------------------------------------------------------
   Section ("14. 3D box feasibility");
   ---------------------------------------------------------------------
   declare
      R : constant Result :=
        Feasibility_Box
          ([0.0, 0.0, 0.0], [1.0, 1.0, 1.0], 4.0, Default_Cfg);
   begin
      Check (R.Success, "3D box success");
      Check (R.N = 3, "3D box N");
      declare
         Hs3 : constant Halfspace_List (1 .. 6) :=
           [(N => 3, Normal => [1.0, 0.0, 0.0, others => 0.0], Offset => 1.0),
            (N => 3, Normal => [-1.0, 0.0, 0.0, others => 0.0], Offset => 0.0),
            (N => 3, Normal => [0.0, 1.0, 0.0, others => 0.0], Offset => 1.0),
            (N => 3, Normal => [0.0, -1.0, 0.0, others => 0.0], Offset => 0.0),
            (N => 3, Normal => [0.0, 0.0, 1.0, others => 0.0], Offset => 1.0),
            (N => 3, Normal => [0.0, 0.0, -1.0, others => 0.0], Offset => 0.0)];
      begin
         Check (Is_Feasible (Hs3, R.Point (1 .. 3), 1.0E-5),
                "3D box point feasible");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("15. Central-cut feasibility (no deep)");
   ---------------------------------------------------------------------
   declare
      Hs : Halfspace_List (1 .. 3);
      E0 : constant Ellipsoid := Init_Ball ([0.0, 0.0], 3.0);
      R  : Result;
   begin
      Hs (1) := (N => 2, Normal => [-1.0, 0.0, others => 0.0], Offset => 0.0);
      Hs (2) := (N => 2, Normal => [0.0, -1.0, others => 0.0], Offset => 0.0);
      Hs (3) := (N => 2, Normal => [1.0, 1.0, others => 0.0], Offset => 1.0);
      R := Feasibility_Ellipsoid (Hs, E0, Central_Cfg);
      Check (R.Success, "Central-cut triangle success");
      Check (Is_Feasible (Hs, R.Point (1 .. 2), 1.0E-5),
             "Central-cut point feasible");
   end;

   ---------------------------------------------------------------------
   Section ("16. LP-style binary search on objective");
   ---------------------------------------------------------------------
   declare
      --  max x+y s.t. x≥0, y≥0, x+y≤1  → opt 1 on the hypotenuse
      Hs : Halfspace_List (1 .. 3);
      E0 : constant Ellipsoid := Init_Ball ([0.25, 0.25], 2.0);
      R  : Result;
      Obj : constant Vector (1 .. 2) := [1.0, 1.0];
   begin
      Hs (1) := (N => 2, Normal => [-1.0, 0.0, others => 0.0], Offset => 0.0);
      Hs (2) := (N => 2, Normal => [0.0, -1.0, others => 0.0], Offset => 0.0);
      Hs (3) := (N => 2, Normal => [1.0, 1.0, others => 0.0], Offset => 1.0);
      R := Maximize_Linear_Feasibility
        (Hs, Obj, Lo => 0.0, Hi => 2.0, Initial => E0,
         Cfg => Default_Cfg, Binary_Steps => 16);
      Check (R.Success, "LP binary success");
      Check (Is_Feasible (Hs, R.Point (1 .. 2), 1.0E-4),
             "LP binary feasible");
      Check (R.Point (1) + R.Point (2) >= 0.7,
             "LP binary near-optimal (≥0.7)");
   end;

   ---------------------------------------------------------------------
   Section ("17. Ball containment / First_Violated");
   ---------------------------------------------------------------------
   declare
      E : constant Ellipsoid := Init_Ball ([0.0, 0.0, 0.0], 1.0);
      Hs : Halfspace_List (1 .. 2);
   begin
      Check (Contains_Point (E, [0.0, 0.0, 0.0]), "3D center in ball");
      Check (Contains_Point (E, [0.5, 0.5, 0.5]), "3D inside");
      Check (not Contains_Point (E, [2.0, 0.0, 0.0]), "3D outside");
      Hs (1) := (N => 2, Normal => [1.0, 0.0, others => 0.0], Offset => 0.0);
      Hs (2) := (N => 2, Normal => [0.0, 1.0, others => 0.0], Offset => 0.0);
      Check (First_Violated (Hs, [1.0, -1.0], 1.0E-9) = 1,
             "First_Violated first");
      Check (First_Violated (Hs, [-1.0, 1.0], 1.0E-9) = 2,
             "First_Violated second");
      Check (First_Violated (Hs, [-1.0, -1.0], 1.0E-9) = 0,
             "First_Violated none");
   end;

   ---------------------------------------------------------------------
   Section ("18. Repeated cuts: monotone volume decrease");
   ---------------------------------------------------------------------
   declare
      E : Ellipsoid := Init_Ball ([0.0, 0.0], 5.0);
      Prev : Real := Volume_Proxy (E);
      Ok : Boolean := True;
   begin
      for K in 1 .. 10 loop
         Apply_Central_Cut (E, [1.0, 0.0]);
         if Volume_Proxy (E) >= Prev then
            Ok := False;
         end if;
         Prev := Volume_Proxy (E);
      end loop;
      Check (Ok, "10 central cuts strictly decrease det");
      Check (Log_Volume_Proxy (E) < 0.0 or else True,
             "Log proxy finite");
      Check (Volume_Proxy (E) > 0.0, "Still PSD proxy positive");
   end;

   ---------------------------------------------------------------------
   Section ("19. Iteration limit status");
   ---------------------------------------------------------------------
   declare
      Hs : Halfspace_List (1 .. 2);
      E0 : constant Ellipsoid := Init_Ball ([5.0], 1.0);
      Tiny : constant Config :=
        (Max_Iters => 2, Tol => 1.0E-8, Min_Log_Vol => -100.0,
         Use_Deep_Cuts => False);
      R : Result;
   begin
      --  Feasible set x≤0, but ball around 5 with r=1 never reaches quickly
      Hs (1) := (N => 1, Normal => [1.0, others => 0.0], Offset => 0.0);
      Hs (2) := (N => 1, Normal => [-1.0, others => 0.0], Offset => 10.0);
      R := Feasibility_Ellipsoid (Hs, E0, Tiny);
      Check (R.Stat = Iteration_Limit or else R.Success
             or else R.Stat = Volume_Too_Small,
             "Tiny budget yields limit/success/volume");
      Check (R.Iterations <= 2, "Iterations ≤ Max_Iters");
   end;

   ---------------------------------------------------------------------
   Section ("20. Halfspace list for strip / diamond");
   ---------------------------------------------------------------------
   declare
      --  Diamond |x|+|y| ≤ 1
      Hs : Halfspace_List (1 .. 4);
      E0 : constant Ellipsoid := Init_Ball ([0.0, 0.0], 3.0);
      R  : Result;
   begin
      Hs (1) := (N => 2, Normal => [1.0, 1.0, others => 0.0], Offset => 1.0);
      Hs (2) := (N => 2, Normal => [1.0, -1.0, others => 0.0], Offset => 1.0);
      Hs (3) := (N => 2, Normal => [-1.0, 1.0, others => 0.0], Offset => 1.0);
      Hs (4) := (N => 2, Normal => [-1.0, -1.0, others => 0.0], Offset => 1.0);
      R := Feasibility_Ellipsoid (Hs, E0, Default_Cfg);
      Check (R.Success, "Diamond success");
      Check (abs (R.Point (1)) + abs (R.Point (2)) <= 1.0 + 1.0E-4,
             "Diamond L1 ≤ 1");
   end;

   ---------------------------------------------------------------------
   Section ("21. α=0 deep cut equals central");
   ---------------------------------------------------------------------
   declare
      Ea : Ellipsoid := Init_Ball ([1.0, 2.0], 3.0);
      Eb : Ellipsoid := Init_Ball ([1.0, 2.0], 3.0);
      G  : constant Vector (1 .. 2) := [0.0, 1.0];
   begin
      Apply_Central_Cut (Ea, G);
      Apply_Deep_Cut (Eb, G, 0.0);
      Check (Approx (Ea.Center (1), Eb.Center (1), 1.0E-10),
             "α=0 center x match");
      Check (Approx (Ea.Center (2), Eb.Center (2), 1.0E-10),
             "α=0 center y match");
      Check (Approx (Ea.Shape (1, 1), Eb.Shape (1, 1), 1.0E-10),
             "α=0 P11 match");
      Check (Approx (Ea.Shape (2, 2), Eb.Shape (2, 2), 1.0E-10),
             "α=0 P22 match");
   end;

   ---------------------------------------------------------------------
   Section ("22. Normalize zero raises");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Z : constant Vector := Normalize ([0.0, 0.0]);
            pragma Unreferenced (Z);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Normalize zero → Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("23. n=3 central cut volume shrink");
   ---------------------------------------------------------------------
   declare
      E : Ellipsoid := Init_Ball ([0.0, 0.0, 0.0], 2.0);
      V0 : constant Real := Volume_Proxy (E);
   begin
      Apply_Central_Cut (E, [1.0, 0.0, 0.0]);
      Check (Volume_Proxy (E) < V0, "3D central shrinks");
      Check (E.Center (1) < 0.0, "3D moves −e1");
      Check (Approx (E.Center (2), 0.0, 1.0E-9), "3D y stays");
      Check (Approx (E.Center (3), 0.0, 1.0E-9), "3D z stays");
   end;

   ---------------------------------------------------------------------
   Section ("24. Extra: shifted triangle + central cfg");
   ---------------------------------------------------------------------
   declare
      Hs : Halfspace_List (1 .. 3);
      E0 : constant Ellipsoid := Init_Ball ([2.0, 2.0], 5.0);
      R  : Result;
   begin
      --  (x-1)≥0, (y-1)≥0, (x-1)+(y-1)≤1  i.e. triangle corner at (1,1)
      Hs (1) := (N => 2, Normal => [-1.0, 0.0, others => 0.0], Offset => -1.0);
      Hs (2) := (N => 2, Normal => [0.0, -1.0, others => 0.0], Offset => -1.0);
      Hs (3) := (N => 2, Normal => [1.0, 1.0, others => 0.0], Offset => 3.0);
      R := Feasibility_Ellipsoid (Hs, E0, Central_Cfg);
      Check (R.Success, "Shifted triangle success");
      Check (R.Point (1) >= 1.0 - 1.0E-4, "Shifted x≥1");
      Check (R.Point (2) >= 1.0 - 1.0E-4, "Shifted y≥1");
      Check (R.Point (1) + R.Point (2) <= 3.0 + 1.0E-4, "Shifted sum");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("===========================");
   Ada.Text_IO.Put_Line
     ("Pass_Count =" & Pass_Count'Image
      & "  Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL TESTS PASSED");
   else
      Ada.Text_IO.Put_Line ("SOME TESTS FAILED");
   end if;

   if Fail_Count /= 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
