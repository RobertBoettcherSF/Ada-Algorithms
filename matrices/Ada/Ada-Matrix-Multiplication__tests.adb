--  Standalone test suite for Matrix_Multiplication educational survey.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Matrix_Multiplication;

procedure Tests is
   package MM renames Matrix_Multiplication;
   use MM;
   --  Enum literal Coppersmith_Winograd collides with sibling naming;
   --  always write MM.Coppersmith_Winograd for that Method_Kind value.

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
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

begin
   Ada.Text_IO.Put_Line
     ("Matrix Multiplication educational survey test suite");
   Ada.Text_IO.Put_Line
     ("===================================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Mat_Near / Norm / Diff");
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
   end;

   ---------------------------------------------------------------------
   Section ("2. Structure / power-of-two / grid");
   ---------------------------------------------------------------------
   declare
      S : constant Matrix := Identity (3);
      R : constant Matrix (1 .. 2, 1 .. 3) :=
        [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]];
   begin
      Check (Is_Square (S), "Identity square");
      Check (not Is_Square (R), "2x3 not square");
      Check (Is_Power_Of_Two (1), "1 is 2^0");
      Check (Is_Power_Of_Two (8), "8 is 2^3");
      Check (Is_Power_Of_Two (32), "32 is 2^5");
      Check (not Is_Power_Of_Two (0), "0 not power");
      Check (not Is_Power_Of_Two (3), "3 not power");
      Check (Next_Power_Of_Two (3) = 4, "next(3)=4");
      Check (Next_Power_Of_Two (5) = 8, "next(5)=8");
      Check (Next_Power_Of_Two (17) = 32, "next(17)=32");
      Check (Next_Power_Of_Two (0) = 0, "next(0)=0");
      Check (Divides (4, 16), "4 divides 16");
      Check (not Divides (3, 16), "3 not divide 16");
      Check (Is_Valid_Grid (8, 4), "grid 8/4 ok");
      Check (not Is_Valid_Grid (8, 3), "grid 8/3 bad");
      Check (not Is_Valid_Grid (8, 0), "grid P=0 bad");
   end;

   ---------------------------------------------------------------------
   Section ("3. Mat_Add / Mat_Sub / Mat_Scale / Pad / Trim");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) := [[1.0, 2.0], [3.0, 4.0]];
      B : constant Matrix (1 .. 2, 1 .. 2) := [[5.0, 6.0], [7.0, 8.0]];
      S : constant Matrix := Mat_Add (A, B);
      D : constant Matrix := Mat_Sub (A => B, B => A);
      K : constant Matrix := Mat_Scale (A, 2.0);
      P : constant Matrix := Pad_To_Power_Of_Two (Identity (3));
      T : constant Matrix := Trim (P, 3);
   begin
      Check (Mat_Near (S, [[6.0, 8.0], [10.0, 12.0]]), "Mat_Add");
      Check (Mat_Near (D, [[4.0, 4.0], [4.0, 4.0]]), "Mat_Sub");
      Check (Mat_Near (K, [[2.0, 4.0], [6.0, 8.0]]), "Mat_Scale");
      Check (P'Length (1) = 4, "pad 3 -> 4");
      Check (Mat_Near (T, Identity (3)), "trim back to I3");
   end;

   ---------------------------------------------------------------------
   Section ("4. Float builders");
   ---------------------------------------------------------------------
   declare
      Z : constant Matrix := Zeros (3);
      O : constant Matrix := Ones (2, 2.5);
      I : constant Matrix := Identity (3);
      Q : constant Matrix := Sequential_Fill (2);
      D : constant Matrix := Deterministic (2, 7);
      H : constant Matrix := Make_Hilbert (2);
   begin
      Check (Mat_Near (Z, [[0.0, 0.0, 0.0],
                           [0.0, 0.0, 0.0],
                           [0.0, 0.0, 0.0]]), "Zeros");
      Check (Mat_Near (O, [[2.5, 2.5], [2.5, 2.5]]), "Ones");
      Check (Near (I (1, 1), 1.0) and then Near (I (1, 2), 0.0)
             and then Near (I (2, 2), 1.0), "Identity diag");
      Check (Near (Q (1, 1), 1.0) and then Near (Q (2, 2), 4.0),
             "Sequential_Fill");
      Check (D (1, 1) >= 0.0 and then D (1, 1) < 1.0, "Deterministic range");
      Check (Approx (H (1, 1), 1.0) and then Approx (H (1, 2), 0.5)
             and then Approx (H (2, 2), 1.0 / 3.0), "Hilbert");
   end;

   ---------------------------------------------------------------------
   Section ("5. Taxonomy: count / names / exponents");
   ---------------------------------------------------------------------
   begin
      Check (Method_Count = 7, "Method_Count = 7");
      Check (Method_Name (Classical) = "Classical", "name Classical");
      Check (Method_Name (Strassen) = "Strassen", "name Strassen");
      Check (Method_Name (MM.Coppersmith_Winograd) = "Coppersmith-Winograd",
             "name CW");
      Check (Method_Name (Cannon) = "Cannon", "name Cannon");
      Check (Method_Name (Freivalds_Verify) = "Freivalds-Verify",
             "name Freivalds");
      Check (Method_Name (SUMMA) = "SUMMA", "name SUMMA");
      Check (Method_Name (Laser_Family) = "Laser-Family", "name Laser");

      Check (Approx (Exponent_Of (Classical), 3.0), "exp Classical=3");
      Check (Approx (Exponent_Of (Strassen), 2.807_355, 1.0E-5),
             "exp Strassen~2.807");
      Check (Approx (Exponent_Of (MM.Coppersmith_Winograd), 2.3755, 1.0E-6),
             "exp CW=2.3755");
      Check (Approx (Exponent_Of (Cannon), 3.0), "exp Cannon=3");
      Check (Approx (Exponent_Of (Freivalds_Verify), 2.0), "exp Freivalds=2");
      Check (Approx (Exponent_Of (SUMMA), 3.0), "exp SUMMA=3");
      Check (Approx (Exponent_Of (Laser_Family), 2.373, 1.0E-6),
             "exp Laser=2.373");

      Check (Exponent_Of (Classical) > Exponent_Of (Strassen),
             "Classical > Strassen");
      Check (Exponent_Of (Strassen) > Exponent_Of (MM.Coppersmith_Winograd),
             "Strassen > CW");
      Check (Exponent_Of (MM.Coppersmith_Winograd) > Exponent_Of (Laser_Family),
             "CW > Laser");
   end;

   ---------------------------------------------------------------------
   Section ("6. Is_Practical / Supports_Runnable / Classify");
   ---------------------------------------------------------------------
   begin
      Check (Is_Practical (Classical), "Classical practical");
      Check (Is_Practical (Strassen), "Strassen practical");
      Check (Is_Practical (Cannon), "Cannon practical");
      Check (Is_Practical (Freivalds_Verify), "Freivalds practical");
      Check (Is_Practical (SUMMA), "SUMMA practical (concept)");
      Check (not Is_Practical (MM.Coppersmith_Winograd), "CW not practical");
      Check (not Is_Practical (Laser_Family), "Laser not practical");

      Check (Supports_Runnable (Classical), "Classical runnable");
      Check (Supports_Runnable (Strassen), "Strassen runnable");
      Check (Supports_Runnable (Cannon), "Cannon runnable");
      Check (Supports_Runnable (Freivalds_Verify), "Freivalds runnable");
      Check (not Supports_Runnable (MM.Coppersmith_Winograd),
             "CW not runnable");
      Check (not Supports_Runnable (SUMMA), "SUMMA not runnable");
      Check (not Supports_Runnable (Laser_Family), "Laser not runnable");

      declare
         Info : Method_Info;
         Ok_All : Boolean := True;
      begin
         for M in Method_Kind loop
            Info := Classify_Method (M);
            if Info.Kind /= M then
               Ok_All := False;
            end if;
            if abs (Info.Exponent - Exponent_Of (M)) > 1.0E-6 then
               Ok_All := False;
            end if;
            if Info.Practical /= Is_Practical (M) then
               Ok_All := False;
            end if;
            if Info.Runnable_Sketch /= Supports_Runnable (M) then
               Ok_All := False;
            end if;
         end loop;
         Check (Ok_All, "Classify_Method consistent");
      end;

      Check (Describe (Classical)'Length > 5, "Describe Classical");
      Check (Describe (SUMMA)'Length > 5, "Describe SUMMA");
   end;

   ---------------------------------------------------------------------
   Section ("7. Milestone table");
   ---------------------------------------------------------------------
   declare
      Count_Ok : Boolean := False;
   begin
      case Milestone_Count is
         when 8 => Count_Ok := True;
         when others => Count_Ok := False;
      end case;
      Check (Count_Ok, "Milestone_Count = 8");
      for I in 1 .. Milestone_Count loop
         declare
            M : constant Milestone := Get_Milestone (I);
         begin
            Check (M.Year > 0, "milestone year > 0 #" & I'Image);
            Check (M.Exponent > 0.0, "milestone exp > 0 #" & I'Image);
            Check (Milestone_Label (I)'Length > 5,
                   "milestone label #" & I'Image);
         end;
      end loop;
      Check (Get_Milestone (1).Year = 1969, "first Strassen 1969");
      Check (Get_Milestone (2).Year = 1969, "second Cannon 1969");
      Check (Get_Milestone (3).Year = 1979, "third Freivalds 1979");
      Check (Approx (Get_Milestone (5).Exponent, 2.3755), "CW milestone exp");
   end;

   ---------------------------------------------------------------------
   Section ("8. Estimated_Ops / Recommend_Method");
   ---------------------------------------------------------------------
   begin
      Check (Approx (Estimated_Ops (2, Classical), 8.0), "ops 2^3=8");
      Check (Estimated_Ops (4, Strassen) < Estimated_Ops (4, Classical),
             "Strassen ops < Classical @4");
      Check (Estimated_Ops (8, Laser_Family)
             < Estimated_Ops (8, MM.Coppersmith_Winograd),
             "Laser ops < CW @8");

      Check (Recommend_Method (4, False) = Classical, "rec small Classical");
      Check (Recommend_Method (16, False) = Strassen, "rec 16 Strassen");
      Check (Recommend_Method (32, False) = Strassen, "rec 32 Strassen");
      Check (Recommend_Method (8, True) = Cannon, "rec parallel Cannon");
      Check (Recommend_Method (2, True) = Cannon, "rec N=2 parallel Cannon");
      Check (Recommend_Method (1, True) = Classical,
             "rec N=1 parallel falls to Classical");
   end;

   ---------------------------------------------------------------------
   Section ("9. Multiply_Classical");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Sequential_Fill (3);
      B : constant Matrix := Identity (3);
      R : constant Multiply_Result := Multiply_Classical (A, B);
      P : constant Matrix := Product_Matrix (R);
      C : constant Multiply_Result :=
        Multiply_Classical (Ones (2), Ones (2));
   begin
      Check (R.Success and then R.Stat = Ok, "Classical I success");
      Check (Mat_Near (P, A), "A*I = A");
      Check (R.Scalar_Multiplies = 27, "Classical 3^3 mults");
      Check (C.Success and then Near (C.C (1, 1), 2.0), "Ones*Ones");
      Check (C.Scalar_Multiplies = 8, "Classical 2^3 mults");
   end;

   ---------------------------------------------------------------------
   Section ("10. Multiply_Strassen vs Classical");
   ---------------------------------------------------------------------
   declare
      procedure Compare (N : Positive; Leaf : Positive := 1) is
         A : constant Matrix := Deterministic (N, 3);
         B : constant Matrix := Deterministic (N, 5);
         Rc : constant Multiply_Result := Multiply_Classical (A, B);
         Rs : constant Multiply_Result := Multiply_Strassen (A, B, Leaf);
      begin
         Check (Rc.Success and then Rs.Success,
                "both ok N=" & N'Image);
         Check (Mat_Near (Product_Matrix (Rc), Product_Matrix (Rs), 1.0E-4),
                "Strassen~Classical N=" & N'Image);
         Check (Rs.Padded_N >= N, "padded >= N @" & N'Image);
      end Compare;
   begin
      Compare (1);
      Compare (2);
      Compare (3);
      Compare (4);
      Compare (5);
      Compare (8);
      declare
         R : constant Multiply_Result :=
           Multiply_Strassen (Identity (4), Sequential_Fill (4));
      begin
         Check (R.Success and then R.Recursion_Depth >= 1,
                "Strassen recursion depth");
         Check (R.Scalar_Multiplies = 7 ** 2,
                "pure Strassen leaf=1: 7^2 scalar mults at n=4");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Multiply_Cannon vs Classical");
   ---------------------------------------------------------------------
   declare
      procedure Compare_Cannon (N, P : Natural) is
         A : constant Matrix := Deterministic (N, 2);
         B : constant Matrix := Deterministic (N, 9);
         Rc : constant Multiply_Result := Multiply_Classical (A, B);
         Rn : constant Multiply_Result := Multiply_Cannon (A, B, P);
      begin
         Check (Rc.Success and then Rn.Success,
                "Cannon ok N=" & N'Image & " P=" & P'Image);
         Check (Mat_Near (Product_Matrix (Rc), Product_Matrix (Rn), 1.0E-4),
                "Cannon~Classical N=" & N'Image & " P=" & P'Image);
         Check (Rn.Grid_P = (if P = 0 then N else P),
                "Grid_P recorded");
         Check (Rn.Shift_Count = Rn.Grid_P, "Shift_Count = P");
         Check (Rn.Block_Size = N / Rn.Grid_P, "Block_Size = N/P");
      end Compare_Cannon;
   begin
      Compare_Cannon (1, 0);
      Compare_Cannon (2, 0);
      Compare_Cannon (4, 0);
      Compare_Cannon (4, 2);
      Compare_Cannon (4, 4);
      Compare_Cannon (8, 2);
      Compare_Cannon (8, 4);
      declare
         Bad : constant Multiply_Result :=
           Multiply_Cannon (Identity (4), Identity (4), 3);
      begin
         Check (not Bad.Success and then Bad.Stat = Dimension_Error,
                "Cannon bad grid -> Dimension_Error");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Multiply dispatch / catalogue rejects");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Identity (2);
      B : constant Matrix := Ones (2);
      Rc : constant Multiply_Result := Multiply (A, B, Classical);
      Rs : constant Multiply_Result := Multiply (A, B, Strassen);
      Rn : constant Multiply_Result := Multiply (A, B, Cannon, Grid_P => 2);
      Rcw : constant Multiply_Result :=
        Multiply (A, B, MM.Coppersmith_Winograd);
      Rsu : constant Multiply_Result := Multiply (A, B, SUMMA);
      Rla : constant Multiply_Result := Multiply (A, B, Laser_Family);
      Rfv : constant Multiply_Result := Multiply (A, B, Freivalds_Verify);
   begin
      Check (Rc.Success and then Rs.Success and then Rn.Success,
             "dispatch Classical/Strassen/Cannon ok");
      Check (Mat_Near (Product_Matrix (Rc), Product_Matrix (Rs), 1.0E-4),
             "dispatch Classical~Strassen");
      Check (Mat_Near (Product_Matrix (Rc), Product_Matrix (Rn), 1.0E-4),
             "dispatch Classical~Cannon");

      Check (not Rcw.Success, "CW reject Success=False");
      Check (Rcw.Stat = Not_Implemented, "CW Not_Implemented");
      Check (not Supports_Runnable (MM.Coppersmith_Winograd),
             "Supports_Runnable CW False");

      Check (not Rsu.Success, "SUMMA reject");
      Check (Rsu.Stat = Not_Implemented, "SUMMA Not_Implemented");
      Check (not Supports_Runnable (SUMMA), "Supports_Runnable SUMMA False");

      Check (not Rla.Success, "Laser reject");
      Check (Rla.Stat = Galactic_Only, "Laser Galactic_Only");
      Check (not Supports_Runnable (Laser_Family),
             "Supports_Runnable Laser False");

      Check (not Rfv.Success, "Freivalds via Multiply reject");
      Check (Rfv.Stat = Not_Implemented,
             "Freivalds Multiply -> Not_Implemented");
   end;

   ---------------------------------------------------------------------
   Section ("13. Freivalds Integer builders / classical");
   ---------------------------------------------------------------------
   declare
      A : constant Int_Matrix := Int_Sequential_Fill (3);
      B : constant Int_Matrix := Int_Identity (3);
      R : constant Int_Multiply_Result := Multiply_Classical_Int (A, B);
      P : constant Int_Matrix := Int_Product_Matrix (R);
      D : constant Int_Matrix := Int_Deterministic (2, 4);
   begin
      Check (Is_Square_Int (A), "Int square");
      Check (R.Success, "Int Classical success");
      Check (Int_Mat_Equal (P, A), "Int A*I = A");
      Check (Int_Mat_Equal (Int_Zeros (2),
             [[0, 0], [0, 0]]), "Int_Zeros");
      Check (Int_Mat_Equal (Int_Ones (2, 3),
             [[3, 3], [3, 3]]), "Int_Ones");
      Check (D (1, 1) in 0 .. 9, "Int_Deterministic range");
   end;

   ---------------------------------------------------------------------
   Section ("14. Verify_Freivalds equal / unequal");
   ---------------------------------------------------------------------
   declare
      A : constant Int_Matrix := Int_Deterministic (4, 1);
      B : constant Int_Matrix := Int_Deterministic (4, 2);
      Good : constant Int_Multiply_Result := Multiply_Classical_Int (A, B);
      C_Ok : constant Int_Matrix := Int_Product_Matrix (Good);
      C_Bad : constant Int_Matrix := Corrupt_Entry (C_Ok, 2, 3, 1);
      V_Ok : constant Verify_Result :=
        Verify_Freivalds (A, B, C_Ok, Trials => 10, Seed => 42);
      V_Bad : constant Verify_Result :=
        Verify_Freivalds (A, B, C_Bad, Trials => 10, Seed => 7);
      V_Id : constant Verify_Result :=
        Verify_Freivalds (Int_Identity (3), Int_Identity (3),
                          Int_Identity (3), Trials => 5);
   begin
      Check (V_Ok.Stat = Equal_Probably, "Freivalds true product");
      Check (V_Ok.Failures = 0, "Freivalds true: zero failures");
      Check (V_Ok.Trials_Used = 10, "Freivalds used 10 trials");
      Check (V_Bad.Stat = Unequal, "Freivalds detects corrupt");
      Check (V_Bad.Failures >= 1, "Freivalds corrupt: failure counted");
      Check (V_Id.Stat = Equal_Probably, "Freivalds I*I=I");

      declare
         Seed : Natural := 99;
         V1 : constant Verdict :=
           Verify_Freivalds_Once (A, B, C_Ok, Seed);
         V2 : constant Verdict :=
           Verify_Freivalds_Once (A, B, C_Bad, Seed);
      begin
         Check (V1 = Equal_Probably, "Once true");
         Check (V2 = Unequal or else V2 = Equal_Probably,
                "Once corrupt may miss (one-sided)");
         --  With high probability Unequal; accept Equal_Probably once.
         --  Strengthen with multi-trial already above.
      end;
   end;

   ---------------------------------------------------------------------
   Section ("15. Cross-check Classical/Strassen/Cannon identity");
   ---------------------------------------------------------------------
   declare
      N : constant := 6;
      A : constant Matrix := Deterministic (N, 11);
      B : constant Matrix := Deterministic (N, 13);
      Rc : constant Multiply_Result := Multiply_Classical (A, B);
      Rs : constant Multiply_Result := Multiply_Strassen (A, B);
      Rn : constant Multiply_Result := Multiply_Cannon (A, B, 2);
      Rp : constant Multiply_Result := Multiply_Cannon (A, B, 3);
   begin
      Check (Rc.Success and then Rs.Success and then Rn.Success
             and then Rp.Success, "cross all success");
      Check (Mat_Near (Product_Matrix (Rc), Product_Matrix (Rs), 1.0E-3),
             "cross Classical~Strassen n=6");
      Check (Mat_Near (Product_Matrix (Rc), Product_Matrix (Rn), 1.0E-4),
             "cross Classical~Cannon P=2");
      Check (Mat_Near (Product_Matrix (Rc), Product_Matrix (Rp), 1.0E-4),
             "cross Classical~Cannon P=3");
   end;

   ---------------------------------------------------------------------
   Section ("16. Larger n / Max_N edge");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Deterministic (16, 1);
      B : constant Matrix := Deterministic (16, 2);
      Rc : constant Multiply_Result := Multiply_Classical (A, B);
      Rs : constant Multiply_Result := Multiply_Strassen (A, B, Leaf => 2);
      Rn : constant Multiply_Result := Multiply_Cannon (A, B, 4);
   begin
      Check (Rc.Success and then Rs.Success and then Rn.Success,
             "n=16 all ok");
      Check (Mat_Near (Product_Matrix (Rc), Product_Matrix (Rs), 1.0E-3),
             "n=16 Classical~Strassen");
      Check (Mat_Near (Product_Matrix (Rc), Product_Matrix (Rn), 1.0E-4),
             "n=16 Classical~Cannon");
      Check (Recommend_Method (16, False) = Strassen, "rec@16 Strassen");
      Check (Recommend_Method (16, True) = Cannon, "rec@16 parallel Cannon");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("========================================");
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
