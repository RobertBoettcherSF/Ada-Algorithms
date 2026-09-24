--  Standalone test suite for Mirror_Descent.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Mirror_Descent;
use Mirror_Descent;

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
   function Pos (X : Positive) return Positive is (X);
   function Nat_View (X : Natural) return Natural is (X);
   function R (X : Real) return Real is (X);
   function Geo (G : Geometry) return Geometry is (G);

   function Create_Raises
     (D : Dimension; Eta : Real; Kind : Geometry) return Boolean
   is
      S : State;
   begin
      S := Create (D, Positive_Real (Eta), Kind);
      pragma Unreferenced (S);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when Constraint_Error =>
         return True;
   end Create_Raises;

   function Create_Initial_Raises
     (Eta : Real; Initial : Vector; Kind : Geometry) return Boolean
   is
      S : State;
   begin
      S := Create (Positive_Real (Eta), Initial, Kind);
      pragma Unreferenced (S);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when Constraint_Error =>
         return True;
   end Create_Initial_Raises;

   function Step_Raises
     (S : in out State; Gradient : Vector) return Boolean
   is
   begin
      Step (S, Gradient);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Step_Raises;

   function Dot_Raises (A, B : Vector) return Boolean is
      X : Real;
   begin
      X := Dot (A, B);
      pragma Unreferenced (X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Dot_Raises;

   function Norm2_Raises (X : Vector) return Boolean is
      Y : Real;
   begin
      Y := Norm2 (X);
      pragma Unreferenced (Y);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Norm2_Raises;

   function Normalize_Raises (X : Vector) return Boolean is
      Y : Vector (X'Range);
   begin
      Y := Normalize_Simplex (X);
      pragma Unreferenced (Y);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Normalize_Raises;

   function Bregman_E_Raises (A, B : Vector) return Boolean is
      X : Real;
   begin
      X := Bregman_Euclidean (A, B);
      pragma Unreferenced (X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Bregman_E_Raises;

   function Bregman_H_Raises (A, B : Vector) return Boolean is
      X : Real;
   begin
      X := Bregman_Entropy (A, B);
      pragma Unreferenced (X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Bregman_H_Raises;

   function Reset_Initial_Raises
     (S : in out State; Initial : Vector) return Boolean
   is
   begin
      Reset (S, Initial);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Reset_Initial_Raises;

   function Set_Eta_Raises (S : in out State; Eta : Real) return Boolean is
   begin
      Set_Learning_Rate (S, Positive_Real (Eta));
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when Constraint_Error =>
         return True;
   end Set_Eta_Raises;

begin
   Put_Line ("Mirror_Descent — test suite");

   -----------------------------------------------------------------
   Section ("Create Euclidean / accessors");
   -----------------------------------------------------------------
   declare
      S : constant State := Create (3, 0.1, Euclidean);
      P : constant Vector := Point (S);
      G : constant Vector := Get (S);
   begin
      Check (Dimension_Of (S) = 3, "D = 3");
      Check (Near (Learning_Rate (S), 0.1), "eta = 0.1");
      Check (Geometry_Of (S) = Geo (Euclidean), "geometry Euclidean");
      Check (Rounds (S) = 0, "rounds start at 0");
      Check (P'Length = 3, "point length 3");
      Check (Near (P (1), 0.0) and then Near (P (2), 0.0)
               and then Near (P (3), 0.0), "Euclidean starts at origin");
      Check (Vector_Near (P, G), "Get aliases Point");
      Check (not Simplex_Projection_Enabled (S), "projection off by default");
   end;

   declare
      S : constant State := Create (1, 0.25, Euclidean);
   begin
      Check (Dimension_Of (S) = 1, "D = 1");
      Check (Near (Point (S) (1), 0.0), "1-D origin");
   end;

   declare
      S : constant State := Create (Max_Dim, 0.05, Euclidean);
   begin
      Check (Dimension_Of (S) = Max_Dim, "D = Max_Dim");
      Check (Point (S)'Length = Max_Dim, "point length Max_Dim");
   end;

   -----------------------------------------------------------------
   Section ("Create Entropic / uniform simplex");
   -----------------------------------------------------------------
   declare
      S : constant State := Create (4, 0.2, Entropic);
      P : constant Vector := Point (S);
   begin
      Check (Geometry_Of (S) = Geo (Entropic), "geometry Entropic");
      Check (Is_Simplex (P), "uniform start is simplex");
      Check (Near (P (1), 0.25) and then Near (P (2), 0.25)
               and then Near (P (3), 0.25) and then Near (P (4), 0.25),
             "uniform 1/4");
      Check (Rounds (S) = 0, "entropic rounds 0");
   end;

   declare
      S : constant State := Create (1, 0.5, Entropic);
   begin
      Check (Near (Point (S) (1), 1.0), "1-D entropic is 1");
      Check (Is_Simplex (Point (S)), "1-D is simplex");
   end;

   -----------------------------------------------------------------
   Section ("Create with custom initial");
   -----------------------------------------------------------------
   declare
      S : constant State :=
        Create (0.1, [1.0, 2.0, -1.0], Euclidean);
      P : constant Vector := Point (S);
   begin
      Check (Dimension_Of (S) = 3, "custom Euclidean D=3");
      Check (Near (P (1), 1.0) and then Near (P (2), 2.0)
               and then Near (P (3), -1.0), "custom Euclidean point");
   end;

   declare
      S : constant State :=
        Create (0.3, [0.2, 0.3, 0.5], Entropic);
      P : constant Vector := Point (S);
   begin
      Check (Is_Simplex (P), "custom entropic is simplex");
      Check (Near (P (1), 0.2) and then Near (P (2), 0.3)
               and then Near (P (3), 0.5), "custom entropic preserved");
   end;

   declare
      --  Non-normalized positive vector: entropic Create re-normalizes.
      S : constant State :=
        Create (0.1, [1.0, 1.0, 2.0], Entropic);
      P : constant Vector := Point (S);
   begin
      Check (Is_Simplex (P), "renormalized entropic is simplex");
      Check (Near (P (1), 0.25) and then Near (P (2), 0.25)
               and then Near (P (3), 0.5), "renormalized ratios");
   end;

   -----------------------------------------------------------------
   Section ("Reset");
   -----------------------------------------------------------------
   declare
      S : State := Create (2, 0.1, Euclidean);
   begin
      Step (S, [1.0, -1.0]);
      Check (Rounds (S) = 1, "rounds after one step");
      Reset (S);
      Check (Rounds (S) = 0, "reset clears rounds");
      Check (Near (Point (S) (1), 0.0) and then Near (Point (S) (2), 0.0),
             "reset Euclidean to origin");
   end;

   declare
      S : State := Create (3, 0.2, Entropic);
   begin
      Step (S, [1.0, 0.0, 0.0]);
      Reset (S);
      Check (Is_Simplex (Point (S)), "reset entropic still simplex");
      Check (Near (Point (S) (1), 1.0 / 3.0), "reset entropic uniform");
      Check (Rounds (S) = 0, "reset entropic rounds 0");
   end;

   declare
      S : State := Create (2, 0.1, Euclidean);
   begin
      Reset (S, [3.0, 4.0]);
      Check (Near (Point (S) (1), 3.0) and then Near (Point (S) (2), 4.0),
             "reset to custom Euclidean");
      Check (Rounds (S) = 0, "custom reset clears rounds");
   end;

   -----------------------------------------------------------------
   Section ("Euclidean Step = gradient descent");
   -----------------------------------------------------------------
   declare
      S : State := Create (2, 0.5, Euclidean);
      P : Vector (1 .. 2);
   begin
      Step (S, [2.0, -4.0]);
      P := Point (S);
      --  x ← 0 − 0.5·(2,−4) = (−1, 2)
      Check (Near (P (1), -1.0) and then Near (P (2), 2.0),
             "one Euclidean step");
      Check (Rounds (S) = 1, "rounds = 1");
      Step (S, [-2.0, 2.0]);
      P := Point (S);
      --  (−1,2) − 0.5·(−2,2) = (0, 1)
      Check (Near (P (1), 0.0) and then Near (P (2), 1.0),
             "second Euclidean step");
      Check (Rounds (S) = 2, "rounds = 2");
   end;

   -----------------------------------------------------------------
   Section ("Euclidean minimize ||x - x*||^2");
   -----------------------------------------------------------------
   declare
      Star : constant Vector := [1.0, -1.0, 0.5];
      S    : State := Create (0.25, [0.0, 0.0, 0.0],
                              Euclidean);
      G    : Vector (1 .. 3);
      Dist0, Dist1 : Real;
   begin
      Dist0 := Norm2 (Sub (Point (S), Star));
      for T in 1 .. 40 loop
         G := Sub (Point (S), Star);  -- ∇(½‖x−x*‖²) = x−x*
         Step (S, G);
      end loop;
      Dist1 := Norm2 (Sub (Point (S), Star));
      Check (Dist1 < Dist0, "distance to star decreased");
      Check (Dist1 < 1.0E-3, "converged close to star");
      Check (Rounds (S) = 40, "40 Euclidean rounds");
      Check (Vector_Near (Point (S), Star, 1.0E-3), "point near star");
   end;

   -----------------------------------------------------------------
   Section ("Euclidean with simplex projection");
   -----------------------------------------------------------------
   declare
      S : State := Create (3, 1.0, Euclidean);
      P : Vector (1 .. 3);
   begin
      Enable_Simplex_Projection (S, True);
      Check (Simplex_Projection_Enabled (S), "projection enabled");
      --  From origin, gradient (−2, 0, 0) → x = (2,0,0) then project.
      Step (S, [-2.0, 0.0, 0.0]);
      P := Point (S);
      Check (Is_Simplex (P), "projected point is simplex");
      Check (Near (P (1), 1.0, 1.0E-6), "mass on first coordinate");
      Check (Near (P (2), 0.0, 1.0E-6) and then Near (P (3), 0.0, 1.0E-6),
             "other coords zero after project");
   end;

   declare
      S : State := Create (2, 0.5, Euclidean);
   begin
      Enable_Simplex_Projection (S, True);
      Enable_Simplex_Projection (S, False);
      Check (not Simplex_Projection_Enabled (S), "projection disabled");
      Step (S, [-4.0, 0.0]);
      --  No project: x = (2, 0)
      Check (Near (Point (S) (1), 2.0), "no project keeps off-simplex");
   end;

   -----------------------------------------------------------------
   Section ("Entropic Step = Hedge / MWU");
   -----------------------------------------------------------------
   declare
      S : State := Create (3, 1.0, Entropic);
      P : Vector (1 .. 3);
      --  With η=1, g=(1,0,0): w ← (e^{-1}, 1, 1)/Z
      E1 : constant Real := 0.36787944117144233;  -- exp(-1)
      Z  : constant Real := E1 + 1.0 + 1.0;
   begin
      Step (S, [1.0, 0.0, 0.0]);
      P := Point (S);
      Check (Is_Simplex (P), "after Hedge step still simplex");
      Check (Near (P (1), E1 / Z, 1.0E-9), "coord 1 shrunk by exp(-η)");
      Check (Near (P (2), 1.0 / Z, 1.0E-9), "coord 2");
      Check (Near (P (3), 1.0 / Z, 1.0E-9), "coord 3");
      Check (P (1) < P (2), "losing expert has less mass");
   end;

   declare
      S : State := Create (3, 0.5, Entropic);
   begin
      for T in 1 .. 30 loop
         Step (S, [1.0, 0.0, 0.5]);
      end loop;
      Check (Is_Simplex (Point (S)), "stays on simplex after many steps");
      Check (Point (S) (2) > Point (S) (3), "best expert has most mass");
      Check (Point (S) (3) > Point (S) (1), "medium beats worst");
      Check (Point (S) (2) > 0.8, "mass concentrates on best");
   end;

   -----------------------------------------------------------------
   Section ("Entropic linear loss demo");
   -----------------------------------------------------------------
   declare
      --  Minimize ⟨x, c⟩ over simplex; optimum is vertex of min c_i.
      C : constant Vector := [0.9, 0.1, 0.5];
      S : State := Create (3, Suggested_Eta_Entropic (3, 50), Entropic);
      Loss0, Loss1 : Real;
   begin
      Loss0 := Dot (Point (S), C);
      for T in 1 .. 50 loop
         Step (S, C);  -- subgradient of linear loss is c
      end loop;
      Loss1 := Dot (Point (S), C);
      Check (Loss1 < Loss0, "linear loss decreased");
      Check (Point (S) (2) > 0.7, "mass on argmin of c");
      Check (Near (Loss1, C (2), 0.15), "loss near optimum c_2");
   end;

   -----------------------------------------------------------------
   Section ("Dot / Norm2 / Scale / Add / Sub");
   -----------------------------------------------------------------
   declare
      A : constant Vector := [1.0, 2.0, 3.0];
      B : constant Vector := [4.0, -1.0, 0.5];
      C : Vector (1 .. 3);
   begin
      Check (Near (Dot (A, B), 1.0 * 4.0 + 2.0 * (-1.0) + 3.0 * 0.5),
             "Dot product");
      Check (Near (Norm2 (A), 3.74165738677, 1.0E-9), "Norm2 of (1,2,3)");
      Check (Near (Norm2 ([3.0, 4.0]), 5.0), "3-4-5 Norm2");
      C := Scale (2.0, A);
      Check (Near (C (1), 2.0) and then Near (C (2), 4.0)
               and then Near (C (3), 6.0), "Scale by 2");
      C := Add (A, B);
      Check (Near (C (1), 5.0) and then Near (C (2), 1.0)
               and then Near (C (3), 3.5), "Add");
      C := Sub (A, B);
      Check (Near (C (1), -3.0) and then Near (C (2), 3.0)
               and then Near (C (3), 2.5), "Sub");
      Check (Near (R (0.0), 0.0), "R view helper");
   end;

   Check (Near (1.0, 1.0 + 1.0E-12, 1.0E-9), "Near true");
   Check (not Near (1.0, 2.0, 1.0E-9), "Near false");
   Check (Vector_Near ([1.0], [1.0]),
          "Vector_Near equal");
   Check (not Vector_Near ([1.0], [2.0]),
          "Vector_Near unequal");
   Check (not Vector_Near ([1.0], [1.0, 1.0]),
          "Vector_Near length mismatch");

   -----------------------------------------------------------------
   Section ("Normalize_Simplex / Is_Simplex / Project_Simplex");
   -----------------------------------------------------------------
   declare
      X : constant Vector := [2.0, 2.0, 4.0];
      N : constant Vector := Normalize_Simplex (X);
   begin
      Check (Is_Simplex (N), "normalized is simplex");
      Check (Near (N (1), 0.25) and then Near (N (2), 0.25)
               and then Near (N (3), 0.5), "normalize ratios");
   end;

   Check (Is_Simplex ([0.5, 0.5]), "simplex (0.5,0.5)");
   Check (not Is_Simplex ([1.0, 1.0]), "not simplex sum 2");
   Check (not Is_Simplex ([-0.1, 1.1]), "negative not simplex");
   Check (Is_Simplex ([1.0]), "singleton simplex");
   Check (not Is_Simplex ([1 .. 0 => <>]), "empty not simplex");

   declare
      X : Vector := [0.5, 0.3, 0.1];  -- sum 0.9
      P : Vector (1 .. 3);
   begin
      Project_Simplex (X);
      Check (Is_Simplex (X), "in-place Project_Simplex");
      P := Project_Simplex ([5.0, -1.0, 0.0]);
      Check (Is_Simplex (P), "functional Project_Simplex");
      Check (Near (P (1), 1.0, 1.0E-6), "large positive → vertex");
   end;

   declare
      P : constant Vector :=
        Project_Simplex ([0.2, 0.2, 0.2, 0.2]);
   begin
      Check (Is_Simplex (P), "equal off-simplex projected");
      Check (Near (P (1), 0.25) and then Near (P (2), 0.25)
               and then Near (P (3), 0.25) and then Near (P (4), 0.25),
             "equal → uniform");
   end;

   declare
      P : constant Vector :=
        Project_Simplex ([-1.0, -2.0, -3.0]);
   begin
      Check (Is_Simplex (P), "all-negative projects to simplex");
      --  Largest coordinate (−1) receives all mass → vertex e_1.
      Check (Near (P (1), 1.0, 1.0E-6), "all-neg → vertex on least-negative");
      Check (Near (P (2), 0.0, 1.0E-6) and then Near (P (3), 0.0, 1.0E-6),
             "all-neg other coords zero");
   end;

   -----------------------------------------------------------------
   Section ("Bregman divergences");
   -----------------------------------------------------------------
   declare
      X : constant Vector := [1.0, 0.0];
      Y : constant Vector := [0.0, 0.0];
   begin
      declare
         BE_XY : constant Real := Bregman_Euclidean (X, Y);
         BE_XX : constant Real := Bregman_Euclidean (X, X);
         BE_YX : constant Real := Bregman_Euclidean (X => Y, Y => X);
      begin
         Check (Near (BE_XY, 0.5), "Bregman_E ½‖(1,0)‖²");
         Check (Near (BE_XX, 0.0), "Bregman_E identical 0");
         Check (Near (BE_YX, 0.5), "Bregman_E symmetric here");
      end;
   end;

   declare
      X : constant Vector := [0.5, 0.5];
      Y : constant Vector := [0.25, 0.75];
      --  KL = 0.5 ln(2) + 0.5 ln(2/3) ≈ 0.34657359028 - 0.20273255405
      --       = 0.14384103623
      KL : constant Real := 0.143841036225;
   begin
      Check (Near (Bregman_Entropy (X, Y), KL, 1.0E-8),
             "Bregman_Entropy KL value");
      Check (Near (Bregman_Entropy (X, X), 0.0, 1.0E-12),
             "Bregman_Entropy identical 0");
      Check (Bregman_Entropy (X, Y) >= 0.0, "KL non-negative");
   end;

   -----------------------------------------------------------------
   Section ("Suggested_Eta_Entropic");
   -----------------------------------------------------------------
   declare
      E : constant Real := Suggested_Eta_Entropic (2, 100);
      --  √(ln 2 / 100) ≈ 0.08326
   begin
      Check (E > 0.0, "suggested eta positive");
      Check (Near (E, 0.083257, 1.0E-4), "suggested eta ≈ √(ln2/100)");
   end;
   Check (Suggested_Eta_Entropic (Max_Dim, 1) > 0.0,
          "suggested eta Max_Dim T=1");

   -----------------------------------------------------------------
   Section ("Set_Learning_Rate");
   -----------------------------------------------------------------
   declare
      S : State := Create (2, 0.1, Euclidean);
   begin
      Set_Learning_Rate (S, 0.5);
      Check (Near (Learning_Rate (S), 0.5), "eta updated to 0.5");
      Check (Set_Eta_Raises (S, R (-1.0)), "Set_Learning_Rate rejects η<0");
      Check (Set_Eta_Raises (S, R (0.0)), "Set_Learning_Rate rejects η=0");
   end;

   -----------------------------------------------------------------
   Section ("Invalid_Argument guards");
   -----------------------------------------------------------------
   Check (Create_Raises (2, R (0.0), Euclidean), "Create rejects η=0");
   Check (Create_Raises (2, R (-0.1), Entropic), "Create rejects η<0");
   Check (Create_Initial_Raises (0.1, [1 .. 0 => <>], Euclidean),
          "Create rejects empty initial");
   Check (Create_Initial_Raises
            (0.1, [-1.0, 2.0], Entropic),
          "Create entropic rejects negative");

   declare
      S : State := Create (2, 0.1, Euclidean);
   begin
      Check (Step_Raises (S, [1.0]), "Step rejects short gradient");
      Check (Step_Raises (S, [1.0, 2.0, 3.0]),
             "Step rejects long gradient");
   end;

   declare
      S : State := Create (2, 0.1, Entropic);
   begin
      Check (Step_Raises (S, [1.0]), "Entropic Step length check");
      Check (Reset_Initial_Raises (S, [0.5]),
             "Reset rejects wrong length");
      Check (Reset_Initial_Raises
               (S, [-0.1, 1.1]),
             "Reset entropic rejects negative");
   end;

   Check (Dot_Raises ([1.0], [1.0, 2.0]),
          "Dot length mismatch");
   Check (Dot_Raises ([1 .. 0 => <>], [1 .. 0 => <>]),
          "Dot empty");
   Check (Norm2_Raises ([1 .. 0 => <>]), "Norm2 empty");
   Check (Normalize_Raises ([0.0, 0.0]),
          "Normalize rejects zero sum");
   Check (Normalize_Raises ([-1.0, -1.0]),
          "Normalize rejects negative sum");
   Check (Bregman_E_Raises ([1.0], [1.0, 2.0]),
          "Bregman_E length mismatch");
   Check (Bregman_H_Raises ([0.0, 1.0],
                            [0.5, 0.5]),
          "Bregman_H rejects zero entry");
   Check (Bregman_H_Raises ([0.5], [0.5, 0.5]),
          "Bregman_H length mismatch");

   -----------------------------------------------------------------
   Section ("Iterate subtype alias");
   -----------------------------------------------------------------
   declare
      S : Iterate := Create (2, 0.1, Euclidean);
   begin
      Check (Dimension_Of (S) = 2, "Iterate works as State");
      Step (S, [1.0, 1.0]);
      Check (Rounds (S) = 1, "Iterate Step increments rounds");
   end;

   -----------------------------------------------------------------
   Section ("Many Euclidean dimensions");
   -----------------------------------------------------------------
   declare
      D : constant Dimension := 8;
      S : State := Create (D, 0.1, Euclidean);
      G : Vector (1 .. D) := [others => 0.0];
      P : Vector (1 .. D);
   begin
      for I in 1 .. D loop
         G (I) := Real (I);
      end loop;
      Step (S, G);
      P := Point (S);
      for I in 1 .. D loop
         Check (Near (P (I), -0.1 * Real (I)),
                "Euclidean multi-dim coord" & Integer'Image (I));
      end loop;
   end;

   -----------------------------------------------------------------
   Section ("Entropic Max_Dim smoke");
   -----------------------------------------------------------------
   declare
      S : State := Create (Max_Dim, 0.01, Entropic);
      G : Vector (1 .. Max_Dim) := [others => 0.0];
   begin
      Check (Is_Simplex (Point (S)), "Max_Dim uniform simplex");
      G (1) := 1.0;
      Step (S, G);
      Check (Is_Simplex (Point (S)), "Max_Dim still simplex after step");
      Check (Point (S) (1) < Point (S) (2), "Max_Dim coord1 shrunk");
      Check (Rounds (S) = 1, "Max_Dim rounds 1");
   end;

   -----------------------------------------------------------------
   Section ("Projection idempotence / already-simplex");
   -----------------------------------------------------------------
   declare
      X : constant Vector (1 .. 3) := [0.1, 0.2, 0.7];
      Y : Vector (1 .. 3);
   begin
      Check (Is_Simplex (X), "already simplex");
      Y := Project_Simplex (X);
      Check (Vector_Near (X, Y, 1.0E-9), "project of simplex ≈ identity");
   end;

   -----------------------------------------------------------------
   Section ("Bregman decreases along Euclidean GD");
   -----------------------------------------------------------------
   declare
      Star : constant Vector := [2.0, -1.0];
      S    : State :=
        Create (0.2, [0.0, 0.0], Euclidean);
      B0, B1 : Real;
   begin
      B0 := Bregman_Euclidean (Point (S), Star);
      for T in 1 .. 20 loop
         Step (S, Sub (Point (S), Star));
      end loop;
      B1 := Bregman_Euclidean (Point (S), Star);
      Check (B1 < B0, "Bregman_E to star decreases under GD");
      Check (B1 < 0.01, "Bregman_E small after GD");
   end;

   -----------------------------------------------------------------
   Section ("Entropic Bregman / concentration");
   -----------------------------------------------------------------
   declare
      Uniform : constant Vector := [1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0];
      S       : State := Create (3, 0.4, Entropic);
      Loss0, Loss1 : Real;
      C : constant Vector := [1.0, 0.0, 1.0];
      KL_From_Start : Real;
   begin
      Loss0 := Dot (Point (S), C);
      for T in 1 .. 40 loop
         --  Push toward expert 2 via losses on 1 and 3.
         Step (S, C);
      end loop;
      Loss1 := Dot (Point (S), C);
      KL_From_Start := Bregman_Entropy (Point (S), Uniform);
      Check (Loss1 < Loss0, "linear loss decreases under entropic MD");
      Check (KL_From_Start > 0.5, "KL(x || uniform) grows with concentration");
      Check (Point (S) (2) > 0.85, "entropic concentrated on 2");
   end;

   -----------------------------------------------------------------
   Section ("Near / helper edge cases");
   -----------------------------------------------------------------
   Check (Near (0.0, 0.0), "Near zeros");
   Check (Near (-1.0, -1.0 + 1.0E-12), "Near negatives");
   Check (not Near (-1.0, 1.0), "Near opposite signs");
   Check (Is_Simplex (Normalize_Simplex ([7.0])),
          "normalize singleton");
   Check (Near (Norm2 (Scale (0.0, [3.0, 4.0])), 0.0),
          "scale by zero");
   Check (Near (Dot ([1.0], [0.0]), 0.0),
          "dot with zero");

   -----------------------------------------------------------------
   Section ("Multiple resets and eta changes mid-run");
   -----------------------------------------------------------------
   declare
      S : State := Create (2, 1.0, Euclidean);
   begin
      Step (S, [1.0, 1.0]);
      Set_Learning_Rate (S, 0.1);
      Step (S, [1.0, 1.0]);
      --  x = (0,0) -1*(1,1) = (-1,-1); then -0.1*(1,1) → (-1.1,-1.1)
      Check (Near (Point (S) (1), -1.1) and then Near (Point (S) (2), -1.1),
             "eta change mid-run");
      Reset (S, [5.0, -5.0]);
      Check (Rounds (S) = 0, "reset after mid-run");
      Check (Near (Learning_Rate (S), 0.1), "eta survives Reset");
      Check (Near (Point (S) (1), 5.0), "custom reset point");
   end;

   -----------------------------------------------------------------
   Section ("Constants");
   -----------------------------------------------------------------
   Check (Max_Dim = Pos (64), "Max_Dim = 64");
   Check (Nat_View (Max_Dim) = 64, "Max_Dim via Nat_View");
   Check (Geometry'Pos (Euclidean) = 0, "Euclidean enum pos");
   Check (Geometry'Pos (Entropic) = 1, "Entropic enum pos");

   -----------------------------------------------------------------
   Section ("Tiny eta barely moves");
   -----------------------------------------------------------------
   declare
      S : State := Create (2, 1.0E-8, Euclidean);
   begin
      Step (S, [1.0, -1.0]);
      Check (Near (Point (S) (1), 0.0, 1.0E-6), "tiny eta Euclidean ~stay");
   end;
   declare
      S : State := Create (2, 1.0E-8, Entropic);
      P0, P1 : Vector (1 .. 2);
   begin
      P0 := Point (S);
      Step (S, [1.0, 0.0]);
      P1 := Point (S);
      Check (Vector_Near (P0, P1, 1.0E-6), "tiny eta Entropic ~stay");
   end;

   -----------------------------------------------------------------
   Section ("Large eta Euclidean overshoots then recovers");
   -----------------------------------------------------------------
   declare
      Star : constant Vector := [0.0, 0.0];
      S    : State :=
        Create (1.5, [1.0, 1.0], Euclidean);
      --  η=1.5 on ∇=x−0: x ← x − 1.5 x = −0.5 x (overshoot past origin)
   begin
      Step (S, Sub (Point (S), Star));
      Check (Near (Point (S) (1), -0.5) and then Near (Point (S) (2), -0.5),
             "large eta overshoots");
      Step (S, Sub (Point (S), Star));
      Check (Near (Point (S) (1), 0.25) and then Near (Point (S) (2), 0.25),
             "next step recovers toward 0");
   end;

   -----------------------------------------------------------------
   Section ("Project_Simplex random-ish vectors");
   -----------------------------------------------------------------
   declare
      Cases : constant array (1 .. 6) of Vector (1 .. 3) :=
        [[1.0, 0.0, 0.0],
         [0.0, 0.0, 0.0],
         [10.0, 10.0, 10.0],
         [-5.0, 0.5, 0.5],
         [0.9, 0.05, 0.05],
         [100.0, -50.0, -50.0]];
      P : Vector (1 .. 3);
   begin
      for K in Cases'Range loop
         P := Project_Simplex (Cases (K));
         Check (Is_Simplex (P, 1.0E-8),
                "Project_Simplex case" & Integer'Image (K));
      end loop;
   end;

   -----------------------------------------------------------------
   Section ("Euclidean projected GD on simplex quadratic");
   -----------------------------------------------------------------
   declare
      --  Minimize ½‖x − t‖² over simplex; t outside → projects toward
      --  nearest simplex point.
      Target : constant Vector := [2.0, 0.0, 0.0];
      S      : State := Create (3, 0.2, Euclidean);
      P      : Vector (1 .. 3);
   begin
      Enable_Simplex_Projection (S, True);
      Reset (S, [1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0]);
      for T in 1 .. 60 loop
         Step (S, Sub (Point (S), Target));
      end loop;
      P := Point (S);
      Check (Is_Simplex (P), "projected GD stays on simplex");
      Check (P (1) > 0.9, "projected GD → vertex near target");
   end;

   -----------------------------------------------------------------
   -- Summary
   -----------------------------------------------------------------
   New_Line;
   Put_Line ("========================================");
   Put_Line ("PASS:" & Natural'Image (Pass_Count));
   Put_Line ("FAIL:" & Natural'Image (Fail_Count));
   Put_Line ("========================================");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
