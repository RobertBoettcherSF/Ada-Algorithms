--  Standalone test suite for Gauss_Legendre (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Gauss_Legendre; use Gauss_Legendre;

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
   Ada.Text_IO.Put_Line ("Gauss_Legendre test suite");
   Ada.Text_IO.Put_Line ("=========================");

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
   Section ("3. Initial_State invariants");
   ---------------------------------------------------------------------
   declare
      S : constant State := Initial_State;
      Est : Long_Float;
   begin
      Check (Close (S.A, 1.0), "a0 = 1");
      Check (S.B > 0.0, "b0 > 0");
      Check (S.B < 1.0, "b0 < 1");
      Check (Close (S.B * S.B, 0.5, 1.0E-14), "b0^2 = 1/2");
      Check (Close (S.T, 0.25), "t0 = 1/4");
      Check (Close (S.P, 1.0), "p0 = 1");
      Check (S.Iterations = 0, "Iterations = 0");
      Check (S.A >= S.B, "a0 ≥ b0");
      Check (S.B >= 0.0, "b0 ≥ 0");
      Est := Pi_Estimate (S);
      Check (Est > 2.0 and then Est < 4.0, "π0 in (2,4)");
      Check (Abs_Error (Est, Pi_Constant) > 0.01, "π0 still coarse");
      Check (Abs_Error (Est, Pi_Constant) < 1.0, "π0 within 1 of π");
   end;

   ---------------------------------------------------------------------
   Section ("4. Single Iterate step");
   ---------------------------------------------------------------------
   declare
      S0 : constant State := Initial_State;
      S1 : constant State := Iterate (S0);
      Est1 : Long_Float;
   begin
      Check (S1.Iterations = 1, "after 1 step Iterations=1");
      Check (Close (S1.P, 2.0), "p1 = 2");
      Check (S1.A >= S1.B, "a1 ≥ b1");
      Check (S1.B >= 0.0, "b1 ≥ 0");
      Check (S1.T > 0.0, "t1 > 0");
      Check (S1.A < S0.A or else Close (S1.A, S0.A), "a decreasing (AM)");
      Check (S1.B > S0.B or else Close (S1.B, S0.B), "b increasing (GM)");
      Check (S1.A - S1.B < S0.A - S0.B, "gap a-b shrinks");
      Check (Close (S1.A, 0.5 * (S0.A + S0.B), 1.0E-14), "a1 = (a0+b0)/2");
      Est1 := Pi_Estimate (S1);
      Check (Abs_Error (Est1, Pi_Constant) < Abs_Error (Pi_Estimate (S0),
             Pi_Constant), "error shrinks after 1 step");
      Check (Abs_Error (Est1, Pi_Constant) < 0.01, "|π1−π| < 0.01");
   end;

   ---------------------------------------------------------------------
   Section ("5. Approximate_Pi function (0 .. N)");
   ---------------------------------------------------------------------
   declare
      E0, E1, E2, E3, E4, E5, E8 : Long_Float;
      Prev_Err, Cur_Err : Long_Float;
   begin
      E0 := Approximate_Pi (0);
      E1 := Approximate_Pi (1);
      E2 := Approximate_Pi (2);
      E3 := Approximate_Pi (3);
      E4 := Approximate_Pi (4);
      E5 := Approximate_Pi (5);
      E8 := Approximate_Pi (8);

      Check (E0 > 2.0, "Approx(0) > 2");
      Check (Abs_Error (E1, Pi_Constant) < Abs_Error (E0, Pi_Constant),
             "err(1) < err(0)");
      Check (Abs_Error (E2, Pi_Constant) < Abs_Error (E1, Pi_Constant),
             "err(2) < err(1)");
      Check (Abs_Error (E3, Pi_Constant) < Abs_Error (E2, Pi_Constant)
               or else Abs_Error (E3, Pi_Constant) < 1.0E-14,
             "err(3) ≤ err(2) or saturated");
      Check (Abs_Error (E4, Pi_Constant) < 1.0E-12, "|π4−π| < 1e-12");
      Check (Abs_Error (E5, Pi_Constant) < 1.0E-14, "|π5−π| < 1e-14");
      Check (Near (E5, Pi_Constant, 1.0E-14), "Near π5 to Pi_Constant");
      Check (Near (E8, Pi_Constant, 1.0E-14), "Near π8 to Pi_Constant");
      Check (Near (E5, Ada_Pi, 1.0E-14), "π5 ≈ Ada_Pi");
      Check (Near (E5, Elementary_Pi, 1.0E-14), "π5 ≈ Elementary_Pi");
      Check (Close (Approximate_Pi, E8), "default Iterations = 8");

      --  Digit-doubling flavour: error roughly shrinks until saturation
      Prev_Err := Abs_Error (E0, Pi_Constant);
      for N in Iteration_Count range 1 .. 6 loop
         Cur_Err := Abs_Error (Approximate_Pi (N), Pi_Constant);
         Check (Cur_Err <= Prev_Err + 1.0E-18,
                "non-increasing abs error at N=" &
                Natural'Image (N));
         Prev_Err := Cur_Err;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("6. Approximate_Pi procedure (state + estimate)");
   ---------------------------------------------------------------------
   declare
      Final : State;
      Est   : Long_Float;
   begin
      Approximate_Pi (0, Final, Est);
      Check (Final.Iterations = 0, "proc(0) Iterations=0");
      Check (Close (Est, Pi_Estimate (Final)), "proc(0) Est matches state");
      Check (Close (Est, Approximate_Pi (0)), "proc(0) = func(0)");

      Approximate_Pi (3, Final, Est);
      Check (Final.Iterations = 3, "proc(3) Iterations=3");
      Check (Close (Final.P, 8.0), "proc(3) p = 2^3 = 8");
      Check (Close (Est, Approximate_Pi (3)), "proc(3) = func(3)");
      Check (Final.A >= Final.B, "proc(3) a ≥ b");
      Check (Final.B >= 0.0, "proc(3) b ≥ 0");
      Check (Final.T > 0.0, "proc(3) t > 0");

      Approximate_Pi (Default_Iterations, Final, Est);
      Check (Final.Iterations = Natural (Default_Iterations),
             "proc default Iterations");
      Check (Near (Est, Pi_Constant, 1.0E-14), "proc default ≈ π");
   end;

   ---------------------------------------------------------------------
   Section ("7. AGM monotone properties across iterations");
   ---------------------------------------------------------------------
   declare
      S, Prev : State;
      Gap_Prev, Gap : Long_Float;
   begin
      S := Initial_State;
      Gap_Prev := S.A - S.B;
      for N in 1 .. 8 loop
         Prev := S;
         S := Iterate (S);
         Check (S.A >= S.B, "a≥b at n=" & Integer'Image (N));
         Check (S.B >= 0.0, "b≥0 at n=" & Integer'Image (N));
         Check (S.T > 0.0, "t>0 at n=" & Integer'Image (N));
         Check (Close (S.P, Prev.P * 2.0), "p doubles at n=" &
                Integer'Image (N));
         Check (S.Iterations = N, "Iterations counter at n=" &
                Integer'Image (N));
         --  a decreases (non-strict), b increases (non-strict)
         Check (S.A <= Prev.A + 1.0E-15, "a non-increasing at n=" &
                Integer'Image (N));
         Check (S.B >= Prev.B - 1.0E-15, "b non-decreasing at n=" &
                Integer'Image (N));
         Gap := S.A - S.B;
         Check (Gap <= Gap_Prev + 1.0E-15, "gap shrinks at n=" &
                Integer'Image (N));
         Gap_Prev := Gap;
      end loop;
      Check (S.A - S.B < 1.0E-14, "a≈b after 8 steps");
   end;

   ---------------------------------------------------------------------
   Section ("8. Stabilisation within Long_Float");
   ---------------------------------------------------------------------
   declare
      E5, E6, E10, E15, E20 : Long_Float;
   begin
      E5  := Approximate_Pi (5);
      E6  := Approximate_Pi (6);
      E10 := Approximate_Pi (10);
      E15 := Approximate_Pi (15);
      E20 := Approximate_Pi (20);
      Check (Near (E5, E6, 1.0E-14), "π5 ≈ π6 (saturated)");
      Check (Near (E6, E10, 1.0E-14), "π6 ≈ π10");
      Check (Near (E10, E15, 1.0E-14), "π10 ≈ π15");
      Check (Near (E15, E20, 1.0E-14), "π15 ≈ π20");
      Check (Near (E20, Pi_Constant, 1.0E-14), "π20 ≈ Pi_Constant");
      Check (Abs_Error (E20, Ada_Pi) < 1.0E-14, "|π20−Ada_Pi| < 1e-14");
      Check (Abs_Error (E20, Elementary_Pi) < 1.0E-14,
             "|π20−Elementary_Pi| < 1e-14");
      Check (Rel_Error (E20, Pi_Constant) < 1.0E-14, "rel err π20 tiny");
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
      Bad.T := 0.0;
      declare
         Tmp : State;
      begin
         Tmp := Iterate (Bad);
         Check (False and then Tmp.Iterations = 0, "Iterate t=0 should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Iterate with t=0 raises");

      Raised := False;
      declare
         Tmp : Long_Float;
      begin
         Tmp := Pi_Estimate (Bad);
         Check (False and then Tmp = 0.0, "Pi_Estimate t=0 should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Pi_Estimate with t=0 raises");

      Raised := False;
      Bad.T := -1.0;
      declare
         Tmp : Long_Float;
      begin
         Tmp := Pi_Estimate (Bad);
         Check (False and then Tmp = 0.0, "Pi_Estimate t<0 should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Pi_Estimate with t<0 raises");

      --  Max_Iterations itself is allowed
      Est := Approximate_Pi (Max_Iterations);
      Check (Near (Est, Pi_Constant, 1.0E-14),
             "Approximate_Pi(Max) succeeds");
      Approximate_Pi (Max_Iterations, Dummy, Est);
      Check (Dummy.Iterations = Max_Iterations,
             "proc Max Iterations field");
      Check (Near (Est, Pi_Constant, 1.0E-14), "proc Max estimate");
   end;

   ---------------------------------------------------------------------
   Section ("10. Worked numerical checkpoints");
   ---------------------------------------------------------------------
   declare
      --  Hand-checkable early values (Long_Float tolerance)
      S0, S1, S2 : State;
      Pi0, Pi1, Pi2 : Long_Float;
   begin
      S0 := Initial_State;
      --  b0 = 1/√2 ≈ 0.7071067811865475
      Check (Close (S0.B, 0.707_106_781_186_547_5, 1.0E-14),
             "b0 known value");
      Pi0 := Pi_Estimate (S0);
      --  (1+1/√2)^2 / 1  = (1+√2/2)^2 ≈ 2.914213562…
      Check (Close (Pi0, (1.0 + S0.B) * (1.0 + S0.B), 1.0E-12),
             "π0 = (a0+b0)^2/(4t0) with 4t0=1");

      S1 := Iterate (S0);
      Pi1 := Pi_Estimate (S1);
      Check (Close (Pi1, 3.140_579_250_522_168, 1.0E-10),
             "π1 ≈ 3.140579…");
      Check (Abs_Error (Pi1, Pi_Constant) < 1.1E-3, "|π1−π| < 1.1e-3");

      S2 := Iterate (S1);
      Pi2 := Pi_Estimate (S2);
      Check (Close (Pi2, 3.141_592_646_213_543, 1.0E-9),
             "π2 ≈ 3.141592646…");
      Check (Abs_Error (Pi2, Pi_Constant) < 1.0E-8, "|π2−π| < 1e-8");

      Check (Close (Approximate_Pi (1), Pi1), "func(1)=π1");
      Check (Close (Approximate_Pi (2), Pi2), "func(2)=π2");
   end;

   ---------------------------------------------------------------------
   Section ("11. Error magnitudes (digit-doubling sketch)");
   ---------------------------------------------------------------------
   declare
      Errs : array (0 .. 5) of Long_Float;
      Ref  : constant Long_Float := Pi_Constant;
   begin
      for N in Errs'Range loop
         Errs (N) := Abs_Error (Approximate_Pi (N), Ref);
      end loop;
      Check (Errs (0) > 1.0E-2, "err0 > 1e-2");
      Check (Errs (1) < 2.0E-3, "err1 < 2e-3");
      Check (Errs (2) < 1.0E-7, "err2 < 1e-7");
      Check (Errs (3) < 1.0E-14 or else Errs (3) < Errs (2),
             "err3 tiny or < err2");
      Check (Errs (4) < 1.0E-14, "err4 < 1e-14");
      Check (Errs (5) < 1.0E-14, "err5 < 1e-14");
      --  Rough doubling: each early step multiplies correct digits
      Check (Errs (1) < Errs (0) / 10.0, "err1 ≪ err0 / 10");
      Check (Errs (2) < Errs (1) / 100.0, "err2 ≪ err1 / 100");
   end;

   ---------------------------------------------------------------------
   Section ("12. Rel_Error vs references");
   ---------------------------------------------------------------------
   declare
      Est : Long_Float;
   begin
      Est := Approximate_Pi (6);
      Check (Rel_Error (Est, Pi_Constant) < 1.0E-14,
             "rel vs Pi_Constant");
      Check (Rel_Error (Est, Ada_Pi) < 1.0E-14, "rel vs Ada_Pi");
      Check (Rel_Error (Est, Elementary_Pi) < 1.0E-14,
             "rel vs Elementary_Pi");
      Check (Near (Est, Pi_Constant), "Near default tol");
      Check (Close (Abs_Error (Est, Pi_Constant),
                    Rel_Error (Est, Pi_Constant) * abs (Pi_Constant),
                    1.0E-20),
             "abs ≈ rel·|π|");
      Check (Close (Approximate_Pi (Default_Iterations), Approximate_Pi),
             "Default_Iterations matches default call");
      Check (Near (Approximate_Pi (Max_Iterations), Pi_Constant, 1.0E-14),
             "Max iters near Pi_Constant");
      Check (Abs_Error (Approximate_Pi (0), Pi_Constant) >
               Abs_Error (Approximate_Pi (Default_Iterations), Pi_Constant),
             "default better than zero iters");
   end;

   ---------------------------------------------------------------------
   Section ("13. p = 2^n and estimate consistency");
   ---------------------------------------------------------------------
   declare
      S   : State := Initial_State;
      Pow : Long_Float := 1.0;
      Est : Long_Float;
   begin
      for N in 0 .. 10 loop
         Check (Close (S.P, Pow), "p=2^n at n=" & Integer'Image (N));
         Est := Pi_Estimate (S);
         Check (Close (Est, Approximate_Pi (N)),
                "estimate matches Approx at n=" & Integer'Image (N));
         if N = 0 then
            Check (Est > 2.5 and then Est < 3.2,
                   "π estimate band at n=" & Integer'Image (N));
         else
            Check (Est > 3.0 and then Est < 3.2,
                   "π estimate band at n=" & Integer'Image (N));
         end if;
         if N < 10 then
            S := Iterate (S);
            Pow := Pow * 2.0;
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
