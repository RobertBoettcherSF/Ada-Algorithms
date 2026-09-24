--  Standalone test suite for Pareto_Interpolation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics.Elementary_Functions;
with Ada.Text_IO;
with Pareto_Interpolation; use Pareto_Interpolation;

procedure Tests is

   package Math renames Ada.Numerics.Elementary_Functions;

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

   function Approx (A, B : Float; Tol : Float := 1.0E-4) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Rel_Near (A, B : Float; Tol : Float := 1.0E-3) return Boolean is
   begin
      if abs (B) < 1.0E-12 then
         return abs (A - B) <= Tol;
      end if;
      return abs (A - B) <= Tol * abs (B);
   end Rel_Near;

begin
   Ada.Text_IO.Put_Line ("Pareto_Interpolation test suite");
   Ada.Text_IO.Put_Line ("===============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Is_Positive / Validate_Parameters");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny");
      Check (not Near (1.0, 2.0), "Near rejects");
      Check (Is_Positive (1.0), "Is_Positive 1");
      Check (not Is_Positive (0.0), "Is_Positive 0");
      Check (not Is_Positive (-1.0), "Is_Positive neg");
      Check (Validate_Parameters (1.0, 2.0) = Ok, "Validate ok");
      Check (Validate_Parameters (0.0, 2.0) = Bad_Parameters,
             "Validate kappa=0");
      Check (Validate_Parameters (-1.0, 2.0) = Bad_Parameters,
             "Validate kappa<0");
      Check (Validate_Parameters (1.0, 0.0) = Bad_Parameters,
             "Validate theta=0");
      Check (Validate_Parameters (1.0, -0.5) = Bad_Parameters,
             "Validate theta<0");
   end;

   ---------------------------------------------------------------------
   Section ("2. Validate_Cumulative");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Validate_Cumulative (35_000.0, 40_000.0, 0.45, 0.55) = Ok,
             "Wiki pair ok");
      Check (Validate_Cumulative (10.0, 5.0, 0.2, 0.4) =
             Invalid_Proportions,
             "a >= b rejected");
      Check (Validate_Cumulative (10.0, 20.0, 0.6, 0.4) =
             Invalid_Proportions,
             "Pa >= Pb rejected");
      Check (Validate_Cumulative (10.0, 20.0, 0.0, 0.5) =
             Invalid_Proportions,
             "Pa=0 rejected");
      Check (Validate_Cumulative (10.0, 20.0, 0.2, 1.0) =
             Invalid_Proportions,
             "Pb=1 rejected");
      Check (Validate_Cumulative (-1.0, 20.0, 0.2, 0.5) = Bad_Parameters,
             "negative a rejected");
      Check (Validate_Cumulative (0.0, 20.0, 0.2, 0.5) = Bad_Parameters,
             "a=0 rejected");
   end;

   ---------------------------------------------------------------------
   Section ("3. Known kappa,theta — CDF / Quantile inverses");
   ---------------------------------------------------------------------
   declare
      Kappa : constant Float := 2.0;
      Theta : constant Float := 1.5;
      R, Q  : Eval_Result;
      Pvals : constant array (1 .. 5) of Float :=
        [0.1, 0.25, 0.5, 0.75, 0.9];
      X     : Float;
      Round : Boolean := True;
   begin
      --  At x = kappa, CDF = 0
      R := CDF (Kappa, Kappa, Theta);
      Check (R.Success and Approx (R.Value, 0.0, 1.0E-5),
             "CDF(kappa)=0");

      --  Below kappa
      R := CDF (Kappa - 0.5, Kappa, Theta);
      Check (R.Success and Approx (R.Value, 0.0), "CDF below kappa");

      --  Closed form: F(x) = 1 - (k/x)^t
      X := 8.0;
      R := CDF (X, Kappa, Theta);
      declare
         Expect : constant Float :=
           1.0 - Math.Exp (Theta * (Math.Log (Kappa) - Math.Log (X)));
      begin
         Check (R.Success and Approx (R.Value, Expect, 1.0E-5),
                "CDF closed form at 8");
      end;

      --  Quantile o CDF and CDF o Quantile
      for I in Pvals'Range loop
         Q := Quantile (Pvals (I), Kappa, Theta);
         if not Q.Success then
            Round := False;
         else
            R := CDF (Q.Value, Kappa, Theta);
            if not (R.Success and Approx (R.Value, Pvals (I), 2.0E-4))
            then
               Round := False;
            end if;
         end if;
      end loop;
      Check (Round, "CDF(Quantile(p)) ≈ p for 5 probs");

      Round := True;
      declare
         Xs : constant array (1 .. 4) of Float :=
           [2.5, 4.0, 10.0, 50.0];
      begin
         for I in Xs'Range loop
            R := CDF (Xs (I), Kappa, Theta);
            Q := Quantile (R.Value, Kappa, Theta);
            if not (Q.Success
                    and Rel_Near (Q.Value, Xs (I), 2.0E-3))
            then
               Round := False;
            end if;
         end loop;
      end;
      Check (Round, "Quantile(CDF(x)) ≈ x for 4 xs");

      --  Inverse_CDF rename
      Q := Inverse_CDF (0.5, Kappa, Theta);
      R := Median (Kappa, Theta);
      Check (Q.Success and R.Success and Approx (Q.Value, R.Value, 1.0E-4),
             "Inverse_CDF(0.5)=Median");
   end;

   ---------------------------------------------------------------------
   Section ("4. Median formula kappa * 2^(1/theta)");
   ---------------------------------------------------------------------
   declare
      R : Eval_Result;
      Expect : Float;
   begin
      R := Median (1.0, 1.0);
      Check (R.Success and Approx (R.Value, 2.0, 1.0E-5),
             "Median(1,1)=2");

      R := Median (10.0, 2.0);
      Expect := 10.0 * Math.Sqrt (2.0);  -- 2^{1/2}
      Check (R.Success and Approx (R.Value, Expect, 1.0E-4),
             "Median(10,2)=10*sqrt(2)");

      R := Median (5.0, 0.5);
      Expect := 5.0 * 4.0;  -- 2^{1/0.5} = 4
      Check (R.Success and Approx (R.Value, Expect, 1.0E-4),
             "Median(5,0.5)=20");

      R := Median (-1.0, 1.0);
      Check (not R.Success and R.Stat = Bad_Parameters,
             "Median bad kappa");
      R := Median (1.0, 0.0);
      Check (not R.Success and R.Stat = Bad_Parameters,
             "Median bad theta");
   end;

   ---------------------------------------------------------------------
   Section ("5. PDF checks");
   ---------------------------------------------------------------------
   declare
      Kappa : constant Float := 1.0;
      Theta : constant Float := 2.0;
      R     : Eval_Result;
      Expect : Float;
   begin
      R := PDF (0.5, Kappa, Theta);
      Check (R.Success and Approx (R.Value, 0.0), "PDF below kappa = 0");

      --  f(x) = θ κ^θ / x^{θ+1}; at x=1: 2*1/1^3 = 2
      R := PDF (1.0, Kappa, Theta);
      Check (R.Success and Approx (R.Value, 2.0, 1.0E-4),
             "PDF(1;1,2)=2");

      R := PDF (2.0, Kappa, Theta);
      Expect := 2.0 * 1.0 / 8.0;  -- 2 / 2^3 = 0.25
      Check (R.Success and Approx (R.Value, Expect, 1.0E-4),
             "PDF(2;1,2)=0.25");

      R := PDF (3.0, -1.0, 2.0);
      Check (not R.Success and R.Stat = Bad_Parameters, "PDF bad kappa");
   end;

   ---------------------------------------------------------------------
   Section ("6. Fit_From_Cumulative (Wikipedia formulas)");
   ---------------------------------------------------------------------
   declare
      --  Construct Pa, Pb from known kappa, theta at a, b then recover
      Kappa : constant Float := 1_000.0;
      Theta : constant Float := 1.2;
      A     : constant Float := 2_000.0;
      B     : constant Float := 5_000.0;
      Fa, Fb : Eval_Result;
      P      : Parameters;
      M      : Eval_Result;
   begin
      Fa := CDF (A, Kappa, Theta);
      Fb := CDF (B, Kappa, Theta);
      Check (Fa.Success and Fb.Success, "synthetic CDF ok");

      P := Fit_From_Cumulative (A, B, Fa.Value, Fb.Value);
      Check (P.Success, "Fit_From_Cumulative success");
      Check (Rel_Near (P.Theta, Theta, 5.0E-3), "recover theta");
      Check (Rel_Near (P.Kappa, Kappa, 5.0E-3), "recover kappa");

      M := Median (P);
      Check (M.Success
             and Rel_Near (M.Value, Kappa * Math.Exp ((1.0 / Theta)
                            * Math.Log (2.0)), 5.0E-3),
             "fitted median matches true");
   end;

   ---------------------------------------------------------------------
   Section ("7. Interpolate_Median wiki narrative");
   ---------------------------------------------------------------------
   declare
      C : constant Cumulative_Pair := Make_Wiki_Cumulative;
      R : Eval_Result;
      P : Parameters;
      Manual_Theta : Float;
      Manual_Kappa : Float;
      Manual_Med   : Float;
      Diff_P, Denom : Float;
   begin
      Check (C.Valid, "Make_Wiki_Cumulative Valid");
      P := Fit_From_Cumulative (C);
      Check (P.Success, "wiki fit success");

      Manual_Theta :=
        (Math.Log (1.0 - 0.45) - Math.Log (1.0 - 0.55))
        / (Math.Log (40_000.0) - Math.Log (35_000.0));
      Check (Approx (P.Theta, Manual_Theta, 1.0E-4),
             "wiki theta matches hand formula");

      Diff_P := 0.55 - 0.45;
      Denom  := Math.Exp (-Manual_Theta * Math.Log (35_000.0))
              - Math.Exp (-Manual_Theta * Math.Log (40_000.0));
      Manual_Kappa :=
        Math.Exp ((1.0 / Manual_Theta) * Math.Log (Diff_P / Denom));
      Check (Rel_Near (P.Kappa, Manual_Kappa, 1.0E-3),
             "wiki kappa matches hand formula");

      Manual_Med :=
        Manual_Kappa * Math.Exp ((1.0 / Manual_Theta) * Math.Log (2.0));
      R := Interpolate_Median (C);
      Check (R.Success and Rel_Near (R.Value, Manual_Med, 1.0E-3),
             "Interpolate_Median matches hand median");

      R := Interpolate_Median (35_000.0, 40_000.0, 0.45, 0.55);
      Check (R.Success and Rel_Near (R.Value, Manual_Med, 1.0E-3),
             "Interpolate_Median positional");
   end;

   ---------------------------------------------------------------------
   Section ("8. Reject bad params / empty samples");
   ---------------------------------------------------------------------
   declare
      P : Parameters;
      R : Eval_Result;
      Empty : Observations (1 .. 0);
      Bad   : constant Observations := [-1.0, 2.0, 3.0];
      Flat  : constant Observations := [5.0, 5.0, 5.0];
      S     : Sample;
   begin
      P := Fit_From_Cumulative (10.0, 20.0, 0.9, 0.2);
      Check (not P.Success and P.Stat = Invalid_Proportions,
             "fit rejects Pa>Pb");

      P := Fit_From_Sample (Empty);
      Check (not P.Success and P.Stat = Empty_Sample,
             "fit empty sample");

      P := Fit_From_Sample (Bad);
      Check (not P.Success and P.Stat = Bad_Parameters,
             "fit negative obs");

      P := Fit_From_Sample (Flat);
      Check (not P.Success and P.Stat = Bad_Parameters,
             "fit all-equal obs");

      S.Valid := False;
      S.Count := 0;
      P := Fit_From_Sample (S);
      Check (not P.Success and P.Stat = Empty_Sample,
             "fit invalid Sample");

      R := Quantile (0.0, 1.0, 1.0);
      Check (not R.Success and R.Stat = Invalid_Proportions,
             "Quantile p=0");
      R := Quantile (1.0, 1.0, 1.0);
      Check (not R.Success and R.Stat = Invalid_Proportions,
             "Quantile p=1");
      R := Quantile (0.5, 0.0, 1.0);
      Check (not R.Success and R.Stat = Bad_Parameters,
             "Quantile bad kappa");

      R := CDF (1.0, 1.0, -2.0);
      Check (not R.Success and R.Stat = Bad_Parameters, "CDF bad theta");

      R := Interpolate_In_Class (10.0, 5.0, 0.1, 0.2, 0.15);
      Check (not R.Success, "In_Class a>=b fails");
   end;

   ---------------------------------------------------------------------
   Section ("9. Sample MLE fit sanity");
   ---------------------------------------------------------------------
   declare
      True_K : constant Float := 3.0;
      True_T : constant Float := 2.5;
      S : constant Sample :=
        Make_Pareto_Sample (200, True_K, True_T, Seed => 42);
      P : Parameters;
      M_True, M_Fit : Eval_Result;
   begin
      Check (S.Valid and S.Count = 200, "synthetic sample size");
      P := Fit_From_Sample (S);
      Check (P.Success, "MLE fit success");
      --  κ̂ = min → slightly above true κ with high prob; allow slack
      Check (P.Kappa >= True_K - 1.0E-3, "MLE kappa >= true");
      Check (Rel_Near (P.Kappa, True_K, 0.15), "MLE kappa near true");
      Check (Rel_Near (P.Theta, True_T, 0.25), "MLE theta near true");

      M_True := Median (True_K, True_T);
      M_Fit  := Median (P);
      Check (M_True.Success and M_Fit.Success
             and Rel_Near (M_Fit.Value, M_True.Value, 0.25),
             "MLE median sanity");

      --  Make_Sample round-trip
      declare
         Obs : constant Observations := [1.5, 2.0, 4.0, 8.0];
         S2  : constant Sample := Make_Sample (Obs);
         P2  : Parameters;
      begin
         Check (S2.Valid and S2.Count = 4, "Make_Sample count");
         P2 := Fit_From_Sample (S2);
         Check (P2.Success and Approx (P2.Kappa, 1.5, 1.0E-5),
                "MLE kappa = min");
         Check (P2.Theta > 0.0, "MLE theta positive");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Parameters overloads / Make_Example");
   ---------------------------------------------------------------------
   declare
      P : Parameters;
      R : Eval_Result;
   begin
      P := Make_Example (Unit_Pareto);
      Check (P.Success and Approx (P.Kappa, 1.0) and Approx (P.Theta, 1.0),
             "Unit_Pareto example");
      R := PDF (2.0, P);
      Check (R.Success and Approx (R.Value, 0.25, 1.0E-4),
             "PDF via Parameters (unit: 1/x^2 at 2)");
      R := CDF (2.0, P);
      Check (R.Success and Approx (R.Value, 0.5, 1.0E-4),
             "CDF via Parameters");
      R := Quantile (0.5, P);
      Check (R.Success and Approx (R.Value, 2.0, 1.0E-4),
             "Quantile via Parameters");
      R := Median (P);
      Check (R.Success and Approx (R.Value, 2.0, 1.0E-4),
             "Median via Parameters");
      R := Interpolate_Median (P);
      Check (R.Success and Approx (R.Value, 2.0, 1.0E-4),
             "Interpolate_Median(P) rename");

      P := Make_Example (Thin_Tail);
      Check (P.Success and Approx (P.Kappa, 10.0) and Approx (P.Theta, 3.0),
             "Thin_Tail example");
      P := Make_Example (Heavy_Tail);
      Check (P.Success and Approx (P.Theta, 0.5), "Heavy_Tail example");
      P := Make_Example (Wiki_Income_Example);
      Check (P.Success and P.Kappa > 0.0 and P.Theta > 0.0,
             "Wiki_Income_Example fit");
   end;

   ---------------------------------------------------------------------
   Section ("11. Class interpolation helper");
   ---------------------------------------------------------------------
   declare
      --  Known params → class bounds → interpolate median Prob=0.5
      Kappa : constant Float := 100.0;
      Theta : constant Float := 1.5;
      Lo    : constant Float := 150.0;
      Hi    : constant Float := 300.0;
      P_Lo, P_Hi : Eval_Result;
      R     : Eval_Result;
      True_Med : Eval_Result;
   begin
      P_Lo := CDF (Lo, Kappa, Theta);
      P_Hi := CDF (Hi, Kappa, Theta);
      Check (P_Lo.Success and P_Hi.Success, "class CDF bounds");

      R := Interpolate_In_Class
        (Lo, Hi, P_Lo.Value, P_Hi.Value, 0.5);
      True_Med := Median (Kappa, Theta);
      Check (R.Success and True_Med.Success
             and Rel_Near (R.Value, True_Med.Value, 5.0E-3),
             "In_Class recovers median");

      R := Interpolate_Quantile (0.25, Lo, Hi, P_Lo.Value, P_Hi.Value);
      declare
         Q25 : constant Eval_Result := Quantile (0.25, Kappa, Theta);
      begin
         Check (R.Success and Q25.Success
                and Rel_Near (R.Value, Q25.Value, 5.0E-3),
                "Interpolate_Quantile recovers Q(0.25)");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Failed Parameters forwarding");
   ---------------------------------------------------------------------
   declare
      Bad : constant Parameters :=
        (Kappa => 0.0, Theta => 0.0, Stat => Bad_Parameters,
         Success => False);
      R : Eval_Result;
   begin
      R := PDF (1.0, Bad);
      Check (not R.Success and R.Stat = Bad_Parameters,
             "PDF forwards Bad_Parameters");
      R := CDF (1.0, Bad);
      Check (not R.Success and R.Stat = Bad_Parameters,
             "CDF forwards Bad_Parameters");
      R := Quantile (0.5, Bad);
      Check (not R.Success and R.Stat = Bad_Parameters,
             "Quantile forwards Bad_Parameters");
      R := Median (Bad);
      Check (not R.Success and R.Stat = Bad_Parameters,
             "Median forwards Bad_Parameters");
   end;

   ---------------------------------------------------------------------
   Section ("13. Slice / Cumulative_Pair Valid flag");
   ---------------------------------------------------------------------
   declare
      Obs : constant Observations := [2.0, 3.0, 5.0];
      S   : constant Sample := Make_Sample (Obs);
      Sl  : constant Observations := Slice (S);
      C_Ok  : constant Cumulative_Pair :=
        Make_Cumulative (1.0, 2.0, 0.2, 0.4);
      C_Bad : constant Cumulative_Pair :=
        Make_Cumulative (2.0, 1.0, 0.2, 0.4);
   begin
      Check (Sl'Length = 3 and Approx (Sl (Sl'First), 2.0), "Slice ok");
      Check (C_Ok.Valid, "Valid cumulative");
      Check (not C_Bad.Valid, "Invalid cumulative Valid=False");
   end;

   ---------------------------------------------------------------------
   Section ("14. Extra CDF/PDF/Quantile grid");
   ---------------------------------------------------------------------
   declare
      Ok_All : Boolean := True;
      Kappa  : constant Float := 7.0;
      Theta  : constant Float := 0.8;
      R, Q   : Eval_Result;
   begin
      for K in 1 .. 9 loop
         declare
            P : constant Float := 0.1 * Float (K);
         begin
            Q := Quantile (P, Kappa, Theta);
            R := CDF (Q.Value, Kappa, Theta);
            if not (Q.Success and R.Success
                    and Approx (R.Value, P, 5.0E-4))
            then
               Ok_All := False;
            end if;
         end;
      end loop;
      Check (Ok_All, "9-point quantile-CDF roundtrip");

      --  PDF ≈ finite-difference of CDF at interior points
      declare
         K2 : constant Float := 1.0;
         T2 : constant Float := 2.0;
         H  : constant Float := 1.0E-3;
         Xs : constant array (1 .. 4) of Float :=
           [1.5, 2.0, 4.0, 10.0];
         Ok_Fd : Boolean := True;
         Fl, Fr, Fd : Eval_Result;
         Deriv : Float;
      begin
         for I in Xs'Range loop
            Fl := CDF (Xs (I) - H, K2, T2);
            Fr := CDF (Xs (I) + H, K2, T2);
            Fd := PDF (Xs (I), K2, T2);
            if not (Fl.Success and Fr.Success and Fd.Success) then
               Ok_Fd := False;
            else
               Deriv := (Fr.Value - Fl.Value) / (2.0 * H);
               if not Rel_Near (Deriv, Fd.Value, 2.0E-2) then
                  Ok_Fd := False;
               end if;
            end if;
         end loop;
         Check (Ok_Fd, "PDF ≈ dCDF/dx finite difference");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("15. Status enumeration smoke");
   ---------------------------------------------------------------------
   declare
      --  Touch each status via intentional failures / success
      P : Parameters;
   begin
      P := Fit_From_Cumulative (1.0, 2.0, 0.1, 0.2);
      Check (P.Stat = Ok, "Status Ok");
      P := Fit_From_Sample (Observations'(1 .. 0 => <>));
      Check (P.Stat = Empty_Sample, "Status Empty_Sample");
      Check (Validate_Parameters (0.0, 1.0) = Bad_Parameters,
             "Status Bad_Parameters");
      Check (Validate_Cumulative (1.0, 2.0, 0.5, 0.5) =
             Invalid_Proportions,
             "Status Invalid_Proportions");
      declare
         --  Length Max_Samples+1 triggers Dimension_Error in Fit_From_Sample
         Big : Observations (1 .. Max_Samples + 1);
         Q   : Parameters;
      begin
         for I in Big'Range loop
            Big (I) := Float (I);
         end loop;
         Q := Fit_From_Sample (Big);
         Check (Q.Stat = Dimension_Error, "Status Dimension_Error");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("16. Survival / identity checks");
   ---------------------------------------------------------------------
   declare
      Kappa : constant Float := 4.0;
      Theta : constant Float := 1.25;
      Ok_Id : Boolean := True;
      R     : Eval_Result;
      Surv  : Float;
      Xs    : constant array (1 .. 5) of Float :=
        [4.0, 5.0, 8.0, 16.0, 40.0];
   begin
      for I in Xs'Range loop
         R := CDF (Xs (I), Kappa, Theta);
         if not R.Success then
            Ok_Id := False;
         else
            Surv := Math.Exp (Theta * (Math.Log (Kappa) - Math.Log (Xs (I))));
            if not Approx (1.0 - R.Value, Surv, 1.0E-4) then
               Ok_Id := False;
            end if;
         end if;
      end loop;
      Check (Ok_Id, "1-CDF = (kappa/x)^theta on grid");

      --  Quantile at tiny / near-one probs
      R := Quantile (1.0E-4, Kappa, Theta);
      Check (R.Success and R.Value >= Kappa, "Q(1e-4) >= kappa");
      R := Quantile (1.0 - 1.0E-4, Kappa, Theta);
      Check (R.Success and R.Value > Kappa, "Q(1-1e-4) > kappa");
   end;

   ---------------------------------------------------------------------
   Section ("17. More cumulative / builder edge cases");
   ---------------------------------------------------------------------
   declare
      C : Cumulative_Pair;
      P : Parameters;
      R : Eval_Result;
      S : Sample;
   begin
      C := Make_Cumulative (100.0, 200.0, 0.3, 0.7);
      Check (C.Valid, "Make_Cumulative mid Valid");
      P := Fit_From_Cumulative (C);
      Check (P.Success and P.Theta > 0.0, "fit mid cumulative");

      R := Interpolate_Quantile (0.5, 100.0, 200.0, 0.3, 0.7);
      Check (R.Success and R.Value > 0.0, "Interpolate_Quantile mid");

      --  Seeded samples differ by seed
      declare
         S1 : constant Sample :=
           Make_Pareto_Sample (30, 2.0, 1.5, Seed => 1);
         S2 : constant Sample :=
           Make_Pareto_Sample (30, 2.0, 1.5, Seed => 99);
         Diff : Boolean := False;
      begin
         Check (S1.Valid and S2.Valid, "two seeds valid");
         for I in 0 .. 29 loop
            if not Near (S1.X (I), S2.X (I)) then
               Diff := True;
            end if;
         end loop;
         Check (Diff, "different seeds differ");
      end;

      S := Make_Pareto_Sample (5, 1.0, 1.0, Seed => 0);
      Check (S.Valid and S.Count = 5, "seed 0 still valid");

      --  Parameters Median rename path already covered; CDF at large x → 1
      R := CDF (1.0E6, 1.0, 2.0);
      Check (R.Success and R.Value > 0.999, "CDF large x near 1");

      R := PDF (1.0E6, 1.0, 2.0);
      Check (R.Success and R.Value < 1.0E-10, "PDF large x tiny");

      --  Ill_Started default on fresh Eval_Result
      declare
         E : Eval_Result;
      begin
         Check (E.Stat = Ill_Started and not E.Success,
                "Eval_Result default Ill_Started");
      end;

      declare
         Par : Parameters;
      begin
         Check (Par.Stat = Ill_Started and not Par.Success,
                "Parameters default Ill_Started");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("18. Theta recovery sensitivity");
   ---------------------------------------------------------------------
   declare
      Ok_T : Boolean := True;
      Thetas : constant array (1 .. 4) of Float :=
        [0.75, 1.0, 2.0, 4.0];
   begin
      for I in Thetas'Range loop
         declare
            K : constant Float := 50.0;
            T : constant Float := Thetas (I);
            A : constant Float := 80.0;
            B : constant Float := 120.0;
            Fa : constant Eval_Result := CDF (A, K, T);
            Fb : constant Eval_Result := CDF (B, K, T);
            P  : Parameters;
         begin
            P := Fit_From_Cumulative (A, B, Fa.Value, Fb.Value);
            if not (P.Success and Rel_Near (P.Theta, T, 1.0E-2)
                    and Rel_Near (P.Kappa, K, 1.0E-2))
            then
               Ok_T := False;
            end if;
         end;
      end loop;
      Check (Ok_T, "recover 4 theta values from cumulative");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("----------------------------------------");
   Ada.Text_IO.Put_Line
     ("Passed:" & Natural'Image (Pass_Count)
      & "  Failed:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
