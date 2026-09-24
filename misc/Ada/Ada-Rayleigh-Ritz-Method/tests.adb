--  Standalone test suite for Rayleigh_Ritz_Method (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Rayleigh_Ritz_Method; use Rayleigh_Ritz_Method;

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

   function Matches_Spectrum
     (Got : Small_Vector;
      K   : Dim_K;
      Exp : Small_Vector;
      Tol : Real := 1.0E-6) return Boolean
   is
      Used : array (1 .. Max_K) of Boolean := [others => False];
   begin
      for I in 1 .. K loop
         declare
            Found : Boolean := False;
         begin
            for J in 1 .. K loop
               if not Used (J)
                 and then abs (Got (Index_K (I)) - Exp (Index_K (J))) <= Tol
               then
                  Used (J) := True;
                  Found := True;
                  exit;
               end if;
            end loop;
            if not Found then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Matches_Spectrum;

begin
   Put_Line ("Rayleigh_Ritz_Method test suite");
   Put_Line ("===============================");

   ---------------------------------------------------------------------
   Section ("1. Helpers: Near / Dot / Norm / Scale / Axpy");
   ---------------------------------------------------------------------
   declare
      X : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      Y : constant Vector (1 .. 3) := [4.0, 5.0, 6.0];
      Z : Vector (1 .. 3);
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (not Near (1.0, 2.0), "Near far");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (Approx (Dot (X, Y), 32.0, 1.0E-12), "Dot product");
      Check (Approx (Real (Norm2 (X)), 14.0, 1.0E-12), "Norm2");
      Check (Approx (Real (Norm (X)), 3.74165738677, 1.0E-8), "Norm");
      Z := X;
      Scale (Z, 2.0);
      Check (Approx (Z (1), 2.0) and then Approx (Z (2), 4.0)
               and then Approx (Z (3), 6.0),
             "Scale *2");
      Z := Y;
      Axpy (Z, 1.0, X);
      Check (Approx (Z (1), 5.0) and then Approx (Z (2), 7.0)
               and then Approx (Z (3), 9.0),
             "Axpy");
      Check (Approx (Real (Norm ([Real'(0.0), 0.0])), 0.0), "Norm zero");
   end;

   ---------------------------------------------------------------------
   Section ("2. Identity / Zero / Mat_Vec / Residual");
   ---------------------------------------------------------------------
   declare
      I3 : constant Matrix := Identity (3);
      Z3 : constant Matrix := Zero_Matrix (3);
      X  : constant Vector (1 .. 3) := [1.0, -2.0, 0.5];
      Y  : constant Vector := Mat_Vec (I3, X);
   begin
      Check (Approx (I3 (1, 1), 1.0) and then Approx (I3 (2, 2), 1.0)
               and then Approx (I3 (1, 2), 0.0),
             "Identity diagonal");
      Check (Approx (Z3 (1, 1), 0.0) and then Approx (Z3 (3, 2), 0.0),
             "Zero matrix");
      Check (Approx (Y (1), 1.0) and then Approx (Y (2), -2.0)
               and then Approx (Y (3), 0.5),
             "Mat_Vec Identity");
      Check (Approx (Real (Residual_Norm (I3, X, 1.0)), 0.0, 1.0E-12),
             "Residual on eigenvector of I");
   end;

   ---------------------------------------------------------------------
   Section ("3. Rayleigh quotient on known eigenpairs");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix (1 .. 3, 1 .. 3) :=
        [[2.0, 0.0, 0.0],
         [0.0, 2.0, 1.0],
         [0.0, 1.0, 2.0]];
      V1 : constant Vector (1 .. 3) := [0.0, 1.0, -1.0];
      V2 : constant Vector (1 .. 3) := [1.0, 0.0, 0.0];
      V3 : constant Vector (1 .. 3) := [0.0, 1.0, 1.0];
   begin
      Check (Approx (Rayleigh_Quotient (A, V1), 1.0, 1.0E-12), "RQ eval 1");
      Check (Approx (Rayleigh_Quotient (A, V2), 2.0, 1.0E-12), "RQ eval 2");
      Check (Approx (Rayleigh_Quotient (A, V3), 3.0, 1.0E-12), "RQ eval 3");
      Check (Approx (Rayleigh_Quotient (A, [2.0, 0.0, 0.0]), 2.0, 1.0E-12),
             "RQ scaled eigenvector");
      begin
         declare
            Dummy : constant Real :=
              Rayleigh_Quotient (A, [Real'(0.0), 0.0, 0.0]);
         begin
            pragma Unreferenced (Dummy);
            Check (False, "RQ zero raises");
         end;
      exception
         when Degenerate =>
            Check (True, "RQ zero raises Degenerate");
      end;
   end;

   declare
      D : Matrix (1 .. 4, 1 .. 4) := [others => [others => 0.0]];
   begin
      D (1, 1) := 10.0;
      D (2, 2) := 20.0;
      D (3, 3) := 30.0;
      D (4, 4) := 40.0;
      Check (Approx (Rayleigh_Quotient (D, [1.0, 0.0, 0.0, 0.0]), 10.0),
             "RQ diag e1");
      Check (Approx (Rayleigh_Quotient (D, [0.0, 1.0, 0.0, 0.0]), 20.0),
             "RQ diag e2");
      Check (Approx (Rayleigh_Quotient (D, [0.0, 0.0, 1.0, 0.0]), 30.0),
             "RQ diag e3");
      Check (Approx (Rayleigh_Quotient (D, [0.0, 0.0, 0.0, 1.0]), 40.0),
             "RQ diag e4");
      Check (Approx (Rayleigh_Quotient (D, [1.0, 1.0, 0.0, 0.0]), 15.0,
                    1.0E-10),
             "RQ mixture e1+e2");
   end;

   ---------------------------------------------------------------------
   Section ("4. Orthonormalization (MGS)");
   ---------------------------------------------------------------------
   declare
      Q    : Basis (1 .. 3, 1 .. 3);
      Rank : Dim_K;
   begin
      Set_Column (Q, 1, [1.0, 0.0, 0.0]);
      Set_Column (Q, 2, [1.0, 1.0, 0.0]);
      Set_Column (Q, 3, [1.0, 1.0, 1.0]);
      Orthonormalize (Q, Rank);
      Check (Rank = 3, "MGS full rank 3");
      Check (Is_Orthonormal (Q, 3), "MGS orthonormal 3");
      Check (Approx (Real (Norm (Column (Q, 1))), 1.0, 1.0E-10),
             "MGS col1 unit");
      Check (Approx (Real (Norm (Column (Q, 2))), 1.0, 1.0E-10),
             "MGS col2 unit");
      Check (Approx (Real (Norm (Column (Q, 3))), 1.0, 1.0E-10),
             "MGS col3 unit");
      Check (Approx (Dot (Column (Q, 1), Column (Q, 2)), 0.0, 1.0E-10),
             "MGS col1 perp col2");
      Check (Approx (Dot (Column (Q, 1), Column (Q, 3)), 0.0, 1.0E-10),
             "MGS col1 perp col3");
      Check (Approx (Dot (Column (Q, 2), Column (Q, 3)), 0.0, 1.0E-10),
             "MGS col2 perp col3");
   end;

   declare
      Q    : Basis (1 .. 3, 1 .. 3);
      Rank : Dim_K;
   begin
      Set_Column (Q, 1, [1.0, 2.0, 3.0]);
      Set_Column (Q, 2, [2.0, 4.0, 6.0]);
      Set_Column (Q, 3, [0.0, 0.0, 1.0]);
      Orthonormalize (Q, Rank);
      Check (Rank = 2, "MGS rank deficient -> 2");
      Check (Is_Orthonormal (Q, 2), "MGS deficient orthonormal");
   end;

   declare
      Q    : Basis (1 .. 2, 1 .. 2);
      Rank : Dim_K;
   begin
      Set_Column (Q, 1, [0.0, 0.0]);
      Set_Column (Q, 2, [0.0, 0.0]);
      Orthonormalize (Q, Rank);
      Check (Rank = 0, "MGS all-zero rank 0");
   end;

   declare
      Q    : Basis (1 .. 2, 1 .. 1);
      Rank : Dim_K;
   begin
      Set_Column (Q, 1, [3.0, 4.0]);
      Orthonormalize (Q, Rank);
      Check (Rank = 1, "MGS single column rank");
      Check (Approx (Column (Q, 1) (1), 0.6, 1.0E-10)
               and then Approx (Column (Q, 1) (2), 0.8, 1.0E-10),
             "MGS normalize 3-4-5");
   end;

   ---------------------------------------------------------------------
   Section ("5. Eigen_2x2 analytic");
   ---------------------------------------------------------------------
   declare
      L1, L2, V1x, V1y, V2x, V2y : Real;
   begin
      Eigen_2x2 (2.0, 1.0, 2.0, L1, L2, V1x, V1y, V2x, V2y);
      Check (Approx (L1, 1.0, 1.0E-10), "2x2 wiki Lam1=1");
      Check (Approx (L2, 3.0, 1.0E-10), "2x2 wiki Lam2=3");
      Check (Approx (V1x * V1x + V1y * V1y, 1.0, 1.0E-10), "2x2 v1 unit");
      Check (Approx (V2x * V2x + V2y * V2y, 1.0, 1.0E-10), "2x2 v2 unit");
      Check (Approx (V1x * V2x + V1y * V2y, 0.0, 1.0E-10), "2x2 orthogonal");
      Check (Approx ((2.0 - L1) * V1x + 1.0 * V1y, 0.0, 1.0E-9),
             "2x2 residual v1 row1");
      Check (Approx (1.0 * V1x + (2.0 - L1) * V1y, 0.0, 1.0E-9),
             "2x2 residual v1 row2");
   end;

   declare
      L1, L2, V1x, V1y, V2x, V2y : Real;
   begin
      Eigen_2x2 (4.0, 0.0, 1.0, L1, L2, V1x, V1y, V2x, V2y);
      Check (Approx (L1, 1.0) and then Approx (L2, 4.0),
             "2x2 diagonal sorted");
      Eigen_2x2 (5.0, 0.0, 5.0, L1, L2, V1x, V1y, V2x, V2y);
      Check (Approx (L1, 5.0) and then Approx (L2, 5.0),
             "2x2 repeated eval");
   end;

   ---------------------------------------------------------------------
   Section ("6. Jacobi symmetric eigensolver");
   ---------------------------------------------------------------------
   declare
      T    : Small_Matrix (1 .. 3, 1 .. 3) :=
        [[2.0, 0.0, 0.0],
         [0.0, 2.0, 1.0],
         [0.0, 1.0, 2.0]];
      Y    : Small_Matrix (1 .. 3, 1 .. 3);
      Eigs : Small_Vector (1 .. 3);
      Exp  : constant Small_Vector (1 .. 3) := [1.0, 2.0, 3.0];
   begin
      Jacobi_Symmetric (T, Y, Eigs, 3);
      Check (Matches_Spectrum (Eigs, 3, Exp, 1.0E-8),
             "Jacobi wiki 3x3 spectrum");
      Check (Eigs (1) <= Eigs (2) and then Eigs (2) <= Eigs (3),
             "Jacobi sorted ascending");
      Check (Approx (Y (1, 1) * Y (1, 1) + Y (2, 1) * Y (2, 1)
                       + Y (3, 1) * Y (3, 1),
                     1.0, 1.0E-8),
             "Jacobi Y col1 unit");
      Check (Approx (Y (1, 1) * Y (1, 2) + Y (2, 1) * Y (2, 2)
                       + Y (3, 1) * Y (3, 2),
                     0.0, 1.0E-8),
             "Jacobi Y col1 perp col2");
   end;

   declare
      T    : Small_Matrix (1 .. 1, 1 .. 1) := [[7.5]];
      Y    : Small_Matrix (1 .. 1, 1 .. 1);
      Eigs : Small_Vector (1 .. 1);
   begin
      Jacobi_Symmetric (T, Y, Eigs, 1);
      Check (Approx (Eigs (1), 7.5), "Jacobi 1x1");
      Check (Approx (Y (1, 1), 1.0), "Jacobi 1x1 eigenvector");
   end;

   declare
      T    : Small_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0.0]];
      Y    : Small_Matrix (1 .. 4, 1 .. 4);
      Eigs : Small_Vector (1 .. 4);
   begin
      T (1, 1) := 1.0;
      T (2, 2) := 3.0;
      T (3, 3) := 2.0;
      T (4, 4) := 4.0;
      T (1, 2) := 0.5;
      T (2, 1) := 0.5;
      Jacobi_Symmetric (T, Y, Eigs, 4);
      Check (Eigs (1) <= Eigs (2) and then Eigs (2) <= Eigs (3)
               and then Eigs (3) <= Eigs (4),
             "Jacobi 4x4 sorted");
      Check (Approx (Eigs (1) + Eigs (2) + Eigs (3) + Eigs (4),
                     10.0, 1.0E-6),
             "Jacobi 4x4 trace");
   end;

   ---------------------------------------------------------------------
   Section ("7. Project_QtAQ / wiki invariant subspace");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 3, 1 .. 3) :=
        [[2.0, 0.0, 0.0],
         [0.0, 2.0, 1.0],
         [0.0, 1.0, 2.0]];
      Q : Basis (1 .. 3, 1 .. 2);
      T : Small_Matrix (1 .. 2, 1 .. 2);
   begin
      Set_Column (Q, 1, [0.0, 1.0, 0.0]);
      Set_Column (Q, 2, [0.0, 0.0, 1.0]);
      T := Project_QtAQ (A, Q, 2);
      Check (Approx (T (1, 1), 2.0) and then Approx (T (1, 2), 1.0)
               and then Approx (T (2, 1), 1.0) and then Approx (T (2, 2), 2.0),
             "Project wiki V*AV");
   end;

   ---------------------------------------------------------------------
   Section ("8. Ritz_Extract: wiki example + full space");
   ---------------------------------------------------------------------
   declare
      A   : constant Matrix (1 .. 3, 1 .. 3) :=
        [[2.0, 0.0, 0.0],
         [0.0, 2.0, 1.0],
         [0.0, 1.0, 2.0]];
      Q   : Basis (1 .. 3, 1 .. 2);
      K   : Dim_K := 2;
      RV  : Small_Vector (1 .. 2);
      RX  : Basis (1 .. 3, 1 .. 2);
      Exp : constant Small_Vector (1 .. 2) := [1.0, 3.0];
   begin
      Set_Column (Q, 1, [0.0, 1.0, 0.0]);
      Set_Column (Q, 2, [0.0, 0.0, 1.0]);
      Ritz_Extract (A, Q, K, RV, RX);
      Check (K = 2, "Wiki RR kept K=2");
      Check (Matches_Spectrum (RV, 2, Exp, 1.0E-8),
             "Wiki RR Ritz values 1,3");
      Check (Approx (Real (Residual_Norm (A, Column (RX, 1), RV (1))),
                     0.0, 1.0E-8),
             "Wiki RR residual 1");
      Check (Approx (Real (Residual_Norm (A, Column (RX, 2), RV (2))),
                     0.0, 1.0E-8),
             "Wiki RR residual 2");
   end;

   declare
      A   : constant Matrix (1 .. 3, 1 .. 3) :=
        [[2.0, 0.0, 0.0],
         [0.0, 2.0, 1.0],
         [0.0, 1.0, 2.0]];
      Q   : Basis := Identity_Basis (3, 3);
      K   : Dim_K := 3;
      RV  : Small_Vector (1 .. 3);
      RX  : Basis (1 .. 3, 1 .. 3);
      Exp : constant Small_Vector (1 .. 3) := [1.0, 2.0, 3.0];
   begin
      Ritz_Extract (A, Q, K, RV, RX);
      Check (K = 3, "Full-space RR K=3");
      Check (Matches_Spectrum (RV, 3, Exp, 1.0E-8),
             "Full-space RR spectrum");
      for J in Index_K range 1 .. 3 loop
         Check (Approx (Real (Residual_Norm (A, Column (RX, J), RV (J))),
                        0.0, 1.0E-7),
                "Full-space residual J=" & Index_K'Image (J));
      end loop;
   end;

   declare
      A  : constant Matrix (1 .. 3, 1 .. 3) :=
        [[2.0, 0.0, 0.0],
         [0.0, 2.0, 1.0],
         [0.0, 1.0, 2.0]];
      Q  : Basis (1 .. 3, 1 .. 1);
      K  : Dim_K := 1;
      RV : Small_Vector (1 .. 1);
      RX : Basis (1 .. 3, 1 .. 1);
      X  : constant Vector (1 .. 3) := [0.0, 1.0, 1.0];
   begin
      Set_Column (Q, 1, X);
      Ritz_Extract (A, Q, K, RV, RX);
      Check (K = 1, "K=1 kept");
      Check (Approx (RV (1), Rayleigh_Quotient (A, X), 1.0E-10),
             "K=1 equals Rayleigh quotient");
      Check (Approx (RV (1), 3.0, 1.0E-10), "K=1 Ritz value 3");
   end;

   ---------------------------------------------------------------------
   Section ("9. Discrete Laplacian exact eigenpairs via RQ");
   ---------------------------------------------------------------------
   declare
      N : constant Dim_N := 5;
      A : constant Matrix := Discrete_Laplacian (N);
   begin
      for J in Index_N range 1 .. N loop
         declare
            V   : Vector := Laplacian_Exact_Eigenvector (N, J);
            Lam : constant Real := Laplacian_Exact_Eigenvalue (N, J);
            Nv  : constant Non_Negative := Norm (V);
         begin
            Scale (V, 1.0 / Real (Nv));
            Check (Approx (Rayleigh_Quotient (A, V), Lam, 1.0E-10),
                   "Lap RQ mode" & Index_N'Image (J));
            Check (Approx (Real (Residual_Norm (A, V, Lam)), 0.0, 1.0E-9),
                   "Lap residual mode" & Index_N'Image (J));
         end;
      end loop;
      Check (Approx (Laplacian_Exact_Eigenvalue (5, 1),
                     2.0 - 2.0 * 0.86602540378, 1.0E-6),
             "Lap formula sanity mode1");
   end;

   ---------------------------------------------------------------------
   Section ("10. RR on Fourier trial = exact Laplacian modes");
   ---------------------------------------------------------------------
   declare
      N   : constant Dim_N := 6;
      A   : constant Matrix := Discrete_Laplacian (N);
      Q   : Basis := Fourier_Trial_Basis (N, 4);
      K   : Dim_K := 4;
      RV  : Small_Vector (1 .. 4);
      RX  : Basis (1 .. N, 1 .. 4);
      Exp : Small_Vector (1 .. 4);
   begin
      for J in Index_K range 1 .. 4 loop
         Exp (J) := Laplacian_Exact_Eigenvalue (N, J);
      end loop;
      Ritz_Extract (A, Q, K, RV, RX);
      Check (K = 4, "Fourier RR K=4");
      Check (Matches_Spectrum (RV, 4, Exp, 1.0E-8),
             "Fourier RR exact lowest 4");
      for J in Index_K range 1 .. 4 loop
         Check (Approx (Real (Residual_Norm (A, Column (RX, J), RV (J))),
                        0.0, 1.0E-7),
                "Fourier residual" & Index_K'Image (J));
      end loop;
   end;

   declare
      N   : constant Dim_N := 5;
      A   : constant Matrix := Discrete_Laplacian (N);
      Q   : Basis := Fourier_Trial_Basis (N, 5);
      K   : Dim_K := 5;
      RV  : Small_Vector (1 .. 5);
      RX  : Basis (1 .. N, 1 .. 5);
      Exp : Small_Vector (1 .. 5);
   begin
      for J in Index_K range 1 .. 5 loop
         Exp (J) := Laplacian_Exact_Eigenvalue (N, J);
      end loop;
      Ritz_Extract (A, Q, K, RV, RX);
      Check (Matches_Spectrum (RV, 5, Exp, 1.0E-7),
             "Full Fourier RR all evals");
   end;

   ---------------------------------------------------------------------
   Section ("11. Polynomial trial approximates lowest modes");
   ---------------------------------------------------------------------
   declare
      N      : constant Dim_N := 8;
      A      : constant Matrix := Discrete_Laplacian (N);
      Exact1 : constant Real := Laplacian_Exact_Eigenvalue (N, 1);
      Lam_K2, Lam_K4, Lam_K6 : Real;
   begin
      declare
         Q  : Basis := Polynomial_Trial_Basis (N, 2);
         K  : Dim_K := 2;
         RV : Small_Vector (1 .. 2);
         RX : Basis (1 .. N, 1 .. 2);
      begin
         Ritz_Extract (A, Q, K, RV, RX);
         Lam_K2 := RV (1);
         Check (K >= 1, "Poly K=2 rank ok");
         Check (Lam_K2 >= Exact1 - 1.0E-8, "Poly K=2 >= exact (SPD)");
         Check (Lam_K2 < Exact1 + 0.5, "Poly K=2 reasonably close");
      end;
      declare
         Q  : Basis := Polynomial_Trial_Basis (N, 4);
         K  : Dim_K := 4;
         RV : Small_Vector (1 .. 4);
         RX : Basis (1 .. N, 1 .. 4);
      begin
         Ritz_Extract (A, Q, K, RV, RX);
         Lam_K4 := RV (1);
         Check (Lam_K4 >= Exact1 - 1.0E-8, "Poly K=4 >= exact");
         Check (Lam_K4 <= Lam_K2 + 1.0E-8,
                "Monotonicity: K=4 <= K=2 lowest Ritz");
      end;
      declare
         Q  : Basis := Polynomial_Trial_Basis (N, 6);
         K  : Dim_K := 6;
         RV : Small_Vector (1 .. 6);
         RX : Basis (1 .. N, 1 .. 6);
      begin
         Ritz_Extract (A, Q, K, RV, RX);
         Lam_K6 := RV (1);
         Check (Lam_K6 >= Exact1 - 1.0E-8, "Poly K=6 >= exact");
         Check (Lam_K6 <= Lam_K4 + 1.0E-8,
                "Monotonicity: K=6 <= K=4 lowest Ritz");
         Check (Approx (Lam_K6, Exact1, 5.0E-2),
                "Poly K=6 approximates ground state");
      end;
      Check (Lam_K6 <= Lam_K2, "Overall monotonicity K6<=K2");
   end;

   ---------------------------------------------------------------------
   Section ("12. Generalized RR: simple SPD pair");
   ---------------------------------------------------------------------
   declare
      A   : Matrix (1 .. 3, 1 .. 3) := [others => [others => 0.0]];
      B   : constant Matrix := Identity (3);
      Q   : Basis := Identity_Basis (3, 3);
      K   : Dim_K := 3;
      RV  : Small_Vector (1 .. 3);
      RX  : Basis (1 .. 3, 1 .. 3);
      Exp : constant Small_Vector (1 .. 3) := [1.0, 2.0, 3.0];
   begin
      A (1, 1) := 1.0;
      A (2, 2) := 2.0;
      A (3, 3) := 3.0;
      Ritz_Extract_Generalized (A, B, Q, K, RV, RX);
      Check (K = 3, "Gen RR B=I K");
      Check (Matches_Spectrum (RV, 3, Exp, 1.0E-8),
             "Gen RR B=I spectrum");
   end;

   declare
      A   : constant Matrix := Identity (3);
      B   : Matrix (1 .. 3, 1 .. 3) := [others => [others => 0.0]];
      Q   : Basis := Identity_Basis (3, 3);
      K   : Dim_K := 3;
      RV  : Small_Vector (1 .. 3);
      RX  : Basis (1 .. 3, 1 .. 3);
      Exp : constant Small_Vector (1 .. 3) := [0.25, 0.5, 1.0];
   begin
      B (1, 1) := 1.0;
      B (2, 2) := 2.0;
      B (3, 3) := 4.0;
      Ritz_Extract_Generalized (A, B, Q, K, RV, RX);
      Check (Matches_Spectrum (RV, 3, Exp, 1.0E-7),
             "Gen RR A=I B=diag spectrum");
   end;

   declare
      A   : constant Matrix (1 .. 2, 1 .. 2) :=
        [[2.0, 1.0], [1.0, 2.0]];
      B   : constant Matrix := Identity (2);
      Q   : Basis := Identity_Basis (2, 2);
      K   : Dim_K := 2;
      RV  : Small_Vector (1 .. 2);
      RX  : Basis (1 .. 2, 1 .. 2);
      Exp : constant Small_Vector (1 .. 2) := [1.0, 3.0];
   begin
      Ritz_Extract_Generalized (A, B, Q, K, RV, RX);
      Check (Matches_Spectrum (RV, 2, Exp, 1.0E-8),
             "Gen RR 2x2 with B=I");
   end;

   ---------------------------------------------------------------------
   Section ("13. Residuals / RQ consistency on Ritz vectors");
   ---------------------------------------------------------------------
   declare
      N  : constant Dim_N := 6;
      A  : constant Matrix := Discrete_Laplacian (N);
      Q  : Basis := Polynomial_Trial_Basis (N, 3);
      K  : Dim_K := 3;
      RV : Small_Vector (1 .. 3);
      RX : Basis (1 .. N, 1 .. 3);
   begin
      Ritz_Extract (A, Q, K, RV, RX);
      Check (Is_Orthonormal (RX, K, 1.0E-7), "Ritz vectors orthonormal");
      for J in Index_K range 1 .. K loop
         declare
            Xj : constant Vector := Column (RX, J);
         begin
            Check (Approx (Rayleigh_Quotient (A, Xj), RV (J), 1.0E-8),
                   "Ritz RQ consistency" & Index_K'Image (J));
            Check (Real (Residual_Norm (A, Xj, RV (J))) < 1.0,
                   "Poly residual bounded" & Index_K'Image (J));
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("14. Edge cases / exceptions");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix := Identity (2);
      Q  : Basis (1 .. 2, 1 .. 2);
      K  : Dim_K := 2;
      RV : Small_Vector (1 .. 2);
      RX : Basis (1 .. 2, 1 .. 2);
   begin
      Set_Column (Q, 1, [0.0, 0.0]);
      Set_Column (Q, 2, [0.0, 0.0]);
      begin
         Ritz_Extract (A, Q, K, RV, RX);
         Check (False, "Empty basis should raise");
      exception
         when Rank_Deficient =>
            Check (True, "Empty basis Rank_Deficient");
      end;
   end;

   declare
      A  : constant Matrix := Identity (2);
      B  : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 0.0], [0.0, -1.0]];
      Q  : Basis := Identity_Basis (2, 2);
      K  : Dim_K := 2;
      RV : Small_Vector (1 .. 2);
      RX : Basis (1 .. 2, 1 .. 2);
   begin
      begin
         Ritz_Extract_Generalized (A, B, Q, K, RV, RX);
         Check (False, "Indefinite B should raise");
      exception
         when Degenerate =>
            Check (True, "Indefinite B Degenerate");
      end;
   end;

   Check (not Is_Orthonormal
            (Basis'(1 .. 2 => [1.0, 1.0]), 2),
          "Is_Orthonormal rejects ones");

   ---------------------------------------------------------------------
   Section ("15. Extra spectrum / projection / Laplacian checks");
   ---------------------------------------------------------------------
   declare
      N : constant Dim_N := 4;
      A : constant Matrix := Discrete_Laplacian (N);
      Q : constant Basis := Fourier_Trial_Basis (N, 2);
      T : constant Small_Matrix := Project_QtAQ (A, Q, 2);
   begin
      Check (Approx (T (1, 1), Laplacian_Exact_Eigenvalue (N, 1), 1.0E-8),
             "Proj Fourier T11");
      Check (Approx (T (2, 2), Laplacian_Exact_Eigenvalue (N, 2), 1.0E-8),
             "Proj Fourier T22");
      Check (Approx (T (1, 2), 0.0, 1.0E-8), "Proj Fourier T12~0");
      Check (Approx (T (2, 1), 0.0, 1.0E-8), "Proj Fourier T21~0");
   end;

   for N in Dim_N range 2 .. 7 loop
      declare
         Lam1 : constant Real := Laplacian_Exact_Eigenvalue (N, 1);
         LamN : constant Real :=
           Laplacian_Exact_Eigenvalue (N, N);
      begin
         Check (Lam1 > 0.0 and then Lam1 < LamN,
                "Lap ordering N=" & Dim_N'Image (N));
         Check (LamN < 4.0 + 1.0E-9,
                "Lap max < 4 N=" & Dim_N'Image (N));
      end;
   end loop;

   declare
      A   : Matrix (1 .. 4, 1 .. 4) := [others => [others => 0.0]];
      Q   : Basis := Identity_Basis (4, 4);
      K   : Dim_K := 4;
      RV  : Small_Vector (1 .. 4);
      RX  : Basis (1 .. 4, 1 .. 4);
      Exp : constant Small_Vector (1 .. 4) := [1.0, 2.0, 3.0, 4.0];
   begin
      for I in Index_N range 1 .. 4 loop
         A (I, I) := Real (I);
      end loop;
      Ritz_Extract (A, Q, K, RV, RX);
      Check (Matches_Spectrum (RV, 4, Exp, 1.0E-10), "Diagonal full RR");
   end;

   declare
      N : constant Dim_N := 8;
      A : constant Matrix := Discrete_Laplacian (N);
      L2, L3, L4 : Real;
   begin
      declare
         Q  : Basis := Fourier_Trial_Basis (N, 2);
         K  : Dim_K := 2;
         RV : Small_Vector (1 .. 2);
         RX : Basis (1 .. N, 1 .. 2);
      begin
         Ritz_Extract (A, Q, K, RV, RX);
         L2 := RV (1);
      end;
      declare
         Q  : Basis := Fourier_Trial_Basis (N, 3);
         K  : Dim_K := 3;
         RV : Small_Vector (1 .. 3);
         RX : Basis (1 .. N, 1 .. 3);
      begin
         Ritz_Extract (A, Q, K, RV, RX);
         L3 := RV (1);
      end;
      declare
         Q  : Basis := Fourier_Trial_Basis (N, 4);
         K  : Dim_K := 4;
         RV : Small_Vector (1 .. 4);
         RX : Basis (1 .. N, 1 .. 4);
      begin
         Ritz_Extract (A, Q, K, RV, RX);
         L4 := RV (1);
      end;
      Check (Approx (L2, L3, 1.0E-10) and then Approx (L3, L4, 1.0E-10),
             "Fourier nested ground state exact/stable");
      Check (Approx (L2, Laplacian_Exact_Eigenvalue (N, 1), 1.0E-10),
             "Fourier ground = exact");
   end;

   declare
      Q : Basis (1 .. 3, 1 .. 2);
      V : constant Vector (1 .. 3) := [1.5, -2.5, 3.5];
   begin
      Set_Column (Q, 1, V);
      Check (Approx (Column (Q, 1) (1), 1.5)
               and then Approx (Column (Q, 1) (2), -2.5)
               and then Approx (Column (Q, 1) (3), 3.5),
             "Set/Column roundtrip");
   end;

   declare
      A : constant Matrix := Discrete_Laplacian (3);
      X : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      Y : constant Vector := Mat_Vec (A, X);
   begin
      Check (Approx (Y (1), 1.0) and then Approx (Y (2), 0.0)
               and then Approx (Y (3), 1.0),
             "Lap Mat_Vec on ones");
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("=================================");
   Put_Line ("PASS: " & Natural'Image (Pass_Count));
   Put_Line ("FAIL: " & Natural'Image (Fail_Count));
   Put_Line ("Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
