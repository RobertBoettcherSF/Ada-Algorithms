--  Standalone test suite for Cannon's algorithm (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Cannons_Algorithm; use Cannons_Algorithm;

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

   function Approx (A, B : Float; Tol : Float := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Leading (R : Multiply_Result) return Matrix is
   begin
      return Product_Matrix (R);
   end Leading;

   --  Compare Cannon vs classical for given n and Grid_P (0 = default).
   procedure Check_Cannon_Eq_Classical
     (N : Dimension; P : Natural; Seed_A, Seed_B : Natural; Label : String)
   is
      A  : constant Matrix := Deterministic (N, Seed_A);
      B  : constant Matrix := Deterministic (N, Seed_B);
      RC : constant Multiply_Result := Multiply_Classical (A, B);
      RK : constant Multiply_Result := Multiply_Cannon (A, B, P);
      Eff_P : constant Natural := (if P = 0 then N else P);
   begin
      Check (RC.Success and RK.Success, Label & " both succeed");
      Check (RK.Stat = Ok and RK.N = N, Label & " status/N");
      Check (RK.Grid_P = Eff_P and RK.Block_Size = N / Eff_P
               and RK.Shift_Count = Eff_P,
             Label & " grid telemetry");
      Check (Mat_Near (Leading (RK), Leading (RC)),
             Label & " Cannon ≡ classical");
      Check (Approx (Diff_Frobenius (Leading (RK), Leading (RC)), 0.0,
                     1.0E-4),
             Label & " residual ≈ 0");
   end Check_Cannon_Eq_Classical;

begin
   Ada.Text_IO.Put_Line ("Cannon's algorithm test suite");
   Ada.Text_IO.Put_Line ("=============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Mat_Near / Norm_Frobenius / Diff");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) := [[3.0, 4.0], [0.0, 0.0]];
      B : constant Matrix (1 .. 2, 1 .. 2) := [[3.0, 4.0], [0.0, 0.0]];
      C : constant Matrix (1 .. 2, 1 .. 2) := [[1.0, 0.0], [0.0, 0.0]];
      Z : constant Matrix := Zeros (2);
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny");
      Check (not Near (1.0, 2.0), "Near rejects");
      Check (Mat_Near (A, B), "Mat_Near equal");
      Check (not Mat_Near (A, C), "Mat_Near rejects");
      Check (Approx (Norm_Frobenius (A), 5.0), "Frobenius 3-4");
      Check (Approx (Norm_Frobenius (Z), 0.0), "Frobenius zero");
      Check (Approx (Diff_Frobenius (A, B), 0.0), "Diff zero");
      Check (Approx (Diff_Frobenius (A, C), 4.472_136, 1.0E-4),
             "Diff 3-4 vs e1");
      Check (Near (-2.0, -2.0), "Near negatives");
   end;

   ---------------------------------------------------------------------
   Section ("2. Is_Square / Divides / Is_Valid_Grid");
   ---------------------------------------------------------------------
   declare
      S : constant Matrix := Identity (3);
      R : constant Matrix (1 .. 2, 1 .. 3) :=
        [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]];
   begin
      Check (Is_Square (S), "Identity square");
      Check (not Is_Square (R), "2x3 not square");
      Check (Divides (2, 8), "2|8");
      Check (Divides (4, 4), "4|4");
      Check (not Divides (3, 8), "3 not| 8");
      Check (not Divides (0, 4), "0 not divides");
      Check (Is_Valid_Grid (8, 2), "grid 8/2");
      Check (Is_Valid_Grid (8, 8), "grid 8/8");
      Check (Is_Valid_Grid (1, 1), "grid 1/1");
      Check (not Is_Valid_Grid (8, 3), "grid 8/3 bad");
      Check (not Is_Valid_Grid (8, 0), "grid P=0 bad");
      Check (not Is_Valid_Grid (0, 1), "grid N=0 bad");
      Check (not Is_Valid_Grid (8, 16), "grid P>N bad");
   end;

   ---------------------------------------------------------------------
   Section ("3. Mat_Add / Mat_Sub / Mat_Scale");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) := [[1.0, 2.0], [3.0, 4.0]];
      B : constant Matrix (1 .. 2, 1 .. 2) := [[5.0, 6.0], [7.0, 8.0]];
      S : constant Matrix := Mat_Add (A, B);
      D : constant Matrix := Mat_Sub (A => B, B => A);
      T : constant Matrix := Mat_Scale (A, 2.0);
   begin
      Check (Approx (S (1, 1), 6.0) and Approx (S (2, 2), 12.0), "Add");
      Check (Approx (D (1, 1), 4.0) and Approx (D (2, 1), 4.0), "Sub");
      Check (Approx (T (1, 2), 4.0) and Approx (T (2, 2), 8.0), "Scale");
   end;

   ---------------------------------------------------------------------
   Section ("4. Builders");
   ---------------------------------------------------------------------
   declare
      Z : constant Matrix := Zeros (3);
      O : constant Matrix := Ones (2, 7.0);
      I : constant Matrix := Identity (4);
      S : constant Matrix := Sequential_Fill (2);
      D : constant Matrix := Deterministic (3, 1);
      H : constant Matrix := Make_Hilbert (3);
   begin
      Check (Approx (Z (2, 2), 0.0) and Approx (Norm_Frobenius (Z), 0.0),
             "Zeros");
      Check (Approx (O (1, 1), 7.0) and Approx (O (2, 2), 7.0), "Ones");
      Check (Approx (I (1, 1), 1.0) and Approx (I (2, 3), 0.0)
               and Approx (I (4, 4), 1.0),
             "Identity entries");
      Check (Approx (S (1, 1), 1.0) and Approx (S (1, 2), 2.0)
               and Approx (S (2, 1), 3.0) and Approx (S (2, 2), 4.0),
             "Sequential_Fill 2x2");
      Check (D (1, 1) >= 0.0 and D (1, 1) < 1.0
               and D (3, 3) >= 0.0 and D (3, 3) < 1.0,
             "Deterministic in [0,1)");
      Check (Approx (H (1, 1), 1.0) and Approx (H (1, 2), 0.5)
               and Approx (H (2, 2), 1.0 / 3.0, 1.0E-6),
             "Hilbert");
   end;

   ---------------------------------------------------------------------
   Section ("5. Classical multiply basics");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) := [[1.0, 2.0], [3.0, 4.0]];
      B : constant Matrix (1 .. 2, 1 .. 2) := [[5.0, 6.0], [7.0, 8.0]];
      R : constant Multiply_Result := Multiply_Classical (A, B);
      --  [[19,22],[43,50]]
   begin
      Check (R.Success and R.Stat = Ok and R.N = 2, "classical ok");
      Check (Approx (R.C (1, 1), 19.0) and Approx (R.C (1, 2), 22.0)
               and Approx (R.C (2, 1), 43.0) and Approx (R.C (2, 2), 50.0),
             "classical 2x2 known");
      Check (R.Shift_Count = 0 and R.Grid_P = 0, "classical no mesh");
   end;
   declare
      I : constant Matrix := Identity (5);
      A : constant Matrix := Sequential_Fill (5);
      R : constant Multiply_Result := Multiply_Classical (I, A);
   begin
      Check (Mat_Near (Leading (R), A), "I * A = A classical");
   end;
   declare
      A : constant Matrix := Ones (3, 2.0);
      B : constant Matrix := Ones (3, 3.0);
      R : constant Multiply_Result := Multiply_Classical (A, B);
   begin
      --  each entry = 2*3*3 = 18
      Check (Approx (R.C (1, 1), 18.0) and Approx (R.C (3, 3), 18.0),
             "ones classical product");
   end;

   ---------------------------------------------------------------------
   Section ("6. Cannon 1x1 and small element-per-PE");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 1) := [[7.0]];
      B : constant Matrix (1 .. 1, 1 .. 1) := [[3.0]];
      R : constant Multiply_Result := Multiply_Cannon (A, B);
   begin
      Check (R.Success and Approx (R.C (1, 1), 21.0), "1x1 product");
      Check (R.Grid_P = 1 and R.Block_Size = 1 and R.Shift_Count = 1,
             "1x1 telemetry");
   end;
   Check_Cannon_Eq_Classical (2, 0, 1, 2, "n=2 default P");
   Check_Cannon_Eq_Classical (2, 2, 3, 4, "n=2 P=2");
   Check_Cannon_Eq_Classical (3, 0, 5, 6, "n=3 default P");
   Check_Cannon_Eq_Classical (3, 3, 7, 8, "n=3 P=3");
   Check_Cannon_Eq_Classical (4, 0, 1, 9, "n=4 default P");

   ---------------------------------------------------------------------
   Section ("7. Cannon with block tiles (various P)");
   ---------------------------------------------------------------------
   Check_Cannon_Eq_Classical (4, 1, 2, 3, "n=4 P=1 (single PE)");
   Check_Cannon_Eq_Classical (4, 2, 4, 5, "n=4 P=2 BS=2");
   Check_Cannon_Eq_Classical (4, 4, 6, 7, "n=4 P=4 BS=1");
   Check_Cannon_Eq_Classical (6, 2, 1, 2, "n=6 P=2");
   Check_Cannon_Eq_Classical (6, 3, 3, 4, "n=6 P=3");
   Check_Cannon_Eq_Classical (6, 6, 5, 6, "n=6 P=6");
   Check_Cannon_Eq_Classical (8, 2, 1, 1, "n=8 P=2");
   Check_Cannon_Eq_Classical (8, 4, 2, 2, "n=8 P=4");
   Check_Cannon_Eq_Classical (8, 8, 3, 3, "n=8 P=8");
   Check_Cannon_Eq_Classical (9, 3, 4, 5, "n=9 P=3");
   Check_Cannon_Eq_Classical (9, 9, 6, 7, "n=9 P=9");

   ---------------------------------------------------------------------
   Section ("8. Identity / zeros / scale residuals");
   ---------------------------------------------------------------------
   for N in 1 .. 8 loop
      declare
         I  : constant Matrix := Identity (N);
         A  : constant Matrix := Deterministic (N, N);
         RI : constant Multiply_Result := Multiply_Cannon (I, A, 0);
         RA : constant Multiply_Result := Multiply_Cannon (A, I,
            (if N mod 2 = 0 then 2 else 1));
         Z  : constant Matrix := Zeros (N);
         RZ : constant Multiply_Result := Multiply_Cannon (A, Z,
            (if N mod 2 = 0 and N >= 2 then N / 2 else N));
      begin
         Check (Mat_Near (Leading (RI), A),
                "I*A identity left n=" & N'Image);
         Check (Mat_Near (Leading (RA), A),
                "A*I identity right n=" & N'Image);
         Check (Approx (Norm_Frobenius (Leading (RZ)), 0.0),
                "A*0 = 0 n=" & N'Image);
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("9. Sequential / Hilbert / Ones products");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Sequential_Fill (4);
      B : constant Matrix := Sequential_Fill (4);
      RC : constant Multiply_Result := Multiply_Classical (A, B);
      R1 : constant Multiply_Result := Multiply_Cannon (A, B, 1);
      R2 : constant Multiply_Result := Multiply_Cannon (A, B, 2);
      R4 : constant Multiply_Result := Multiply_Cannon (A, B, 4);
   begin
      Check (Mat_Near (Leading (R1), Leading (RC)), "seq P=1");
      Check (Mat_Near (Leading (R2), Leading (RC)), "seq P=2");
      Check (Mat_Near (Leading (R4), Leading (RC)), "seq P=4");
   end;
   declare
      H : constant Matrix := Make_Hilbert (5);
      I : constant Matrix := Identity (5);
      R : constant Multiply_Result := Multiply_Cannon (H, I, 5);
   begin
      Check (Mat_Near (Leading (R), H, 1.0E-5), "Hilbert * I");
   end;
   declare
      A : constant Matrix := Ones (4, 1.5);
      B : constant Matrix := Ones (4, 2.0);
      R : constant Multiply_Result := Multiply_Cannon (A, B, 2);
      --  entry = 1.5 * 2.0 * 4 = 12
   begin
      Check (Approx (R.C (1, 1), 12.0) and Approx (R.C (4, 4), 12.0),
             "ones block product");
   end;

   ---------------------------------------------------------------------
   Section ("10. Larger n batch Cannon ≡ classical");
   ---------------------------------------------------------------------
   for N in 10 .. 16 loop
      declare
         --  Prefer a divisor of N for Grid_P when possible.
         P : Natural := N;
      begin
         if N mod 2 = 0 then
            P := 2;
         elsif N mod 3 = 0 then
            P := 3;
         end if;
         Check_Cannon_Eq_Classical (N, 0, N, N + 1,
                                    "large default n=" & N'Image);
         Check_Cannon_Eq_Classical (N, P, N + 2, N + 3,
                                    "large P mesh n=" & N'Image);
         Check_Cannon_Eq_Classical (N, 1, N + 4, N + 5,
                                    "large P=1 n=" & N'Image);
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("11. Max_N / mid sizes with several grids");
   ---------------------------------------------------------------------
   Check_Cannon_Eq_Classical (16, 4, 10, 11, "n=16 P=4");
   Check_Cannon_Eq_Classical (16, 8, 12, 13, "n=16 P=8");
   Check_Cannon_Eq_Classical (16, 16, 14, 15, "n=16 P=16");
   Check_Cannon_Eq_Classical (24, 3, 1, 2, "n=24 P=3");
   Check_Cannon_Eq_Classical (24, 4, 3, 4, "n=24 P=4");
   Check_Cannon_Eq_Classical (24, 6, 5, 6, "n=24 P=6");
   Check_Cannon_Eq_Classical (32, 2, 7, 8, "n=32 P=2");
   Check_Cannon_Eq_Classical (32, 4, 9, 10, "n=32 P=4");
   Check_Cannon_Eq_Classical (32, 8, 11, 12, "n=32 P=8");

   ---------------------------------------------------------------------
   Section ("12. Dimension errors / bad Grid_P");
   ---------------------------------------------------------------------
   declare
      A4 : constant Matrix := Identity (4);
      B4 : constant Matrix := Ones (4);
      R0 : constant Multiply_Result := Multiply_Cannon (A4, B4, 3);
      --  3 does not divide 4
      R5 : constant Multiply_Result := Multiply_Cannon (A4, B4, 5);
      --  P > n
      R1 : constant Matrix := Identity (1);
      --  empty-ish: classical on Max uses valid; Dimension via Grid
   begin
      Check (R0.Stat = Dimension_Error and not R0.Success,
             "P=3 does not divide n=4");
      Check (R5.Stat = Dimension_Error and not R5.Success,
             "P=5 > n=4");
      Check (Multiply_Cannon (A4, B4, 0).Success, "default P ok");
      Check (Multiply_Classical (R1, R1).Success, "1x1 classical ok");
   end;
   declare
      A : constant Matrix := Deterministic (8, 1);
      B : constant Matrix := Deterministic (8, 2);
   begin
      Check (Multiply_Cannon (A, B, 7).Stat = Dimension_Error,
             "P=7 not| 8");
      Check (Multiply_Cannon (A, B, 16).Stat = Dimension_Error,
             "P=16 > 8");
      Check (Multiply_Cannon (A, B, 1).Success
               and Multiply_Cannon (A, B, 1).Shift_Count = 1,
             "P=1 single-PE ok");
   end;

   ---------------------------------------------------------------------
   Section ("13. Product_Matrix / input immutability");
   ---------------------------------------------------------------------
   declare
      A0 : constant Matrix := Sequential_Fill (3);
      B0 : constant Matrix := Deterministic (3, 9);
      A  : constant Matrix := A0;
      B  : constant Matrix := B0;
      R  : constant Multiply_Result := Multiply_Cannon (A, B, 3);
      P  : constant Matrix := Product_Matrix (R);
   begin
      Check (Mat_Near (A, A0) and Mat_Near (B, B0), "inputs unchanged");
      Check (P'Length (1) = 3 and Mat_Near (P, Leading (R)),
             "Product_Matrix shape");
   end;

   ---------------------------------------------------------------------
   Section ("14. Scale / Mat_Scale consistency");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Mat_Scale (Identity (5), 4.0);
      B : constant Matrix := Sequential_Fill (5);
      R : constant Multiply_Result := Multiply_Cannon (A, B, 5);
      E : constant Matrix := Mat_Scale (B, 4.0);
   begin
      Check (Mat_Near (Leading (R), E), "4I * B = 4B via Cannon");
   end;

   ---------------------------------------------------------------------
   Section ("15. Non-1-based bounds (offset matrices)");
   ---------------------------------------------------------------------
   declare
      A : Matrix (3 .. 5, 7 .. 9);
      B : Matrix (10 .. 12, 2 .. 4);
      K : Natural := 0;
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            K := K + 1;
            A (I, J) := Float (K);
         end loop;
      end loop;
      K := 0;
      for I in B'Range (1) loop
         for J in B'Range (2) loop
            K := K + 1;
            B (I, J) := Float (K) * 0.5;
         end loop;
      end loop;
      declare
         RC : constant Multiply_Result := Multiply_Classical (A, B);
         RK : constant Multiply_Result := Multiply_Cannon (A, B, 3);
      begin
         Check (RC.Success and RK.Success, "offset both ok");
         Check (Mat_Near (Leading (RK), Leading (RC)),
                "offset Cannon ≡ classical");
      end;
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("=================================");
   Ada.Text_IO.Put_Line
     ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;

end Tests;
