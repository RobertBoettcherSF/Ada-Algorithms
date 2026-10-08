--  Own checks (see tests/SOURCES.txt). Assume Adaboost is wrong. Every
--  model is replayed from Freund and Schapire's definition, computed here:
--  weights start at 1/n; each round takes the decision stump of least
--  weighted error over every feature, every training value as threshold
--  and both polarities (first one kept on a tie, same order as a scan);
--  alpha = (1/2) ln ((1-e)/e); weights multiply by exp(-alpha y h) and
--  are normalized. A round with error >= 1/2 is not taken.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Environment_Variables;
with Ada.Numerics.Elementary_Functions;
with Adaboost;
use type Adaboost.Class_Label, Adaboost.Feature_Index, Adaboost.Feature_Value, Adaboost.Sample_Index, Adaboost.Decision_Stump, Adaboost.Classifier_Weight;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Expect (Cond : Boolean; What : String) is
   begin
      Checked := Checked + 1;
      if not Cond then
         Failures := Failures + 1;
         if Failures <= 20 then
            Put_Line ("  FAIL own: " & What);
         end if;
      end if;
   end Expect;

   type U32 is mod 2 ** 32;
   Default_Seed : constant U32 := 20261008;
   function Seed_From_Env return U32 is
      S : U32 := Default_Seed;
   begin
      if Ada.Environment_Variables.Exists ("AA_SEED") then
         S := U32'Value (Ada.Environment_Variables.Value ("AA_SEED"));
      end if;
      Put_Line ("own checks seed:" & S'Image & " (default" & Default_Seed'Image
                & "; set AA_SEED to override)");
      return S;
   end Seed_From_Env;
   Lcg : U32 := Seed_From_Env;
   function Rand (M : Positive) return Natural is
   begin
      Lcg := Lcg * 1664525 + 1013904223;
      return Natural ((Lcg / 256) mod U32 (M));
   end Rand;

   procedure Replay (X : Adaboost.Features_Matrix; Y : Adaboost.Labels_Array; Cap : Positive; What : String) is
      M : Adaboost.AdaBoost_Model (Cap);
      N : constant Positive := X'Length (1);
      type W is array (1 .. N) of Float;
      function Row (P : Positive) return Adaboost.Sample_Index is
        (Adaboost.Sample_Index'Val (Adaboost.Sample_Index'Pos (X'First (1)) + (P - 1)));
      D : W := [others => 1.0 / Float (N)];
      type St is record
         Feat : Integer;
         Th   : Float;
         Pol  : Integer;
      end record;
      Rounds : Natural := 0;
   begin
      Adaboost.Train (M, X, Y);
      for Round in 1 .. Cap loop
         declare
            Best_E : Float := Float'Last;
            Best   : St := (0, 0.0, 1);
            function Yv (P : Positive) return Float is
              (if Y (Adaboost.Sample_Index'Val (Adaboost.Sample_Index'Pos (Y'First) + (P - 1))) = Adaboost.Positive then 1.0 else -1.0);
         begin
            for F in X'Range (2) loop
               for I in 1 .. N loop
                  declare
                     Th : constant Float := Float (X (Row (I), F));
                     function Err_Of (Pol : Integer) return Float is
                        E : Float := 0.0;
                        H : Float;
                     begin
                        for K in 1 .. N loop
                           H := Float (X (Row (K), F));
                           H := (if (Pol = 1 and then H > Th) or else (Pol = -1 and then H <= Th)
                                 then 1.0 else -1.0);
                           if H /= Yv (K) then
                              E := E + D (K);
                           end if;
                        end loop;
                        return E;
                     end Err_Of;
                  begin
                     for Pol in 1 .. 2 loop
                        declare
                           P : constant Integer := (if Pol = 1 then 1 else -1);
                           E : constant Float := Err_Of (P);
                        begin
                           if E < Best_E then
                              Best_E := E;
                              Best := (Integer (F), Th, P);
                           end if;
                        end;
                     end loop;
                  end;
               end loop;
            end loop;
            exit when Best_E >= 0.5 - 1.0e-5;
            Rounds := Rounds + 1;
            Expect (Rounds <= M.Count, What & " stopped before a stump with error below 1/2, round" & Round'Image);
            exit when Rounds > M.Count;
            Expect (M.Learners (Rounds).Feature = Adaboost.Feature_Index (Best.Feat)
                    and then Float (M.Learners (Rounds).Threshold) = Best.Th
                    and then M.Learners (Rounds).Polarity = Best.Pol,
                    What & " stump differs, round" & Round'Image);
            declare
               Eps   : constant Float := Float'Max (Best_E, 1.0e-10);
               Alpha : constant Float := 0.5 * Ada.Numerics.Elementary_Functions.Log ((1.0 - Eps) / Eps);
               Z     : Float := 0.0;
            begin
               Expect (abs (Float (M.Alphas (Rounds)) - Alpha) <= 1.0e-5 * Float'Max (1.0, abs Alpha),
                       What & " alpha, round" & Round'Image);
               exit when Best_E < 1.0e-10;
               for K in 1 .. N loop
                  declare
                     H  : constant Float := Float (X (Row (K), Adaboost.Feature_Index (Best.Feat)));
                     Hv : constant Float :=
                       (if (Best.Pol = 1 and then H > Best.Th) or else (Best.Pol = -1 and then H <= Best.Th)
                        then 1.0 else -1.0);
                  begin
                     D (K) := D (K) * Ada.Numerics.Elementary_Functions.Exp (-Alpha * Yv (K) * Hv);
                     Z := Z + D (K);
                  end;
               end loop;
               for K in 1 .. N loop
                  D (K) := D (K) / Z;
               end loop;
            end;
         end;
      end loop;
      Expect (M.Count = Rounds, What & " extra rounds:" & M.Count'Image & " vs" & Rounds'Image);
      for K in 1 .. N loop
         declare
            V : Adaboost.Feature_Vector (X'Range (2));
            S : Float := 0.0;
         begin
            for F in V'Range loop
               V (F) := X (Row (K), F);
            end loop;
            for R in 1 .. M.Count loop
               declare
                  H : constant Float := Float (V (M.Learners (R).Feature));
                  Hv : constant Float :=
                    (if (M.Learners (R).Polarity = 1 and then H > Float (M.Learners (R).Threshold))
                        or else (M.Learners (R).Polarity = -1 and then H <= Float (M.Learners (R).Threshold))
                     then 1.0 else -1.0);
               begin
                  S := S + Float (M.Alphas (R)) * Hv;
               end;
            end loop;
            Expect (Adaboost.Predict (M, V) = (if S >= 0.0 then Adaboost.Positive else Adaboost.Negative), What & " predict = sign of the vote");
         end;
      end loop;
   end Replay;

begin
   for Trial in 1 .. 40 loop
      declare
         N : constant Positive := 4 + Rand (8);
         F : constant Positive := 1 + Rand (3);
         X : Adaboost.Features_Matrix (1 .. Adaboost.Sample_Index (N), 1 .. Adaboost.Feature_Index (F));
         Y : Adaboost.Labels_Array (1 .. Adaboost.Sample_Index (N));
      begin
         for I in X'Range (1) loop
            for J in X'Range (2) loop
               X (I, J) := Adaboost.Feature_Value (Rand (7)) - 3.0;
            end loop;
            Y (I) := (if X (I, X'First (2)) >= 0.0 then Adaboost.Positive else Adaboost.Negative);
            if Rand (4) = 0 then
               Y (I) := (if Y (I) = Adaboost.Positive then Adaboost.Negative else Adaboost.Positive);
            end if;
         end loop;
         Replay (X, Y, 1 + Rand (6), "trial" & Trial'Image);
      end;
   end loop;
   --  labels paired by position, whatever their index origin
   declare
      X  : Adaboost.Features_Matrix (1 .. 4, 1 .. 2);
      Y1 : Adaboost.Labels_Array (1 .. 4);
      Y5 : Adaboost.Labels_Array (5 .. 8);
      M1, M5 : Adaboost.AdaBoost_Model (4);
   begin
      for I in 1 .. 4 loop
         X (Adaboost.Sample_Index (I), 1) := Adaboost.Feature_Value (I);
         X (Adaboost.Sample_Index (I), 2) := Adaboost.Feature_Value (I mod 2);
         Y1 (Adaboost.Sample_Index (I)) := (if I mod 2 = 0 then Adaboost.Positive else Adaboost.Negative);
         Y5 (Adaboost.Sample_Index (4 + I)) := Y1 (Adaboost.Sample_Index (I));
      end loop;
      begin
         Adaboost.Train (M1, X, Y1);
         Adaboost.Train (M5, X, Y5);
         Expect (M1.Count = M5.Count, "label origin 5: same count");
         for R in 1 .. M1.Count loop
            Expect (M1.Learners (R) = M5.Learners (R) and then M1.Alphas (R) = M5.Alphas (R),
                    "label origin 5: same model");
         end loop;
      exception
         when Constraint_Error =>
            Expect (False, "label origin 5 raised Constraint_Error");
      end;
   end;
   Expect (Checked > 100, "enough checks:" & Checked'Image);
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Checked'Image & " (AdaBoost replayed from the definition)");
end Own_Checks;
