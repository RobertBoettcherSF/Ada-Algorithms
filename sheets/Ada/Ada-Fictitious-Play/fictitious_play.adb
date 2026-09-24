-- fictitious_play.adb
-- Implementation body for Fictitious Play variants.

with Ada.Numerics.Elementary_Functions;
with Ada.Numerics.Float_Random;

package body Fictitious_Play is

   use Ada.Numerics.Elementary_Functions;
   
   -- RNG for stochastic variants
   RNG : Ada.Numerics.Float_Random.Generator;

   -- ==========================================
   -- Helper Functions
   -- ==========================================
   
   -- Validation helper to check matrix consistency
   procedure Validate_Inputs (
      P1_Payoffs : Payoff_Matrix;
      P2_Payoffs : Payoff_Matrix;
      Iterations : Positive;
      P1_History : Action_Array;
      P2_History : Action_Array
   ) is
   begin
      if P1_Payoffs'Length(1) /= P2_Payoffs'Length(1) or else 
         P1_Payoffs'Length(2) /= P2_Payoffs'Length(2) then
         raise Invalid_Matrix_Dimensions;
      end if;
      
      if P1_History'Length /= Iterations or else P2_History'Length /= Iterations then
         raise Invalid_History_Length;
      end if;
   end Validate_Inputs;

   function Calculate_Best_Response_P1 (
      Payoffs    : Payoff_Matrix;
      P2_Beliefs : Belief_Counts
   ) return Action_Index is
      Best_Act : Action_Index := Payoffs'First(1);
      Max_Exp  : Payoff_Value := -1.0e10; -- Start with a very low number
      Cur_Exp  : Payoff_Value;
   begin
      for I in Payoffs'Range(1) loop
         Cur_Exp := 0.0;
         for J in Payoffs'Range(2) loop
            Cur_Exp := Cur_Exp + Payoffs(I, J) * Payoff_Value(P2_Beliefs(J));
         end loop;
         
         if Cur_Exp > Max_Exp then
            Max_Exp := Cur_Exp;
            Best_Act := I;
         end if;
      end loop;
      return Best_Act;
   end Calculate_Best_Response_P1;

   function Calculate_Best_Response_P2 (
      Payoffs    : Payoff_Matrix;
      P1_Beliefs : Belief_Counts
   ) return Action_Index is
      Best_Act : Action_Index := Payoffs'First(2);
      Max_Exp  : Payoff_Value := -1.0e10;
      Cur_Exp  : Payoff_Value;
   begin
      for J in Payoffs'Range(2) loop
         Cur_Exp := 0.0;
         for I in Payoffs'Range(1) loop
            Cur_Exp := Cur_Exp + Payoffs(I, J) * Payoff_Value(P1_Beliefs(I));
         end loop;
         
         if Cur_Exp > Max_Exp then
            Max_Exp := Cur_Exp;
            Best_Act := J;
         end if;
      end loop;
      return Best_Act;
   end Calculate_Best_Response_P2;

   -- Helper for Softmax sampling
   function Sample_Smoothed_Action (
      Payoffs : Payoff_Matrix;
      Beliefs : Belief_Counts;
      Is_P1   : Boolean;
      Lambda  : Float
   ) return Action_Index is
      First_Bound : constant Action_Index := (if Is_P1 then Payoffs'First(1) else Payoffs'First(2));
      Last_Bound  : constant Action_Index := (if Is_P1 then Payoffs'Last(1) else Payoffs'Last(2));
      
      type Float_Array is array (Action_Index range <>) of Float;
      Exp_Payoffs : Float_Array (First_Bound .. Last_Bound) := (others => 0.0);
      Max_Exp     : Float := -1.0e10;
      Sum_Weights : Float := 0.0;
      Rand_Val    : Float;
      Cumulative  : Float := 0.0;
   begin
      -- 1. Calculate Expected Payoffs
      if Is_P1 then
         for I in Payoffs'Range(1) loop
            for J in Payoffs'Range(2) loop
               Exp_Payoffs(I) := Exp_Payoffs(I) + Float(Payoffs(I, J)) * Float(Beliefs(J));
            end loop;
            if Exp_Payoffs(I) > Max_Exp then Max_Exp := Exp_Payoffs(I); end if;
         end loop;
      else
         for J in Payoffs'Range(2) loop
            for I in Payoffs'Range(1) loop
               Exp_Payoffs(J) := Exp_Payoffs(J) + Float(Payoffs(I, J)) * Float(Beliefs(I));
            end loop;
            if Exp_Payoffs(J) > Max_Exp then Max_Exp := Exp_Payoffs(J); end if;
         end loop;
      end if;

      -- 2. Apply Softmax (subtract Max_Exp for numerical stability)
      for Idx in Exp_Payoffs'Range loop
         Exp_Payoffs(Idx) := Exp(Lambda * (Exp_Payoffs(Idx) - Max_Exp));
         Sum_Weights := Sum_Weights + Exp_Payoffs(Idx);
      end loop;

      -- 3. Sample
      Rand_Val := Ada.Numerics.Float_Random.Random(RNG) * Sum_Weights;
      for Idx in Exp_Payoffs'Range loop
         Cumulative := Cumulative + Exp_Payoffs(Idx);
         if Rand_Val <= Cumulative then
            return Idx;
         end if;
      end loop;
      
      return Exp_Payoffs'Last; -- Fallback for floating point edge cases
   end Sample_Smoothed_Action;


   -- ==========================================
   -- Core Variants Implementations
   -- ==========================================

   procedure Simultaneous_Play (
      P1_Payoffs        : in Payoff_Matrix;
      P2_Payoffs        : in Payoff_Matrix;
      Iterations        : in Positive;
      P1_Initial_Action : in Action_Index;
      P2_Initial_Action : in Action_Index;
      P1_History        : out Action_Array;
      P2_History        : out Action_Array
   ) is
      P1_Beliefs : Belief_Counts(P1_Payoffs'Range(1)) := (others => 0);
      P2_Beliefs : Belief_Counts(P2_Payoffs'Range(2)) := (others => 0);
      Next_P1    : Action_Index;
      Next_P2    : Action_Index;
   begin
      Validate_Inputs(P1_Payoffs, P2_Payoffs, Iterations, P1_History, P2_History);

      P1_History(1) := P1_Initial_Action;
      P2_History(1) := P2_Initial_Action;
      P1_Beliefs(P1_Initial_Action) := 1;
      P2_Beliefs(P2_Initial_Action) := 1;

      for T in 2 .. Iterations loop
         Next_P1 := Calculate_Best_Response_P1(P1_Payoffs, P2_Beliefs);
         Next_P2 := Calculate_Best_Response_P2(P2_Payoffs, P1_Beliefs);

         P1_History(T) := Next_P1;
         P2_History(T) := Next_P2;

         P1_Beliefs(Next_P1) := P1_Beliefs(Next_P1) + 1;
         P2_Beliefs(Next_P2) := P2_Beliefs(Next_P2) + 1;
      end loop;
   end Simultaneous_Play;


   procedure Alternating_Play (
      P1_Payoffs        : in Payoff_Matrix;
      P2_Payoffs        : in Payoff_Matrix;
      Iterations        : in Positive;
      P1_Initial_Action : in Action_Index;
      P2_Initial_Action : in Action_Index;
      P1_History        : out Action_Array;
      P2_History        : out Action_Array
   ) is
      P1_Beliefs : Belief_Counts(P1_Payoffs'Range(1)) := (others => 0);
      P2_Beliefs : Belief_Counts(P2_Payoffs'Range(2)) := (others => 0);
      Next_P1    : Action_Index;
      Next_P2    : Action_Index;
   begin
      Validate_Inputs(P1_Payoffs, P2_Payoffs, Iterations, P1_History, P2_History);

      P1_History(1) := P1_Initial_Action;
      P2_History(1) := P2_Initial_Action;
      P1_Beliefs(P1_Initial_Action) := 1;
      P2_Beliefs(P2_Initial_Action) := 1;

      for T in 2 .. Iterations loop
         -- P1 moves and updates beliefs
         Next_P1 := Calculate_Best_Response_P1(P1_Payoffs, P2_Beliefs);
         P1_History(T) := Next_P1;
         P1_Beliefs(Next_P1) := P1_Beliefs(Next_P1) + 1;

         -- P2 observes P1's new move, moves, and updates
         Next_P2 := Calculate_Best_Response_P2(P2_Payoffs, P1_Beliefs);
         P2_History(T) := Next_P2;
         P2_Beliefs(Next_P2) := P2_Beliefs(Next_P2) + 1;
      end loop;
   end Alternating_Play;


   procedure Smoothed_Play (
      P1_Payoffs        : in Payoff_Matrix;
      P2_Payoffs        : in Payoff_Matrix;
      Iterations        : in Positive;
      Lambda            : in Float;
      P1_Initial_Action : in Action_Index;
      P2_Initial_Action : in Action_Index;
      P1_History        : out Action_Array;
      P2_History        : out Action_Array
   ) is
      P1_Beliefs : Belief_Counts(P1_Payoffs'Range(1)) := (others => 0);
      P2_Beliefs : Belief_Counts(P2_Payoffs'Range(2)) := (others => 0);
      Next_P1    : Action_Index;
      Next_P2    : Action_Index;
   begin
      Validate_Inputs(P1_Payoffs, P2_Payoffs, Iterations, P1_History, P2_History);
      Ada.Numerics.Float_Random.Reset(RNG);

      P1_History(1) := P1_Initial_Action;
      P2_History(1) := P2_Initial_Action;
      P1_Beliefs(P1_Initial_Action) := 1;
      P2_Beliefs(P2_Initial_Action) := 1;

      for T in 2 .. Iterations loop
         Next_P1 := Sample_Smoothed_Action(P1_Payoffs, P2_Beliefs, True, Lambda);
         Next_P2 := Sample_Smoothed_Action(P2_Payoffs, P1_Beliefs, False, Lambda);

         P1_History(T) := Next_P1;
         P2_History(T) := Next_P2;

         P1_Beliefs(Next_P1) := P1_Beliefs(Next_P1) + 1;
         P2_Beliefs(Next_P2) := P2_Beliefs(Next_P2) + 1;
      end loop;
   end Smoothed_Play;


   procedure Inertial_Play (
      P1_Payoffs        : in Payoff_Matrix;
      P2_Payoffs        : in Payoff_Matrix;
      Iterations        : in Positive;
      Inertia_Prob      : in Probability;
      P1_Initial_Action : in Action_Index;
      P2_Initial_Action : in Action_Index;
      P1_History        : out Action_Array;
      P2_History        : out Action_Array
   ) is
      P1_Beliefs : Belief_Counts(P1_Payoffs'Range(1)) := (others => 0);
      P2_Beliefs : Belief_Counts(P2_Payoffs'Range(2)) := (others => 0);
      Best_P1    : Action_Index;
      Best_P2    : Action_Index;
   begin
      Validate_Inputs(P1_Payoffs, P2_Payoffs, Iterations, P1_History, P2_History);
      Ada.Numerics.Float_Random.Reset(RNG);

      P1_History(1) := P1_Initial_Action;
      P2_History(1) := P2_Initial_Action;
      P1_Beliefs(P1_Initial_Action) := 1;
      P2_Beliefs(P2_Initial_Action) := 1;

      for T in 2 .. Iterations loop
         Best_P1 := Calculate_Best_Response_P1(P1_Payoffs, P2_Beliefs);
         Best_P2 := Calculate_Best_Response_P2(P2_Payoffs, P1_Beliefs);

         -- Apply Inertia: Keep previous action if RNG falls under inertia probability
         if Ada.Numerics.Float_Random.Random(RNG) < Float(Inertia_Prob) then
            P1_History(T) := P1_History(T - 1);
         else
            P1_History(T) := Best_P1;
         end if;

         if Ada.Numerics.Float_Random.Random(RNG) < Float(Inertia_Prob) then
            P2_History(T) := P2_History(T - 1);
         else
            P2_History(T) := Best_P2;
         end if;

         P1_Beliefs(P1_History(T)) := P1_Beliefs(P1_History(T)) + 1;
         P2_Beliefs(P2_History(T)) := P2_Beliefs(P2_History(T)) + 1;
      end loop;
   end Inertial_Play;

end Fictitious_Play;
