--  Standalone test suite for BBP (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with BBP; use BBP;

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

   --  Known hex digits of π after the point: 243F6A8885A30...
   Known_Hex : constant array (0 .. 12) of Hex_Digit :=
     [2, 4, 3, 15, 6, 10, 8, 8, 8, 5, 10, 3, 0];

begin
   Ada.Text_IO.Put_Line ("BBP test suite");
   Ada.Text_IO.Put_Line ("==============");

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
   Section ("3. Domain constants / caps");
   ---------------------------------------------------------------------
   declare
      Est_Max, Est_Def, Est_Bare, S_Max : Long_Float;
   begin
      Est_Max  := Approximate_Pi (Max_Terms);
      Est_Def  := Approximate_Pi (Default_Terms);
      Est_Bare := Approximate_Pi;
      S_Max    := Series_Sum (Max_Terms);
      Check (Est_Max > 3.0 and then Est_Max < 3.2, "Max_Terms usable band");
      Check (Close (Est_Def, Est_Bare), "Default_Terms drives default call");
      Check (S_Max > 0.0, "Sum(Max_Terms) positive");
      Check (Close (Est_Max, S_Max), "Approx(Max) = Sum(Max)");
      Check (Near (Est_Max, Pi_Constant, 1.0E-14), "Max_Terms near π");
      Check (Abs_Error (Est_Def, Pi_Constant) < 1.0E-12,
             "Default_Terms abs err < 1e-12");
      Check (abs (Series_Term (Term_Index'Last)) < abs (Series_Term (0)),
             "last term smaller than t0");
      Check (Hex_Digit_Of_Pi (Max_Hex_Digit) = Known_Hex (Max_Hex_Digit),
             "Max_Hex_Digit matches known");
      Check (Close (Series_Sum (Default_Terms), Approximate_Pi (Default_Terms)),
             "Sum(Default)=Approx(Default)");
   end;

   ---------------------------------------------------------------------
   Section ("4. Term_Parenthesis / Series_Term");
   ---------------------------------------------------------------------
   declare
      P0, T0, T1, T2 : Long_Float;
   begin
      P0 := Term_Parenthesis (0);
      --  4/1 − 2/4 − 1/5 − 1/6 = 4 − 0.5 − 0.2 − 0.1666… = 3.1333…
      Check (Close (P0, 4.0 - 0.5 - 0.2 - 1.0 / 6.0, 1.0E-14),
             "paren(0) = 4−1/2−1/5−1/6");
      Check (P0 > 3.13 and then P0 < 3.14, "paren(0) band");
      T0 := Series_Term (0);
      T1 := Series_Term (1);
      T2 := Series_Term (2);
      Check (Close (T0, P0), "t0 = paren(0)");
      Check (T0 > 3.0, "t0 > 3");
      Check (T1 > 0.0 and then T1 < 1.0, "t1 in (0,1)");
      Check (T2 > 0.0 and then T2 < T1, "t2 < t1");
      Check (Close (T1, Term_Parenthesis (1) / 16.0, 1.0E-14),
             "t1 = paren(1)/16");
      Check (Close (T2, Term_Parenthesis (2) / 256.0, 1.0E-14),
             "t2 = paren(2)/256");
      Check (abs (T1) < abs (T0), "|t1| < |t0|");
      Check (abs (T2) < abs (T1), "|t2| < |t1|");
   end;

   ---------------------------------------------------------------------
   Section ("5. Series_Sum consistency");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3, Acc : Long_Float;
   begin
      S1 := Series_Sum (1);
      S2 := Series_Sum (2);
      S3 := Series_Sum (3);
      Check (Close (S1, Series_Term (0)), "Sum(1) = t0");
      Check (Close (S2, Series_Term (0) + Series_Term (1),
                    1.0E-12 * abs (S2)),
             "Sum(2) = t0+t1");
      Acc := 0.0;
      for K in 0 .. 2 loop
         Acc := Acc + Series_Term (K);
      end loop;
      Check (Close (S3, Acc, 1.0E-12 * abs (S3)), "Sum(3) = Σ t0..t2");
      Check (S1 > 0.0 and then S2 > 0.0 and then S3 > 0.0,
             "partial sums positive");
      Check (S2 > S1, "Sum(2) > Sum(1)");
      Check (S3 > S2, "Sum(3) > Sum(2)");
      Check (Close (S2, S1 + Series_Term (1), 1.0E-12 * abs (S2)),
             "Sum(2) = Sum(1)+t1");
   end;

   ---------------------------------------------------------------------
   Section ("6. Approximate_Pi approaches π");
   ---------------------------------------------------------------------
   declare
      E1, E2, E4, E8, E12, E20 : Long_Float;
      Err1, Err4, Err12 : Long_Float;
   begin
      E1  := Approximate_Pi (1);
      E2  := Approximate_Pi (2);
      E4  := Approximate_Pi (4);
      E8  := Approximate_Pi (8);
      E12 := Approximate_Pi (12);
      E20 := Approximate_Pi (20);

      Check (E1 > 3.13 and then E1 < 3.14, "π1 in known band (~3.133)");
      Err1 := Abs_Error (E1, Pi_Constant);
      Check (Err1 > 1.0E-3 and then Err1 < 1.0E-2, "|π1−π| ~ 1e-2");

      Check (E2 > 3.14 and then E2 < 3.142, "π2 band");
      Check (Abs_Error (E2, Pi_Constant) < Err1, "err(2) < err(1)");

      Err4 := Abs_Error (E4, Pi_Constant);
      Check (Err4 < 1.0E-5, "|π4−π| < 1e-5");
      Check (Near (E4, Pi_Constant, 1.0E-4), "Near π4 at 1e-4");

      Check (Abs_Error (E8, Pi_Constant) < 1.0E-9, "|π8−π| < 1e-9");
      Err12 := Abs_Error (E12, Pi_Constant);
      Check (Err12 < 1.0E-12, "|π12−π| < 1e-12");
      Check (Near (E12, Pi_Constant, 1.0E-12), "Near π12 to Pi_Constant");
      Check (Near (E20, Pi_Constant, 1.0E-14), "Near π20 machine");
      Check (Abs_Error (E20, Pi_Constant) < 1.0E-14, "|π20−π| < 1e-14");
      Check (Close (E12, Approximate_Pi), "default ≈ 12 terms");
   end;

   ---------------------------------------------------------------------
   Section ("7. Procedure Approximate_Pi / Sum = Estimate");
   ---------------------------------------------------------------------
   declare
      Est, Sum : Long_Float;
   begin
      Approximate_Pi (8, Est, Sum);
      Check (Close (Est, Sum), "Estimate = Sum (BBP identity)");
      Check (Close (Est, Approximate_Pi (8)), "proc ≈ func at 8");
      Approximate_Pi (1, Est, Sum);
      Check (Close (Est, Series_Term (0)), "proc(1) = t0");
      Approximate_Pi (Default_Terms, Est, Sum);
      Check (Close (Est, Approximate_Pi), "proc default matches func");
      Check (Close (Sum, Series_Sum (Default_Terms)),
             "proc Sum = Series_Sum");
   end;

   ---------------------------------------------------------------------
   Section ("8. Monotone error decrease then saturation");
   ---------------------------------------------------------------------
   declare
      Prev, Cur, Err : Long_Float;
      Ref : constant Long_Float := Pi_Constant;
   begin
      Prev := Abs_Error (Approximate_Pi (1), Ref);
      for N in 2 .. 10 loop
         Cur := Abs_Error (Approximate_Pi (N), Ref);
         Check (Cur <= Prev + 1.0E-18,
                "err not worse at Terms=" & Integer'Image (N));
         Prev := Cur;
      end loop;
      Err := Abs_Error (Approximate_Pi (Max_Terms), Ref);
      Check (Err < 1.0E-14, "Max_Terms saturated");
      Check (Near (Approximate_Pi (30), Approximate_Pi (40), 1.0E-15),
             "30 ≈ 40 terms (Float noise)");
   end;

   ---------------------------------------------------------------------
   Section ("9. Hex_Digit_Of_Pi known expansion");
   ---------------------------------------------------------------------
   declare
      D : Hex_Digit;
      Fr : Long_Float;
   begin
      for N in Known_Hex'Range loop
         D := Hex_Digit_Of_Pi (N);
         Check (D = Known_Hex (N),
                "hex[" & Integer'Image (N) & "] ="
                & Integer'Image (Integer (Known_Hex (N))));
      end loop;

      Fr := Hex_Fractional_Part (0);
      Check (Fr >= 0.0 and then Fr < 1.0, "frac(0) in [0,1)");
      Check (Integer (Long_Float'Truncation (Fr * 16.0)) = 2,
             "trunc(16·frac0) = 2");
      Fr := Hex_Fractional_Part (3);
      Check (Fr >= 0.0 and then Fr < 1.0, "frac(3) in [0,1)");
      Check (Integer (Long_Float'Truncation (Fr * 16.0)) = 15,
             "trunc(16·frac3) = 15");
   end;

   ---------------------------------------------------------------------
   Section ("10. Hex_Fractional_Part / digit consistency");
   ---------------------------------------------------------------------
   declare
      Fr : Long_Float;
      D  : Hex_Digit;
      Skim : Integer;
   begin
      for N in 0 .. Max_Hex_Digit loop
         Fr := Hex_Fractional_Part (N);
         D  := Hex_Digit_Of_Pi (N);
         Check (Fr >= 0.0 and then Fr < 1.0,
                "frac in [0,1) at N=" & Integer'Image (N));
         Skim := Integer (Long_Float'Truncation (Fr * 16.0));
         if Skim < 0 then
            Skim := 0;
         elsif Skim > 15 then
            Skim := 15;
         end if;
         Check (Hex_Digit (Skim) = D,
                "digit matches skim at N=" & Integer'Image (N));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid_Argument guards");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      Dummy  : Long_Float;
      Dig    : Hex_Digit;
   begin
      Raised := False;
      begin
         Dummy := Series_Term (Max_Terms);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Series_Term(Max_Terms) raises");

      Raised := False;
      begin
         Dummy := Series_Sum (0);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Series_Sum(0) raises");

      Raised := False;
      begin
         Dummy := Series_Sum (Max_Terms + 1);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Series_Sum(Max+1) raises");

      Raised := False;
      begin
         Dig := Hex_Digit_Of_Pi (Max_Hex_Digit + 1);
         Dummy := Long_Float (Dig);  -- reached only if no raise
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Hex_Digit_Of_Pi(Max+1) raises");

      Raised := False;
      begin
         Dummy := Hex_Fractional_Part (Max_Hex_Digit + 1);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Hex_Fractional_Part(Max+1) raises");

      --  Valid boundaries do not raise
      Dummy := Series_Term (0);
      Check (Dummy > 0.0, "Series_Term(0) ok");
      Dummy := Series_Term (Max_Terms - 1);
      Check (abs (Dummy) < 1.0E-40 or else abs (Dummy) < abs (Series_Term (0)),
             "Series_Term(Last) tiny vs t0");
      Dig := Hex_Digit_Of_Pi (Max_Hex_Digit);
      Check (Dig = Known_Hex (Max_Hex_Digit),
             "Hex_Digit_Of_Pi(Max) = known");
   end;

   ---------------------------------------------------------------------
   Section ("12. Rel_Error / Abs_Error vs references");
   ---------------------------------------------------------------------
   declare
      Est : Long_Float;
   begin
      Est := Approximate_Pi (Default_Terms);
      Check (Rel_Error (Est, Pi_Constant) < 1.0E-12,
             "rel vs Pi_Constant");
      Check (Rel_Error (Est, Ada_Pi) < 1.0E-12, "rel vs Ada_Pi");
      Check (Rel_Error (Est, Elementary_Pi) < 1.0E-12,
             "rel vs Elementary_Pi");
      Check (Near (Est, Pi_Constant, 1.0E-12), "Near default tol tight");
      Check (Close (Abs_Error (Est, Pi_Constant),
                    Rel_Error (Est, Pi_Constant) * abs (Pi_Constant),
                    1.0E-20),
             "abs ≈ rel·|π|");
      Check (Abs_Error (Approximate_Pi (1), Pi_Constant) >
               Abs_Error (Approximate_Pi (Default_Terms), Pi_Constant),
             "default better than 1 term");
      Check (Near (Approximate_Pi (Max_Terms), Pi_Constant, 1.0E-14),
             "Max terms near Pi_Constant");
   end;

   ---------------------------------------------------------------------
   Section ("13. Cross-check: series vs hex sketch at N=0");
   ---------------------------------------------------------------------
   declare
      --  At N=0, 16^0·π fractional part should be {π} = π−3 ≈ 0.14159…
      --  and first hex digit of that is 2 (0.243F…₁₆).
      Fr0 : Long_Float;
      Pi_Frac : Long_Float;
   begin
      Fr0 := Hex_Fractional_Part (0);
      Pi_Frac := Pi_Constant - 3.0;
      Check (Close (Fr0, Pi_Frac, 1.0E-10),
             "frac(0) ≈ {π} = π−3");
      Check (Close (Fr0, Approximate_Pi (20) - 3.0, 1.0E-10),
             "frac(0) ≈ series−3");
      Check (Integer (Hex_Digit_Of_Pi (0)) =
               Integer (Long_Float'Truncation (Pi_Frac * 16.0)),
             "digit0 from {π}·16");
   end;

   ---------------------------------------------------------------------
   Section ("14. More series term properties");
   ---------------------------------------------------------------------
   declare
      Acc : Long_Float := 0.0;
      T   : Long_Float;
   begin
      for K in 0 .. 5 loop
         T := Series_Term (K);
         Check (T > 0.0, "t_k > 0 at k=" & Integer'Image (K));
         Acc := Acc + T;
      end loop;
      Check (Close (Acc, Series_Sum (6), 1.0E-12),
             "manual Σ t0..t5 = Sum(6)");
      Check (Close (Acc, Approximate_Pi (6), 1.0E-12),
             "manual Σ = Approximate_Pi(6)");
      Check (Term_Parenthesis (1) > 0.0, "paren(1) > 0");
      Check (Term_Parenthesis (5) > 0.0, "paren(5) > 0");
      Check (Term_Parenthesis (10) > 0.0, "paren(10) > 0");
      --  Parenthesis ~ O(1/k) for large k; term ~ 16^(−k)/k
      Check (Term_Parenthesis (20) < Term_Parenthesis (5),
             "paren shrinks with k");
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
