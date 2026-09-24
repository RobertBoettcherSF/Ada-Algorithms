--  Standalone test suite for Sinkhorn_Knopp_Algorithm (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Sinkhorn_Knopp_Algorithm; use Sinkhorn_Knopp_Algorithm;

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

   function Raised_Invalid (Thunk_Label : String) return Boolean;
   --  Placeholder; each raise site checked inline below.

   pragma Unreferenced (Raised_Invalid);

   function Raised_Invalid (Thunk_Label : String) return Boolean is
   begin
      pragma Unreferenced (Thunk_Label);
      return False;
   end Raised_Invalid;

begin
   Ada.Text_IO.Put_Line ("Sinkhorn_Knopp_Algorithm test suite");
   Ada.Text_IO.Put_Line ("===================================");

   ---------------------------------------------------------------------
   Section ("1. Predicates: square / near / nonnegative / positive");
   ---------------------------------------------------------------------
   declare
      Sq  : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 2.0], [3.0, 4.0]];
      Rec : constant Matrix (1 .. 2, 1 .. 3) :=
        [[0.1, 0.2, 0.7], [0.3, 0.4, 0.3]];
      Neg : constant Matrix (1 .. 2, 1 .. 2) :=
        [[0.5, 0.5], [0.5, -0.1]];
      Zrow : constant Matrix (1 .. 2, 1 .. 2) :=
        [[0.0, 0.0], [1.0, 1.0]];
      Empty : Matrix (1 .. 0, 1 .. 0);
   begin
      Check (Is_Square (Sq), "Is_Square 2x2");
      Check (not Is_Square (Rec), "Is_Square rejects 2x3");
      Check (Is_Square (Empty), "Is_Square empty");
      Check (Near (1.0, 1.0 + Zero_Tol / 2.0), "Near true");
      Check (not Near (1.0, 2.0), "Near false");
      Check (Is_Nonnegative (Sq), "Is_Nonnegative positive");
      Check (not Is_Nonnegative (Neg), "Is_Nonnegative rejects neg");
      Check (Is_Nonnegative (Zrow), "Is_Nonnegative zero row ok");
      Check (Is_Strictly_Positive (Sq), "Is_Strictly_Positive 2x2");
      Check (not Is_Strictly_Positive (Zrow), "Strict rejects zeros");
      Check (Is_Strictly_Positive (Empty), "Strict empty vacuous");
      Check (Has_Positive_Row_Sums (Sq), "Has_Positive_Row_Sums");
      Check (not Has_Positive_Row_Sums (Zrow), "Rejects zero row sums");
      Check (Has_Positive_Col_Sums (Sq), "Has_Positive_Col_Sums");
      Check (Near (Row_Sum (Sq, 1), 3.0), "Row_Sum 1");
      Check (Near (Col_Sum (Sq, 2), 6.0), "Col_Sum 2");
   end;

   ---------------------------------------------------------------------
   Section ("2. Row_Sums / Col_Sums / Ones_Vector / residual");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 2.0], [3.0, 4.0]];
      RS : constant Vector := Row_Sums (A);
      CS : constant Vector := Col_Sums (A);
      O1 : constant Vector := Ones_Vector (3);
      O0 : constant Vector := Ones_Vector (0);
      RT : constant Vector := [1.0, 1.0];
      CT : constant Vector := [1.0, 1.0];
   begin
      Check (RS'Length = 2 and then Near (RS (1), 3.0)
             and then Near (RS (2), 7.0),
             "Row_Sums values");
      Check (CS'Length = 2 and then Near (CS (1), 4.0)
             and then Near (CS (2), 6.0),
             "Col_Sums values");
      Check (O1'Length = 3 and then Near (O1 (1), 1.0)
             and then Near (O1 (3), 1.0),
             "Ones_Vector length 3");
      Check (O0'Length = 0, "Ones_Vector empty");
      Check (Max_Marginal_Residual (A, RT, CT) > 1.0,
             "Residual of unscaled Example_2x2 large");
   end;

   ---------------------------------------------------------------------
   Section ("3. Constructors: Ones / Identity / Uniform / Toy / Hilbert");
   ---------------------------------------------------------------------
   for N in Dimension range 1 .. 8 loop
      declare
         O  : constant Matrix := Ones_Matrix (N);
         I  : constant Matrix := Identity (N);
         U  : constant Matrix := Uniform (N);
         T  : constant Matrix := Positive_Toy (N);
         H  : constant Matrix := Hilbert_Like (N);
         K  : constant Matrix := Transportation_Kernel (N, 4.0);
      begin
         Check (Is_Strictly_Positive (O),
                "Ones positive n=" & Dimension'Image (N));
         Check (Is_Nearly_Doubly_Stochastic (I),
                "Identity nearly DS n=" & Dimension'Image (N));
         Check (Is_Nearly_Doubly_Stochastic (U),
                "Uniform nearly DS n=" & Dimension'Image (N));
         Check (Is_Strictly_Positive (T),
                "Positive_Toy n=" & Dimension'Image (N));
         Check (Is_Strictly_Positive (H),
                "Hilbert_Like n=" & Dimension'Image (N));
         Check (Is_Strictly_Positive (K),
                "Transport kernel n=" & Dimension'Image (N));
         Check (Near (O (1, 1), 1.0),
                "Ones entry n=" & Dimension'Image (N));
         Check (Near (U (1, 1), 1.0 / Real (N)),
                "Uniform entry n=" & Dimension'Image (N));
         Check (Near (H (1, 1), 1.0),
                "Hilbert (1,1)=1 n=" & Dimension'Image (N));
         Check (Near (K (1, 1), 1.0),
                "Kernel diag ~1 n=" & Dimension'Image (N));
      end;
   end loop;

   declare
      Z0 : constant Matrix := Zero_Matrix (0);
      Z2 : constant Matrix := Zero_Matrix (2);
      E2 : constant Matrix := Example_2x2;
      E3 : constant Matrix := Example_3x3;
   begin
      Check (Z0'Length (1) = 0, "Zero_Matrix empty");
      Check (Near (Z2 (1, 1), 0.0) and then Near (Z2 (2, 2), 0.0),
             "Zero_Matrix 2x2");
      Check (Near (E2 (1, 2), 2.0) and then Near (E2 (2, 1), 3.0),
             "Example_2x2 entries");
      Check (Near (E3 (3, 3), 9.0) and then Is_Strictly_Positive (E3),
             "Example_3x3 entries");
   end;

   ---------------------------------------------------------------------
   Section ("4. Scale / Add / Matrices_Near / Frobenius");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) := [[1.0, 2.0], [3.0, 4.0]];
      B : constant Matrix (1 .. 2, 1 .. 2) := [[0.5, 0.5], [0.5, 0.5]];
      S : constant Matrix := Scale (A, 2.0);
      C : constant Matrix := Add (A, B);
   begin
      Check (Near (S (1, 1), 2.0) and then Near (S (2, 2), 8.0),
             "Scale *2");
      Check (Near (C (1, 1), 1.5) and then Near (C (2, 2), 4.5), "Add");
      Check (Matrices_Near (A, A), "Matrices_Near self");
      Check (not Matrices_Near (A, B), "Matrices_Near distinct");
      Check (Near (Frobenius_Distance (A, A), 0.0), "Frobenius self 0");
      Check (Frobenius_Distance (A, B) > 1.0, "Frobenius A-B > 1");
   end;

   ---------------------------------------------------------------------
   Section ("5. Normalize_Rows / Normalize_Columns");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix := Example_2x2;
      NR : constant Matrix := Normalize_Rows (A);
      NC : constant Matrix := Normalize_Columns (A);
      RT : constant Vector := [2.0, 3.0];
      CT : constant Vector := [1.5, 2.5];
      NRT : constant Matrix := Normalize_Rows (A, RT);
      NCT : constant Matrix := Normalize_Columns (A, CT);
   begin
      Check (Near (Row_Sum (NR, 1), 1.0) and then Near (Row_Sum (NR, 2), 1.0),
             "Normalize_Rows sums to 1");
      Check (Near (Col_Sum (NC, 1), 1.0) and then Near (Col_Sum (NC, 2), 1.0),
             "Normalize_Columns sums to 1");
      Check (Near (Row_Sum (NRT, 1), 2.0) and then Near (Row_Sum (NRT, 2), 3.0),
             "Normalize_Rows with targets");
      Check (Near (Col_Sum (NCT, 1), 1.5) and then Near (Col_Sum (NCT, 2), 2.5),
             "Normalize_Columns with targets");
      Check (Is_Nonnegative (NR) and then Is_Nonnegative (NC),
             "Normalized stay nonnegative");
   end;

   --  Raise paths for Normalize
   declare
      Neg : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0], [1.0, -0.5]];
      Zrow : constant Matrix (1 .. 2, 1 .. 2) :=
        [[0.0, 0.0], [1.0, 1.0]];
      Empty : Matrix (1 .. 0, 1 .. 0);
      Ok : Boolean;
   begin
      Ok := False;
      begin
         declare
            Dummy : constant Matrix := Normalize_Rows (Neg);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Ok := True;
      end;
      Check (Ok, "Normalize_Rows rejects negative");

      Ok := False;
      begin
         declare
            Dummy : constant Matrix := Normalize_Rows (Zrow);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Ok := True;
      end;
      Check (Ok, "Normalize_Rows rejects zero row");

      Ok := False;
      begin
         declare
            Dummy : constant Matrix := Normalize_Rows (Empty);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Ok := True;
      end;
      Check (Ok, "Normalize_Rows rejects empty");

      Ok := False;
      begin
         declare
            Dummy : constant Matrix :=
              Normalize_Columns (Matrix'([[0.0, 1.0], [0.0, 1.0]]));
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Ok := True;
      end;
      Check (Ok, "Normalize_Columns rejects zero column");

      Ok := False;
      begin
         declare
            Dummy : constant Matrix :=
              Normalize_Rows (Example_2x2, Vector'([-1.0, 1.0]));
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Ok := True;
      end;
      Check (Ok, "Normalize_Rows rejects nonpositive target");
   end;

   ---------------------------------------------------------------------
   Section ("6. Iterate fixed steps");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix := Example_2x2;
      I0 : constant Matrix := Iterate (A, 0);
      I1 : constant Matrix := Iterate (A, 1);
      I5 : constant Matrix := Iterate (A, 5);
      I20 : constant Matrix := Iterate (A, 20);
   begin
      Check (Matrices_Near (I0, A, Zero_Tol), "Iterate 0 is copy");
      Check (Near (Row_Sum (I1, 1), 1.0, 1.0E-9)
             or else Near (Col_Sum (I1, 1), 1.0, 1.0E-9),
             "Iterate 1 touches margins");
      Check (Is_Nonnegative (I5), "Iterate 5 nonnegative");
      Check (Max_Marginal_Residual
               (I20, Ones_Vector (2), Ones_Vector (2)) < 1.0E-6,
             "Iterate 20 residual small on 2x2");
   end;

   for N in Dimension range 2 .. 6 loop
      declare
         T  : constant Matrix := Positive_Toy (N);
         It : constant Matrix := Iterate (T, 50);
         R  : constant Real :=
           Max_Marginal_Residual
             (It, Ones_Vector (N), Ones_Vector (N));
      begin
         Check (R < 1.0E-8,
                "Iterate 50 residual n=" & Dimension'Image (N));
         Check (Is_Nearly_Doubly_Stochastic (It, 1.0E-7),
                "Iterate 50 nearly DS n=" & Dimension'Image (N));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("7. Solve → doubly stochastic");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Example_2x2;
      R : constant Sinkhorn_Result := Solve (A);
      S : constant Matrix := Scaled_Matrix (R);
   begin
      Check (R.Converged, "Solve 2x2 converged");
      Check (R.Rows = 2 and then R.Cols = 2, "Solve 2x2 shape");
      Check (R.Residual <= Default_Eps, "Solve 2x2 residual ≤ eps");
      Check (Is_Nearly_Doubly_Stochastic (S), "Solve 2x2 nearly DS");
      Check (R.Iterations >= 1, "Solve 2x2 used iterations");
   end;

   declare
      A : constant Matrix := Example_3x3;
      R : constant Sinkhorn_Result := Solve (A);
      S : constant Matrix := Scaled_Matrix (R);
   begin
      Check (R.Converged, "Solve 3x3 converged");
      Check (Is_Nearly_Doubly_Stochastic (S, 1.0E-8),
             "Solve 3x3 nearly DS");
   end;

   for N in Dimension range 1 .. 10 loop
      declare
         T : constant Matrix := Positive_Toy (N);
         H : constant Matrix := Hilbert_Like (N);
         O : constant Matrix := Ones_Matrix (N);
         RT : constant Sinkhorn_Result := Solve (T);
         RH : constant Sinkhorn_Result := Solve (H);
         RO : constant Sinkhorn_Result := Solve (O);
      begin
         Check (RT.Converged and then
                Is_Nearly_Doubly_Stochastic (Scaled_Matrix (RT), 1.0E-8),
                "Solve Positive_Toy DS n=" & Dimension'Image (N));
         Check (RH.Converged and then
                Is_Nearly_Doubly_Stochastic (Scaled_Matrix (RH), 1.0E-8),
                "Solve Hilbert DS n=" & Dimension'Image (N));
         Check (RO.Converged and then
                Is_Nearly_Doubly_Stochastic (Scaled_Matrix (RO), 1.0E-8),
                "Solve Ones DS n=" & Dimension'Image (N));
         --  Ones → Uniform
         Check (Matrices_Near
                  (Scaled_Matrix (RO), Uniform (N), 1.0E-8),
                "Ones Sinkhorn → Uniform n=" & Dimension'Image (N));
      end;
   end loop;

   --  Already DS converges immediately or in few steps
   declare
      U : constant Matrix := Uniform (4);
      R : constant Sinkhorn_Result := Solve (U);
   begin
      Check (R.Converged, "Uniform Solve converged");
      Check (R.Residual <= Default_Eps, "Uniform residual tiny");
      Check (R.Iterations = 0 or else R.Iterations <= 2,
             "Uniform few iterations");
   end;

   --  Identity is DS (permutation) — Solve should accept and keep DS
   declare
      I : constant Matrix := Identity (3);
      R : constant Sinkhorn_Result := Solve (I);
   begin
      Check (R.Converged, "Identity Solve converged");
      Check (Is_Nearly_Doubly_Stochastic (Scaled_Matrix (R)),
             "Identity stays DS");
   end;

   ---------------------------------------------------------------------
   Section ("8. Scale vectors D1 A D2 ≈ Scaled");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Positive_Toy (4);
      R : constant Sinkhorn_Result := Solve (A);
      S : constant Matrix := Scaled_Matrix (R);
      Rebuilt : Matrix (1 .. 4, 1 .. 4);
   begin
      for I in 1 .. 4 loop
         for J in 1 .. 4 loop
            Rebuilt (I, J) :=
              R.Row_Scale (I) * A (I, J) * R.Col_Scale (J);
         end loop;
      end loop;
      Check (Matrices_Near (S, Rebuilt, 1.0E-8),
             "Scaled = diag(D1) A diag(D2)");
      Check (R.Row_Scale (1) > 0.0 and then R.Col_Scale (1) > 0.0,
             "Scale factors positive");
   end;

   for N in Dimension range 2 .. 7 loop
      declare
         A : constant Matrix := Hilbert_Like (N);
         R : constant Sinkhorn_Result := Solve (A);
         S : constant Matrix := Scaled_Matrix (R);
         Rebuilt : Matrix (1 .. N, 1 .. N);
         Ok : Boolean := True;
      begin
         for I in 1 .. N loop
            for J in 1 .. N loop
               Rebuilt (I, J) :=
                 R.Row_Scale (I) * A (I, J) * R.Col_Scale (J);
            end loop;
         end loop;
         Ok := Matrices_Near (S, Rebuilt, 1.0E-7);
         Check (Ok, "D1 A D2 n=" & Dimension'Image (N));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("9. Prescribed marginals / rectangular");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix := Example_2x2;
      RT : constant Vector := [0.4, 0.6];
      CT : constant Vector := [0.3, 0.7];
      R  : constant Sinkhorn_Result := Solve (A, RT, CT);
      S  : constant Matrix := Scaled_Matrix (R);
   begin
      Check (R.Converged, "Marginal Solve 2x2 converged");
      Check (Near (Row_Sum (S, 1), 0.4, 1.0E-8)
             and then Near (Row_Sum (S, 2), 0.6, 1.0E-8),
             "Row marginals matched");
      Check (Near (Col_Sum (S, 1), 0.3, 1.0E-8)
             and then Near (Col_Sum (S, 2), 0.7, 1.0E-8),
             "Col marginals matched");
   end;

   declare
      --  2×3 nonnegative with positive support
      A  : constant Matrix (1 .. 2, 1 .. 3) :=
        [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]];
      RT : constant Vector := [0.5, 0.5];
      CT : constant Vector := [0.2, 0.3, 0.5];
      R  : constant Sinkhorn_Result := Solve (A, RT, CT);
      S  : constant Matrix := Scaled_Matrix (R);
   begin
      Check (R.Converged, "Rectangular 2x3 converged");
      Check (R.Rows = 2 and then R.Cols = 3, "Rectangular shape");
      Check (Near (Row_Sum (S, 1), 0.5, 1.0E-8)
             and then Near (Row_Sum (S, 2), 0.5, 1.0E-8),
             "Rect row marginals");
      Check (Near (Col_Sum (S, 1), 0.2, 1.0E-8)
             and then Near (Col_Sum (S, 2), 0.3, 1.0E-8)
             and then Near (Col_Sum (S, 3), 0.5, 1.0E-8),
             "Rect col marginals");
   end;

   declare
      A  : constant Matrix := Transportation_Kernel (5, 0.5);
      RT : constant Vector := Ones_Vector (5, 1.0 / 5.0);
      CT : constant Vector := Ones_Vector (5, 1.0 / 5.0);
      --  Note: all-ones/5 is uniform marginals summing to 1 each? No —
      --  each target is 0.2, five of them sum to 1 — good for a coupling.
      R  : constant Sinkhorn_Result := Solve (A, RT, CT);
      S  : constant Matrix := Scaled_Matrix (R);
   begin
      Check (R.Converged, "Transport kernel marginal Solve");
      Check (Max_Marginal_Residual (S, RT, CT) <= Default_Eps * 10.0,
             "Transport residual OK");
   end;

   declare
      A  : constant Matrix := Positive_Toy (3);
      RT : constant Vector := [1.0, 2.0, 3.0];
      CT : constant Vector := [2.0, 2.0, 2.0];
      It : constant Matrix := Iterate (A, 40, RT, CT);
   begin
      Check (Max_Marginal_Residual (It, RT, CT) < 1.0E-6,
             "Iterate with unequal marginals");
   end;

   ---------------------------------------------------------------------
   Section ("10. Invalid_Argument paths for Solve");
   ---------------------------------------------------------------------
   declare
      Ok : Boolean;
      Empty : Matrix (1 .. 0, 1 .. 0);
      Neg : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0], [1.0, -1.0]];
      Rec : constant Matrix (1 .. 2, 1 .. 3) :=
        [[1.0, 1.0, 1.0], [1.0, 1.0, 1.0]];
      Zrow : constant Matrix (1 .. 2, 1 .. 2) :=
        [[0.0, 0.0], [1.0, 2.0]];
   begin
      Ok := False;
      begin
         declare
            Dummy : constant Sinkhorn_Result := Solve (Empty);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Ok := True;
      end;
      Check (Ok, "Solve rejects empty");

      Ok := False;
      begin
         declare
            Dummy : constant Sinkhorn_Result := Solve (Neg);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Ok := True;
      end;
      Check (Ok, "Solve rejects negative");

      Ok := False;
      begin
         declare
            Dummy : constant Sinkhorn_Result := Solve (Rec);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Ok := True;
      end;
      Check (Ok, "Solve DS rejects rectangular");

      Ok := False;
      begin
         declare
            Dummy : constant Sinkhorn_Result := Solve (Zrow);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Ok := True;
      end;
      Check (Ok, "Solve rejects zero row");

      Ok := False;
      begin
         declare
            Dummy : constant Sinkhorn_Result :=
              Solve (Example_2x2, Vector'([-1.0, 1.0]), Ones_Vector (2));
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Ok := True;
      end;
      Check (Ok, "Solve rejects nonpositive row target");
   end;

   ---------------------------------------------------------------------
   Section ("11. Epsilon / Max_Iter behaviour");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Positive_Toy (5);
      Loose : constant Sinkhorn_Result :=
        Solve (A, Epsilon => 1.0E-3, Max_Iter => 10_000);
      Tight : constant Sinkhorn_Result :=
        Solve (A, Epsilon => 1.0E-12, Max_Iter => 10_000);
      Cap  : constant Sinkhorn_Result :=
        Solve (A, Epsilon => 1.0E-30, Max_Iter => 3);
   begin
      Check (Loose.Converged, "Loose eps converged");
      Check (Tight.Converged, "Tight eps converged");
      Check (Loose.Iterations <= Tight.Iterations,
             "Loose needs ≤ tight iterations");
      Check (Cap.Iterations = 3, "Max_Iter cap respected");
      Check (not Cap.Converged or else Cap.Residual <= 1.0E-30,
             "Tiny eps may not converge in 3 iters");
   end;

   ---------------------------------------------------------------------
   Section ("12. Is_Nearly_Doubly_Stochastic edge cases");
   ---------------------------------------------------------------------
   declare
      Empty : Matrix (1 .. 0, 1 .. 0);
      Bad_Sum : constant Matrix (1 .. 2, 1 .. 2) :=
        [[0.6, 0.6], [0.4, 0.4]];
      Rec : constant Matrix (1 .. 2, 1 .. 3) :=
        [[0.5, 0.5, 0.0], [0.5, 0.5, 0.0]];
   begin
      Check (Is_Nearly_Doubly_Stochastic (Empty), "DS empty");
      Check (not Is_Nearly_Doubly_Stochastic (Bad_Sum), "DS bad sums");
      Check (not Is_Nearly_Doubly_Stochastic (Rec), "DS rejects rect");
      Check (Is_Nearly_Doubly_Stochastic (Uniform (1)), "DS 1x1");
      Check (Is_Nearly_Doubly_Stochastic (Identity (5)), "DS Identity 5");
   end;

   ---------------------------------------------------------------------
   Section ("13. Larger classroom sizes (n up to 16)");
   ---------------------------------------------------------------------
   for N in Dimension range 11 .. 16 loop
      declare
         T : constant Matrix := Positive_Toy (N);
         R : constant Sinkhorn_Result :=
           Solve (T, Epsilon => 1.0E-9, Max_Iter => 5_000);
      begin
         Check (R.Converged,
                "Solve converged n=" & Dimension'Image (N));
         Check (Is_Nearly_Doubly_Stochastic
                  (Scaled_Matrix (R), 1.0E-7),
                "Nearly DS n=" & Dimension'Image (N));
      end;
   end loop;

   for N in Dimension range 2 .. 8 loop
      declare
         K : constant Matrix := Transportation_Kernel (N, 0.75);
         R : constant Sinkhorn_Result := Solve (K);
      begin
         Check (R.Converged and then
                Is_Nearly_Doubly_Stochastic (Scaled_Matrix (R), 1.0E-7),
                "Transport→DS n=" & Dimension'Image (N));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("14. Consistency: Iterate vs Solve");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Hilbert_Like (4);
      R : constant Sinkhorn_Result :=
        Solve (A, Epsilon => 1.0E-12, Max_Iter => 2_000);
      It : constant Matrix := Iterate (A, Natural'Max (R.Iterations, 1));
   begin
      Check (R.Converged, "Consistency Solve converged");
      --  After the same number of full pairs, residuals should be comparable
      Check (Max_Marginal_Residual
               (It, Ones_Vector (4), Ones_Vector (4)) < 1.0E-6
             or else Matrices_Near
               (Scaled_Matrix (R), It, 1.0E-4),
             "Iterate ~ Solve after similar steps");
   end;

   --  Row then column once equals Iterate(_, 1)
   declare
      A : constant Matrix := Example_3x3;
      Manual : constant Matrix :=
        Normalize_Columns (Normalize_Rows (A));
      Auto : constant Matrix := Iterate (A, 1);
   begin
      Check (Matrices_Near (Manual, Auto, 1.0E-12),
             "Iterate 1 = NormCols(NormRows)");
   end;

   ---------------------------------------------------------------------
   Section ("15. Extra positive toys / scale positivity");
   ---------------------------------------------------------------------
   for N in Dimension range 1 .. 5 loop
      declare
         A : constant Matrix :=
           Add (Positive_Toy (N), Scale (Ones_Matrix (N), 0.1));
         R : constant Sinkhorn_Result := Solve (A);
         S : constant Matrix := Scaled_Matrix (R);
         Pos_Scales : Boolean := True;
      begin
         Check (R.Converged, "Perturbed toy Solve n="
                & Dimension'Image (N));
         for I in 1 .. N loop
            if R.Row_Scale (I) <= 0.0 or else R.Col_Scale (I) <= 0.0 then
               Pos_Scales := False;
            end if;
            for J in 1 .. N loop
               if S (I, J) < -Zero_Tol then
                  Pos_Scales := False;
               end if;
            end loop;
         end loop;
         Check (Pos_Scales, "Positive scales+entries n="
                & Dimension'Image (N));
      end;
   end loop;

   --  Summary
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line (
     "Results: " & Natural'Image (Pass_Count) & " PASS,"
     & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
