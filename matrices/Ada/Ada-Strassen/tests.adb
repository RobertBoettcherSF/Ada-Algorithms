--  Standalone test suite for Strassen (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Strassen; use Strassen;

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

begin
   Ada.Text_IO.Put_Line ("Strassen algorithm test suite");
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
   Section ("2. Is_Square / Power_Of_Two / Next_Power_Of_Two");
   ---------------------------------------------------------------------
   declare
      S : constant Matrix := Identity (3);
      R : constant Matrix (1 .. 2, 1 .. 3) :=
        [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]];
   begin
      Check (Is_Square (S), "Identity square");
      Check (not Is_Square (R), "2x3 not square");
      Check (Is_Power_Of_Two (1), "1 is 2^0");
      Check (Is_Power_Of_Two (2), "2 is 2^1");
      Check (Is_Power_Of_Two (8), "8 is 2^3");
      Check (Is_Power_Of_Two (32), "32 is 2^5");
      Check (not Is_Power_Of_Two (0), "0 not power");
      Check (not Is_Power_Of_Two (3), "3 not power");
      Check (not Is_Power_Of_Two (6), "6 not power");
      Check (Next_Power_Of_Two (1) = 1, "next(1)=1");
      Check (Next_Power_Of_Two (2) = 2, "next(2)=2");
      Check (Next_Power_Of_Two (3) = 4, "next(3)=4");
      Check (Next_Power_Of_Two (5) = 8, "next(5)=8");
      Check (Next_Power_Of_Two (17) = 32, "next(17)=32");
      Check (Next_Power_Of_Two (0) = 0, "next(0)=0");
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
   Section ("4. Builders: Zeros / Ones / Identity / Sequential / Det");
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
   Section ("5. Pad / Trim");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Sequential_Fill (3);
      P : constant Matrix := Pad_To_Power_Of_Two (A);
      T : constant Matrix := Trim (P, 3);
   begin
      Check (P'Length (1) = 4 and P'Length (2) = 4, "pad 3→4 size");
      Check (Approx (P (4, 4), 0.0) and Approx (P (3, 3), 9.0),
             "pad zeros + keep");
      Check (Mat_Near (T, A), "trim recovers");
      declare
         B : constant Matrix := Identity (4);
         Q : constant Matrix := Pad_To_Power_Of_Two (B);
      begin
         Check (Q'Length (1) = 4 and Mat_Near (Q, B), "pad already pot");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Classical: Identity / known 2x2");
   ---------------------------------------------------------------------
   declare
      I : constant Matrix := Identity (1);
      R : constant Multiply_Result := Multiply_Classical (I, I);
   begin
      Check (R.Success and R.Stat = Ok, "1x1 classical Success");
      Check (Approx (R.C (1, 1), 1.0), "1x1 product 1");
      Check (R.Scalar_Multiplies = 1, "1x1 mults=1");
   end;
   declare
      I : constant Matrix := Identity (4);
      A : constant Matrix := Sequential_Fill (4);
      R : constant Multiply_Result := Multiply_Classical (I, A);
   begin
      Check (R.Success, "I*A Success");
      Check (Mat_Near (Leading (R), A), "I*A = A");
      Check (R.Scalar_Multiplies = 64, "4x4 classical mults=64");
      Check (R.Recursion_Depth = 0, "classical depth 0");
   end;
   declare
      --  [[1,2],[3,4]] * [[5,6],[7,8]] = [[19,22],[43,50]]
      A : constant Matrix (1 .. 2, 1 .. 2) := [[1.0, 2.0], [3.0, 4.0]];
      B : constant Matrix (1 .. 2, 1 .. 2) := [[5.0, 6.0], [7.0, 8.0]];
      R : constant Multiply_Result := Multiply_Classical (A, B);
   begin
      Check (R.Success, "2x2 classical Success");
      Check (Approx (R.C (1, 1), 19.0) and Approx (R.C (1, 2), 22.0)
               and Approx (R.C (2, 1), 43.0) and Approx (R.C (2, 2), 50.0),
             "2x2 classical values");
      Check (R.Scalar_Multiplies = 8, "2x2 classical mults=8");
   end;

   ---------------------------------------------------------------------
   Section ("7. Strassen ≡ Classical on identity");
   ---------------------------------------------------------------------
   for N in 1 .. 8 loop
      declare
         I  : constant Matrix := Identity (N);
         A  : constant Matrix := Deterministic (N, 3);
         RC : constant Multiply_Result := Multiply_Classical (I, A);
         RS : constant Multiply_Result := Multiply_Strassen (I, A);
      begin
         Check (RC.Success and RS.Success,
                "I*A n=" & N'Image & " both Success");
         Check (Mat_Near (Leading (RC), Leading (RS), 1.0E-4),
                "I*A n=" & N'Image & " Strassen≡Classical");
         Check (Mat_Near (Leading (RS), A, 1.0E-4),
                "I*A n=" & N'Image & " = A");
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("8. Strassen ≡ Classical small n (dense)");
   ---------------------------------------------------------------------
   for N in 1 .. 8 loop
      declare
         A  : constant Matrix := Deterministic (N, 11);
         B  : constant Matrix := Deterministic (N, 29);
         RC : constant Multiply_Result := Multiply_Classical (A, B);
         RS : constant Multiply_Result := Multiply_Strassen (A, B);
         Diff : constant Float :=
           Diff_Frobenius (Leading (RC), Leading (RS));
      begin
         Check (RC.Success and RS.Success,
                "AB n=" & N'Image & " Success");
         Check (Diff < 1.0E-3,
                "AB n=" & N'Image & " ‖C_c−C_s‖_F small");
         Check (Mat_Near (Leading (RC), Leading (RS), 1.0E-3),
                "AB n=" & N'Image & " Mat_Near");
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("9. Known 2x2 Strassen products");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) := [[1.0, 2.0], [3.0, 4.0]];
      B : constant Matrix (1 .. 2, 1 .. 2) := [[5.0, 6.0], [7.0, 8.0]];
      R : constant Multiply_Result := Multiply_Strassen (A, B);
   begin
      Check (R.Success and R.Stat = Ok, "2x2 Strassen Success");
      Check (Approx (R.C (1, 1), 19.0) and Approx (R.C (1, 2), 22.0)
               and Approx (R.C (2, 1), 43.0) and Approx (R.C (2, 2), 50.0),
             "2x2 Strassen values");
      Check (R.Padded_N = 2, "2x2 no pad");
      Check (R.Recursion_Depth >= 1, "2x2 recursion depth≥1");
      --  Leaf=1 ⇒ seven 1×1 multiplies
      Check (R.Scalar_Multiplies = 7, "2x2 Strassen mults=7");
   end;

   ---------------------------------------------------------------------
   Section ("10. Scalar multiply counts (education)");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Deterministic (4, 1);
      B : constant Matrix := Deterministic (4, 2);
      RC : constant Multiply_Result := Multiply_Classical (A, B);
      RS : constant Multiply_Result := Multiply_Strassen (A, B);
      --  Leaf=1: 4→2→1 ⇒ 7^2 = 49 leaf multiplies
      RS8 : constant Multiply_Result :=
        Multiply_Strassen (Deterministic (8, 1), Deterministic (8, 2));
   begin
      Check (RC.Scalar_Multiplies = 64, "classical 4x4 = 64");
      Check (RS.Scalar_Multiplies = 49, "Strassen 4x4 Leaf=1 = 49");
      Check (RS.Scalar_Multiplies < RC.Scalar_Multiplies,
             "Strassen fewer mults than classical @4");
      Check (RS8.Scalar_Multiplies = 343, "Strassen 8x8 Leaf=1 = 7^3");
      Check (RS8.Success, "8x8 Strassen Success");
   end;

   ---------------------------------------------------------------------
   Section ("11. Leaf threshold");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Deterministic (4, 5);
      B : constant Matrix := Deterministic (4, 7);
      R1 : constant Multiply_Result := Multiply_Strassen (A, B, Leaf => 1);
      R4 : constant Multiply_Result := Multiply_Strassen (A, B, Leaf => 4);
      R8 : constant Multiply_Result := Multiply_Strassen (A, B, Leaf => 8);
   begin
      Check (Mat_Near (Leading (R1), Leading (R4), 1.0E-4),
             "Leaf 1 ≡ Leaf 4");
      Check (Mat_Near (Leading (R1), Leading (R8), 1.0E-4),
             "Leaf 1 ≡ Leaf 8");
      Check (R4.Scalar_Multiplies = 64, "Leaf≥4 ⇒ classical 64");
      Check (R4.Recursion_Depth = 0, "Leaf≥4 depth 0");
      Check (R1.Recursion_Depth = 2, "4x4 Leaf=1 depth 2");
   end;

   ---------------------------------------------------------------------
   Section ("12. Pad-and-trim (non-power-of-2)");
   ---------------------------------------------------------------------
   declare
      Sizes : constant array (Positive range <>) of Dimension :=
        [3, 5, 6, 7, 9, 12, 15];
   begin
      for K in Sizes'Range loop
         declare
            N  : constant Dimension := Sizes (K);
            A  : constant Matrix := Deterministic (N, 13);
            B  : constant Matrix := Deterministic (N, 17);
            RC : constant Multiply_Result := Multiply_Classical (A, B);
            RS : constant Multiply_Result := Multiply_Strassen (A, B);
         begin
            Check (RC.Success and RS.Success,
                   "pad n=" & N'Image & " Success");
            Check (RS.Padded_N = Next_Power_Of_Two (N),
                   "pad n=" & N'Image & " Padded_N");
            Check (Diff_Frobenius (Leading (RC), Leading (RS)) < 1.0E-3,
                   "pad n=" & N'Image & " residual≈0");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("13. Associativity sketch (A B) C ≈ A (B C)");
   ---------------------------------------------------------------------
   declare
      N : constant := 4;
      A : constant Matrix := Deterministic (N, 2);
      B : constant Matrix := Deterministic (N, 3);
      C : constant Matrix := Deterministic (N, 5);
      AB : constant Multiply_Result := Multiply_Strassen (A, B);
      BC : constant Multiply_Result := Multiply_Strassen (B, C);
      Left  : constant Multiply_Result :=
        Multiply_Strassen (Leading (AB), C);
      Right : constant Multiply_Result :=
        Multiply_Strassen (A, Leading (BC));
   begin
      Check (Left.Success and Right.Success, "assoc Success");
      Check (Diff_Frobenius (Leading (Left), Leading (Right)) < 1.0E-3,
             "assoc (AB)C ≈ A(BC) Strassen");
   end;
   declare
      N : constant := 3;
      A : constant Matrix := Sequential_Fill (N);
      B : constant Matrix := Identity (N);
      C : constant Matrix := Deterministic (N, 9);
      AB : constant Multiply_Result := Multiply_Classical (A, B);
      BC : constant Multiply_Result := Multiply_Classical (B, C);
      Left  : constant Multiply_Result :=
        Multiply_Classical (Leading (AB), C);
      Right : constant Multiply_Result :=
        Multiply_Classical (A, Leading (BC));
   begin
      Check (Diff_Frobenius (Leading (Left), Leading (Right)) < 1.0E-4,
             "assoc classical n=3");
   end;

   ---------------------------------------------------------------------
   Section ("14. Ones / Zeros edge products");
   ---------------------------------------------------------------------
   declare
      Z : constant Matrix := Zeros (5);
      O : constant Matrix := Ones (5, 1.0);
      R1 : constant Multiply_Result := Multiply_Strassen (Z, O);
      R2 : constant Multiply_Result := Multiply_Strassen (O, O);
      R3 : constant Multiply_Result := Multiply_Classical (O, O);
   begin
      Check (Approx (Norm_Frobenius (Leading (R1)), 0.0), "0*Ones = 0");
      Check (Approx (R2.C (1, 1), 5.0) and Approx (R2.C (5, 5), 5.0),
             "Ones*Ones = n");
      Check (Mat_Near (Leading (R2), Leading (R3), 1.0E-4),
             "Ones Strassen≡Classical");
   end;

   ---------------------------------------------------------------------
   Section ("15. Larger n / residual Strassen vs Classical");
   ---------------------------------------------------------------------
   declare
      Sizes : constant array (Positive range <>) of Dimension := [16, 32];
   begin
      for K in Sizes'Range loop
         declare
            N  : constant Dimension := Sizes (K);
            A  : constant Matrix := Deterministic (N, 41);
            B  : constant Matrix := Deterministic (N, 43);
            RC : constant Multiply_Result := Multiply_Classical (A, B);
            RS : constant Multiply_Result := Multiply_Strassen (A, B);
            Diff : constant Float :=
              Diff_Frobenius (Leading (RC), Leading (RS));
            Tol  : constant Float := 1.0E-2 * Float (N);
         begin
            Check (RC.Success and RS.Success,
                   "large n=" & N'Image & " Success");
            Check (Diff < Tol,
                   "large n=" & N'Image & " ‖diff‖_F bound");
            Check (RS.Padded_N = N, "large n=" & N'Image & " already pot");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("16. A*I and I*A Strassen");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Sequential_Fill (7);
      I : constant Matrix := Identity (7);
      R1 : constant Multiply_Result := Multiply_Strassen (A, I);
      R2 : constant Multiply_Result := Multiply_Strassen (I, A);
   begin
      Check (Mat_Near (Leading (R1), A, 1.0E-4), "A*I = A (pad 7)");
      Check (Mat_Near (Leading (R2), A, 1.0E-4), "I*A = A (pad 7)");
      Check (R1.Padded_N = 8, "7 pads to 8");
   end;

   ---------------------------------------------------------------------
   Section ("17. Dimension_Error / Product_Matrix");
   ---------------------------------------------------------------------
   declare
      --  Precondition requires square equal sizes; exercise Fail_Dim via
      --  oversized path is not reachable under Pre. Check Max_N identity.
      A : constant Matrix := Identity (Max_N);
      R : constant Multiply_Result := Multiply_Strassen (A, A);
      P : constant Matrix := Product_Matrix (R);
   begin
      Check (R.Success and R.N = Max_N, "Max_N Strassen I*I");
      Check (Mat_Near (P, A, 1.0E-3), "Product_Matrix Identity");
      Check (P'Length (1) = Max_N, "Product_Matrix size");
   end;
   declare
      A : constant Matrix := Identity (2);
      B : constant Matrix := Zeros (2);
      R : constant Multiply_Result := Multiply_Classical (A, B);
   begin
      Check (R.Success and Approx (Norm_Frobenius (Leading (R)), 0.0),
             "I*0 classical");
      Check (R.Stat = Ok, "Stat Ok");
   end;

   ---------------------------------------------------------------------
   Section ("18. Hilbert / sequential cross-check");
   ---------------------------------------------------------------------
   declare
      H : constant Matrix := Make_Hilbert (4);
      S : constant Matrix := Sequential_Fill (4);
      RC : constant Multiply_Result := Multiply_Classical (H, S);
      RS : constant Multiply_Result := Multiply_Strassen (H, S);
   begin
      Check (Diff_Frobenius (Leading (RC), Leading (RS)) < 1.0E-3,
             "Hilbert*Seq residual");
   end;
   declare
      A : constant Matrix := Deterministic (1, 99);
      B : constant Matrix := Deterministic (1, 100);
      RS : constant Multiply_Result := Multiply_Strassen (A, B);
      RC : constant Multiply_Result := Multiply_Classical (A, B);
   begin
      Check (Approx (RS.C (1, 1), A (1, 1) * B (1, 1)), "1x1 Strassen");
      Check (Approx (RC.C (1, 1), RS.C (1, 1)), "1x1 match");
      Check (RS.Recursion_Depth = 0, "1x1 depth 0");
      Check (RS.Scalar_Multiplies = 1, "1x1 mults 1");
   end;

   ---------------------------------------------------------------------
   Section ("19. Recursion depth ladder");
   ---------------------------------------------------------------------
   declare
      R2  : constant Multiply_Result :=
        Multiply_Strassen (Identity (2), Identity (2));
      R4  : constant Multiply_Result :=
        Multiply_Strassen (Identity (4), Identity (4));
      R8  : constant Multiply_Result :=
        Multiply_Strassen (Identity (8), Identity (8));
      R16 : constant Multiply_Result :=
        Multiply_Strassen (Identity (16), Identity (16));
   begin
      Check (R2.Recursion_Depth = 1, "depth n=2 → 1");
      Check (R4.Recursion_Depth = 2, "depth n=4 → 2");
      Check (R8.Recursion_Depth = 3, "depth n=8 → 3");
      Check (R16.Recursion_Depth = 4, "depth n=16 → 4");
   end;

   ---------------------------------------------------------------------
   Section ("20. Mixed builders residual sweep");
   ---------------------------------------------------------------------
   declare
      procedure Cross (N : Dimension; Label : String) is
         A  : constant Matrix := Sequential_Fill (N);
         B  : constant Matrix := Ones (N, 0.5);
         RC : constant Multiply_Result := Multiply_Classical (A, B);
         RS : constant Multiply_Result := Multiply_Strassen (A, B);
      begin
         Check (Diff_Frobenius (Leading (RC), Leading (RS)) < 1.0E-3,
                "cross " & Label);
      end Cross;
   begin
      Cross (1, "n=1");
      Cross (2, "n=2");
      Cross (3, "n=3");
      Cross (4, "n=4");
      Cross (5, "n=5");
      Cross (8, "n=8");
      Cross (10, "n=10");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("----------------------------------");
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
