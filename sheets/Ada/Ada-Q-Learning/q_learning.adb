package body Q_Learning is

   function Max_Q_Value
     (Table : Q_Table;
      State : State_Type) return Value_Type
   is
      --  Initialize with the value of the first action to guarantee a baseline
      Max_Val : Value_Type := Table (State, Action_Type'First);
   begin
      --  Iterate through all actions to find the highest Q-value
      for A in Action_Type loop
         if Table (State, A) > Max_Val then
            Max_Val := Table (State, A);
         end if;
      end loop;
      return Max_Val;
   end Max_Q_Value;

   function Best_Action
     (Table : Q_Table;
      State : State_Type) return Action_Type
   is
      Max_Val  : Value_Type := Table (State, Action_Type'First);
      Best_Act : Action_Type := Action_Type'First;
   begin
      --  Iterate through all actions to find the action yielding the highest Q-value
      for A in Action_Type loop
         if Table (State, A) > Max_Val then
            Max_Val := Table (State, A);
            Best_Act := A;
         end if;
      end loop;
      return Best_Act;
   end Best_Action;

   procedure Update_Q_Value
     (Table           : in out Q_Table;
      State           : in State_Type;
      Action          : in Action_Type;
      Reward          : in Value_Type;
      Next_State      : in State_Type;
      Learning_Rate   : in Probability;
      Discount_Factor : in Probability)
   is
      Max_Next_Q : constant Value_Type := Max_Q_Value (Table, Next_State);
      Current_Q  : constant Value_Type := Table (State, Action);
      New_Q      : Value_Type;
   begin
      --  Standard Q-learning equation:
      --  Q(S,A) <- Q(S,A) + alpha * [R + gamma * max_a Q(S',a) - Q(S,A)]
      New_Q := Current_Q + Learning_Rate * (Reward + Discount_Factor * Max_Next_Q - Current_Q);
      Table (State, Action) := New_Q;
   end Update_Q_Value;

   procedure Update_Double_Q_Value
     (Table_A         : in out Q_Table;
      Table_B         : in out Q_Table;
      State           : in State_Type;
      Action          : in Action_Type;
      Reward          : in Value_Type;
      Next_State      : in State_Type;
      Learning_Rate   : in Probability;
      Discount_Factor : in Probability;
      Update_A        : in Boolean)
   is
      Best_Next_Action : Action_Type;
      Current_Q        : Value_Type;
      Target_Q         : Value_Type;
      New_Q            : Value_Type;
   begin
      if Update_A then
         --  Select action using Table A
         Best_Next_Action := Best_Action (Table_A, Next_State);
         Current_Q        := Table_A (State, Action);
         
         --  Evaluate action using Table B
         Target_Q         := Table_B (Next_State, Best_Next_Action);

         --  Update Table A
         New_Q := Current_Q + Learning_Rate * (Reward + Discount_Factor * Target_Q - Current_Q);
         Table_A (State, Action) := New_Q;
      else
         --  Select action using Table B
         Best_Next_Action := Best_Action (Table_B, Next_State);
         Current_Q        := Table_B (State, Action);
         
         --  Evaluate action using Table A
         Target_Q         := Table_A (Next_State, Best_Next_Action);

         --  Update Table B
         New_Q := Current_Q + Learning_Rate * (Reward + Discount_Factor * Target_Q - Current_Q);
         Table_B (State, Action) := New_Q;
      end if;
   end Update_Double_Q_Value;

   function Epsilon_Greedy_Action
     (Table         : Q_Table;
      State         : State_Type;
      Epsilon       : Probability;
      Random_Value  : Probability;
      Random_Action : Action_Type) return Action_Type
   is
   begin
      --  If the random threshold is below epsilon, we explore by taking a random action.
      --  Otherwise, we exploit by taking the currently known best action.
      if Random_Value < Epsilon then
         return Random_Action;
      else
         return Best_Action (Table, State);
      end if;
   end Epsilon_Greedy_Action;

end Q_Learning;
