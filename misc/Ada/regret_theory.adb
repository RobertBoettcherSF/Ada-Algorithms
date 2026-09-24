-- regret_theory.adb
package body Regret_Theory is

   ---------------------------
   -- Regret_From_Payoffs   --
   ---------------------------
   function Regret_From_Payoffs (Payoffs : Matrix) return Matrix is
      Result  : Matrix (Payoffs'Range (1), Payoffs'Range (2));
      Max_Val : Payoff_Value;
   begin
      if Payoffs'Length (1) = 0 or Payoffs'Length (2) = 0 then
         raise Empty_Matrix_Error;
      end if;

      -- Iterate over each state of nature (columns)
      for J in Payoffs'Range (2) loop
         -- 1. Find max payoff in the current state
         Max_Val := Payoffs (Payoffs'First (1), J);
         for I in Payoffs'Range (1) loop
            if Payoffs (I, J) > Max_Val then
               Max_Val := Payoffs (I, J);
            end if;
         end loop;
         
         -- 2. Calculate regret for each action in the current state
         for I in Payoffs'Range (1) loop
            Result (I, J) := Max_Val - Payoffs (I, J);
         end loop;
      end loop;

      return Result;
   end Regret_From_Payoffs;

   ---------------------------
   -- Regret_From_Costs     --
   ---------------------------
   function Regret_From_Costs (Costs : Matrix) return Matrix is
      Result  : Matrix (Costs'Range (1), Costs'Range (2));
      Min_Val : Payoff_Value;
   begin
      if Costs'Length (1) = 0 or Costs'Length (2) = 0 then
         raise Empty_Matrix_Error;
      end if;

      -- Iterate over each state of nature (columns)
      for J in Costs'Range (2) loop
         -- 1. Find min cost in the current state
         Min_Val := Costs (Costs'First (1), J);
         for I in Costs'Range (1) loop
            if Costs (I, J) < Min_Val then
               Min_Val := Costs (I, J);
            end if;
         end loop;
         
         -- 2. Calculate regret for each action in the current state
         for I in Costs'Range (1) loop
            Result (I, J) := Costs (I, J) - Min_Val;
         end loop;
      end loop;

      return Result;
   end Regret_From_Costs;

   ---------------------------
   -- Max_Regret_For_Action --
   ---------------------------
   function Max_Regret_For_Action (Regrets : Matrix; Action : Positive) return Payoff_Value is
      Max_Regret : Payoff_Value := Regrets (Action, Regrets'First (2));
   begin
      for J in Regrets'Range (2) loop
         if Regrets (Action, J) > Max_Regret then
            Max_Regret := Regrets (Action, J);
         end if;
      end loop;
      return Max_Regret;
   end Max_Regret_For_Action;

   ---------------------------
   -- Minimax_Regret        --
   ---------------------------
   procedure Minimax_Regret 
     (Regrets     : in Matrix; 
      Best_Action : out Positive; 
      Min_Max     : out Payoff_Value) 
   is
      Current_Max    : Payoff_Value;
      Global_Min_Max : Payoff_Value := Payoff_Value'Last;
      Best_I         : Positive     := Regrets'First (1);
   begin
      if Regrets'Length (1) = 0 or Regrets'Length (2) = 0 then
         raise Empty_Matrix_Error;
      end if;

      -- Iterate over each possible Action (rows)
      for I in Regrets'Range (1) loop
         Current_Max := Max_Regret_For_Action (Regrets, I);
         
         -- Check if this action provides a smaller maximum regret
         if Current_Max < Global_Min_Max then
            Global_Min_Max := Current_Max;
            Best_I := I;
         end if;
      end loop;

      Best_Action := Best_I;
      Min_Max := Global_Min_Max;
   end Minimax_Regret;

end Regret_Theory;
