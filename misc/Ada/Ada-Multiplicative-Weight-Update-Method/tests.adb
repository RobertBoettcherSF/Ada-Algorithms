--  Standalone test suite for Multiplicative_Weight_Update_Method.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Multiplicative_Weight_Update_Method;
use Multiplicative_Weight_Update_Method;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Pos (X : Positive) return Positive is (X);
   function Nat_View (X : Natural) return Natural is (X);
   function R (X : Real) return Real is (X);

   function Create_Initial_Raises
     (Eta : Real; Initial : Weight_Vector; Variant : Update_Kind)
      return Boolean
   is
      L : Learner;
   begin
      L := Create (Positive_Real (Eta), Initial, Variant);
      pragma Unreferenced (L);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when Constraint_Error =>
         return True;
   end Create_Initial_Raises;

   function Update_Raises
     (L : in out Learner; Losses : Loss_Vector) return Boolean
   is
   begin
      Update (L, Losses);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Update_Raises;

   function Expert_Loss_Raises
     (L : Learner; I : Expert_Index) return Boolean
   is
      X : Real;
   begin
      X := Expert_Loss (L, I);
      pragma Unreferenced (X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Expert_Loss_Raises;

   function Expected_Loss_Raises
     (P : Probability_Vector; Losses : Loss_Vector) return Boolean
   is
      X : Real;
   begin
      X := Expected_Loss (P, Losses);
      pragma Unreferenced (X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Expected_Loss_Raises;

   function Reset_Initial_Raises
     (L : in out Learner; Initial : Weight_Vector) return Boolean
   is
   begin
      Reset (L, Initial);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Reset_Initial_Raises;

begin
   Put_Line ("Multiplicative_Weight_Update_Method — test suite");

   -----------------------------------------------------------------
   Section ("Create / uniform / accessors");
   -----------------------------------------------------------------
   declare
      L : constant Learner := Create (3, 0.1, Hedge);
      W : constant Weight_Vector := Weights (L);
      P : constant Probability_Vector := Probabilities (L);
      D : constant Probability_Vector := Distribution (L);
   begin
      Check (Expert_Count_Of (L) = 3, "N = 3");
      Check (Near (Learning_Rate (L), 0.1), "eta = 0.1");
      Check (Variant_Of (L) = Hedge, "variant Hedge");
      Check (Rounds (L) = 0, "rounds start at 0");
      Check (W'Length = 3, "weights length 3");
      Check (Near (W (1), 1.0) and then Near (W (2), 1.0)
               and then Near (W (3), 1.0), "uniform weights 1");
      Check (Near (Weight_Sum (L), 3.0), "weight sum 3");
      Check (Distribution_Sums_To_One (P), "probabilities sum to 1");
      Check (Near (P (1), 1.0 / 3.0) and then Near (P (2), 1.0 / 3.0)
               and then Near (P (3), 1.0 / 3.0), "uniform probabilities");
      Check (Near (D (1), P (1)) and then Near (D (2), P (2)),
             "Distribution aliases Probabilities");
      Check (Choose (L) = 1, "Choose ties to smallest index");
      Check (Best_Expert (L) = 1, "Best_Expert before updates is 1");
      Check (Near (Algorithm_Loss (L), 0.0), "alg loss 0");
      Check (Near (Best_Expert_Loss (L), 0.0), "best expert loss 0");
      Check (Near (External_Regret (L), 0.0), "external regret 0");
      Check (Near (Average_Regret (L), 0.0), "average regret 0 at T=0");
   end;

   declare
      L : constant Learner := Create (1, 0.25, Multiplicative);
   begin
      Check (Expert_Count_Of (L) = 1, "N = 1");
      Check (Variant_Of (L) = Multiplicative, "variant Multiplicative");
      Check (Choose (L) = 1, "single expert Choose = 1");
      Check (Near (Probabilities (L) (1), 1.0), "single expert p=1");
   end;

   declare
      L : constant Learner := Create (Max_Experts, 0.05, Hedge);
   begin
      Check (Expert_Count_Of (L) = Max_Experts, "N = Max_Experts");
      Check (Weights (L)'Length = Max_Experts, "weights length Max");
      Check (Distribution_Sums_To_One (Probabilities (L)),
             "Max_Experts distribution sums to 1");
   end;

   -----------------------------------------------------------------
   Section ("Create with custom initial weights");
   -----------------------------------------------------------------
   declare
      Init : constant Weight_Vector := [2.0, 1.0, 1.0];
      L    : constant Learner := Create (0.2, Init, Hedge);
      P    : constant Probability_Vector := Probabilities (L);
   begin
      Check (Expert_Count_Of (L) = 3, "custom N = 3");
      Check (Near (Weights (L) (1), 2.0), "custom w1=2");
      Check (Near (Weight_Sum (L), 4.0), "custom sum=4");
      Check (Near (P (1), 0.5), "custom p1=0.5");
      Check (Near (P (2), 0.25) and then Near (P (3), 0.25),
             "custom p2=p3=0.25");
      Check (Choose (L) = 1, "Choose heaviest expert");
      Check (Is_Valid_Initial (Init), "Is_Valid_Initial true");
   end;

   Check (not Is_Valid_Initial (Weight_Vector'(1 => -1.0)),
          "Is_Valid_Initial rejects non-positive");
   Check (not Is_Valid_Initial (Weight_Vector'(1 => 0.0)),
          "Is_Valid_Initial rejects zero");
   Check (Is_Valid_Initial (Weight_Vector'(1 => 0.001)),
          "Is_Valid_Initial accepts tiny positive");

   -----------------------------------------------------------------
   Section ("Invalid Create arguments");
   -----------------------------------------------------------------
   --  Eta must be Positive_Real at the call site for Create (N, Eta, ...);
   --  use Create with Initial to pass bad eta via conversion helpers.
   Check (Create_Initial_Raises
            (R (0.0), Weight_Vector'(1 => 1.0), Hedge),
          "eta=0 raises");
   Check (Create_Initial_Raises
            (R (-0.5), Weight_Vector'(1 => 1.0), Hedge),
          "eta negative raises");
   Check (Create_Initial_Raises
            (R (1.0), Weight_Vector'(1 => 1.0), Multiplicative),
          "Multiplicative eta=1 raises");
   Check (Create_Initial_Raises
            (R (1.5), Weight_Vector'(1 => 1.0), Multiplicative),
          "Multiplicative eta>1 raises");
   Check (not Create_Initial_Raises
            (R (0.99), Weight_Vector'(1 => 1.0), Multiplicative),
          "Multiplicative eta=0.99 ok");
   Check (not Create_Initial_Raises
            (R (2.0), Weight_Vector'(1 => 1.0), Hedge),
          "Hedge large eta ok");
   Check (Create_Initial_Raises
            (R (0.1), Weight_Vector'(1 => 0.0), Hedge),
          "zero initial weight raises");
   Check (Create_Initial_Raises
            (R (0.1), Weight_Vector'(1 => -2.0, 2 => 1.0), Hedge),
          "negative initial weight raises");

   -----------------------------------------------------------------
   Section ("Hedge single-round update");
   -----------------------------------------------------------------
   declare
      L : Learner := Create (2, 0.5, Hedge);
      --  loss [1, 0]: expert 1 punished, expert 2 untouched
      Loss : constant Loss_Vector := [1.0, 0.0];
      W    : Weight_Vector (1 .. 2);
      P    : Probability_Vector (1 .. 2);
      E    : Real;
   begin
      E := Expected_Loss (Probabilities (L), Loss);
      Check (Near (E, 0.5), "expected loss before update = 0.5");
      Update (L, Loss);
      Check (Rounds (L) = 1, "rounds = 1");
      W := Weights (L);
      --  w1 = exp(-0.5), w2 = 1
      Check (Near (W (1), 0.6065306597, 1.0E-6), "Hedge w1 = exp(-0.5)");
      Check (Near (W (2), 1.0), "Hedge w2 unchanged");
      P := Probabilities (L);
      Check (Distribution_Sums_To_One (P), "post-update probs sum 1");
      Check (P (2) > P (1), "better expert has higher probability");
      Check (Choose (L) = 2, "Choose picks expert 2");
      Check (Near (Algorithm_Loss (L), 0.5), "alg cum loss 0.5");
      Check (Near (Expert_Loss (L, 1), 1.0), "expert1 cum 1");
      Check (Near (Expert_Loss (L, 2), 0.0), "expert2 cum 0");
      Check (Best_Expert (L) = 2, "best expert is 2");
      Check (Near (Best_Expert_Loss (L), 0.0), "best loss 0");
      Check (Near (External_Regret (L), 0.5), "external regret 0.5");
      Check (Near (Average_Regret (L), 0.5), "average regret 0.5");
   end;

   -----------------------------------------------------------------
   Section ("Multiplicative single-round update");
   -----------------------------------------------------------------
   declare
      L : Learner := Create (2, 0.5, Multiplicative);
      Loss : constant Loss_Vector := [1.0, 0.0];
      W : Weight_Vector (1 .. 2);
   begin
      Update (L, Loss);
      W := Weights (L);
      --  w1 = (1-0.5)^1 = 0.5, w2 = (1-0.5)^0 = 1
      Check (Near (W (1), 0.5), "Multiplicative w1 = 0.5");
      Check (Near (W (2), 1.0), "Multiplicative w2 = 1");
      Check (Choose (L) = 2, "Multiplicative Choose = 2");
      Check (Near (Probabilities (L) (2), 1.0 / 1.5, 1.0E-9),
             "Multiplicative p2 = 2/3");
   end;

   declare
      L : Learner := Create (2, 0.25, Multiplicative);
      Loss : constant Loss_Vector := [0.5, 0.0];
      W : Weight_Vector (1 .. 2);
      Expected_W1 : constant Real := 0.8660254037844386;  -- sqrt(0.75)
   begin
      Update (L, Loss);
      W := Weights (L);
      Check (Near (W (1), Expected_W1, 1.0E-9),
             "Multiplicative fractional loss (1-eta)^ell");
      Check (Near (W (2), 1.0), "zero loss keeps weight");
   end;

   -----------------------------------------------------------------
   Section ("Update validation");
   -----------------------------------------------------------------
   declare
      L : Learner := Create (3, 0.1, Hedge);
   begin
      Check (Update_Raises (L, Loss_Vector'(1 => 0.0, 2 => 0.0)),
             "short loss vector raises");
      Check (Update_Raises
               (L, Loss_Vector'(1 => 0.0, 2 => 0.0, 3 => 0.0, 4 => 0.0)),
             "long loss vector raises");
   end;
   declare
      L : Learner := Create (2, 0.1, Multiplicative);
   begin
      Check (Update_Raises (L, Loss_Vector'(1 => -0.1, 2 => 0.0)),
             "Multiplicative negative loss raises");
      Check (Update_Raises (L, Loss_Vector'(1 => 1.1, 2 => 0.0)),
             "Multiplicative loss > 1 raises");
      Check (not Update_Raises (L, Loss_Vector'(1 => 0.0, 2 => 1.0)),
             "Multiplicative boundary losses ok");
   end;
   declare
      L : Learner := Create (2, 0.1, Hedge);
   begin
      --  Hedge allows losses outside [0,1]
      Check (not Update_Raises (L, Loss_Vector'(1 => 2.0, 2 => -1.0)),
             "Hedge unbounded losses ok");
   end;

   -----------------------------------------------------------------
   Section ("Reset");
   -----------------------------------------------------------------
   declare
      L : Learner := Create (3, 0.2, Hedge);
   begin
      Update (L, [1.0, 0.0, 0.5]);
      Update (L, [0.0, 1.0, 0.0]);
      Check (Rounds (L) = 2, "two rounds before reset");
      Check (Algorithm_Loss (L) > 0.0, "alg loss positive before reset");
      Reset (L);
      Check (Rounds (L) = 0, "rounds cleared");
      Check (Near (Algorithm_Loss (L), 0.0), "alg loss cleared");
      Check (Near (Weights (L) (1), 1.0)
               and then Near (Weights (L) (2), 1.0)
               and then Near (Weights (L) (3), 1.0),
             "weights restored to uniform");
      Check (Near (External_Regret (L), 0.0), "regret cleared");
      Check (Variant_Of (L) = Hedge, "variant preserved");
      Check (Near (Learning_Rate (L), 0.2), "eta preserved");
   end;

   declare
      L : Learner := Create (2, 0.1, Hedge);
      Init : constant Weight_Vector := [3.0, 1.0];
   begin
      Update (L, [1.0, 0.0]);
      Reset (L, Init);
      Check (Near (Weights (L) (1), 3.0), "custom reset w1");
      Check (Near (Weights (L) (2), 1.0), "custom reset w2");
      Check (Rounds (L) = 0, "custom reset rounds 0");
      Check (Reset_Initial_Raises (L, Weight_Vector'(1 => 1.0)),
             "reset wrong length raises");
      Check (Reset_Initial_Raises (L, Weight_Vector'(1 => 0.0, 2 => 1.0)),
             "reset non-positive raises");
   end;

   -----------------------------------------------------------------
   Section ("Update_Rewards");
   -----------------------------------------------------------------
   declare
      L : Learner := Create (2, 0.5, Hedge);
      --  reward [0, 1] => loss [0, -1] wait: ell = -r so [0, -1]
      --  Actually reward high for expert 2: Rewards [0, 1] => Losses [0, -1]
      --  Expert 2 gets weight boost via exp(-eta*(-1)) = exp(eta)
   begin
      Update_Rewards (L, [0.0, 1.0]);
      Check (Weights (L) (2) > Weights (L) (1),
             "higher reward increases weight (Hedge)");
      Check (Choose (L) = 2, "Choose after rewards = 2");
   end;

   declare
      L : Learner := Create (2, 0.25, Multiplicative);
   begin
      --  rewards in [-1,0] so -r in [0,1]
      Update_Rewards (L, [-1.0, 0.0]);
      Check (Weights (L) (1) < Weights (L) (2),
             "Multiplicative reward update punishes expert 1");
   end;

   -----------------------------------------------------------------
   Section ("Best expert tracking over many rounds");
   -----------------------------------------------------------------
   declare
      L : Learner := Create (4, 0.2, Hedge);
      --  Expert 3 is always best (loss 0); others lose 1
   begin
      for T in 1 .. 20 loop
         Update (L, [1.0, 1.0, 0.0, 1.0]);
      end loop;
      Check (Rounds (L) = 20, "20 rounds");
      Check (Best_Expert (L) = 3, "best expert is 3");
      Check (Near (Best_Expert_Loss (L), 0.0), "best loss still 0");
      Check (Choose (L) = 3, "Choose converges to expert 3");
      Check (Probabilities (L) (3) > 0.9, "mass concentrates on expert 3");
      Check (External_Regret (L) >= 0.0, "external regret non-negative");
      Check (Average_Regret (L) >= 0.0, "average regret non-negative");
      Check (Average_Regret (L) < 0.5, "average regret decays below 0.5");
   end;

   -----------------------------------------------------------------
   Section ("No-regret: average regret shrinks with T");
   -----------------------------------------------------------------
   declare
      function Run_Avg (T : Positive) return Real is
         N : constant Expert_Count := 5;
         Eta : constant Positive_Real := Suggested_Eta (N, T, Hedge);
         L : Learner := Create (N, Eta, Hedge);
         Loss : Loss_Vector (1 .. N);
      begin
         for Round in 1 .. T loop
            for I in 1 .. N loop
               --  expert I has loss 0 on rounds where Round mod N = I rem;
               --  expert 1 always best with loss 0; others loss 1
               if I = 1 then
                  Loss (I) := 0.0;
               else
                  Loss (I) := 1.0;
               end if;
            end loop;
            Update (L, Loss);
         end loop;
         return Average_Regret (L);
      end Run_Avg;
      A50  : constant Real := Run_Avg (50);
      A200 : constant Real := Run_Avg (200);
   begin
      Check (A50 >= 0.0, "avg regret T=50 >= 0");
      Check (A200 >= 0.0, "avg regret T=200 >= 0");
      Check (A200 < A50, "average regret decreases with T");
      Check (A200 < 0.25, "average regret T=200 small");
   end;

   -----------------------------------------------------------------
   Section ("Suggested_Eta");
   -----------------------------------------------------------------
   declare
      E1 : constant Real := Suggested_Eta (2, 100, Hedge);
      E2 : constant Real := Suggested_Eta (2, 100, Multiplicative);
      E3 : constant Real := Suggested_Eta (1, 10, Hedge);
      E4 : constant Real := Suggested_Eta (8, 1, Multiplicative);
   begin
      Check (E1 > 0.0, "Suggested_Eta Hedge positive");
      Check (E2 > 0.0 and then E2 <= 0.5,
             "Suggested_Eta Multiplicative in (0,0.5]");
      Check (E3 > 0.0, "Suggested_Eta N=1 positive");
      Check (E4 = 0.5 or else E4 <= 0.5,
             "Suggested_Eta Multiplicative capped at 0.5");
      Check (Suggested_Eta (4, 400, Hedge)
               < Suggested_Eta (4, 100, Hedge),
             "Suggested_Eta decreases in T");
   end;

   -----------------------------------------------------------------
   Section ("Expected_Loss helper");
   -----------------------------------------------------------------
   declare
      P : constant Probability_Vector := [0.5, 0.5];
      L : constant Loss_Vector := [1.0, 0.0];
   begin
      Check (Near (Expected_Loss (P, L), 0.5), "⟨p,ℓ⟩ = 0.5");
      Check (Expected_Loss_Raises
               (Probability_Vector'(1 => 1.0), L),
             "Expected_Loss length mismatch raises");
      Check (Expected_Loss_Raises
               (Probability_Vector'(1 .. 0 => <>), L),
             "Expected_Loss empty raises");
   end;

   -----------------------------------------------------------------
   Section ("Near / Distribution_Sums_To_One");
   -----------------------------------------------------------------
   Check (Near (1.0, 1.0 + 1.0E-12, 1.0E-9), "Near true within tol");
   Check (not Near (1.0, 2.0, 1.0E-3), "Near false outside tol");
   Check (Distribution_Sums_To_One ([0.2, 0.3, 0.5]), "sums to one");
   Check (not Distribution_Sums_To_One ([0.2, 0.3, 0.4]), "does not sum");
   Check (not Distribution_Sums_To_One ([-0.1, 1.1]), "negative mass");
   Check (not Distribution_Sums_To_One
            (Probability_Vector'(1 .. 0 => <>)), "empty false");

   -----------------------------------------------------------------
   Section ("Expert_Loss bounds");
   -----------------------------------------------------------------
   declare
      L : Learner := Create (2, 0.1, Hedge);
   begin
      Update (L, [0.3, 0.7]);
      Check (Near (Expert_Loss (L, 1), 0.3), "expert loss 1");
      Check (Near (Expert_Loss (L, 2), 0.7), "expert loss 2");
      Check (Expert_Loss_Raises (L, 3), "expert index > N raises");
   end;

   -----------------------------------------------------------------
   Section ("Multiplicative vs Hedge qualitative agreement");
   -----------------------------------------------------------------
   declare
      LH : Learner := Create (3, 0.2, Hedge);
      LM : Learner := Create (3, 0.2, Multiplicative);
      Loss : constant Loss_Vector := [1.0, 0.5, 0.0];
   begin
      for K in 1 .. 15 loop
         Update (LH, Loss);
         Update (LM, Loss);
      end loop;
      Check (Choose (LH) = 3 and then Choose (LM) = 3,
             "both variants choose best expert");
      Check (Best_Expert (LH) = 3 and then Best_Expert (LM) = 3,
             "both track same best expert");
      Check (Probabilities (LH) (3) > Probabilities (LH) (1),
             "Hedge ranks best highest");
      Check (Probabilities (LM) (3) > Probabilities (LM) (1),
             "Multiplicative ranks best highest");
   end;

   -----------------------------------------------------------------
   Section ("Identical losses keep uniform (up to scale)");
   -----------------------------------------------------------------
   declare
      L : Learner := Create (4, 0.3, Hedge);
   begin
      for K in 1 .. 10 loop
         Update (L, [0.4, 0.4, 0.4, 0.4]);
      end loop;
      declare
         P : constant Probability_Vector := Probabilities (L);
      begin
         Check (Near (P (1), 0.25) and then Near (P (2), 0.25)
                  and then Near (P (3), 0.25) and then Near (P (4), 0.25),
                "identical losses keep uniform distribution");
         Check (Choose (L) = 1, "ties broken to index 1");
      end;
   end;

   -----------------------------------------------------------------
   Section ("Zero losses leave weights unchanged");
   -----------------------------------------------------------------
   declare
      L : Learner := Create (0.1, Weight_Vector'(1 => 2.0, 2 => 3.0), Hedge);
      W0 : constant Weight_Vector := Weights (L);
   begin
      Update (L, [0.0, 0.0]);
      Check (Near (Weights (L) (1), W0 (1))
               and then Near (Weights (L) (2), W0 (2)),
             "zero losses: Hedge weights unchanged");
      Check (Near (Algorithm_Loss (L), 0.0), "zero-loss alg cum 0");
   end;
   declare
      L : Learner := Create (0.1, Weight_Vector'(1 => 2.0, 2 => 3.0),
                             Multiplicative);
      W0 : constant Weight_Vector := Weights (L);
   begin
      Update (L, [0.0, 0.0]);
      Check (Near (Weights (L) (1), W0 (1))
               and then Near (Weights (L) (2), W0 (2)),
             "zero losses: Multiplicative weights unchanged");
   end;

   -----------------------------------------------------------------
   Section ("External regret vs best expert identity");
   -----------------------------------------------------------------
   declare
      L : Learner := Create (3, 0.15, Hedge);
   begin
      Update (L, [0.0, 1.0, 1.0]);
      Update (L, [0.2, 0.8, 1.0]);
      Update (L, [0.1, 0.9, 0.5]);
      Check (Near (External_Regret (L),
                  Algorithm_Loss (L) - Best_Expert_Loss (L)),
             "External_Regret = Alg - Best");
      Check (Near (Average_Regret (L),
                  External_Regret (L) / Real (Rounds (L))),
             "Average_Regret = External / T");
   end;

   -----------------------------------------------------------------
   Section ("Concentration under persistent best expert");
   -----------------------------------------------------------------
   declare
      L : Learner := Create (5, Suggested_Eta (5, 100, Hedge), Hedge);
      P : Probability_Vector (1 .. 5);
   begin
      for T in 1 .. 100 loop
         Update (L, [1.0, 1.0, 1.0, 0.0, 1.0]);
      end loop;
      P := Probabilities (L);
      Check (P (4) > 0.95, "after 100 rounds p_best > 0.95");
      Check (Choose (L) = 4, "Choose = best expert 4");
      Check (Average_Regret (L) < 0.15, "avg regret < 0.15 after 100");
   end;

   -----------------------------------------------------------------
   Section ("Switching best expert");
   -----------------------------------------------------------------
   declare
      L : Learner := Create (2, 0.4, Hedge);
   begin
      for T in 1 .. 10 loop
         Update (L, [0.0, 1.0]);
      end loop;
      Check (Best_Expert (L) = 1, "phase1 best is 1");
      Check (Choose (L) = 1, "phase1 Choose is 1");
      for T in 1 .. 40 loop
         Update (L, [1.0, 0.0]);
      end loop;
      Check (Best_Expert (L) = 2, "phase2 cumulative best becomes 2");
      Check (Choose (L) = 2, "phase2 Choose follows recent wins");
   end;

   -----------------------------------------------------------------
   Section ("Many experts smoke");
   -----------------------------------------------------------------
   declare
      N : constant Expert_Count := 32;
      L : Learner := Create (N, 0.05, Hedge);
      Loss : Loss_Vector (1 .. N);
   begin
      for I in 1 .. N loop
         Loss (I) := Real (I - 1) / Real (N);
      end loop;
      for T in 1 .. 30 loop
         Update (L, Loss);
      end loop;
      Check (Choose (L) = 1, "lowest-loss expert chosen among 32");
      Check (Best_Expert (L) = 1, "best expert index 1");
      Check (Distribution_Sums_To_One (Probabilities (L), 1.0E-8),
             "32-expert distribution normalizes");
      Check (Rounds (L) = 30, "30 rounds recorded");
   end;

   -----------------------------------------------------------------
   Section ("Repeated Create / independent learners");
   -----------------------------------------------------------------
   declare
      A : Learner := Create (2, 0.1, Hedge);
      B : constant Learner := Create (2, 0.1, Hedge);
   begin
      Update (A, [1.0, 0.0]);
      Check (Rounds (A) = 1 and then Rounds (B) = 0,
             "learners are independent");
      Check (Near (Weights (B) (1), 1.0), "B untouched");
   end;

   -----------------------------------------------------------------
   Section ("Probability monotonicity under domination");
   -----------------------------------------------------------------
   declare
      L : Learner := Create (2, 0.3, Hedge);
      Prev : Real := Probabilities (L) (1);
   begin
      for T in 1 .. 12 loop
         Update (L, [0.0, 1.0]);
         declare
            Cur : constant Real := Probabilities (L) (1);
         begin
            Check (Cur >= Prev - 1.0E-12,
                   "p1 nondecreasing when expert1 dominates round"
                   & Integer'Image (T));
            Prev := Cur;
         end;
      end loop;
   end;

   -----------------------------------------------------------------
   Section ("Algorithm loss equals sum of instantaneous expected losses");
   -----------------------------------------------------------------
   declare
      L : Learner := Create (3, 0.2, Hedge);
      Manual : Real := 0.0;
      Losses : constant array (1 .. 5) of Loss_Vector (1 .. 3) :=
        [[1.0, 0.0, 0.5],
         [0.0, 1.0, 0.0],
         [0.5, 0.5, 0.5],
         [0.2, 0.8, 0.1],
         [1.0, 1.0, 0.0]];
   begin
      for K in Losses'Range loop
         Manual := Manual
           + Expected_Loss (Probabilities (L), Losses (K));
         Update (L, Losses (K));
      end loop;
      Check (Near (Algorithm_Loss (L), Manual, 1.0E-9),
             "Algorithm_Loss matches manual sum of ⟨p,ℓ⟩");
   end;

   -----------------------------------------------------------------
   Section ("Boundary: eta near 0 and near 1 (Multiplicative)");
   -----------------------------------------------------------------
   declare
      L : Learner := Create (2, 1.0E-6, Hedge);
   begin
      Update (L, [1.0, 0.0]);
      Check (Near (Weights (L) (1), 1.0, 1.0E-4),
             "tiny eta barely changes weights");
   end;
   declare
      L : Learner := Create (2, 0.999, Multiplicative);
   begin
      Update (L, [1.0, 0.0]);
      Check (Weights (L) (1) < 0.01, "eta near 1 nearly zeros mistaken expert");
      Check (Near (Weights (L) (2), 1.0), "correct expert weight untouched");
   end;

   -----------------------------------------------------------------
   Section ("Max_Experts constant");
   -----------------------------------------------------------------
   Check (Max_Experts = Pos (64), "Max_Experts = 64");
   Check (Nat_View (Max_Experts) = 64, "Max_Experts via Nat_View");

   -----------------------------------------------------------------
   Section ("Regret non-negative when a perfect expert exists");
   -----------------------------------------------------------------
   declare
      L : Learner := Create (3, 0.25, Multiplicative);
   begin
      for T in 1 .. 25 loop
         Update (L, [1.0, 0.0, 1.0]);
      end loop;
      Check (External_Regret (L) >= -1.0E-9, "regret >= 0 (num tol)");
      Check (Best_Expert (L) = 2, "perfect expert is 2");
      Check (Near (Best_Expert_Loss (L), 0.0), "perfect expert loss 0");
   end;

   -----------------------------------------------------------------
   -- Summary
   -----------------------------------------------------------------
   New_Line;
   Put_Line ("========================================");
   Put_Line ("PASS:" & Natural'Image (Pass_Count));
   Put_Line ("FAIL:" & Natural'Image (Fail_Count));
   Put_Line ("========================================");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
