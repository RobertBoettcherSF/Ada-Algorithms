package body Reinforcement_Learning is

   procedure Initialize (Table : out Q_Table) is
   begin
      -- Safely iterate over bounds, doing nothing if array is empty
      for S in Table'Range (1) loop
         for A in Table'Range (2) loop
            Table (S, A) := 0.0;
         end loop;
      end loop;
   end Initialize;

   function Get_Best_Action (Table : in Q_Table; State : in State_ID) return Action_ID is
      Best_A : Action_ID;
      Max_Q  : Q_Value;
   begin
      -- Redundant explicit checks to ensure safety even if compiled without assertions
      if Table'Length (1) = 0 or else State not in Table'Range (1) then
         raise Invalid_State;
      end if;
      if Table'Length (2) = 0 then
         raise Invalid_Action;
      end if;

      Best_A := Table'First (2);
      Max_Q  := Table (State, Best_A);

      for A in Table'First (2) .. Table'Last (2) loop
         if Table (State, A) > Max_Q then
            Max_Q  := Table (State, A);
            Best_A := A;
         end if;
      end loop;
      return Best_A;
   end Get_Best_Action;

   function Get_Max_Q (Table : in Q_Table; State : in State_ID) return Q_Value is
      Max_Q : Q_Value;
   begin
      if Table'Length (1) = 0 or else State not in Table'Range (1) then
         raise Invalid_State;
      end if;
      if Table'Length (2) = 0 then
         raise Invalid_Action;
      end if;

      Max_Q := Table (State, Table'First (2));
      for A in Table'First (2) .. Table'Last (2) loop
         if Table (State, A) > Max_Q then
            Max_Q := Table (State, A);
         end if;
      end loop;
      return Max_Q;
   end Get_Max_Q;

   procedure Update_Q_Learning
     (Table         : in out Q_Table;
      Current_State : in State_ID;
      Action        : in Action_ID;
      Reward        : in Reward_Type;
      Next_State    : in State_ID;
      Alpha         : in Probability;
      Gamma         : in Probability)
   is
      Max_Next_Q : Q_Value;
      Current_Q  : Q_Value;
      Target     : Q_Value;
   begin
      if Current_State not in Table'Range (1) or else
         Next_State not in Table'Range (1)
      then
         raise Invalid_State;
      end if;
      if Action not in Table'Range (2) then
         raise Invalid_Action;
      end if;

      Max_Next_Q := Get_Max_Q (Table, Next_State);
      Current_Q  := Table (Current_State, Action);
      
      -- Bellman Equation application for Q-Learning
      Target := Q_Value (Reward) + Q_Value (Gamma) * Max_Next_Q;

      Table (Current_State, Action) := Current_Q + Q_Value (Alpha) * (Target - Current_Q);
   end Update_Q_Learning;

   procedure Update_SARSA
     (Table         : in out Q_Table;
      Current_State : in State_ID;
      Action        : in Action_ID;
      Reward        : in Reward_Type;
      Next_State    : in State_ID;
      Next_Action   : in Action_ID;
      Alpha         : in Probability;
      Gamma         : in Probability)
   is
      Next_Q     : Q_Value;
      Current_Q  : Q_Value;
      Target     : Q_Value;
   begin
      if Current_State not in Table'Range (1) or else
         Next_State not in Table'Range (1)
      then
         raise Invalid_State;
      end if;
      if Action not in Table'Range (2) or else
         Next_Action not in Table'Range (2)
      then
         raise Invalid_Action;
      end if;

      Next_Q    := Table (Next_State, Next_Action);
      Current_Q := Table (Current_State, Action);
      
      -- Bellman Equation application for SARSA
      Target := Q_Value (Reward) + Q_Value (Gamma) * Next_Q;

      Table (Current_State, Action) := Current_Q + Q_Value (Alpha) * (Target - Current_Q);
   end Update_SARSA;

   function Almost_Equal (Left, Right : Q_Value; Epsilon : Q_Value := 0.00001) return Boolean is
   begin
      return abs (Left - Right) < Epsilon;
   end Almost_Equal;

end Reinforcement_Learning;
