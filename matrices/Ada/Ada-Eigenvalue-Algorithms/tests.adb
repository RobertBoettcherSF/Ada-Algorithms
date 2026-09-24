--  Standalone test suite for Eigenvalue_Algorithms (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Elementary_Functions;
with Eigenvalue_Algorithms; use Eigenvalue_Algorithms;

procedure Tests is

   package Math renames Ada.Numerics.Elementary_Functions;

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   function Abs_F_Local (X : Float) return Float is
   begin
      if X < 0.0 then
         return -X;
      end if;
      return X;
   end Abs_F_Local;

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

   function Approx (A, B : Float; Tol : Float := 1.0E-5) return Boolean is
   begin
      return Near (A, B, Tol);
   end Approx;

begin
   Put_Line ("Eigenvalue_Algorithms — educational survey tests");
   Put_Line ("Max_N =" & Max_N'Image);

   ---------------------------------------------------------------------
   Section ("1. Helpers: Near, Dot, Norm2, Add/Sub/Scale");
   ---------------------------------------------------------------------
   declare
      A : constant Vector := [1.0, 2.0];
      B : constant Vector := [1.0, 2.0];
      C : constant Vector := [1.0, 3.0];
      D : constant Vector := [3.0, 4.0, 0.0];
      Z : constant Vector := [0.0, 0.0, 0.0];
      S : Vector (1 .. 2);
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Vec_Near (A, B), "Vec_Near equal");
      Check (not Vec_Near (A, C), "Vec_Near rejects");
      Check (Vec_Near (A, C, 1.5), "Vec_Near loose Tol");
      Check (Approx (Norm2 (D), 5.0, 1.0E-6), "Norm2(3,4,0)=5");
      Check (Approx (Norm2 (Z), 0.0), "Norm2 zero");
      Check (Approx (Dot (A, C), 7.0), "Dot product");
      S := Add (A, C);
      Check (Approx (S (1), 2.0) and then Approx (S (2), 5.0), "Add");
      S := Sub (C, A);
      Check (Approx (S (1), 0.0) and then Approx (S (2), 1.0), "Sub");
      S := Scale (A, 2.0);
      Check (Approx (S (1), 2.0) and then Approx (S (2), 4.0), "Scale");
      Check (Approx (Dot (A, A), 5.0), "Dot self");
   end;

   ---------------------------------------------------------------------
   Section ("2. Mat_Vec, Identity, Is_Square, Normalize");
   ---------------------------------------------------------------------
   declare
      I2 : constant Matrix := Identity (2);
      I3 : constant Matrix := Identity (3);
      A  : constant Matrix (1 .. 2, 1 .. 2) :=
        [[2.0, 1.0], [1.0, 2.0]];
      V  : constant Vector := [1.0, 0.0];
      W  : Vector (1 .. 2);
      U  : constant Vector := Normalize ([3.0, 4.0]);
   begin
      Check (Is_Square (I2), "Is_Square Identity");
      Check (Approx (I2 (1, 1), 1.0) and then Approx (I2 (2, 2), 1.0),
             "Identity diag");
      Check (Approx (I2 (1, 2), 0.0) and then Approx (I2 (2, 1), 0.0),
             "Identity off");
      Check (Approx (I3 (3, 3), 1.0), "Identity 3");
      W := Mat_Vec (I2, V);
      Check (Vec_Near (W, V, 1.0E-12), "Mat_Vec I·v = v");
      W := Mat_Vec (A, [1.0, 1.0]);
      Check (Vec_Near (W, [3.0, 3.0], 1.0E-12), "Mat_Vec A·ones");
      Check (Approx (Norm2 (U), 1.0, 1.0E-6), "Normalize unit");
      Check (Approx (U (1), 0.6, 1.0E-5) and then Approx (U (2), 0.8, 1.0E-5),
             "Normalize 3-4-5");
   end;

   ---------------------------------------------------------------------
   Section ("3. Rayleigh, Eigen_Residual, Is_Symmetric");
   ---------------------------------------------------------------------
   declare
      D : constant Matrix := Make_Diagonal ([2.0, 5.0, 1.0]);
      E : constant Vector := Make_Unit_Vector (3, 2);
      R : Float;
      Res : Vector (1 .. 3);
   begin
      Check (Is_Symmetric (D), "Diagonal is symmetric");
      Check (Is_Diagonal (D), "Is_Diagonal");
      R := Rayleigh_Quotient (D, E);
      Check (Approx (R, 5.0, 1.0E-6), "Rayleigh e2 = 5");
      Res := Eigen_Residual (D, E, 5.0);
      Check (Approx (Norm2 (Res), 0.0, 1.0E-6), "Eigen residual zero");
      Check (Approx (Eigen_Residual_Norm (D, E, 5.0), 0.0, 1.0E-6),
             "Eigen_Residual_Norm");
      Check (Approx (Rayleigh_Quotient (D, Make_Ones_Vector (3)),
                     Dot (Make_Ones_Vector (3), Mat_Vec (D, Make_Ones_Vector (3)))
                       / 3.0,
                     1.0E-5),
             "Rayleigh ones");
   end;

   ---------------------------------------------------------------------
   Section ("4. Builders: Diagonal, Poisson, Known spectrum");
   ---------------------------------------------------------------------
   declare
      Diag : constant Matrix := Make_Diagonal ([1.0, 2.0, 3.0, 4.0]);
      Poi  : constant Matrix := Make_Poisson_1D (5);
      Eigs : constant Vector := [1.0, 2.0, 3.0];
      Ks   : constant Matrix := Make_Known_Spectrum_Symmetric (Eigs);
      Ns   : constant Matrix := Make_Nonsymmetric (4);
      Prop : Matrix_Properties;
   begin
      Check (Is_Diagonal (Diag), "Make_Diagonal diagonal");
      Check (Approx (Diag (4, 4), 4.0), "Make_Diagonal entry");
      Check (Is_Symmetric (Poi), "Poisson symmetric");
      Check (Is_Tridiagonal (Poi), "Poisson tridiagonal");
      Check (Approx (Poi (1, 1), 2.0) and then Approx (Poi (1, 2), -1.0),
             "Poisson stencil");
      Check (Is_Symmetric (Ks, 1.0E-4), "Known spectrum symmetric");
      Check (not Is_Symmetric (Ns), "Nonsymmetric builder");
      Check (Approx (Poisson_Eigenvalue (5, 1),
                     2.0 - 2.0 * Math.Cos (3.141592653589793 / 6.0),
                     1.0E-4),
             "Poisson λ_1 formula");
      Prop := Classify_Matrix (Poi);
      Check (Prop.Symmetric and then Prop.Tridiagonal,
             "Classify Poisson");
      Prop := Classify_Matrix (Diag);
      Check (Prop.Diagonal and then Prop.Symmetric, "Classify Diagonal");
      Prop := Classify_Matrix (Ns);
      Check (not Prop.Symmetric, "Classify nonsym");
   end;

   ---------------------------------------------------------------------
   Section ("5. Taxonomy: Recommend / Classify_Method / Names");
   ---------------------------------------------------------------------
   declare
      P_Sym : constant Matrix_Properties :=
        (N => 4, Symmetric => True, Tridiagonal => True, Diagonal => False);
      P_Ns  : constant Matrix_Properties :=
        (N => 6, Symmetric => False, Tridiagonal => False, Diagonal => False);
      P_Big : constant Matrix_Properties :=
        (N => 10, Symmetric => True, Tridiagonal => False, Diagonal => False);
      Info  : Method_Info;
   begin
      Check (Recommend_Method (P_Sym, Want_Dominant) = Power,
             "Recommend dominant → Power");
      Check (Recommend_Method (P_Sym, Want_Near_Shift, True) = Inverse,
             "Recommend near+shift → Inverse");
      Check (Recommend_Method (P_Sym, Want_Near_Shift, False)
               = Rayleigh_Quotient,
             "Recommend near no shift → RQI");
      Check (Recommend_Method (P_Sym, Want_Full_Spectrum)
               = Jacobi_Symmetric,
             "Recommend full small sym → Jacobi");
      Check (Recommend_Method (P_Big, Want_Full_Spectrum) = QR_Iteration,
             "Recommend full large sym → QR");
      Check (Recommend_Method (P_Sym, Want_Extremal_Few) = Lanczos,
             "Recommend extremal sym → Lanczos");
      Check (Recommend_Method (P_Ns, Want_Extremal_Few) = Arnoldi,
             "Recommend extremal nonsym → Arnoldi");
      Check (Method_Count = 8, "Method_Count = 8");
      Check (Method_Name (Power) = "Power", "Method_Name Power");
      Check (Method_Name (Divide_And_Conquer) = "Divide_And_Conquer",
             "Method_Name DAC");
      Info := Classify_Method (Jacobi_Symmetric);
      Check (Info.Needs_Symmetric and then Info.Full_Spectrum
             and then Info.Runnable_Sketch,
             "Jacobi Method_Info");
      Info := Classify_Method (Divide_And_Conquer);
      Check (not Info.Runnable_Sketch and then Info.Needs_Symmetric,
             "DAC catalogue-only");
      Info := Classify_Method (Lanczos);
      Check (Info.Krylov and then Info.Needs_Symmetric, "Lanczos Krylov");
      Info := Classify_Method (Arnoldi);
      Check (Info.Krylov and then not Info.Needs_Symmetric, "Arnoldi Krylov");
      Info := Classify_Method (Inverse);
      Check (Info.Uses_Shift, "Inverse uses shift");
   end;

   ---------------------------------------------------------------------
   Section ("6. Power_Dominant");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix := Make_Diagonal ([1.0, 2.0, 9.0]);
      X0 : constant Vector := Make_Ones_Vector (3);
      R  : Eigenpair_Result;
      P  : constant Parameters :=
        (Tol => 1.0E-6, Max_Iter => 100, Mu => 0.0,
         Has_Shift => False, M => 0, Max_Sweeps => 50);
   begin
      R := Power_Dominant (A, X0, P);
      Check (R.Success, "Power success");
      Check (R.Stat = Converged, "Power Converged");
      Check (Approx (Abs_F_Local (R.Eigenvalue), 9.0, 1.0E-3),
             "Power λ ≈ 9");
      Check (R.Residual < 1.0E-4, "Power residual small");
      Check (Approx (Norm2 (R.Eigenvector (1 .. 3)), 1.0, 1.0E-5),
             "Power eigenvector unit");
   end;

   ---------------------------------------------------------------------
   Section ("7. Inverse_Near");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix := Make_Diagonal ([1.0, 4.0, 7.0]);
      X0 : constant Vector := Make_Perturbed_Basis (3, 2, 0.2);
      R  : Eigenpair_Result;
   begin
      R := Inverse_Near (A, 3.8, X0);
      Check (R.Success, "Inverse success");
      Check (Approx (R.Eigenvalue, 4.0, 1.0E-3), "Inverse λ ≈ 4");
      Check (R.Residual < 1.0E-4, "Inverse residual");
      Check (Approx (R.Mu, 3.8), "Inverse Mu echoed");
   end;

   ---------------------------------------------------------------------
   Section ("8. Rayleigh_Quotient_Iterate");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix := Make_Diagonal ([2.0, 5.0, 8.0]);
      X0 : constant Vector := Make_Perturbed_Basis (3, 3, 0.15);
      R  : Eigenpair_Result;
      P  : Parameters := Default_Parameters;
   begin
      P.Has_Shift := True;
      P.Mu := 7.5;
      P.Max_Iter := 30;
      R := Rayleigh_Quotient_Iterate (A, X0, P);
      Check (R.Success, "RQI success");
      Check (Approx (R.Eigenvalue, 8.0, 1.0E-3), "RQI λ ≈ 8");
      Check (R.Residual < 1.0E-4, "RQI residual");
   end;

   ---------------------------------------------------------------------
   Section ("9. Jacobi_Diagonalize");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix :=
        Make_Known_Spectrum_Symmetric ([1.0, 2.0, 3.0, 4.0]);
      R  : Spectrum_Result;
      P  : Parameters := Default_Parameters;
      Ok_All : Boolean;
   begin
      P.Tol := 1.0E-8;
      P.Max_Sweeps := 40;
      R := Jacobi_Diagonalize (A, P);
      Check (R.Success, "Jacobi success");
      Check (R.Has_Vectors, "Jacobi has vectors");
      Check (Approx (R.Eigenvalues (1), 1.0, 1.0E-3), "Jacobi λ1");
      Check (Approx (R.Eigenvalues (2), 2.0, 1.0E-3), "Jacobi λ2");
      Check (Approx (R.Eigenvalues (3), 3.0, 1.0E-3), "Jacobi λ3");
      Check (Approx (R.Eigenvalues (4), 4.0, 1.0E-3), "Jacobi λ4");
      Ok_All := True;
      for K in 1 .. 4 loop
         declare
            Vk : constant Vector := Column (R.Eigenvectors, K);
            Rn : constant Float :=
              Eigen_Residual_Norm (A, Vk (1 .. 4), R.Eigenvalues (K));
         begin
            if Rn > 1.0E-3 then
               Ok_All := False;
            end if;
         end;
      end loop;
      Check (Ok_All, "Jacobi eigen residuals");
      Check (R.Off_Diag < 1.0E-4, "Jacobi off-diag small");
   end;

   ---------------------------------------------------------------------
   Section ("10. QR_Unshifted tiny symmetric");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([3.0, 1.0, 2.0]);
      R : Spectrum_Result;
      P : Parameters := Default_Parameters;
   begin
      P.Tol := 1.0E-8;
      P.Max_Iter := 80;
      R := QR_Unshifted (A, P);
      Check (R.Success, "QR success on diagonal");
      Check (Approx (R.Eigenvalues (1), 1.0, 1.0E-4), "QR λ sorted 1");
      Check (Approx (R.Eigenvalues (2), 2.0, 1.0E-4), "QR λ sorted 2");
      Check (Approx (R.Eigenvalues (3), 3.0, 1.0E-4), "QR λ sorted 3");
   end;

   declare
      A : constant Matrix :=
        Make_Known_Spectrum_Symmetric ([1.0, 2.0, 3.0]);
      R : Spectrum_Result;
      P : Parameters := Default_Parameters;
   begin
      P.Tol := 1.0E-6;
      P.Max_Iter := 200;
      R := QR_Unshifted (A, P);
      Check (R.Success or else R.Off_Diag < 0.05, "QR dense progress");
      Check (Approx (R.Eigenvalues (1), 1.0, 5.0E-2)
             or else Approx (R.Eigenvalues (1), 1.0, 0.2),
             "QR dense λ1 rough");
   end;

   ---------------------------------------------------------------------
   Section ("11. Lanczos_Build");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix := Make_Poisson_1D (6);
      X0 : constant Vector := Make_Ones_Vector (6);
      R  : Krylov_Result;
      P  : Parameters := Default_Parameters;
   begin
      P.M := 4;
      P.Tol := 1.0E-10;
      R := Lanczos_Build (A, X0, P);
      Check (R.Success, "Lanczos success");
      Check (R.Steps >= 3 and then R.Steps <= 4, "Lanczos steps 3..4");
      Check (R.Has_V, "Lanczos Has_V");
      Check (R.Stat = Ok or else R.Stat = Breakdown, "Lanczos status");
      --  Orthogonality of first two Lanczos vectors
      declare
         V1 : constant Vector := Column (R.V, 1);
         V2 : constant Vector := Column (R.V, 2);
      begin
         Check (Approx (Norm2 (V1 (1 .. 6)), 1.0, 1.0E-5), "Lanczos v1 unit");
         Check (Approx (Dot (V1 (1 .. 6), V2 (1 .. 6)), 0.0, 1.0E-4),
                "Lanczos v1⊥v2");
      end;
      Check (Approx (R.Alphas (1),
                     Rayleigh_Quotient (A, Column (R.V, 1) (1 .. 6)),
                     1.0E-4),
             "Lanczos α1 = v1ᵀ A v1");
   end;

   declare
      A  : constant Matrix := Make_Nonsymmetric (4);
      X0 : constant Vector := Make_Ones_Vector (4);
      R  : Krylov_Result;
   begin
      R := Lanczos_Build (A, X0);
      Check (R.Stat = Not_Symmetric, "Lanczos rejects nonsym");
      Check (not R.Success, "Lanczos nonsym fail");
   end;

   ---------------------------------------------------------------------
   Section ("12. Arnoldi_Build");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix := Make_Nonsymmetric (5);
      X0 : constant Vector := Make_Ones_Vector (5);
      R  : Krylov_Result;
      P  : Parameters := Default_Parameters;
   begin
      P.M := 3;
      R := Arnoldi_Build (A, X0, P);
      Check (R.Success, "Arnoldi success");
      Check (R.Steps = 3, "Arnoldi steps=3");
      Check (R.Has_V, "Arnoldi Has_V");
      declare
         V1 : constant Vector := Column (R.V, 1);
         V2 : constant Vector := Column (R.V, 2);
      begin
         Check (Approx (Norm2 (V1 (1 .. 5)), 1.0, 1.0E-5), "Arnoldi v1 unit");
         Check (Approx (Dot (V1 (1 .. 5), V2 (1 .. 5)), 0.0, 1.0E-4),
                "Arnoldi v1⊥v2");
      end;
      --  Hessenberg: H(3,1) should be ~0
      Check (Approx (R.H (3, 1), 0.0, 1.0E-5), "Arnoldi Hessenberg H31~0");
   end;

   declare
      A  : constant Matrix := Make_Poisson_1D (5);
      X0 : constant Vector := Make_Ones_Vector (5);
      R  : Krylov_Result;
      P  : Parameters := Default_Parameters;
   begin
      P.M := 3;
      R := Arnoldi_Build (A, X0, P);
      Check (R.Success, "Arnoldi on SPD");
      Check (R.Steps >= 2, "Arnoldi SPD steps");
   end;

   ---------------------------------------------------------------------
   Section ("13. Dispatchers / Auto");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix := Make_Diagonal ([1.0, 2.0, 6.0]);
      X0 : constant Vector := Make_Ones_Vector (3);
      R  : Eigenpair_Result;
      S  : Spectrum_Result;
      P  : Parameters := Default_Parameters;
   begin
      R := Run_Eigenpair (A, X0, Power, P);
      Check (R.Success and then Approx (R.Eigenvalue, 6.0, 1.0E-2),
             "Run_Eigenpair Power");
      P.Has_Shift := True;
      P.Mu := 1.9;
      R := Run_Eigenpair (A, Make_Perturbed_Basis (3, 2), Inverse, P);
      Check (R.Success and then Approx (R.Eigenvalue, 2.0, 1.0E-2),
             "Run_Eigenpair Inverse");
      R := Run_Eigenpair (A, X0, Jacobi_Symmetric, P);
      Check (R.Stat = Not_Implemented, "Run_Eigenpair Jacobi → NI");
      S := Run_Spectrum (A, Jacobi_Symmetric, Default_Parameters);
      Check (S.Success, "Run_Spectrum Jacobi");
      S := Run_Spectrum (A, QR_Iteration, Default_Parameters);
      Check (S.Success, "Run_Spectrum QR");
      S := Run_Spectrum (A, Power, Default_Parameters);
      Check (S.Stat = Not_Implemented, "Run_Spectrum Power → NI");
      R := Run_Auto_Eigenpair (A, X0, Want_Dominant);
      Check (R.Success and then Approx (R.Eigenvalue, 6.0, 1.0E-2),
             "Run_Auto dominant");
      R := Run_Auto_Eigenpair
             (A, Make_Perturbed_Basis (3, 1), Want_Near_Shift,
              (Tol => 1.0E-6, Max_Iter => 50, Mu => 1.1,
               Has_Shift => True, M => 0, Max_Sweeps => 50));
      Check (R.Success and then Approx (R.Eigenvalue, 1.0, 1.0E-2),
             "Run_Auto near shift");
   end;

   ---------------------------------------------------------------------
   Section ("14. Edge cases / Poisson power");
   ---------------------------------------------------------------------
   declare
      Poi : constant Matrix := Make_Poisson_1D (8);
      Dom : constant Float := Poisson_Eigenvalue (8, 8);
      R   : Eigenpair_Result;
      J   : Spectrum_Result;
      Zero_Start : constant Vector := [0.0, 0.0, 0.0];
      Bad : Eigenpair_Result;
   begin
      R := Power_Dominant
             (Poi, Make_Perturbed_Basis (8, 8, 0.05),
              (Tol => 1.0E-7, Max_Iter => 400, Mu => 0.0,
               Has_Shift => False, M => 0, Max_Sweeps => 50));
      Check (R.Success, "Power on Poisson");
      Check (Approx (R.Eigenvalue, Dom, 8.0E-2)
             or else Approx (R.Eigenvalue, Poisson_Eigenvalue (8, 7), 8.0E-2),
             "Power ≈ large Poisson eigen");
      J := Jacobi_Diagonalize (Poi);
      Check (J.Success, "Jacobi Poisson");
      Check (Approx (J.Eigenvalues (8), Dom, 1.0E-2), "Jacobi λ_max Poisson");
      Bad := Power_Dominant (Make_Diagonal ([1.0, 2.0, 3.0]), Zero_Start);
      Check (Bad.Stat = Ill_Started, "Power zero start Ill_Started");
      declare
         Wide : constant Matrix (1 .. 2, 1 .. 3) :=
           [others => [others => 0.0]];
      begin
         Check (not Is_Square (Wide), "nonsquare Is_Square false");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("15. More Power / Inverse / RQI cases");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix := Make_Known_Spectrum_Symmetric ([1.0, 3.0, 5.0]);
      R  : Eigenpair_Result;
      P  : Parameters := Default_Parameters;
   begin
      R := Power_Dominant (A, Make_Ones_Vector (3), P);
      Check (R.Success, "Power known-spectrum success");
      Check (Approx (R.Eigenvalue, 5.0, 5.0E-2), "Power known λ≈5");
      R := Inverse_Near (A, 0.9, Make_Perturbed_Basis (3, 1), P);
      Check (R.Success, "Inverse known-spectrum");
      Check (Approx (R.Eigenvalue, 1.0, 5.0E-2), "Inverse known λ≈1");
      P.Has_Shift := False;
      R := Rayleigh_Quotient_Iterate
             (Make_Diagonal ([10.0, 20.0]), Make_Ones_Vector (2), P);
      Check (R.Success, "RQI no initial shift");
      Check (R.Residual < 1.0E-3, "RQI no-shift residual");
   end;

   ---------------------------------------------------------------------
   Section ("16. Jacobi / QR extras");
   ---------------------------------------------------------------------
   declare
      D : constant Matrix := Make_Diagonal ([4.0, 1.0, 2.0, 3.0]);
      J : Spectrum_Result;
      Q : Spectrum_Result;
      P : Parameters := Default_Parameters;
   begin
      P.Tol := 1.0E-9;
      J := Jacobi_Diagonalize (D, P);
      Check (J.Success, "Jacobi on diagonal");
      Check (Approx (J.Eigenvalues (1), 1.0, 1.0E-5), "Jacobi diag λ1");
      Check (Approx (J.Eigenvalues (4), 4.0, 1.0E-5), "Jacobi diag λ4");
      Check (J.Off_Diag < 1.0E-6, "Jacobi Final nearly diagonal");
      Q := QR_Unshifted (D, P);
      Check (Q.Success, "QR on diagonal again");
      Check (Approx (Q.Eigenvalues (2), 2.0, 1.0E-4), "QR mid λ");
      --  Nonsymmetric Jacobi reject
      J := Jacobi_Diagonalize (Make_Nonsymmetric (3));
      Check (J.Stat = Not_Symmetric, "Jacobi rejects nonsym");
      Check (not J.Success, "Jacobi nonsym fail");
   end;

   ---------------------------------------------------------------------
   Section ("17. Krylov extras / Method_Info catalogue");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Poisson_1D (4);
      L : Krylov_Result;
      Ar : Krylov_Result;
      P : Parameters := Default_Parameters;
      Info : Method_Info;
   begin
      P.M := 2;
      L := Lanczos_Build (A, Make_Ones_Vector (4), P);
      Check (L.Success and then L.Steps = 2, "Lanczos M=2");
      Check (L.Betas (1) > 0.0 or else L.Stat = Breakdown, "Lanczos beta1");
      Ar := Arnoldi_Build (A, Make_Unit_Vector (4, 1), P);
      Check (Ar.Success and then Ar.Steps = 2, "Arnoldi M=2 unit start");
      Check (Approx (Ar.H (1, 1),
                     Rayleigh_Quotient (A, Column (Ar.V, 1) (1 .. 4)),
                     1.0E-4),
             "Arnoldi H11 = Rayleigh");
      Info := Classify_Method (Power);
      Check (Info.Runnable_Sketch and then not Info.Full_Spectrum,
             "Power Method_Info");
      Info := Classify_Method (QR_Iteration);
      Check (Info.Full_Spectrum and then not Info.Krylov, "QR Method_Info");
      Info := Classify_Method (Rayleigh_Quotient);
      Check (Info.Uses_Shift and then Info.Runnable_Sketch, "RQI Method_Info");
      Check (Method_Name (Lanczos) = "Lanczos", "Name Lanczos");
      Check (Method_Name (Arnoldi) = "Arnoldi", "Name Arnoldi");
      Check (Method_Name (QR_Iteration) = "QR_Iteration", "Name QR");
      Check (Method_Name (Jacobi_Symmetric) = "Jacobi_Symmetric", "Name Jacobi");
      Check (Method_Name (Inverse) = "Inverse", "Name Inverse");
      Check (Method_Name (Rayleigh_Quotient) = "Rayleigh_Quotient", "Name RQI");
   end;

   ---------------------------------------------------------------------
   Section ("18. Off_Diag_Norm / Column / ones helpers");
   ---------------------------------------------------------------------
   declare
      I : constant Matrix := Identity (3);
      A : constant Matrix (1 .. 2, 1 .. 2) := [[0.0, 3.0], [4.0, 0.0]];
      C : constant Vector := Column (I, 2);
   begin
      Check (Approx (Off_Diag_Norm (I), 0.0), "Off_Diag Identity");
      Check (Approx (Off_Diag_Norm (A), 5.0, 1.0E-5), "Off_Diag 3-4-5");
      Check (Vec_Near (C, [0.0, 1.0, 0.0], 1.0E-12), "Column e2");
      Check (Vec_Near (Make_Unit_Vector (4, 3), [0.0, 0.0, 1.0, 0.0]),
             "Make_Unit_Vector");
      Check (Approx (Norm2 (Make_Ones_Vector (4)), 2.0, 1.0E-6),
             "Ones norm");
   end;

   New_Line;
   Put_Line ("=====================================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;
   pragma Assert (Fail_Count = 0);

end Tests;
