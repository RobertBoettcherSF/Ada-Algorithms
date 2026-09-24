--  Multiplicative_Weight_Update_Method body.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Multiplicative_Weight_Update_Method is

   package EF is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use EF;

   -------------------------------------------------------------------------
   -- Internal helpers
   -------------------------------------------------------------------------

   function Is_Finite (X : Real) return Boolean is
     (X'Valid and then X > Real'First and then X < Real'Last);

   procedure Require_Initialized (L : Learner) is
   begin
      if not L.Initialized then
         raise Invalid_Argument with "learner is not initialized";
      end if;
   end Require_Initialized;

   procedure Validate_Eta (Eta : Real; Variant : Update_Kind) is
   begin
      if not Is_Finite (Eta) or else Eta <= 0.0 then
         raise Invalid_Argument with "learning rate η must be positive and finite";
      end if;
      if Variant = Multiplicative and then Eta >= 1.0 then
         raise Invalid_Argument
           with "Multiplicative variant requires 0 < η < 1";
      end if;
   end Validate_Eta;

   procedure Validate_Initial (Initial : Weight_Vector) is
   begin
      if Initial'Length = 0 or else Initial'Length > Max_Experts then
         raise Invalid_Argument with "initial weights length out of range";
      end if;
      if Initial'First /= 1 then
         raise Invalid_Argument with "initial weights must be 1-based";
      end if;
      for I in Initial'Range loop
         if not Is_Finite (Initial (I)) or else Initial (I) <= 0.0 then
            raise Invalid_Argument with "initial weights must be positive";
         end if;
      end loop;
   end Validate_Initial;

   function Sum_Weights (L : Learner) return Real is
      S : Real := 0.0;
   begin
      for I in 1 .. L.N loop
         S := S + L.W (I);
      end loop;
      return S;
   end Sum_Weights;

   procedure Apply_Update
     (L : in out Learner; Losses : Loss_Vector)
   is
      Factor : Real;
   begin
      for I in 1 .. L.N loop
         case L.Variant is
            when Hedge =>
               Factor := Exp (-L.Eta * Losses (I));
            when Multiplicative =>
               --  (1 − η)^{ℓ_i}; ℓ_i ∈ [0,1], 0 < η < 1.
               if Losses (I) = 0.0 then
                  Factor := 1.0;
               else
                  Factor := Exp (Losses (I) * Log (1.0 - L.Eta));
               end if;
         end case;
         if not Is_Finite (Factor) or else Factor <= 0.0 then
            raise Invalid_Argument with "weight update produced non-positive factor";
         end if;
         L.W (I) := L.W (I) * Factor;
         if not Is_Finite (L.W (I)) or else L.W (I) <= 0.0 then
            raise Invalid_Argument with "weight became non-positive";
         end if;
      end loop;
   end Apply_Update;

   -------------------------------------------------------------------------
   -- Construction / reset
   -------------------------------------------------------------------------

   function Create
     (N       : Expert_Count;
      Eta     : Positive_Real;
      Variant : Update_Kind := Hedge) return Learner
   is
      L : Learner;
   begin
      Validate_Eta (Eta, Variant);
      L.N := N;
      L.Eta := Eta;
      L.Variant := Variant;
      L.W := [others => 1.0];
      L.Expert_Cum := [others => 0.0];
      L.Alg_Cum := 0.0;
      L.Round_Count := 0;
      L.Initialized := True;
      return L;
   end Create;

   function Create
     (Eta     : Positive_Real;
      Initial : Weight_Vector;
      Variant : Update_Kind := Hedge) return Learner
   is
      L : Learner;
   begin
      Validate_Eta (Eta, Variant);
      Validate_Initial (Initial);
      L.N := Initial'Length;
      L.Eta := Eta;
      L.Variant := Variant;
      L.W := [others => 1.0];
      for I in Initial'Range loop
         L.W (I) := Initial (I);
      end loop;
      L.Expert_Cum := [others => 0.0];
      L.Alg_Cum := 0.0;
      L.Round_Count := 0;
      L.Initialized := True;
      return L;
   end Create;

   procedure Reset (L : in out Learner) is
   begin
      Require_Initialized (L);
      for I in 1 .. L.N loop
         L.W (I) := 1.0;
         L.Expert_Cum (I) := 0.0;
      end loop;
      for I in L.N + 1 .. Max_Experts loop
         L.W (I) := 1.0;
         L.Expert_Cum (I) := 0.0;
      end loop;
      L.Alg_Cum := 0.0;
      L.Round_Count := 0;
   end Reset;

   procedure Reset
     (L       : in out Learner;
      Initial : Weight_Vector)
   is
   begin
      Require_Initialized (L);
      Validate_Initial (Initial);
      if Initial'Length /= L.N then
         raise Invalid_Argument with "initial weights length must equal N";
      end if;
      for I in 1 .. L.N loop
         L.W (I) := Initial (I);
         L.Expert_Cum (I) := 0.0;
      end loop;
      L.Alg_Cum := 0.0;
      L.Round_Count := 0;
   end Reset;

   -------------------------------------------------------------------------
   -- Accessors
   -------------------------------------------------------------------------

   function Expert_Count_Of (L : Learner) return Expert_Count is
   begin
      Require_Initialized (L);
      return L.N;
   end Expert_Count_Of;

   function Learning_Rate (L : Learner) return Positive_Real is
   begin
      Require_Initialized (L);
      return L.Eta;
   end Learning_Rate;

   function Variant_Of (L : Learner) return Update_Kind is
   begin
      Require_Initialized (L);
      return L.Variant;
   end Variant_Of;

   function Rounds (L : Learner) return Natural is
   begin
      Require_Initialized (L);
      return L.Round_Count;
   end Rounds;

   function Weights (L : Learner) return Weight_Vector is
      Result : Weight_Vector (1 .. L.N);
   begin
      Require_Initialized (L);
      for I in 1 .. L.N loop
         Result (I) := L.W (I);
      end loop;
      return Result;
   end Weights;

   function Weight_Sum (L : Learner) return Positive_Real is
      S : Real;
   begin
      Require_Initialized (L);
      S := Sum_Weights (L);
      if not Is_Finite (S) or else S <= 0.0 then
         raise Invalid_Argument with "weight sum is non-positive";
      end if;
      return S;
   end Weight_Sum;

   function Probabilities (L : Learner) return Probability_Vector is
      S : constant Real := Weight_Sum (L);
      P : Probability_Vector (1 .. L.N);
   begin
      for I in 1 .. L.N loop
         P (I) := L.W (I) / S;
      end loop;
      return P;
   end Probabilities;

   function Distribution (L : Learner) return Probability_Vector is
     (Probabilities (L));

   function Choose (L : Learner) return Expert_Index is
      Best : Expert_Index := 1;
   begin
      Require_Initialized (L);
      for I in 2 .. L.N loop
         if L.W (I) > L.W (Best) then
            Best := I;
         end if;
      end loop;
      return Best;
   end Choose;

   function Best_Expert (L : Learner) return Expert_Index is
      Best : Expert_Index := 1;
   begin
      Require_Initialized (L);
      for I in 2 .. L.N loop
         if L.Expert_Cum (I) < L.Expert_Cum (Best) then
            Best := I;
         end if;
      end loop;
      return Best;
   end Best_Expert;

   -------------------------------------------------------------------------
   -- Updates
   -------------------------------------------------------------------------

   procedure Update (L : in out Learner; Losses : Loss_Vector) is
      P       : Probability_Vector (1 .. L.N);
      Instant : Real := 0.0;
   begin
      Require_Initialized (L);
      if Losses'Length /= L.N then
         raise Invalid_Argument with "loss vector length must equal N";
      end if;
      if Losses'First /= 1 then
         raise Invalid_Argument with "loss vector must be 1-based";
      end if;
      for I in Losses'Range loop
         if not Is_Finite (Losses (I)) then
            raise Invalid_Argument with "losses must be finite";
         end if;
         if L.Variant = Multiplicative
           and then (Losses (I) < 0.0 or else Losses (I) > 1.0)
         then
            raise Invalid_Argument
              with "Multiplicative variant requires losses in [0,1]";
         end if;
      end loop;

      P := Probabilities (L);
      for I in 1 .. L.N loop
         Instant := Instant + P (I) * Losses (I);
         L.Expert_Cum (I) := L.Expert_Cum (I) + Losses (I);
      end loop;
      L.Alg_Cum := L.Alg_Cum + Instant;
      Apply_Update (L, Losses);
      L.Round_Count := L.Round_Count + 1;
   end Update;

   procedure Update_Rewards (L : in out Learner; Rewards : Reward_Vector) is
      Losses : Loss_Vector (Rewards'Range);
   begin
      Require_Initialized (L);
      if Rewards'Length /= L.N then
         raise Invalid_Argument with "reward vector length must equal N";
      end if;
      if Rewards'First /= 1 then
         raise Invalid_Argument with "reward vector must be 1-based";
      end if;
      for I in Rewards'Range loop
         if not Is_Finite (Rewards (I)) then
            raise Invalid_Argument with "rewards must be finite";
         end if;
         Losses (I) := -Rewards (I);
      end loop;
      Update (L, Losses);
   end Update_Rewards;

   -------------------------------------------------------------------------
   -- Regret
   -------------------------------------------------------------------------

   function Algorithm_Loss (L : Learner) return Real is
   begin
      Require_Initialized (L);
      return L.Alg_Cum;
   end Algorithm_Loss;

   function Expert_Loss (L : Learner; I : Expert_Index) return Real is
   begin
      Require_Initialized (L);
      if I > L.N then
         raise Invalid_Argument with "expert index out of range";
      end if;
      return L.Expert_Cum (I);
   end Expert_Loss;

   function Best_Expert_Loss (L : Learner) return Real is
   begin
      Require_Initialized (L);
      return L.Expert_Cum (Best_Expert (L));
   end Best_Expert_Loss;

   function External_Regret (L : Learner) return Real is
   begin
      Require_Initialized (L);
      return L.Alg_Cum - Best_Expert_Loss (L);
   end External_Regret;

   function Average_Regret (L : Learner) return Real is
   begin
      Require_Initialized (L);
      if L.Round_Count = 0 then
         return 0.0;
      end if;
      return External_Regret (L) / Real (L.Round_Count);
   end Average_Regret;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Suggested_Eta
     (N : Expert_Count;
      T : Positive;
      Variant : Update_Kind := Hedge) return Positive_Real
   is
      Ln_N : constant Real := Log (Real (N));
      Raw  : Real;
   begin
      if Ln_N < 0.0 then
         raise Invalid_Argument with "internal log error";
      end if;
      --  √(ln N / T); for N = 1 use a tiny positive rate.
      if Ln_N = 0.0 then
         Raw := 1.0 / Real (T);
      else
         Raw := Sqrt (Ln_N / Real (T));
      end if;
      if Raw <= 0.0 then
         Raw := Real'Model_Small;
      end if;
      if Variant = Multiplicative then
         if Raw > 0.5 then
            Raw := 0.5;
         end if;
      end if;
      return Raw;
   end Suggested_Eta;

   function Near (A, B : Real; Tol : Real := 1.0E-9) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Distribution_Sums_To_One
     (P : Probability_Vector; Tol : Real := 1.0E-9) return Boolean
   is
      S : Real := 0.0;
   begin
      if P'Length = 0 then
         return False;
      end if;
      for X of P loop
         if X < 0.0 then
            return False;
         end if;
         S := S + X;
      end loop;
      return Near (S, 1.0, Tol);
   end Distribution_Sums_To_One;

   function Is_Valid_Initial (Initial : Weight_Vector) return Boolean is
   begin
      if Initial'Length = 0 or else Initial'Length > Max_Experts then
         return False;
      end if;
      if Initial'First /= 1 then
         return False;
      end if;
      for X of Initial loop
         if not Is_Finite (X) or else X <= 0.0 then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Initial;

   function Expected_Loss
     (P : Probability_Vector; Losses : Loss_Vector) return Real
   is
      S : Real := 0.0;
   begin
      if P'Length = 0 or else Losses'Length = 0 then
         raise Invalid_Argument with "empty probability or loss vector";
      end if;
      if P'Length /= Losses'Length then
         raise Invalid_Argument with "probability/loss length mismatch";
      end if;
      if P'First /= Losses'First then
         raise Invalid_Argument with "probability/loss index mismatch";
      end if;
      for I in P'Range loop
         S := S + P (I) * Losses (I);
      end loop;
      return S;
   end Expected_Loss;

end Multiplicative_Weight_Update_Method;
