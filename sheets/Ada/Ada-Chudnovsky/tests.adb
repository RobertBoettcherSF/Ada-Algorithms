--  Standalone test suite for Chudnovsky (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Chudnovsky; use Chudnovsky;

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

   function Close
     (A, B : Long_Float; Tol : Long_Float := 1.0E-9) return Boolean
   is
   begin
      return abs (A - B) <= Tol
        or else abs (A - B) <= Tol * (1.0 + abs (B));
   end Close;

begin
   Ada.Text_IO.Put_Line ("Chudnovsky test suite");
   Ada.Text_IO.Put_Line ("=====================");

   ---------------------------------------------------------------------
   Section ("1. Near / Abs_Error / Rel_Error helpers");
   ---------------------------------------------------------------------
   declare
      E, R : Long_Float;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects far");
      Check (Near (0.0, 0.0), "Near zeros");
      Check (Near (Pi_Constant, Pi_Constant), "Near Pi_Constant");
      E := Abs_Error (3.0, 1.0);
      Check (Close (E, 2.0), "Abs_Error 3-1");
      Check (Close (Abs_Error (1.0, 1.0), 0.0), "Abs_Error zero");
      Check (Close (Abs_Error (-1.0, 1.0), 2.0), "Abs_Error signed");
      Check (Close (Abs_Error (Pi_Constant, Pi_Constant), 0.0),
             "Abs_Error Pi self");
      R := Rel_Error (5.1, 5.0);
      Check (Close (R, 0.02, 1.0E-12), "Rel_Error 5.1 vs 5");
      Check (Close (Rel_Error (0.0, 0.0), 0.0), "Rel_Error 0/0");
      Check (Rel_Error (1.0, 0.0) > 1.0E20, "Rel_Error nonzero/0 sentinel");
      Check (Close (Rel_Error (2.0, 1.0), 1.0), "Rel_Error 2 vs 1");
      Check (Close (Rel_Error (-2.0, -1.0), 1.0), "Rel_Error signed ratio");
   end;

   ---------------------------------------------------------------------
   Section ("2. Pi_Constant / Ada_Pi / Elementary_Pi");
   ---------------------------------------------------------------------
   declare
      A, E, P : Long_Float;
   begin
      P := Pi_Constant;
      A := Ada_Pi;
      E := Elementary_Pi;
      Check (P > 3.14 and then P < 3.15, "Pi_Constant in (3.14,3.15)");
      Check (Close (P, A, 1.0E-14), "Pi_Constant ≈ Ada_Pi");
      Check (Close (P, E, 1.0E-14), "Pi_Constant ≈ Elementary_Pi");
      Check (Close (A, E, 1.0E-14), "Ada_Pi ≈ Elementary_Pi");
      Check (Close (Abs_Error (P, A), 0.0, 1.0E-14), "Abs_Error Pi refs");
      Check (Rel_Error (P, A) < 1.0E-14, "Rel_Error Pi refs tiny");
      Check (Close (P, 3.141_592_653_589_793, 1.0E-15),
             "Pi_Constant known digits");
      Check (not Near (P, 22.0 / 7.0, 1.0E-4), "Pi ≠ 22/7 at 1e-4");
      Check (Near (P, 22.0 / 7.0, 2.0E-3), "Pi near 22/7 at 2e-3");
   end;

   ---------------------------------------------------------------------
   Section ("3. Series constants");
   ---------------------------------------------------------------------
   declare
      Num : Long_Float;
   begin
      Check (Close (A_Const, 13_591_409.0), "A_Const = 13591409");
      Check (Close (B_Const, 545_140_134.0), "B_Const = 545140134");
      Check (Close (C_Const, 640_320.0), "C_Const = 640320");
      Check (Close (C3_Const, 262_537_412_640_768_000.0, 1.0),
             "C3_Const = 640320^3");
      Check (Close (C_Const * C_Const * C_Const, C3_Const, 1.0E6),
             "C^3 matches C3_Const");
      Check (Close (Prefactor_Int, 426_880.0), "Prefactor_Int = 426880");
      Num := Pi_Numerator;
      Check (Num > 4.0E7 and then Num < 5.0E7, "Pi_Numerator band");
      Check (Close (Num, Prefactor_Int * 100.024_984_378_110_7, 1.0),
             "Pi_Numerator ≈ 426880√10005");
      Check (Approximate_Pi (Max_Terms) > 3.0, "Max_Terms usable");
      Check (Close (Approximate_Pi (Default_Terms), Approximate_Pi),
             "Default_Terms drives default call");
      Check (Series_Sum (Max_Terms) > 0.0, "Sum(Max_Terms) positive");
      Check (abs (Series_Term (Term_Index'Last)) < abs (Series_Term (0)),
             "last term smaller than t0");
   end;

   ---------------------------------------------------------------------
   Section ("4. Series_Term t0 and signs");
   ---------------------------------------------------------------------
   declare
      T0, T1, T2 : Long_Float;
   begin
      T0 := Series_Term (0);
      T1 := Series_Term (1);
      T2 := Series_Term (2);
      Check (Close (T0, A_Const), "t0 = A = 13591409");
      Check (T0 > 0.0, "t0 > 0");
      Check (T1 < 0.0, "t1 < 0 (alternating)");
      Check (T2 > 0.0, "t2 > 0");
      Check (abs (T1) < abs (T0), "|t1| < |t0|");
      Check (abs (T2) < abs (T1), "|t2| < |t1|");
      Check (Close (T1, T0 * Term_Ratio (0), 1.0E-9 * abs (T1)),
             "t1 = t0 · ratio(0)");
      Check (Close (T2, T1 * Term_Ratio (1), 1.0E-9 * abs (T2)),
             "t2 = t1 · ratio(1)");
   end;

   ---------------------------------------------------------------------
   Section ("5. Term_Ratio properties");
   ---------------------------------------------------------------------
   declare
      R0, R1 : Long_Float;
   begin
      R0 := Term_Ratio (0);
      R1 := Term_Ratio (1);
      Check (R0 < 0.0, "ratio(0) negative (−C³)");
      Check (R1 < 0.0, "ratio(1) negative");
      Check (abs (R0) < 1.0, "|ratio(0)| < 1 (rapid decay)");
      Check (abs (R1) < abs (R0), "|ratio| shrinks with k");
      Check (Close (Series_Term (1) / Series_Term (0), R0, 1.0E-12),
             "Series_Term ratio matches Term_Ratio(0)");
   end;

   ---------------------------------------------------------------------
   Section ("6. Series_Sum consistency");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3, Acc : Long_Float;
   begin
      S1 := Series_Sum (1);
      S2 := Series_Sum (2);
      S3 := Series_Sum (3);
      Check (Close (S1, Series_Term (0)), "Sum(1) = t0");
      Check (Close (S2, Series_Term (0) + Series_Term (1),
                    1.0E-9 * abs (S2)),
             "Sum(2) = t0+t1");
      Acc := 0.0;
      for K in 0 .. 2 loop
         Acc := Acc + Series_Term (K);
      end loop;
      Check (Close (S3, Acc, 1.0E-9 * abs (S3)), "Sum(3) = Σ t0..t2");
      Check (S1 > 0.0 and then S2 > 0.0 and then S3 > 0.0,
             "partial sums positive");
      Check (Close (S2, S1 + Series_Term (1), 1.0E-9 * abs (S2)),
             "Sum(2) = Sum(1)+t1");
   end;

   ---------------------------------------------------------------------
   Section ("7. Approximate_Pi: k=0 alone already close");
   ---------------------------------------------------------------------
   declare
      E1, E2, E3, E4 : Long_Float;
      Err1, Err2 : Long_Float;
   begin
      E1 := Approximate_Pi (1);
      E2 := Approximate_Pi (2);
      E3 := Approximate_Pi (3);
      E4 := Approximate_Pi (4);

      Check (E1 > 3.141_592_653 and then E1 < 3.141_592_654,
             "π1 in known band");
      Err1 := Abs_Error (E1, Pi_Constant);
      Check (Err1 < 1.0E-12, "|π1−π| < 1e-12 (≈14 digits)");
      Check (Err1 < 1.0E-13, "|π1−π| < 1e-13");
      Check (Near (E1, Pi_Constant, 1.0E-12), "Near π1 to Pi_Constant");

      Err2 := Abs_Error (E2, Pi_Constant);
      Check (Err2 <= Err1 + 1.0E-18, "err(2) ≤ err(1) (or noise)");
      Check (Abs_Error (E2, Pi_Constant) < 1.0E-14,
             "|π2−π| < 1e-14 (saturated)");
      Check (Near (E2, Pi_Constant, 1.0E-14), "Near π2");
      Check (Near (E3, Pi_Constant, 1.0E-14), "Near π3");
      Check (Near (E4, Pi_Constant, 1.0E-14), "Near π4");
      Check (Near (E2, Ada_Pi, 1.0E-14), "π2 ≈ Ada_Pi");
      Check (Near (E2, Elementary_Pi, 1.0E-14), "π2 ≈ Elementary_Pi");
   end;

   ---------------------------------------------------------------------
   Section ("8. Approximate_Pi more terms / default");
   ---------------------------------------------------------------------
   declare
      Prev_Err, Cur_Err : Long_Float;
      Ed : Long_Float;
   begin
      Ed := Approximate_Pi;
      Check (Close (Ed, Approximate_Pi (Default_Terms)),
             "default Terms = Default_Terms");
      Check (Near (Ed, Pi_Constant, 1.0E-14), "default near Pi_Constant");
      Check (Near (Approximate_Pi (Max_Terms), Pi_Constant, 1.0E-14),
             "Max_Terms near Pi_Constant");

      Prev_Err := Abs_Error (Approximate_Pi (1), Pi_Constant);
      for N in Term_Count range 2 .. 6 loop
         Cur_Err := Abs_Error (Approximate_Pi (N), Pi_Constant);
         Check (Cur_Err <= Prev_Err + 1.0E-15,
                "non-increasing abs error at Terms=" &
                Natural'Image (N));
         Prev_Err := Cur_Err;
      end loop;

      Check (Abs_Error (Approximate_Pi (1), Pi_Constant) >=
               Abs_Error (Approximate_Pi (Default_Terms), Pi_Constant)
                 - 1.0E-18,
             "default at least as good as 1 term");
   end;

   ---------------------------------------------------------------------
   Section ("9. Approximate_Pi procedure (estimate + sum)");
   ---------------------------------------------------------------------
   declare
      Est, Sum : Long_Float;
   begin
      Approximate_Pi (1, Est, Sum);
      Check (Close (Sum, Series_Sum (1)), "proc(1) Sum = Series_Sum(1)");
      Check (Close (Est, Pi_From_Sum (Sum)), "proc(1) Est = Pi_From_Sum");
      Check (Close (Est, Approximate_Pi (1)), "proc(1) = func(1)");

      Approximate_Pi (3, Est, Sum);
      Check (Close (Sum, Series_Sum (3), 1.0E-9 * abs (Sum)),
             "proc(3) Sum matches");
      Check (Close (Est, Approximate_Pi (3)), "proc(3) = func(3)");
      Check (Near (Est, Pi_Constant, 1.0E-14), "proc(3) near π");

      Approximate_Pi (Default_Terms, Est, Sum);
      Check (Close (Est, Approximate_Pi), "proc(default) = func(default)");
      Check (Sum > 0.0, "proc sum positive");
   end;

   ---------------------------------------------------------------------
   Section ("10. Pi_From_Sum");
   ---------------------------------------------------------------------
   declare
      S : Long_Float;
      P : Long_Float;
   begin
      S := Series_Sum (1);
      P := Pi_From_Sum (S);
      Check (Close (P, Approximate_Pi (1)), "Pi_From_Sum(Sum1)=Approx(1)");
      Check (Close (Pi_From_Sum (Series_Sum (2)), Approximate_Pi (2)),
             "Pi_From_Sum(Sum2)=Approx(2)");
      Check (Pi_Numerator / S > 3.0, "numerator/sum > 3");
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid_Argument");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Raised := False;
      declare
         Tmp : Long_Float;
      begin
         Tmp := Series_Term (Max_Terms);
         Check (False and then Tmp = 0.0, "Series_Term(Max) should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Series_Term(Max_Terms) raises");

      Raised := False;
      declare
         Tmp : Long_Float;
      begin
         Tmp := Series_Sum (0);
         Check (False and then Tmp = 0.0, "Series_Sum(0) should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Series_Sum(0) raises");

      Raised := False;
      declare
         Tmp : Long_Float;
      begin
         Tmp := Series_Sum (Max_Terms + 1);
         Check (False and then Tmp = 0.0, "Series_Sum over max should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Series_Sum(Max_Terms+1) raises");

      Raised := False;
      declare
         Tmp : Long_Float;
      begin
         Tmp := Term_Ratio (Max_Terms - 1);
         Check (False and then Tmp = 0.0, "Term_Ratio past last should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Term_Ratio past last-1 raises");

      Raised := False;
      declare
         Tmp : Long_Float;
      begin
         Tmp := Pi_From_Sum (0.0);
         Check (False and then Tmp = 0.0, "Pi_From_Sum(0) should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Pi_From_Sum(0) raises");

      Raised := False;
      declare
         Tmp : Long_Float;
      begin
         Tmp := Pi_From_Sum (-1.0);
         Check (False and then Tmp = 0.0, "Pi_From_Sum(<0) should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Pi_From_Sum(negative) raises");
   end;

   ---------------------------------------------------------------------
   Section ("12. Cross-checks vs known π");
   ---------------------------------------------------------------------
   declare
      E : Long_Float;
   begin
      for N in Term_Count loop
         E := Approximate_Pi (N);
         Check (E > 3.141_592_65 and then E < 3.141_592_66,
                "Approx band Terms=" & Natural'Image (N));
         Check (Abs_Error (E, Pi_Constant) < 1.0E-12,
                "|err|<1e-12 Terms=" & Natural'Image (N));
         Check (Rel_Error (E, Pi_Constant) < 1.0E-12,
                "rel err tiny Terms=" & Natural'Image (N));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("13. Term recurrence manual walk");
   ---------------------------------------------------------------------
   declare
      T, Acc : Long_Float;
      Est    : Long_Float;
   begin
      T   := A_Const;
      Acc := T;
      Est := Pi_From_Sum (Acc);
      Check (Close (Est, Approximate_Pi (1)), "manual 1-term");

      T   := T * Term_Ratio (0);
      Acc := Acc + T;
      Est := Pi_From_Sum (Acc);
      Check (Close (Est, Approximate_Pi (2), 1.0E-14), "manual 2-term");
      Check (Close (Acc, Series_Sum (2), 1.0E-9 * abs (Acc)),
             "manual Acc = Sum(2)");

      T   := T * Term_Ratio (1);
      Acc := Acc + T;
      Check (Close (Pi_From_Sum (Acc), Approximate_Pi (3), 1.0E-14),
             "manual 3-term");
   end;

   ---------------------------------------------------------------------
   Section ("14. Rel vs Abs and saturation");
   ---------------------------------------------------------------------
   declare
      E1, E8 : Long_Float;
      A1, A8 : Long_Float;
   begin
      E1 := Approximate_Pi (1);
      E8 := Approximate_Pi (8);
      A1 := Abs_Error (E1, Pi_Constant);
      A8 := Abs_Error (E8, Pi_Constant);
      Check (A8 <= A1 + 1.0E-18, "8 terms not worse than 1");
      Check (Close (A1, Rel_Error (E1, Pi_Constant) * abs (Pi_Constant),
                    1.0E-20),
             "abs ≈ rel·|π| at 1 term");
      Check (Near (E8, E1, 1.0E-12),
             "Float noise: 8-term ≈ 1-term at 1e-12");
      Check (Close (Approximate_Pi (Default_Terms), Approximate_Pi),
             "Default_Terms matches default call");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("========================================");
   Ada.Text_IO.Put_Line
     ("Passed:" & Natural'Image (Pass_Count) &
      "  Failed:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;

end Tests;
