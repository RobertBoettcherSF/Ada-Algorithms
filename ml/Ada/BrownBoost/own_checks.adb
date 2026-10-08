--  Own checks (see tests/SOURCES.txt). Assume Brown_Boost is wrong or does
--  nothing. Every trained model is replayed round by round against Freund's
--  definition of BrownBoost (Machine Learning 43, 2001), computed here:
--  * weights w_i proportional to exp (-(r_i + s)**2 / c) from the replayed
--    margins r_i and remaining time s (s starts at c);
--  * the round's stump must reach the best weighted advantage
--    sum w_i h (x_i) y_i over every feature, threshold (a training value)
--    and direction (brute force), and that advantage must exceed 0.0001;
--  * the step (alpha, t) must satisfy both equations: potential conservation
--    sum Phi (r_i + alpha z_i + s - t) = sum Phi (r_i + s) with
--    Phi (z) = 1 - erf (z / sqrt c) (own erf: Taylor series / continued
--    fraction, not the code's A&S 7.1.26), solved here for t, and
--    orthogonality sum z_i exp (-(r_i + alpha z_i + s - t)**2 / c) = 0;
--  * training stops only when s <= 0.0001, the best advantage is <= 0.0001,
--    or the capacity is full;
--  * Predict = sign of sum alpha_j h_j (x) (0 counts as positive), and the
--    empty model predicts negative;
--  * Labels with a different index origin than the feature rows give the
--    same model.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Long_Elementary_Functions; use Ada.Numerics.Long_Elementary_Functions;
with Brown_Boost; use Brown_Boost;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;
   Rounds   : Natural := 0;
   Solved   : Natural := 0;
   --  per variant: rounds whose step conserves the potential at an inner t
   --  (the named solver's own result), and end-of-range rounds
   Inner_By : array (Solver_Variant) of Natural := [others => 0];
   Ends_By  : array (Solver_Variant) of Natural := [others => 0];

   procedure Expect (Cond : Boolean; What : String) is
   begin
      Checked := Checked + 1;
      if not Cond then
         Failures := Failures + 1;
         if Failures <= 25 then
            Put_Line ("  FAIL own: " & What);
         end if;
      end if;
   end Expect;

   type U32 is mod 2 ** 32;
   --  test-data seed: fixed default, printed, overridable with AA_SEED
   Default_Seed : constant U32 := 777;
   function Seed_From_Env return U32 is
      S : U32 := Default_Seed;
   begin
      if Ada.Environment_Variables.Exists ("AA_SEED") then
         S := U32'Value (Ada.Environment_Variables.Value ("AA_SEED"));
      end if;
      Ada.Text_IO.Put_Line ("own checks seed:" & S'Image & " (default" & Default_Seed'Image
                            & "; set AA_SEED to override)");
      return S;
   end Seed_From_Env;
   Lcg : U32 := Seed_From_Env;
   function Rand (M : Positive) return Natural is
   begin
      Lcg := Lcg * 1664525 + 1013904223;
      return Natural ((Lcg / 256) mod U32 (M));
   end Rand;

   --  erf: Taylor series for |x| <= 2.5, continued fraction for erfc beyond
   function Ref_Erf (X : Long_Float) return Long_Float is
      A : constant Long_Float := abs X;
      R : Long_Float;
   begin
      if A <= 2.5 then
         declare
            Term : Long_Float := A;
            Sum  : Long_Float := A;
         begin
            for N in 1 .. 120 loop
               Term := -Term * A * A / Long_Float (N);
               Sum := Sum + Term / Long_Float (2 * N + 1);
               exit when abs (Term) < 1.0E-18;
            end loop;
            R := 2.0 / Sqrt (Ada.Numerics.Pi) * Sum;
         end;
      else
         declare
            F : Long_Float := A;
         begin
            for K in reverse 1 .. 80 loop
               F := A + (Long_Float (K) / 2.0) / F;
            end loop;
            R := 1.0 - Exp (-A * A) / Sqrt (Ada.Numerics.Pi) / F;
         end;
      end if;
      return (if X < 0.0 then -R else R);
   end Ref_Erf;

   function Phi (Z, C : Long_Float) return Long_Float is (1.0 - Ref_Erf (Z / Sqrt (C)));

   Max_M : constant := 40;
   Max_F : constant := 3;

   procedure Check_Data (X : Feature_Matrix; Y : Label_Array; C : Long_Float; Cap : Positive;
                         Variant : Solver_Variant; What : String) is
      M     : constant Ensemble_Model := Train (X, Y, Value_Type (C), Variant, Cap);
      R     : array (X'Range (1)) of Long_Float := [others => 0.0];
      S     : Long_Float := C;
      Yv    : array (X'Range (1)) of Long_Float;
      Stop  : Boolean := False;

      function H (St : Decision_Stump; I : Integer) return Long_Float is
        (if Long_Float (X (I, St.Feature)) * Long_Float (St.Direction)
            >= Long_Float (St.Threshold) * Long_Float (St.Direction) then 1.0 else -1.0);

      --  best normalized advantage at the current r, s; and advantage of St
      procedure Advantages (St : Decision_Stump; Best, Of_St : out Long_Float) is
         W   : array (X'Range (1)) of Long_Float;
         Sum : Long_Float := 0.0;
         Mx  : Long_Float := Long_Float'First;
         function Adv (F : Integer; T, D : Long_Float) return Long_Float is
            A : Long_Float := 0.0;
         begin
            for I in X'Range (1) loop
               A := A + W (I) * (if Long_Float (X (I, F)) * D >= T * D then 1.0 else -1.0) * Yv (I);
            end loop;
            return A;
         end Adv;
      begin
         for I in X'Range (1) loop
            Mx := Long_Float'Max (Mx, -((R (I) + S) ** 2) / C);
         end loop;
         for I in X'Range (1) loop
            W (I) := Exp (-((R (I) + S) ** 2) / C - Mx);
            Sum := Sum + W (I);
         end loop;
         for I in X'Range (1) loop
            W (I) := W (I) / Sum;
         end loop;
         Best := -2.0;
         for F in X'Range (2) loop
            for I in X'Range (1) loop
               for D in 1 .. 2 loop
                  Best := Long_Float'Max (Best, Adv (F, Long_Float (X (I, F)), (if D = 1 then 1.0 else -1.0)));
               end loop;
            end loop;
         end loop;
         Of_St := Adv (St.Feature, Long_Float (St.Threshold), Long_Float (St.Direction));
      end Advantages;
   begin
      for I in X'Range (1) loop
         Yv (I) := (if Y (Y'First + (I - X'First (1))) = Label_Positive then 1.0 else -1.0);
      end loop;
      Expect (M.Size <= Cap, What & " size within capacity");
      for K in 1 .. M.Size loop
         exit when Stop;
         declare
            St     : constant Decision_Stump := M.Models (K).Stump;
            Alpha  : constant Long_Float := Long_Float (M.Models (K).Alpha);
            Best, Of_St : Long_Float;
            Z      : array (X'Range (1)) of Long_Float;
            Perfect : Boolean := True;
         begin
            Rounds := Rounds + 1;
            Expect (St.Feature in X'Range (2) and then (St.Direction = 1.0 or else St.Direction = -1.0),
                    What & " stump fields, round" & K'Image);
            exit when St.Feature not in X'Range (2);
            Advantages (St, Best, Of_St);
            Expect (S > 0.0001 - 1.0E-9, What & " a round was trained after the time ran out, round" & K'Image);
            Expect (Best > 0.0001, What & " a round was trained without a positive advantage, round" & K'Image);
            --  1e-5: the replayed remaining time s follows the code's only to
            --  the accuracy of its erf (A&S 7.1.26, error up to 1.5e-7), and
            --  more loosely for large c, where Phi is flat and t sensitive
            --  (seen: 1.2e-6 at c = 8); that can reorder near-ties
            Expect (Of_St >= Best - 1.0E-5, What & " stump is not the best weighted stump, round" & K'Image
                    & " adv" & Of_St'Image & " best" & Best'Image);
            Expect (Alpha >= 0.0, What & " alpha >= 0, round" & K'Image);
            for I in X'Range (1) loop
               Z (I) := H (St, I) * Yv (I);
               Perfect := Perfect and then Z (I) = 1.0;
            end loop;
            if Perfect then
               --  no mistakes under any weights: the equations have no finite
               --  solution (alpha -> infinity); stop replaying here
               Stop := True;
            else
               declare
                  V0     : Long_Float := 0.0;
                  Lo, Hi : Long_Float;
                  function V (U : Long_Float) return Long_Float is
                     Sum : Long_Float := 0.0;
                  begin
                     for I in X'Range (1) loop
                        Sum := Sum + Phi (R (I) + Alpha * Z (I) + U, C);
                     end loop;
                     return Sum - V0;
                  end V;
                  U, F1, Scale, T : Long_Float;
               begin
                  for I in X'Range (1) loop
                     V0 := V0 + Phi (R (I) + S, C);
                  end loop;
                  --  V is decreasing in U; potential conservation picks U in [0, s]
                  Lo := 0.0;
                  Hi := S;
                  if V (Lo) >= 0.0 and then V (Hi) <= 0.0 then
                     for It in 1 .. 200 loop
                        U := (Lo + Hi) / 2.0;
                        if V (U) > 0.0 then
                           Lo := U;
                        else
                           Hi := U;
                        end if;
                     end loop;
                     U := (Lo + Hi) / 2.0;
                     F1 := 0.0;
                     Scale := 0.0;
                     for I in X'Range (1) loop
                        F1 := F1 + Z (I) * Exp (-((R (I) + Alpha * Z (I) + U) ** 2) / C);
                        Scale := Scale + Exp (-((R (I) + Alpha * Z (I) + U) ** 2) / C);
                     end loop;
                     Solved := Solved + 1;
                     Inner_By (Variant) := Inner_By (Variant) + 1;
                     Expect (abs F1 <= 1.0E-3 * Scale + 1.0E-9,
                             What & " orthogonality fails at the potential-conserving t, round" & K'Image
                             & " residual" & F1'Image & " scale" & Scale'Image & " alpha" & Alpha'Image);
                  else
                     --  no t in [0, s] conserves the potential for this alpha.
                     --  Then the step must sit at the end of the time range
                     --  that comes closest: U = 0 (t = s, the time runs out;
                     --  only as the last round) when the potential is too low
                     --  everywhere, U = s (t = 0, the 0.0001 minimum) when it
                     --  is too high everywhere; and alpha must be the
                     --  orthogonality root at that U (own doubling + bisection).
                     declare
                        --  which end: the sign of the potential difference at
                        --  U = 0 with alpha (0), the orthogonality root there
                        --  (own doubling + bisection; past 1000 the limit), not
                        --  with the code's alpha
                        function Own_At_Zero return Boolean is
                           function G (A : Long_Float) return Long_Float is
                              Sum : Long_Float := 0.0;
                           begin
                              for I in X'Range (1) loop
                                 Sum := Sum + Z (I) * Exp (-((R (I) + A * Z (I)) ** 2) / C);
                              end loop;
                              return Sum;
                           end G;
                           Lo_A : Long_Float := 0.0;
                           Hi_A : Long_Float := 1.0;
                           A0, P : Long_Float := 0.0;
                        begin
                           if G (0.0) > 0.0 then
                              while G (Hi_A) > 0.0 and then Hi_A <= 1000.0 loop
                                 Hi_A := Hi_A * 2.0;
                              end loop;
                              for It in 1 .. 200 loop
                                 exit when Hi_A > 1000.0;
                                 if G ((Lo_A + Hi_A) / 2.0) > 0.0 then
                                    Lo_A := (Lo_A + Hi_A) / 2.0;
                                 else
                                    Hi_A := (Lo_A + Hi_A) / 2.0;
                                 end if;
                              end loop;
                              A0 := (Lo_A + Hi_A) / 2.0;
                           end if;
                           for I in X'Range (1) loop
                              P := P + Phi (R (I) + A0 * Z (I), C);
                           end loop;
                           return P - V0 < 0.0;
                        end Own_At_Zero;
                        At_Zero : constant Boolean := Own_At_Zero;
                        A_Own   : Long_Float;
                        Ran_Out   : Boolean := False;   --  doubling passed 1000
                        Unbounded : Boolean := False;
                        function F1_At (A : Long_Float) return Long_Float is
                           Sum : Long_Float := 0.0;
                        begin
                           for I in X'Range (1) loop
                              Sum := Sum + Z (I) * Exp (-((R (I) + A * Z (I) + (if At_Zero then 0.0 else S)) ** 2) / C);
                           end loop;
                           return Sum;
                        end F1_At;
                        A_Lo : Long_Float := 0.0;
                        A_Hi : Long_Float := 1.0;
                     begin
                        if F1_At (0.0) <= 0.0 then
                           A_Own := 0.0;
                        else
                           while F1_At (A_Hi) > 0.0 loop
                              A_Hi := A_Hi * 2.0;
                              if A_Hi > 1000.0 then
                                 Ran_Out := True;
                                 exit;
                              end if;
                           end loop;
                           for It in 1 .. 200 loop
                              exit when Ran_Out;
                              if F1_At ((A_Lo + A_Hi) / 2.0) > 0.0 then
                                 A_Lo := (A_Lo + A_Hi) / 2.0;
                              else
                                 A_Hi := (A_Lo + A_Hi) / 2.0;
                              end if;
                           end loop;
                           A_Own := (A_Lo + A_Hi) / 2.0;
                        end if;
                        declare
                           U_End : constant Long_Float := (if At_Zero then 0.0 else S);
                           Res, Sc : Long_Float := 0.0;
                        begin
                           for I in X'Range (1) loop
                              Res := Res + Z (I) * Exp (-((R (I) + Alpha * Z (I) + U_End) ** 2) / C);
                              Sc := Sc + Exp (-((R (I) + Alpha * Z (I) + U_End) ** 2) / C);
                           end loop;
                           --  orthogonality at the end point, relative to the sum of
                           --  its factors. Exception: the equation has no finite
                           --  root. That needs F1 > 0 at alpha = 0 and for large
                           --  alpha (the slowest-decaying factors, smallest
                           --  z_i (r_i + U), belong to more correct than wrong
                           --  examples), and the own search to find no genuine
                           --  root (its sign change only where every factor has
                           --  underflowed). Then any alpha with F1 >= 0 is as good
                           --  as a solver can do.
                           declare
                              Min_Lin : Long_Float := Long_Float'Last;
                              Lead    : Long_Float := 0.0;
                              Sc_Own  : Long_Float := 0.0;
                              Genuine : Boolean;
                           begin
                              for I in X'Range (1) loop
                                 Sc_Own := Sc_Own + Exp (-((R (I) + A_Own * Z (I) + U_End) ** 2) / C);
                              end loop;
                              Genuine := not Ran_Out and then Sc_Own > 0.0
                                and then abs F1_At (A_Own) <= 1.0E-3 * Sc_Own;
                              for I in X'Range (1) loop
                                 Min_Lin := Long_Float'Min (Min_Lin, Z (I) * (R (I) + U_End));
                              end loop;
                              for I in X'Range (1) loop
                                 if Z (I) * (R (I) + U_End) <= Min_Lin + 1.0E-12 then
                                    Lead := Lead + Z (I);
                                 end if;
                              end loop;
                              if not Genuine and then Lead > 0.0 and then F1_At (0.0) > 0.0 and then Res >= 0.0 then
                                 Unbounded := True;
                              end if;
                           end;
                           Expect (abs Res <= 1.0E-3 * Sc + 1.0E-300 or else Unbounded,
                                   What & " end-of-range step: alpha" & Alpha'Image & " is not an orthogonality root at U = "
                                   & (if At_Zero then "0" else "s") & " (own root" & A_Own'Image & "), round" & K'Image);
                        end;
                        Ends_By (Variant) := Ends_By (Variant) + 1;
                        if At_Zero then
                           U := 0.0;
                           Expect (K = M.Size, What & " potential too low for every t, but training went on, round"
                                   & K'Image & " alpha" & Alpha'Image & " s" & S'Image);
                           Stop := True;
                        else
                           U := S;
                        end if;
                     end;
                  end if;
                  T := S - U;
                  if T < 0.0001 then
                     T := 0.0001;
                  end if;
                  for I in X'Range (1) loop
                     R (I) := R (I) + Alpha * Z (I);
                  end loop;
                  S := S - T;
               end;
            end if;
         end;
      end loop;
      --  termination: time up, no advantage left, or capacity full
      if not Stop and then M.Size < Cap then
         declare
            Best, Of_St : Long_Float;
         begin
            Advantages ((Feature => X'First (2), Threshold => 0.0, Direction => 1.0), Best, Of_St);
            Expect (S <= 0.0001 + 1.0E-6 or else Best <= 0.0001 + 1.0E-9,
                    What & " training stopped early: s =" & S'Image & " best advantage" & Best'Image);
         end;
      end if;
      --  Predict = sign of the weighted vote
      for Trial in 1 .. 20 loop
         declare
            V   : Feature_Vector (X'Range (2));
            Sum : Long_Float := 0.0;
         begin
            for F in V'Range loop
               V (F) := Value_Type (Rand (9)) - 4.0 + (if Trial mod 2 = 0 then 0.5 else 0.0);
            end loop;
            if Trial = 1 then
               V := [for F in V'Range => X (X'First (1), F)];
            end if;
            for J in 1 .. M.Size loop
               Sum := Sum + Long_Float (M.Models (J).Alpha)
                 * (if Long_Float (V (M.Models (J).Stump.Feature)) * Long_Float (M.Models (J).Stump.Direction)
                       >= Long_Float (M.Models (J).Stump.Threshold) * Long_Float (M.Models (J).Stump.Direction)
                    then 1.0 else -1.0);
            end loop;
            Expect (Predict (M, V) = (if M.Size > 0 and then Sum >= 0.0 then Label_Positive else Label_Negative),
                    What & " Predict = sign of the weighted vote");
         end;
      end loop;
   end Check_Data;

begin
   --  trials 1 .. 300: small sets; 301 .. 380: up to 40 rows, wider c range
   --  (kept short: the whole run must stay well inside the 30 s mutation
   --  timeout on a loaded machine)
   for Trial in 1 .. 380 loop
      declare
         NM  : constant Positive := (if Trial <= 300 then 4 + Rand (9) else 13 + Rand (Max_M - 12));
         NF  : constant Positive := 1 + Rand (Max_F);
         X   : Feature_Matrix (1 .. NM, 1 .. NF);
         Y   : Label_Array (1 .. NM);
         Fs  : constant Positive := 1 + Rand (NF);
         Th  : constant Integer := Rand (5) - 2;
         Cs  : constant array (0 .. 3) of Long_Float := [0.5, 1.0, 2.0, 3.0];
         Cw  : constant array (0 .. 3) of Long_Float := [0.25, 0.5, 4.0, 8.0];
         C   : constant Long_Float := (if Trial <= 300 then Cs (Rand (4)) else Cw (Rand (4)));
         Cap : constant Positive := 1 + Rand (15);
      begin
         for I in X'Range (1) loop
            for F in X'Range (2) loop
               X (I, F) := Value_Type (Rand (7)) - 3.0;
            end loop;
            Y (I) := (if X (I, Fs) >= Value_Type (Th) then Label_Positive else Label_Negative);
            if Rand (5) = 0 then   --  label noise
               Y (I) := (if Y (I) = Label_Positive then Label_Negative else Label_Positive);
            end if;
         end loop;
         for V in Solver_Variant loop
            Check_Data (X, Y, C, Cap, V, "trial" & Trial'Image & " " & V'Image & " m=" & NM'Image
                        & " c=" & C'Image);
         end loop;
         if Trial mod 10 = 0 then
            declare
               Y5 : Label_Array (5 .. 4 + NM);
            begin
               for I in Y'Range loop
                  Y5 (I + 4) := Y (I);
               end loop;
               declare
                  M1 : constant Ensemble_Model := Train (X, Y, Value_Type (C), Bisection_Solver, Cap);
                  M2 : constant Ensemble_Model := Train (X, Y5, Value_Type (C), Bisection_Solver, Cap);
               begin
                  Expect (M1 = M2, "labels with index origin 5 give the same model, trial" & Trial'Image);
               end;
            exception
               when Invalid_Data =>
                  Expect (False, "labels with index origin 5 rejected with Invalid_Data, trial" & Trial'Image);
            end;
         end if;
      end;
   end loop;
   declare
      Empty : constant Ensemble_Model :=
        (Capacity => 3, Size => 0,
         Models => [others => (Stump => (Feature => 1, Threshold => 0.0, Direction => 1.0), Alpha => 0.0)]);
   begin
      Expect (Predict (Empty, [1 => 0.0]) = Label_Negative, "empty model predicts negative");
   end;
   --  Second round, visible half only. Two directions on one repeated
   --  feature value have the same advantage (both call the tied points
   --  positive). The search tries direction +1 first and keeps it on a
   --  tie, so a point below that value is negative.
   declare
      X : constant Feature_Matrix (1 .. 3, 1 .. 1) :=
        [1 => [1 => 1.0], 2 => [1 => 1.0], 3 => [1 => 1.0]];
      Y : constant Label_Array (1 .. 3) :=
        [Label_Positive, Label_Positive, Label_Negative];
      M : constant Ensemble_Model := Train (X, Y, 1.0, Newton_Solver, 1);
      Adv_Pos, Adv_Neg : Long_Float := 0.0;
   begin
      for I in 1 .. 3 loop
         declare
            Label_Sign : constant Long_Float :=
              (if Y (I) = Label_Positive then 1.0 else -1.0);
         begin
            --  Every training value equals the only threshold, so both
            --  directions predict +1 there. The advantage is the same.
            Adv_Pos := Adv_Pos + Label_Sign;
            Adv_Neg := Adv_Neg + Label_Sign;
         end;
      end loop;
      Expect (Adv_Pos = Adv_Neg and then Adv_Pos > 0.0,
              "both directions tie on the repeated feature");
      Expect (M.Size = 1, "the tie still produces one stump");
      Expect (M.Models (1).Stump.Direction = 1.0
              and then M.Models (1).Stump.Threshold = 1.0
              and then M.Models (1).Stump.Feature = 1,
              "a tie keeps the first direction, +1");
      Expect (Predict (M, [1 => 0.0]) = Label_Negative,
              "direction +1 calls a smaller point negative");
   end;

   --  A sum of exactly zero is positive. The two stumps cancel on x = 1;
   --  the test adds the contributions itself.
   declare
      M : constant Ensemble_Model :=
        (Capacity => 2, Size => 2,
         Models =>
           [1 => (Stump => (Feature => 1, Threshold => 0.0, Direction => 1.0),
                  Alpha => 1.0),
            2 => (Stump => (Feature => 1, Threshold => 0.0, Direction => -1.0),
                  Alpha => 1.0)]);
      X : constant Value_Type := 1.0;
      Sum : Long_Float := 0.0;
   begin
      for I in 1 .. 2 loop
         declare
            St : Decision_Stump renames M.Models (I).Stump;
            Pred : constant Long_Float :=
              (if Long_Float (X) * Long_Float (St.Direction)
                  >= Long_Float (St.Threshold) * Long_Float (St.Direction)
               then 1.0 else -1.0);
         begin
            Sum := Sum + Long_Float (M.Models (I).Alpha) * Pred;
         end;
      end loop;
      Expect (Sum = 0.0, "the two stumps cancel");
      Expect (Predict (M, [1 => X]) = Label_Positive, "a zero sum is positive");
   end;

   Expect (Rounds > 1_000 and then Solved > 500, "enough replayed rounds:" & Rounds'Image & Solved'Image);
   for V in Solver_Variant loop
      --  end-of-range steps are the exception (about 4% of rounds here)
      Expect (Inner_By (V) > 300 and then Ends_By (V) > 10 and then 10 * Ends_By (V) < Inner_By (V),
              V'Image & " inner / end-of-range rounds:" & Inner_By (V)'Image & Ends_By (V)'Image);
   end loop;
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Checked'Image & " (" & Rounds'Image & " rounds replayed against Freund's equations;"
             & " inner/end rounds bisection" & Inner_By (Bisection_Solver)'Image & Ends_By (Bisection_Solver)'Image
             & ", newton" & Inner_By (Newton_Solver)'Image & Ends_By (Newton_Solver)'Image & ")");
end Own_Checks;
