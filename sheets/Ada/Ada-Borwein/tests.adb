--  Standalone test suite for Borwein (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Borwein; use Borwein;

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
   Ada.Text_IO.Put_Line ("Borwein test suite");
   Ada.Text_IO.Put_Line ("==================");

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
   Section ("2. Pi_Constant / Inv_Pi / Ada_Pi / Elementary_Pi");
   ---------------------------------------------------------------------
   declare
      A, E, P, Inv : Long_Float;
   begin
      P   := Pi_Constant;
      A   := Ada_Pi;
      E   := Elementary_Pi;
      Inv := Inv_Pi_Constant;
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
      Check (Inv > 0.31 and then Inv < 0.32, "Inv_Pi_Constant band");
      Check (Close (Inv * P, 1.0, 1.0E-14), "Inv_Pi · Pi ≈ 1");
      Check (Close (1.0 / P, Inv, 1.0E-14), "1/Pi ≈ Inv_Pi_Constant");
   end;

   ---------------------------------------------------------------------
   Section ("3. Initial_State invariants");
   ---------------------------------------------------------------------
   declare
      S   : constant State := Initial_State;
      Est : Long_Float;
      Inv : Long_Float;
   begin
      Check (S.Y > 0.0, "y0 > 0");
      Check (S.Y < 0.5, "y0 < 0.5");
      Check (Close (S.Y, 0.414_213_562_373_095_15, 1.0E-14),
             "y0 = √2−1 known");
      Check (Close ((S.Y + 1.0) * (S.Y + 1.0), 2.0, 1.0E-14),
             "(y0+1)^2 = 2");
      Check (S.A > 0.0, "a0 > 0");
      Check (Close (S.A, 0.343_145_750_507_619_4, 1.0E-14),
             "a0 = 6−4√2 known");
      Check (Close (S.A, 2.0 * S.Y * S.Y, 1.0E-14),
             "a0 = 2 y0^2");
      Check (S.Iterations = 0, "Iterations = 0");
      Check (S.Y < 1.0, "y0 < 1 (1−y^4 defined)");
      Est := Pi_Estimate (S);
      Inv := Inv_Pi_Estimate (S);
      Check (Close (Inv, S.A), "Inv_Pi_Estimate = A");
      Check (Close (Est, 1.0 / S.A, 1.0E-14), "Pi_Estimate = 1/A");
      Check (Est > 2.0 and then Est < 4.0, "π0 in (2,4)");
      Check (Abs_Error (Est, Pi_Constant) > 0.1, "π0 still coarse");
      Check (Abs_Error (Est, Pi_Constant) < 1.0, "π0 within 1 of π");
      Check (Close (Est, 2.914_213_562_373_098_5, 1.0E-12),
             "π0 ≈ 2.914213…");
   end;

   ---------------------------------------------------------------------
   Section ("4. Single Iterate step");
   ---------------------------------------------------------------------
   declare
      S0   : constant State := Initial_State;
      S1   : constant State := Iterate (S0);
      Est1 : Long_Float;
      Inv1 : Long_Float;
   begin
      Check (S1.Iterations = 1, "after 1 step Iterations=1");
      Check (S1.Y > 0.0, "y1 > 0");
      Check (S1.Y < S0.Y, "y decreases");
      Check (S1.A > 0.0, "a1 > 0");
      Check (S1.Y < 0.01, "y1 small (<0.01)");
      Check (Close (S1.Y, 3.734_885_463_325_165E-3, 1.0E-12),
             "y1 known value");
      Est1 := Pi_Estimate (S1);
      Inv1 := Inv_Pi_Estimate (S1);
      Check (Close (Inv1, S1.A), "Inv after 1 = A");
      Check (Abs_Error (Est1, Pi_Constant) < Abs_Error (Pi_Estimate (S0),
             Pi_Constant), "error shrinks after 1 step");
      Check (Abs_Error (Est1, Pi_Constant) < 1.0E-7, "|π1−π| < 1e-7");
      Check (Close (Est1, 3.141_592_646_213_547, 1.0E-12),
             "π1 ≈ 3.141592646…");
      Check (Abs_Error (Inv1, Inv_Pi_Constant) < 1.0E-8,
             "|a1−1/π| < 1e-8");
   end;

   ---------------------------------------------------------------------
   Section ("5. Approximate_Pi / Approximate_Inv_Pi (0 .. N)");
   ---------------------------------------------------------------------
   declare
      E0, E1, E2, E3, E4 : Long_Float;
      I0, I1, I2, I4     : Long_Float;
      Prev_Err, Cur_Err  : Long_Float;
   begin
      E0 := Approximate_Pi (0);
      E1 := Approximate_Pi (1);
      E2 := Approximate_Pi (2);
      E3 := Approximate_Pi (3);
      E4 := Approximate_Pi (4);
      I0 := Approximate_Inv_Pi (0);
      I1 := Approximate_Inv_Pi (1);
      I2 := Approximate_Inv_Pi (2);
      I4 := Approximate_Inv_Pi (4);

      Check (E0 > 2.0, "Approx(0) > 2");
      Check (Close (E0 * I0, 1.0, 1.0E-14), "π0 · (1/π)0 ≈ 1");
      Check (Abs_Error (E1, Pi_Constant) < Abs_Error (E0, Pi_Constant),
             "err(1) < err(0)");
      Check (Abs_Error (E2, Pi_Constant) < Abs_Error (E1, Pi_Constant)
               or else Abs_Error (E2, Pi_Constant) < 1.0E-14,
             "err(2) ≤ err(1) or saturated");
      Check (Abs_Error (E1, Pi_Constant) < 1.0E-7, "|π1−π| < 1e-7");
      Check (Abs_Error (E2, Pi_Constant) < 5.0E-14, "|π2−π| < 5e-14");
      Check (Near (E2, Pi_Constant, 5.0E-14), "Near π2 to Pi_Constant");
      Check (Near (E3, Pi_Constant, 5.0E-14), "Near π3 to Pi_Constant");
      Check (Near (E4, Pi_Constant, 5.0E-14), "Near π4 to Pi_Constant");
      Check (Near (E2, Ada_Pi, 5.0E-14), "π2 ≈ Ada_Pi");
      Check (Near (E2, Elementary_Pi, 5.0E-14), "π2 ≈ Elementary_Pi");
      Check (Close (Approximate_Pi, E4), "default Iterations = 4");
      Check (Close (I2, Inv_Pi_Constant, 1.0E-14), "a2 ≈ Inv_Pi_Constant");
      Check (Close (I4, Inv_Pi_Constant, 1.0E-14), "a4 ≈ Inv_Pi_Constant");
      Check (Close (1.0 / I1, E1, 1.0E-14), "1/Inv(1)=Pi(1)");
      Check (Close (1.0 / I2, E2, 1.0E-14), "1/Inv(2)=Pi(2)");

      Prev_Err := Abs_Error (E0, Pi_Constant);
      for N in Iteration_Count range 1 .. 5 loop
         Cur_Err := Abs_Error (Approximate_Pi (N), Pi_Constant);
         Check (Cur_Err <= Prev_Err + 1.0E-18,
                "non-increasing abs error at N=" &
                Natural'Image (N));
         Prev_Err := Cur_Err;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("6. Approximate_Pi / Inv_Pi procedures");
   ---------------------------------------------------------------------
   declare
      Final : State;
      Est   : Long_Float;
   begin
      Approximate_Pi (0, Final, Est);
      Check (Final.Iterations = 0, "proc Pi(0) Iterations=0");
      Check (Close (Est, Pi_Estimate (Final)), "proc Pi(0) Est matches");
      Check (Close (Est, Approximate_Pi (0)), "proc Pi(0) = func(0)");

      Approximate_Pi (2, Final, Est);
      Check (Final.Iterations = 2, "proc Pi(2) Iterations=2");
      Check (Close (Est, Approximate_Pi (2)), "proc Pi(2) = func(2)");
      Check (Final.A > 0.0, "proc Pi(2) a > 0");
      Check (Final.Y >= 0.0, "proc Pi(2) y ≥ 0");
      Check (Near (Est, Pi_Constant, 5.0E-14), "proc Pi(2) ≈ π");

      Approximate_Inv_Pi (2, Final, Est);
      Check (Final.Iterations = 2, "proc Inv(2) Iterations=2");
      Check (Close (Est, Approximate_Inv_Pi (2)), "proc Inv(2)=func(2)");
      Check (Close (Est, Final.A), "proc Inv Est = A");
      Check (Near (Est, Inv_Pi_Constant, 1.0E-14), "proc Inv(2) ≈ 1/π");

      Approximate_Pi (Default_Iterations, Final, Est);
      Check (Final.Iterations = Natural (Default_Iterations),
             "proc default Iterations");
      Check (Near (Est, Pi_Constant, 5.0E-14), "proc default ≈ π");
   end;

   ---------------------------------------------------------------------
   Section ("7. Quartic monotone properties across iterations");
   ---------------------------------------------------------------------
   declare
      S, Prev : State;
   begin
      S := Initial_State;
      for N in 1 .. 6 loop
         Prev := S;
         S := Iterate (S);
         Check (S.A > 0.0, "a>0 at n=" & Integer'Image (N));
         Check (S.Y >= 0.0, "y≥0 at n=" & Integer'Image (N));
         Check (S.Y <= Prev.Y + 1.0E-18, "y non-increasing at n=" &
                Integer'Image (N));
         Check (S.Iterations = N, "Iterations counter at n=" &
                Integer'Image (N));
         Check (S.Y < 1.0, "y<1 at n=" & Integer'Image (N));
         if N >= 2 then
            Check (S.Y < 1.0E-10 or else Close (S.Y, 0.0),
                   "y tiny by n=" & Integer'Image (N));
         end if;
      end loop;
      Check (S.Y < 1.0E-15 or else Close (S.Y, 0.0), "y≈0 after 6 steps");
      Check (Near (Pi_Estimate (S), Pi_Constant, 5.0E-14),
             "π after 6 ≈ Pi_Constant");
   end;

   ---------------------------------------------------------------------
   Section ("8. Stabilisation within Long_Float");
   ---------------------------------------------------------------------
   declare
      E2, E3, E4, E8, E12, E20 : Long_Float;
      I2, I4, I20              : Long_Float;
   begin
      E2  := Approximate_Pi (2);
      E3  := Approximate_Pi (3);
      E4  := Approximate_Pi (4);
      E8  := Approximate_Pi (8);
      E12 := Approximate_Pi (12);
      E20 := Approximate_Pi (20);
      I2  := Approximate_Inv_Pi (2);
      I4  := Approximate_Inv_Pi (4);
      I20 := Approximate_Inv_Pi (20);
      Check (Near (E2, E3, 1.0E-14), "π2 ≈ π3 (saturated)");
      Check (Near (E3, E4, 1.0E-14), "π3 ≈ π4");
      Check (Near (E4, E8, 1.0E-14), "π4 ≈ π8");
      Check (Near (E8, E12, 1.0E-14), "π8 ≈ π12");
      Check (Near (E12, E20, 1.0E-14), "π12 ≈ π20");
      Check (Near (E20, Pi_Constant, 5.0E-14), "π20 ≈ Pi_Constant");
      Check (Abs_Error (E20, Ada_Pi) < 5.0E-14, "|π20−Ada_Pi| < 5e-14");
      Check (Abs_Error (E20, Elementary_Pi) < 5.0E-14,
             "|π20−Elementary_Pi| < 5e-14");
      Check (Rel_Error (E20, Pi_Constant) < 1.0E-14, "rel err π20 tiny");
      Check (Near (I2, I4, 1.0E-14), "a2 ≈ a4");
      Check (Near (I4, I20, 1.0E-14), "a4 ≈ a20");
      Check (Near (I20, Inv_Pi_Constant, 1.0E-14), "a20 ≈ Inv_Pi");
   end;

   ---------------------------------------------------------------------
   Section ("9. Invalid_Argument / boundary defence");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      Bad    : State;
      Dummy  : State;
      Est    : Long_Float;
   begin
      Raised := False;
      begin
         Bad := Iterate (Initial_State);
         for K in 1 .. Max_Iterations loop
            Bad := Iterate (Bad);
         end loop;
         Check (False, "Iterate past max should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Iterate beyond Max_Iterations raises");

      Raised := False;
      Bad := Initial_State;
      Bad.A := 0.0;
      declare
         Tmp : State;
      begin
         Tmp := Iterate (Bad);
         Check (False and then Tmp.Iterations = 0, "Iterate a=0 should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Iterate with a=0 raises");

      Raised := False;
      declare
         Tmp : Long_Float;
      begin
         Tmp := Pi_Estimate (Bad);
         Check (False and then Tmp = 0.0, "Pi_Estimate a=0 should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Pi_Estimate with a=0 raises");

      Raised := False;
      declare
         Tmp : Long_Float;
      begin
         Tmp := Inv_Pi_Estimate (Bad);
         Check (False and then Tmp = 0.0, "Inv_Pi a=0 should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Inv_Pi_Estimate with a=0 raises");

      Raised := False;
      Bad.A := -1.0;
      declare
         Tmp : Long_Float;
      begin
         Tmp := Pi_Estimate (Bad);
         Check (False and then Tmp = 0.0, "Pi_Estimate a<0 should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Pi_Estimate with a<0 raises");

      Est := Approximate_Pi (Max_Iterations);
      Check (Near (Est, Pi_Constant, 5.0E-14),
             "Approximate_Pi(Max) succeeds");
      Approximate_Pi (Max_Iterations, Dummy, Est);
      Check (Dummy.Iterations = Max_Iterations,
             "proc Max Iterations field");
      Check (Near (Est, Pi_Constant, 5.0E-14), "proc Max estimate");
      Approximate_Inv_Pi (Max_Iterations, Dummy, Est);
      Check (Near (Est, Inv_Pi_Constant, 1.0E-14), "proc Max Inv estimate");
   end;

   ---------------------------------------------------------------------
   Section ("10. Worked numerical checkpoints");
   ---------------------------------------------------------------------
   declare
      S0, S1, S2 : State;
      Pi0, Pi1, Pi2 : Long_Float;
      Inv0, Inv1    : Long_Float;
   begin
      S0 := Initial_State;
      Check (Close ((S0.Y + 1.0) * (S0.Y + 1.0), 2.0, 1.0E-14),
             "(y0+1)^2 = 2");
      Pi0  := Pi_Estimate (S0);
      Inv0 := Inv_Pi_Estimate (S0);
      Check (Close (Pi0, 2.914_213_562_373_098_5, 1.0E-12), "π0 checkpoint");
      Check (Close (Inv0, 0.343_145_750_507_619_4, 1.0E-14), "a0 checkpoint");

      S1 := Iterate (S0);
      Pi1  := Pi_Estimate (S1);
      Inv1 := Inv_Pi_Estimate (S1);
      Check (Close (Pi1, 3.141_592_646_213_547, 1.0E-12), "π1 checkpoint");
      Check (Abs_Error (Pi1, Pi_Constant) < 1.0E-8, "|π1−π| < 1e-8");
      Check (Abs_Error (Inv1, Inv_Pi_Constant) < 1.0E-8, "|a1−1/π| < 1e-8");

      S2 := Iterate (S1);
      Pi2 := Pi_Estimate (S2);
      Check (Near (Pi2, Pi_Constant, 5.0E-14), "π2 machine π");
      Check (Abs_Error (Pi2, Pi_Constant) < 5.0E-14, "|π2−π| < 5e-14");

      Check (Close (Approximate_Pi (0), Pi0), "func(0)=π0");
      Check (Close (Approximate_Pi (1), Pi1), "func(1)=π1");
      Check (Close (Approximate_Pi (2), Pi2), "func(2)=π2");
   end;

   ---------------------------------------------------------------------
   Section ("11. Error magnitudes (quartic sketch)");
   ---------------------------------------------------------------------
   declare
      Errs : array (0 .. 4) of Long_Float;
      Ref  : constant Long_Float := Pi_Constant;
   begin
      for N in Errs'Range loop
         Errs (N) := Abs_Error (Approximate_Pi (N), Ref);
      end loop;
      Check (Errs (0) > 1.0E-1, "err0 > 1e-1");
      Check (Errs (1) < 1.0E-7, "err1 < 1e-7");
      Check (Errs (2) < 5.0E-14, "err2 < 5e-14");
      Check (Errs (3) < 5.0E-14, "err3 < 5e-14");
      Check (Errs (4) < 5.0E-14, "err4 < 5e-14");
      --  Quartic flavour: one step jumps many orders of magnitude
      Check (Errs (1) < Errs (0) / 1.0E5, "err1 ≪ err0 / 1e5");
      Check (Errs (2) <= Errs (1) + 1.0E-18, "err2 ≤ err1 (sat)");
   end;

   ---------------------------------------------------------------------
   Section ("12. Rel_Error vs references");
   ---------------------------------------------------------------------
   declare
      Est : Long_Float;
      Inv : Long_Float;
   begin
      Est := Approximate_Pi (4);
      Inv := Approximate_Inv_Pi (4);
      Check (Rel_Error (Est, Pi_Constant) < 1.0E-14,
             "rel vs Pi_Constant");
      Check (Rel_Error (Est, Ada_Pi) < 1.0E-14, "rel vs Ada_Pi");
      Check (Rel_Error (Est, Elementary_Pi) < 1.0E-14,
             "rel vs Elementary_Pi");
      Check (Rel_Error (Inv, Inv_Pi_Constant) < 1.0E-14,
             "rel Inv vs Inv_Pi_Constant");
      Check (Near (Est, Pi_Constant), "Near default tol");
      Check (Close (Abs_Error (Est, Pi_Constant),
                    Rel_Error (Est, Pi_Constant) * abs (Pi_Constant),
                    1.0E-20),
             "abs ≈ rel·|π|");
      Check (Close (Approximate_Pi (Default_Iterations), Approximate_Pi),
             "Default_Iterations matches default call");
      Check (Close (Approximate_Inv_Pi (Default_Iterations),
                    Approximate_Inv_Pi),
             "Default Inv matches default call");
      Check (Near (Approximate_Pi (Max_Iterations), Pi_Constant, 5.0E-14),
             "Max iters near Pi_Constant");
      Check (Abs_Error (Approximate_Pi (0), Pi_Constant) >
               Abs_Error (Approximate_Pi (Default_Iterations), Pi_Constant),
             "default better than zero iters");
   end;

   ---------------------------------------------------------------------
   Section ("13. State consistency Pi ↔ Inv_Pi");
   ---------------------------------------------------------------------
   declare
      S   : State := Initial_State;
      Est : Long_Float;
      Inv : Long_Float;
   begin
      for N in 0 .. 8 loop
         Est := Pi_Estimate (S);
         Inv := Inv_Pi_Estimate (S);
         Check (Close (Est, Approximate_Pi (N)),
                "Pi matches Approx at n=" & Integer'Image (N));
         Check (Close (Inv, Approximate_Inv_Pi (N)),
                "Inv matches Approx at n=" & Integer'Image (N));
         Check (Close (Est * Inv, 1.0, 1.0E-14),
                "π·(1/π)=1 at n=" & Integer'Image (N));
         Check (Close (Inv, S.A), "Inv=A at n=" & Integer'Image (N));
         if N = 0 then
            Check (Est > 2.5 and then Est < 3.2,
                   "π band at n=" & Integer'Image (N));
         else
            Check (Est > 3.0 and then Est < 3.2,
                   "π band at n=" & Integer'Image (N));
         end if;
         if N < 8 then
            S := Iterate (S);
         end if;
      end loop;
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
