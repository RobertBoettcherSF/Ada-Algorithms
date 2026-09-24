--  Standalone test suite for Freivalds (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Freivalds; use Freivalds;

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

begin
   Ada.Text_IO.Put_Line ("Freivalds' algorithm test suite");
   Ada.Text_IO.Put_Line ("===============================");

   ---------------------------------------------------------------------
   Section ("1. Is_Square / Mat_Equal / Vec_Equal / Mat_Max_Abs");
   ---------------------------------------------------------------------
   declare
      S : constant Matrix := Identity (3);
      R : constant Matrix (1 .. 2, 1 .. 3) :=
        [[1, 2, 3], [4, 5, 6]];
      A : constant Matrix (1 .. 2, 1 .. 2) := [[3, 4], [0, 0]];
      B : constant Matrix (1 .. 2, 1 .. 2) := [[3, 4], [0, 0]];
      C : constant Matrix (1 .. 2, 1 .. 2) := [[1, 0], [0, 0]];
      U : constant Vector (1 .. 3) := [1, 2, 3];
      V : constant Vector (1 .. 3) := [1, 2, 3];
      W : constant Vector (1 .. 3) := [1, 2, 0];
   begin
      Check (Is_Square (S), "Identity square");
      Check (not Is_Square (R), "2x3 not square");
      Check (Mat_Equal (A, B), "Mat_Equal equal");
      Check (not Mat_Equal (A, C), "Mat_Equal rejects");
      Check (Vec_Equal (U, V), "Vec_Equal equal");
      Check (not Vec_Equal (U, W), "Vec_Equal rejects");
      Check (Mat_Max_Abs (A) = 4, "Mat_Max_Abs 4");
      Check (Mat_Max_Abs (Zeros (2)) = 0, "Mat_Max_Abs zero");
   end;

   ---------------------------------------------------------------------
   Section ("2. Mat_Add / Mat_Sub / Mat_Scale / Vec_Sub");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) := [[1, 2], [3, 4]];
      B : constant Matrix (1 .. 2, 1 .. 2) := [[5, 6], [7, 8]];
      S : constant Matrix := Mat_Add (A, B);
      D : constant Matrix := Mat_Sub (A => B, B => A);
      T : constant Matrix := Mat_Scale (A, 2);
      U : constant Vector (1 .. 2) := [10, 20];
      V : constant Vector (1 .. 2) := [3, 5];
      W : constant Vector := Vec_Sub (U, V);
   begin
      Check (S (1, 1) = 6 and S (2, 2) = 12, "Add");
      Check (D (1, 1) = 4 and D (2, 1) = 4, "Sub");
      Check (T (1, 2) = 4 and T (2, 2) = 8, "Scale");
      Check (W (1) = 7 and W (2) = 15, "Vec_Sub");
   end;

   ---------------------------------------------------------------------
   Section ("3. Builders: Zeros / Ones / Identity / Sequential / Det");
   ---------------------------------------------------------------------
   declare
      Z : constant Matrix := Zeros (3);
      O : constant Matrix := Ones (2, 7);
      I : constant Matrix := Identity (4);
      S : constant Matrix := Sequential_Fill (2);
      D : constant Matrix := Deterministic (3, 1);
      ZV : constant Vector := Zero_Vector (3);
      OV : constant Vector := Ones_Vector (2, 9);
   begin
      Check (Z (2, 2) = 0 and Mat_Max_Abs (Z) = 0, "Zeros");
      Check (O (1, 1) = 7 and O (2, 2) = 7, "Ones");
      Check (I (1, 1) = 1 and I (2, 3) = 0 and I (4, 4) = 1,
             "Identity entries");
      Check (S (1, 1) = 1 and S (1, 2) = 2
               and S (2, 1) = 3 and S (2, 2) = 4,
             "Sequential_Fill 2x2");
      Check (D (1, 1) in 0 .. 9 and D (3, 3) in 0 .. 9,
             "Deterministic in 0..9");
      Check (ZV (1) = 0 and ZV (3) = 0, "Zero_Vector");
      Check (OV (1) = 9 and OV (2) = 9, "Ones_Vector");
   end;

   ---------------------------------------------------------------------
   Section ("4. Corrupt_Entry");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Identity (3);
      C : constant Matrix := Corrupt_Entry (A, 2, 2, 5);
   begin
      Check (C (2, 2) = 6, "Corrupt diagonal +5");
      Check (C (1, 1) = 1 and C (3, 3) = 1, "Corrupt leaves others");
      Check (not Mat_Equal (A, C), "Corrupt differs");
   end;

   ---------------------------------------------------------------------
   Section ("5. Mat_Vec");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) := [[1, 2], [3, 4]];
      X : constant Vector (1 .. 2) := [1, 0];
      Y : constant Vector := Mat_Vec (A, X);
      Z : constant Vector := Mat_Vec (A, [0, 1]);
   begin
      Check (Y (1) = 1 and Y (2) = 3, "Mat_Vec e1");
      Check (Z (1) = 2 and Z (2) = 4, "Mat_Vec e2");
   end;
   declare
      I : constant Matrix := Identity (5);
      X : constant Vector (1 .. 5) := [2, 3, 5, 7, 11];
      Y : constant Vector := Mat_Vec (I, X);
   begin
      Check (Vec_Equal (Y, X), "I * x = x");
   end;

   ---------------------------------------------------------------------
   Section ("6. LCG / Random_01_Vector reproducibility");
   ---------------------------------------------------------------------
   declare
      S1 : Natural := 42;
      S2 : Natural := 42;
      B1, B2 : Integer;
      Same : Boolean := True;
   begin
      for K in 1 .. 20 loop
         B1 := LCG_Bit (S1);
         B2 := LCG_Bit (S2);
         if B1 /= B2 or else S1 /= S2 then
            Same := False;
         end if;
         if B1 /= 0 and B1 /= 1 then
            Same := False;
         end if;
      end loop;
      Check (Same, "LCG_Bit reproducible + bits in {0,1}");
   end;
   declare
      S1 : Natural := 7;
      S2 : Natural := 7;
      R1 : constant Vector := Random_01_Vector (8, S1);
      R2 : constant Vector := Random_01_Vector (8, S2);
      Ok_Bits : Boolean := True;
   begin
      Check (Vec_Equal (R1, R2), "Random_01_Vector reproducible");
      Check (S1 = S2, "seeds advanced equally");
      for I in R1'Range loop
         if R1 (I) /= 0 and R1 (I) /= 1 then
            Ok_Bits := False;
         end if;
      end loop;
      Check (Ok_Bits, "vector bits in {0,1}");
   end;
   declare
      S : Natural := 0;
      R : Vector (1 .. 16);
      Has0, Has1 : Boolean := False;
   begin
      R := Random_01_Vector (16, S);
      for I in R'Range loop
         if R (I) = 0 then
            Has0 := True;
         end if;
         if R (I) = 1 then
            Has1 := True;
         end if;
      end loop;
      Check (Has0 and Has1, "mixed 0/1 in 16 draws (seed 0)");
   end;

   ---------------------------------------------------------------------
   Section ("7. Classical multiply: Identity / known 2x2");
   ---------------------------------------------------------------------
   declare
      I : constant Matrix := Identity (1);
      R : constant Multiply_Result := Multiply_Classical (I, I);
   begin
      Check (R.Success and R.N = 1, "1x1 classical Success");
      Check (R.C (1, 1) = 1, "1x1 product 1");
   end;
   declare
      I : constant Matrix := Identity (4);
      A : constant Matrix := Sequential_Fill (4);
      R : constant Multiply_Result := Multiply_Classical (I, A);
   begin
      Check (R.Success, "I*A Success");
      Check (Mat_Equal (Product_Matrix (R), A), "I*A = A");
   end;
   declare
      --  [[1,2],[3,4]] * [[5,6],[7,8]] = [[19,22],[43,50]]
      A : constant Matrix (1 .. 2, 1 .. 2) := [[1, 2], [3, 4]];
      B : constant Matrix (1 .. 2, 1 .. 2) := [[5, 6], [7, 8]];
      R : constant Multiply_Result := Multiply_Classical (A, B);
   begin
      Check (R.Success, "2x2 classical Success");
      Check (R.C (1, 1) = 19 and R.C (1, 2) = 22
               and R.C (2, 1) = 43 and R.C (2, 2) = 50,
             "2x2 classical values");
   end;
   declare
      --  Wikipedia Freivalds example:
      --  A=[[2,3],[3,4]], B=[[1,0],[1,2]], AB=[[5,6],[7,8]] ≠ C=[[6,5],[8,7]]
      A : constant Matrix (1 .. 2, 1 .. 2) := [[2, 3], [3, 4]];
      B : constant Matrix (1 .. 2, 1 .. 2) := [[1, 0], [1, 2]];
      R : constant Multiply_Result := Multiply_Classical (A, B);
   begin
      Check (R.Success, "wiki A*B Success");
      Check (R.C (1, 1) = 5 and R.C (1, 2) = 6
               and R.C (2, 1) = 7 and R.C (2, 2) = 8,
             "wiki A*B = [[5,6],[7,8]]");
   end;

   ---------------------------------------------------------------------
   Section ("8. True products always Equal_Probably");
   ---------------------------------------------------------------------
   for N in 1 .. 8 loop
      declare
         A  : constant Matrix := Deterministic (N, 3);
         B  : constant Matrix := Deterministic (N, 11);
         MR : constant Multiply_Result := Multiply_Classical (A, B);
         C  : constant Matrix := Product_Matrix (MR);
         VR : constant Verify_Result :=
           Verify (A, B, C, Trials => 10, Seed => 100 + N);
      begin
         Check (VR.Stat = Equal_Probably,
                "true product n=" & N'Image & " Equal_Probably");
         Check (VR.Failures = 0,
                "true product n=" & N'Image & " Failures=0");
         Check (VR.Trials_Used = 10,
                "true product n=" & N'Image & " Trials=10");
      end;
   end loop;
   declare
      I  : constant Matrix := Identity (5);
      A  : constant Matrix := Sequential_Fill (5);
      MR : constant Multiply_Result := Multiply_Classical (I, A);
      VR : constant Verify_Result :=
        Verify (I, A, Product_Matrix (MR), Trials => 12, Seed => 1);
   begin
      Check (VR.Stat = Equal_Probably, "I*A verified Equal_Probably");
   end;
   declare
      Z  : constant Matrix := Zeros (4);
      A  : constant Matrix := Deterministic (4, 2);
      MR : constant Multiply_Result := Multiply_Classical (Z, A);
      VR : constant Verify_Result :=
        Verify (Z, A, Product_Matrix (MR), Trials => 8, Seed => 99);
   begin
      Check (VR.Stat = Equal_Probably and Mat_Max_Abs (Product_Matrix (MR)) = 0,
             "zero*A = 0 verified");
   end;

   ---------------------------------------------------------------------
   Section ("9. Corrupted C caught as Unequal");
   ---------------------------------------------------------------------
   declare
      Caught : Natural := 0;
      Total  : constant := 20;
   begin
      for K in 1 .. Total loop
         declare
            N  : constant Positive := 2 + (K mod 5);  --  2..6
            A  : constant Matrix := Deterministic (N, K);
            B  : constant Matrix := Deterministic (N, K + 50);
            MR : constant Multiply_Result := Multiply_Classical (A, B);
            C0 : constant Matrix := Product_Matrix (MR);
            --  Corrupt one entry
            Row : constant Positive := 1 + (K mod N);
            Col : constant Positive := 1 + ((K * 3) mod N);
            C  : constant Matrix := Corrupt_Entry (C0, Row, Col, 1);
            VR : constant Verify_Result :=
              Verify (A, B, C, Trials => 16, Seed => 1000 + K);
         begin
            if VR.Stat = Unequal then
               Caught := Caught + 1;
            end if;
         end;
      end loop;
      Check (Caught = Total,
             "all " & Total'Image & " corrupted C caught (16 trials)");
   end;
   declare
      --  Wikipedia counterexample C (wrong product)
      A : constant Matrix (1 .. 2, 1 .. 2) := [[2, 3], [3, 4]];
      B : constant Matrix (1 .. 2, 1 .. 2) := [[1, 0], [1, 2]];
      C : constant Matrix (1 .. 2, 1 .. 2) := [[6, 5], [8, 7]];
      VR : constant Verify_Result :=
        Verify (A, B, C, Trials => 20, Seed => 1);
   begin
      Check (VR.Stat = Unequal, "wiki wrong C → Unequal");
      Check (VR.Failures = 1, "wiki early exit Failures=1");
   end;
   declare
      A  : constant Matrix := Identity (3);
      B  : constant Matrix := Sequential_Fill (3);
      MR : constant Multiply_Result := Multiply_Classical (A, B);
      C  : constant Matrix :=
        Corrupt_Entry (Product_Matrix (MR), 3, 1, -1);
      VR : constant Verify_Result :=
        Verify (A, B, C, Trials => 32, Seed => 5);
   begin
      Check (VR.Stat = Unequal, "corrupt (3,1) Unequal");
   end;

   ---------------------------------------------------------------------
   Section ("10. Freivalds vs classical cross-check");
   ---------------------------------------------------------------------
   for N in 1 .. 10 loop
      declare
         A  : constant Matrix := Deterministic (N, N * 3);
         B  : constant Matrix := Deterministic (N, N * 7 + 1);
         MR : constant Multiply_Result := Multiply_Classical (A, B);
         C  : constant Matrix := Product_Matrix (MR);
         VR : constant Verify_Result :=
           Verify (A, B, C, Trials => 8, Seed => N * 13);
         --  Also verify a deliberately wrong product
         Bad : constant Matrix := Corrupt_Entry (C, 1, 1, 1);
         VB  : constant Verify_Result :=
           Verify (A, B, Bad, Trials => 20, Seed => N * 17);
      begin
         Check (VR.Stat = Equal_Probably,
                "cross true n=" & N'Image);
         Check (VB.Stat = Unequal,
                "cross bad n=" & N'Image);
         Check (Matrices_Equal (C, C), "Matrices_Equal refl n=" & N'Image);
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("11. Dimension / edge cases");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Identity (2);
      B : constant Matrix := Identity (2);
      C : constant Matrix := Identity (2);
      VR : Verify_Result;
   begin
      VR := Verify (A, B, C, Trials => 4, Seed => 1);
      Check (VR.Stat = Equal_Probably and VR.N = 2, "I*I=?I Equal_Probably");
   end;
   --  Max_N identity
   declare
      A  : constant Matrix := Identity (Max_N);
      B  : constant Matrix := Deterministic (Max_N, 1);
      MR : constant Multiply_Result := Multiply_Classical (A, B);
      VR : constant Verify_Result :=
        Verify (A, B, Product_Matrix (MR), Trials => 4, Seed => 2);
   begin
      Check (MR.Success and VR.Stat = Equal_Probably,
             "Max_N=32 identity*Det Equal_Probably");
   end;
   --  1x1 unequal
   declare
      A : constant Matrix (1 .. 1, 1 .. 1) := [[2]];
      B : constant Matrix (1 .. 1, 1 .. 1) := [[3]];
      C : constant Matrix (1 .. 1, 1 .. 1) := [[7]];  --  wrong; 2*3=6
      VR : constant Verify_Result :=
        Verify (A, B, C, Trials => 8, Seed => 3);
   begin
      Check (VR.Stat = Unequal, "1x1 wrong product Unequal");
   end;
   declare
      A : constant Matrix (1 .. 1, 1 .. 1) := [[2]];
      B : constant Matrix (1 .. 1, 1 .. 1) := [[3]];
      C : constant Matrix (1 .. 1, 1 .. 1) := [[6]];
      VR : constant Verify_Result :=
        Verify (A, B, C, Trials => 8, Seed => 3);
   begin
      Check (VR.Stat = Equal_Probably, "1x1 true product Equal_Probably");
   end;

   ---------------------------------------------------------------------
   Section ("12. Verify_Once single trial");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Deterministic (4, 1);
      B : constant Matrix := Deterministic (4, 2);
      MR : constant Multiply_Result := Multiply_Classical (A, B);
      C : constant Matrix := Product_Matrix (MR);
      S : Natural := 55;
      V : Verdict;
   begin
      V := Verify_Once (A, B, C, S);
      Check (V = Equal_Probably, "Verify_Once true Equal_Probably");
      V := Verify_Once (A, B, Corrupt_Entry (C, 2, 3, 1), S);
      --  May or may not catch in one trial; run until Unequal or cap
      declare
         Caught : Boolean := (V = Unequal);
         T : Natural := 1;
      begin
         while not Caught and T < 40 loop
            V := Verify_Once (A, B, Corrupt_Entry (C, 2, 3, 1), S);
            T := T + 1;
            if V = Unequal then
               Caught := True;
            end if;
         end loop;
         Check (Caught, "Verify_Once eventually catches corrupt");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("13. Seeded reproducibility of Verify");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Deterministic (5, 9);
      B : constant Matrix := Deterministic (5, 8);
      MR : constant Multiply_Result := Multiply_Classical (A, B);
      C : constant Matrix := Product_Matrix (MR);
      V1 : constant Verify_Result :=
        Verify (A, B, C, Trials => 6, Seed => 12345);
      V2 : constant Verify_Result :=
        Verify (A, B, C, Trials => 6, Seed => 12345);
   begin
      Check (V1.Stat = V2.Stat and V1.Seed_Final = V2.Seed_Final
               and V1.Trials_Used = V2.Trials_Used,
             "Verify identical seeds → identical result");
   end;
   declare
      A : constant Matrix := Deterministic (3, 1);
      B : constant Matrix := Deterministic (3, 2);
      MR : constant Multiply_Result := Multiply_Classical (A, B);
      Bad : constant Matrix := Corrupt_Entry (Product_Matrix (MR), 1, 2, 1);
      V1 : constant Verify_Result :=
        Verify (A, B, Bad, Trials => 10, Seed => 77);
      V2 : constant Verify_Result :=
        Verify (A, B, Bad, Trials => 10, Seed => 77);
   begin
      Check (V1.Stat = Unequal and V2.Stat = Unequal
               and V1.Trials_Used = V2.Trials_Used
               and V1.Seed_Final = V2.Seed_Final,
             "Verify unequal reproducible");
   end;

   ---------------------------------------------------------------------
   Section ("14. Ones / scale products");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Ones (3, 2);
      B : constant Matrix := Ones (3, 3);
      MR : constant Multiply_Result := Multiply_Classical (A, B);
      --  Each entry = 2*3*3 = 18
      VR : constant Verify_Result :=
        Verify (A, B, Product_Matrix (MR), Trials => 5, Seed => 1);
   begin
      Check (MR.C (1, 1) = 18 and MR.C (3, 3) = 18, "ones product 18");
      Check (VR.Stat = Equal_Probably, "ones product verified");
   end;
   declare
      A : constant Matrix := Mat_Scale (Identity (4), 5);
      B : constant Matrix := Sequential_Fill (4);
      MR : constant Multiply_Result := Multiply_Classical (A, B);
      Expect : constant Matrix := Mat_Scale (B, 5);
   begin
      Check (Mat_Equal (Product_Matrix (MR), Expect), "5I * B = 5B");
      Check (Verify (A, B, Expect, 8, 2).Stat = Equal_Probably,
             "5I*B verified");
   end;

   ---------------------------------------------------------------------
   Section ("15. Larger n batch true + single corrupt");
   ---------------------------------------------------------------------
   for N in 12 .. 16 loop
      declare
         A  : constant Matrix := Deterministic (N, 4);
         B  : constant Matrix := Deterministic (N, 5);
         MR : constant Multiply_Result := Multiply_Classical (A, B);
         C  : constant Matrix := Product_Matrix (MR);
         VR : constant Verify_Result :=
           Verify (A, B, C, Trials => 6, Seed => N);
         VB : constant Verify_Result :=
           Verify (A, B, Corrupt_Entry (C, N, N, -3),
                   Trials => 24, Seed => N + 100);
      begin
         Check (VR.Stat = Equal_Probably, "large true n=" & N'Image);
         Check (VB.Stat = Unequal, "large corrupt n=" & N'Image);
      end;
   end loop;

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
