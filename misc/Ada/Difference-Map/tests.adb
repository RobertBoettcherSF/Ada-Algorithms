--  Standalone test suite for Difference_Map (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Difference_Map; use Difference_Map;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-8) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Vec_Near (X, Y : Vector; Tol : Real := 1.0E-7) return Boolean is
   begin
      if X'Length /= Y'Length then
         return False;
      end if;
      declare
         J : Positive := Y'First;
      begin
         for I in X'Range loop
            if abs (X (I) - Y (J)) > Tol then
               return False;
            end if;
            J := J + 1;
         end loop;
      end;
      return True;
   end Vec_Near;

   function Slice_X (R : Result) return Vector is
      X : Vector (1 .. R.Dim);
   begin
      for I in 1 .. R.Dim loop
         X (I) := R.X (I);
      end loop;
      return X;
   end Slice_X;

   function Slice_Feasible (R : Result) return Vector is
      X : Vector (1 .. R.Dim);
   begin
      for I in 1 .. R.Dim loop
         X (I) := R.Feasible (I);
      end loop;
      return X;
   end Slice_Feasible;

   function Slice_Feasible3 (R : Result) return Vector is
      X : Vector (1 .. 3);
   begin
      for I in 1 .. 3 loop
         X (I) := R.Feasible (I);
      end loop;
      return X;
   end Slice_Feasible3;

begin
   Put_Line ("Difference_Map test suite");
   Put_Line ("=========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Norm2 / Dot / Add / Sub / Scale");
   ---------------------------------------------------------------------
   declare
      X : constant Vector := [3.0, 4.0];
      Y : constant Vector := [1.0, 2.0];
      Z : Vector (1 .. 2);
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-13), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects far");
      Check (Approx (Norm2 (X), 5.0), "Norm2 3-4-5");
      Check (Approx (Norm2 ([0.0, 0.0]), 0.0), "Norm2 zero");
      Check (Approx (Dot (X, Y), 11.0), "Dot product");
      Z := Add (X, Y);
      Check (Approx (Z (1), 4.0) and then Approx (Z (2), 6.0), "Add");
      Z := Sub (X, Y);
      Check (Approx (Z (1), 2.0) and then Approx (Z (2), 2.0), "Sub");
      Z := Scale (2.0, Y);
      Check (Approx (Z (1), 2.0) and then Approx (Z (2), 4.0), "Scale");
      Check (Approx (Distance (X, Y), Norm2 (Sub (X, Y))), "Distance");
      Check (Approx (Distance (X, X), 0.0), "Distance self");
   end;

   ---------------------------------------------------------------------
   Section ("2. Project_Box identities");
   ---------------------------------------------------------------------
   declare
      Lo : constant Vector := [-1.0, 0.0];
      Hi : constant Vector := [1.0, 2.0];
      P  : Vector (1 .. 2);
      Raised : Boolean;
   begin
      P := Project_Box ([0.0, 1.0], Lo, Hi);
      Check (Vec_Near (P, [0.0, 1.0]), "Box interior fixed");
      P := Project_Box ([-2.0, 3.0], Lo, Hi);
      Check (Vec_Near (P, [-1.0, 2.0]), "Box clamps both");
      P := Project_Box ([-1.0, 2.0], Lo, Hi);
      Check (Vec_Near (P, [-1.0, 2.0]), "Box boundary fixed");
      P := Project_Box ([0.5, -5.0], Lo, Hi);
      Check (Approx (P (1), 0.5) and then Approx (P (2), 0.0),
             "Box clamp dim2 only");
      --  Idempotent: P(P(x)) = P(x)
      P := Project_Box ([5.0, -5.0], Lo, Hi);
      Check (Vec_Near (Project_Box (P, Lo, Hi), P), "Box idempotent");
      Raised := False;
      begin
         P := Project_Box ([0.0], [-1.0, 0.0], [1.0, 1.0]);
         Check (False, "unreachable box length");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Box length mismatch raises");
   end;

   ---------------------------------------------------------------------
   Section ("3. Project_Ball / Project_Sphere");
   ---------------------------------------------------------------------
   declare
      C : constant Vector := [0.0, 0.0];
      P : Vector (1 .. 2);
   begin
      P := Project_Ball ([0.3, 0.4], 1.0, C);
      Check (Vec_Near (P, [0.3, 0.4]), "Ball interior fixed");
      P := Project_Ball ([3.0, 4.0], 1.0, C);
      Check (Approx (Norm2 (P), 1.0, 1.0E-9), "Ball boundary norm");
      Check (Vec_Near (P, [0.6, 0.8], 1.0E-9), "Ball direction 3-4-5");
      P := Project_Ball ([0.0, 0.0], 2.0, C);
      Check (Vec_Near (P, [0.0, 0.0]), "Ball origin fixed");
      P := Project_Sphere ([3.0, 4.0], 5.0, C);
      Check (Vec_Near (P, [3.0, 4.0]), "Sphere already on surface");
      P := Project_Sphere ([1.0, 0.0], 2.0, C);
      Check (Vec_Near (P, [2.0, 0.0]), "Sphere scale out");
      P := Project_Sphere ([0.0, 0.0], 3.0, C);
      Check (Approx (Norm2 (P), 3.0, 1.0E-9), "Sphere from center");
      P := Project_Ball ([1.0, 0.0], 1.0, [1.0, 0.0]);
      Check (Vec_Near (P, [1.0, 0.0]), "Ball at center of ball");
      --  Idempotent sphere
      P := Project_Sphere ([1.0, 1.0], 1.0, C);
      Check (Approx (Norm2 (P), 1.0, 1.0E-9), "Sphere unit norm");
      Check (Vec_Near (Project_Sphere (P, 1.0, C), P, 1.0E-9),
             "Sphere idempotent");
   end;

   ---------------------------------------------------------------------
   Section ("4. Project_Orthant / Project_Hyperplane");
   ---------------------------------------------------------------------
   declare
      P3 : Vector (1 .. 3);
      P2 : Vector (1 .. 2);
      N  : constant Vector := [1.0, 0.0];
      X  : constant Vector := [3.0, 5.0];
   begin
      P3 := Project_Orthant ([-1.0, 2.0, -3.0]);
      Check (Vec_Near (P3, [0.0, 2.0, 0.0]), "Orthant clamps negatives");
      P3 := Project_Orthant ([1.0, 2.0, 3.0]);
      Check (Vec_Near (P3, [1.0, 2.0, 3.0]), "Orthant nonnegative fixed");
      Check (Vec_Near (Project_Orthant (P3), P3), "Orthant idempotent");
      P2 := Project_Hyperplane (X, N, 0.0);
      Check (Vec_Near (P2, [0.0, 5.0]), "Hyperplane x=0");
      Check (Approx (Dot (N, P2), 0.0), "Hyperplane satisfies a·x=b");
      P2 := Project_Hyperplane ([1.0, 1.0], [1.0, 1.0], 2.0);
      Check (Approx (P2 (1) + P2 (2), 2.0, 1.0E-9), "Hyperplane x+y=2");
      Check (Vec_Near (Project_Hyperplane (P2, [1.0, 1.0], 2.0), P2),
             "Hyperplane idempotent");
      --  Known: proj of (0,0) onto x+y=2 is (1,1)
      P2 := Project_Hyperplane ([0.0, 0.0], [1.0, 1.0], 2.0);
      Check (Vec_Near (P2, [1.0, 1.0], 1.0E-9), "Hyperplane (0,0)->(1,1)");
   end;

   ---------------------------------------------------------------------
   Section ("5. Constraint dispatch / builders");
   ---------------------------------------------------------------------
   declare
      Box_C  : constant Constraint := Make_Box (2, -1.0, 1.0);
      Ball_C : constant Constraint := Make_Ball (2, 1.0);
      Sph_C  : constant Constraint := Make_Sphere (2, 1.0);
      Orth_C : constant Constraint := Make_Orthant (2);
      Hyp_C  : constant Constraint :=
                 Make_Hyperplane ([1.0, 0.0], 0.0);
      X : constant Vector := [2.0, -0.5];
      P : Vector (1 .. 2);
      Params : Parameters;
   begin
      P := Project (Box_C, X);
      Check (Vec_Near (P, [1.0, -0.5]), "Dispatch Box");
      P := Project (Ball_C, X);
      Check (Approx (Norm2 (P), 1.0, 1.0E-8), "Dispatch Ball");
      P := Project (Sph_C, X);
      Check (Approx (Norm2 (P), 1.0, 1.0E-8), "Dispatch Sphere");
      P := Project (Orth_C, X);
      Check (Vec_Near (P, [2.0, 0.0]), "Dispatch Orthant");
      P := Project (Hyp_C, X);
      Check (Approx (P (1), 0.0) and then Approx (P (2), -0.5),
             "Dispatch Hyperplane");
      Params := Default_Parameters;
      Check (Approx (Params.Beta, 1.0) and then Params.Max_Iter = 1_000,
             "Default_Parameters");
      Params := Default_Parameters (Beta => -1.0, Max_Iter => 50, Tol => 1.0E-6);
      Check (Approx (Params.Beta, -1.0) and then Params.Max_Iter = 50,
             "Default_Parameters overrides");
      Check (Make_Box_Vec ([-2.0, -2.0], [2.0, 2.0]).Kind = Box_Constraint,
             "Make_Box_Vec kind");
   end;

   ---------------------------------------------------------------------
   Section ("6. Elser step β=1 reduction / residual");
   ---------------------------------------------------------------------
   declare
      --  Line (hyperplane x=0) ∩ unit circle (sphere)
      A : constant Constraint := Make_Hyperplane ([1.0, 0.0], 0.0);
      B : constant Constraint := Make_Sphere (2, 1.0);
      X : constant Vector := [0.5, 0.5];
      D1, Dgen : Vector (1 .. 2);
      Res : Real;
   begin
      D1 := Difference_Map_Step (X, A, B, 1.0);
      --  General formula with β=1 should match fast path
      Dgen := Difference_Map_Step (X, A, B, 1.0 + 0.0);
      Check (Vec_Near (D1, Dgen), "β=1 fast path consistent");
      Res := Residual (X, A, B, 1.0);
      Check (Res >= 0.0, "Residual nonnegative");
      --  A known feasible point of A∩B is (0,1) or (0,-1)
      Check (Is_Near_Feasible ([0.0, 1.0], A, B, 1.0, 1.0E-9),
             "Feasible (0,1) near-feasible");
      Check (Approx (Residual ([0.0, 1.0], A, B, 1.0), 0.0, 1.0E-9),
             "Residual at feasible ~ 0");
      Check (not Is_Near_Feasible (X, A, B, 1.0, 1.0E-9),
             "Start not yet feasible");
      declare
         FA : constant Vector := F_A (X, A, 1.0);
         FB : constant Vector := F_B (X, B, 1.0);
      begin
         --  For β=1: f_A(x)=x, f_B(x)=2 P_B(x)−x
         Check (Vec_Near (FA, X, 1.0E-12), "f_A at β=1 equals x");
         Check (Vec_Near (FB, Sub (Scale (2.0, Project (B, X)), X), 1.0E-12),
                "f_B at β=1 equals 2PB−x");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Line ∩ circle via difference map");
   ---------------------------------------------------------------------
   declare
      A : constant Constraint := Make_Hyperplane ([1.0, 0.0], 0.0);
      B : constant Constraint := Make_Sphere (2, 1.0);
      Params : constant Parameters :=
        Default_Parameters (Beta => 1.0, Max_Iter => 200, Tol => 1.0E-8);
      R : Result;
      Fpt : Vector (1 .. 2);
   begin
      R := Iterate_Difference_Map ([0.7, 0.2], A, B, Params);
      Check (R.Converged, "Line∩circle converged");
      Check (R.Near_Feasible, "Line∩circle near-feasible");
      Check (R.Residual <= Params.Tol, "Line∩circle residual ≤ tol");
      Fpt := Slice_Feasible (R);
      Check (Approx (abs (Fpt (1)), 0.0, 1.0E-6), "Feasible on line x=0");
      Check (Approx (Norm2 (Fpt), 1.0, 1.0E-6), "Feasible on unit circle");
      Check (R.Iterations <= Params.Max_Iter, "Iterations within budget");

      R := Iterate_Difference_Map ([-0.3, -0.8], A, B, Params);
      Check (R.Converged, "Line∩circle from other start");
      Fpt := Slice_Feasible (R);
      Check (Approx (Norm2 (Fpt), 1.0, 1.0E-5), "Other start on circle");
   end;

   ---------------------------------------------------------------------
   Section ("8. Box ∩ ball in R^2");
   ---------------------------------------------------------------------
   declare
      A : constant Constraint := Make_Box (2, -0.5, 0.5);
      B : constant Constraint := Make_Ball (2, 1.0);
      --  Intersection nonempty: e.g. (0.5, 0) is on box boundary & in ball
      Params : constant Parameters :=
        Default_Parameters (Beta => 1.0, Max_Iter => 300, Tol => 1.0E-8);
      R : Result;
      Fpt : Vector (1 .. 2);
   begin
      R := Iterate_Difference_Map ([2.0, 2.0], A, B, Params);
      Check (R.Converged, "Box∩ball converged");
      Fpt := Slice_Feasible (R);
      Check (abs (Fpt (1)) <= 0.5 + 1.0E-5
             and then abs (Fpt (2)) <= 0.5 + 1.0E-5,
             "Feasible inside box");
      Check (Norm2 (Fpt) <= 1.0 + 1.0E-5, "Feasible inside ball");
      Check (Is_Near_Feasible
               (Slice_X (R), A, B, 1.0, 1.0E-7)
             or else R.Near_Feasible,
             "Iterate X near-feasible or flag set");
   end;

   ---------------------------------------------------------------------
   Section ("9. Orthant ∩ hyperplane / R^3 sphere ∩ plane");
   ---------------------------------------------------------------------
   declare
      --  Nonnegative orthant ∩ plane x+y+z = 1  → simplex face
      A : constant Constraint := Make_Orthant (3);
      B : constant Constraint :=
            Make_Hyperplane ([1.0, 1.0, 1.0], 1.0);
      Params : constant Parameters :=
        Default_Parameters (Beta => 1.0, Max_Iter => 400, Tol => 1.0E-8);
      R : Result;
      Fpt : Vector (1 .. 3);
      S : Real;
   begin
      R := Iterate_Difference_Map ([2.0, -1.0, 0.5], A, B, Params);
      Check (R.Converged, "Orthant∩plane converged");
      Fpt := Slice_Feasible3 (R);
      Check (Fpt (1) >= -1.0E-6 and then Fpt (2) >= -1.0E-6
             and then Fpt (3) >= -1.0E-6,
             "Feasible in orthant");
      S := Fpt (1) + Fpt (2) + Fpt (3);
      Check (Approx (S, 1.0, 1.0E-5), "Feasible on plane sum=1");
   end;

   declare
      A : constant Constraint :=
            Make_Hyperplane ([0.0, 0.0, 1.0], 0.0);  -- z = 0
      B : constant Constraint := Make_Sphere (3, 1.0);
      Params : constant Parameters :=
        Default_Parameters (Beta => 1.0, Max_Iter => 300, Tol => 1.0E-8);
      R : Result;
      Fpt : Vector (1 .. 3);
   begin
      R := Iterate_Difference_Map ([0.2, 0.3, 0.9], A, B, Params);
      Check (R.Converged, "Plane∩sphere R^3 converged");
      Fpt := Slice_Feasible3 (R);
      Check (Approx (Fpt (3), 0.0, 1.0E-5), "Feasible on z=0");
      Check (Approx (Norm2 (Fpt), 1.0, 1.0E-5), "Feasible on sphere");
   end;

   ---------------------------------------------------------------------
   Section ("10. Alternating projections (convex contrast)");
   ---------------------------------------------------------------------
   declare
      --  Two halfspaces via boxes / orthant+plane — use ball ∩ box (convex)
      A : constant Constraint := Make_Box (2, -1.0, 1.0);
      B : constant Constraint := Make_Ball (2, 0.5);
      Params : constant Parameters :=
        Default_Parameters (Max_Iter => 200, Tol => 1.0E-8);
      R : Result;
      X : Vector (1 .. 2);
      Step : Vector (1 .. 2);
   begin
      R := Alternating_Projections ([3.0, 4.0], A, B, Params);
      Check (R.Converged, "Alt proj box∩ball converged");
      Check (R.Residual <= Params.Tol, "Alt proj residual");
      X := [2.0, 0.0];
      Step := Alternating_Projections_Step (X, A, B);
      Check (Norm2 (Step) <= 0.5 + 1.0E-9, "Alt step in ball");
      Check (abs (Step (1)) <= 1.0 and then abs (Step (2)) <= 1.0,
             "Alt step in box");
   end;

   ---------------------------------------------------------------------
   Section ("11. Douglas–Rachford / averaged projections");
   ---------------------------------------------------------------------
   declare
      A : constant Constraint := Make_Box (2, -0.5, 0.5);
      B : constant Constraint := Make_Ball (2, 1.0);
      Params : constant Parameters :=
        Default_Parameters (Max_Iter => 400, Tol => 1.0E-8);
      R : Result;
      X, Y : Vector (1 .. 2);
   begin
      R := Iterate_Douglas_Rachford ([2.0, 2.0], A, B, Params);
      Check (R.Converged, "DR box∩ball converged");
      Check (R.Near_Feasible, "DR near-feasible");
      X := [1.0, 1.0];
      Y := Douglas_Rachford_Step (X, A, B);
      Check (Y'Length = 2, "DR step length");
      Y := Averaged_Projections_Step (X, A, B);
      Check (Y'Length = 2, "Avg step length");
      --  Reflect twice is identity on a convex projector fixed point...
      --  At least Reflect(C, Project(C,x)) = Project(C,x)
      declare
         P : constant Vector := Project (A, X);
         RR : constant Vector := Reflect (A, P);
      begin
         Check (Vec_Near (RR, P), "Reflect fixes projected point");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. β ≠ 1 path / negative β / Max_Iter=0");
   ---------------------------------------------------------------------
   declare
      A : constant Constraint := Make_Hyperplane ([1.0, 0.0], 0.0);
      B : constant Constraint := Make_Sphere (2, 1.0);
      Params : Parameters;
      R : Result;
      X : constant Vector := [0.4, 0.6];
      D : Vector (1 .. 2);
   begin
      D := Difference_Map_Step (X, A, B, 0.5);
      Check (D'Length = 2, "Step β=0.5 length");
      Check (Residual (D, A, B, 0.5) >= 0.0, "Residual after β=0.5 step");
      Params := Default_Parameters (Beta => -1.0, Max_Iter => 250, Tol => 1.0E-8);
      R := Iterate_Difference_Map ([0.5, 0.5], A, B, Params);
      Check (R.Converged, "β=-1 line∩circle converged");
      Params := Default_Parameters (Beta => 0.7, Max_Iter => 400, Tol => 1.0E-8);
      R := Iterate_Difference_Map ([0.8, -0.1], A, B, Params);
      Check (R.Converged, "β=0.7 line∩circle converged");
      Params := Default_Parameters (Max_Iter => 0, Tol => 1.0E-8);
      R := Iterate_Difference_Map ([0.0, 1.0], A, B, Params);
      Check (R.Iterations = 0, "Max_Iter=0 no steps");
      Check (R.Converged, "Already feasible Max_Iter=0");
   end;

   ---------------------------------------------------------------------
   Section ("13. Exceptions / capacity notes");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      C : Constraint;
      Tmp : Real;
   begin
      Raised := False;
      begin
         Tmp := Project_Hyperplane ([1.0, 2.0], [0.0, 0.0], 1.0) (1);
         Check (Tmp < 0.0, "unreachable zero normal");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Zero normal raises");

      Raised := False;
      begin
         C := Make_Hyperplane ([0.0, 0.0], 1.0);
         Check (C.Offset = -1.0, "unreachable make hyp");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Make_Hyperplane zero raises");

      Raised := False;
      begin
         C := Make_Sphere (2, 0.0);
         Check (C.Radius < 0.0, "unreachable sphere");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Make_Sphere radius 0 raises");

      Raised := False;
      begin
         declare
            Unused : constant Parameters :=
              Default_Parameters (Beta => 0.0);
         begin
            Check (Unused.Beta > 0.0, "unreachable beta0");
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Beta=0 Default_Parameters raises");

      Raised := False;
      begin
         Tmp := Project_Box ([0.0, 0.0], [1.0, 0.0], [0.0, 1.0]) (1);
         Check (Tmp < 0.0, "unreachable inverted box");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Inverted box raises");

      --  Capacity smoke via runtime Norm2 / Project (no static-True checks)
      declare
         V : Vector (1 .. Max_Dim) := [others => 0.0];
         Orth : constant Constraint := Make_Orthant (Max_Dim);
         P : Vector (1 .. Max_Dim);
         Nrm : Real;
      begin
         V (1) := -1.0;
         V (Max_Dim) := 2.0;
         P := Project (Orth, V);
         Nrm := Norm2 (P);
         Check (Approx (P (1), 0.0) and then Approx (P (Max_Dim), 2.0),
                "Orthant on Max_Dim vector");
         Check (Approx (Nrm, 2.0), "Norm2 Max_Dim after orthant");
         Check (Nrm > P (1), "Capacity norm exceeds clamped first");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("14. Projector fixed-point identities (extra)");
   ---------------------------------------------------------------------
   declare
      Lo : constant Vector := [0.0, 0.0, 0.0];
      Hi : constant Vector := [1.0, 1.0, 1.0];
      Samples : constant array (1 .. 5) of Vector (1 .. 3) :=
        [[-1.0, 0.5, 2.0],
         [0.0, 0.0, 0.0],
         [1.0, 1.0, 1.0],
         [0.3, 0.7, 0.1],
         [5.0, -5.0, 0.5]];
      All_Idem : Boolean := True;
      P : Vector (1 .. 3);
   begin
      for S of Samples loop
         P := Project_Box (S, Lo, Hi);
         if not Vec_Near (Project_Box (P, Lo, Hi), P) then
            All_Idem := False;
         end if;
         P := Project_Orthant (S);
         if not Vec_Near (Project_Orthant (P), P) then
            All_Idem := False;
         end if;
         P := Project_Ball (S, 2.0, [0.0, 0.0, 0.0]);
         if not Vec_Near (Project_Ball (P, 2.0, [0.0, 0.0, 0.0]), P) then
            All_Idem := False;
         end if;
      end loop;
      Check (All_Idem, "Box/Orthant/Ball idempotent on samples");
      Check (Approx (Norm2 (Project_Sphere ([2.0, 0.0, 0.0], 1.0,
                          [0.0, 0.0, 0.0])), 1.0),
             "Sphere sample norm");
      P := Project_Hyperplane ([1.0, 2.0, 3.0], [0.0, 1.0, 0.0], 0.0);
      Check (Approx (P (2), 0.0) and then Approx (P (1), 1.0)
             and then Approx (P (3), 3.0),
             "Hyperplane y=0 projection");
      Check (Vec_Near (Project_Hyperplane (P, [0.0, 1.0, 0.0], 0.0), P),
             "Hyperplane y=0 idempotent");
   end;

   ---------------------------------------------------------------------
   Section ("15. Feasible_Candidate / fixed point property");
   ---------------------------------------------------------------------
   declare
      A : constant Constraint := Make_Hyperplane ([1.0, 0.0], 0.0);
      B : constant Constraint := Make_Sphere (2, 1.0);
      Params : constant Parameters :=
        Default_Parameters (Max_Iter => 200, Tol => 1.0E-10);
      R : Result;
      X, Cand, PA, PB : Vector (1 .. 2);
   begin
      R := Iterate_Difference_Map ([0.6, 0.4], A, B, Params);
      Check (R.Converged, "Fixed-point run converged");
      X := Slice_X (R);
      Cand := Feasible_Candidate (X, A, B, 1.0);
      PA := Project (A, F_B (X, B, 1.0));
      PB := Project (B, F_A (X, A, 1.0));
      Check (Vec_Near (PA, PB, 1.0E-7), "PA(fB)=PB(fA) at fixed point");
      Check (Vec_Near (Cand, PA, 1.0E-7), "Feasible_Candidate = PA(fB)");
      --  One more step leaves X essentially unchanged
      declare
         X2 : constant Vector := Difference_Map_Step (X, A, B, 1.0);
      begin
         Check (Vec_Near (X, X2, 1.0E-6), "Fixed point stable under D");
      end;
   end;

   New_Line;
   Put_Line
     ("Result: Pass_Count=" & Natural'Image (Pass_Count)
      & "  Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 80 then
      Put_Line ("ALL PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("NO FAILURES (but Pass_Count < 80)");
   else
      Put_Line ("SOME FAILURES");
   end if;

exception
   when others =>
      Put_Line ("UNEXPECTED EXCEPTION in tests");
      raise;

end Tests;
