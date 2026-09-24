package body Darwin_Godel_Machine is

   function Create_Agent
     (Id   : Positive;
      Fit  : Fitness_Value;
      Comp : Complexity_Value) return Agent_State
   is
   begin
      return (Id => Id, Fitness => Fit, Complexity => Comp, Level => None);
   end Create_Agent;


   function Evaluate (Agent : Agent_State; Env : Environment_State) return Fitness_Value is
      Penalty : Fitness_Value := 0.0;
   begin
      case Env is
         when Static_Env =>
            -- In static environments, nominal capability maps directly to fitness
            return Agent.Fitness;

         when Dynamic_Env =>
            -- In dynamic environments, high code complexity produces brittleness.
            -- This acts as an evolutionary selection pressure against bloat.
            if Agent.Complexity > 100 then
               declare
                  -- Safe conversion: Complexity > 100 ensures positive reduction
                  Reduction : constant Float := Float (Agent.Complexity - 100) * 0.1;
               begin
                  if Float (Agent.Fitness) > Reduction then
                     Penalty := Fitness_Value (Reduction);
                  else
                     Penalty := Agent.Fitness;
                  end if;
               end;
            end if;
            return Agent.Fitness - Penalty;
      end case;
   end Evaluate;


   function Verify_Strict (Base, Candidate : Agent_State; Env : Environment_State) return Boolean is
      Base_Eval : constant Fitness_Value := Evaluate (Base, Env);
      Cand_Eval : constant Fitness_Value := Evaluate (Candidate, Env);
   begin
      -- Gödel limit: Strict proof requires objective improvement.
      if Cand_Eval > Base_Eval then
         -- Bound the complexity increase safely preventing constraint overflow/underflow
         if Candidate.Complexity <= Base.Complexity then
            return True; 
         else
            if Candidate.Complexity - Base.Complexity <= 50 then
               return True;
            end if;
         end if;
      end if;
      
      return False;
   end Verify_Strict;


   function Verify_Heuristic (Base, Candidate : Agent_State; Env : Environment_State) return Boolean is
      Base_Eval : constant Fitness_Value := Evaluate (Base, Env);
      Cand_Eval : constant Fitness_Value := Evaluate (Candidate, Env);
   begin
      -- Heuristic verification skips complexity proof and merely enforces capability gains
      return Cand_Eval > Base_Eval;
   end Verify_Heuristic;


   function Evolve_Exhaustive
     (Base       : Agent_State;
      Candidates : Agent_Array;
      Env        : Environment_State) return Agent_State
   is
      Best_Agent : Agent_State := Base;
      Best_Eval  : Fitness_Value := Evaluate (Base, Env);
      Cand_Eval  : Fitness_Value;
   begin
      if Candidates'Length = 0 then
         raise Population_Empty_Error with "Candidates array is empty";
      end if;

      for I in Candidates'Range loop
         -- Darwinian selection governed by Strict Gödel Verification
         if Verify_Strict (Base, Candidates (I), Env) then
            Cand_Eval := Evaluate (Candidates (I), Env);
            if Cand_Eval > Best_Eval then
               Best_Agent := Candidates (I);
               Best_Agent.Level := Strict_Proof;
               Best_Eval  := Cand_Eval;
            end if;
         end if;
      end loop;

      return Best_Agent;
   end Evolve_Exhaustive;


   function Evolve_Preemptive
     (Base       : Agent_State;
      Candidates : Agent_Array;
      Env        : Environment_State;
      Threshold  : Fitness_Value) return Agent_State
   is
      Cand_Eval : Fitness_Value;
   begin
      if Candidates'Length = 0 then
         raise Population_Empty_Error with "Candidates array is empty";
      end if;

      if Threshold <= 0.0 then
         raise Invalid_Threshold with "Threshold must be strictly positive";
      end if;

      for I in Candidates'Range loop
         if Verify_Heuristic (Base, Candidates (I), Env) then
            Cand_Eval := Evaluate (Candidates (I), Env);
            
            -- Prevent overflow when calculating target threshold
            declare
               Base_Eval : constant Fitness_Value := Evaluate (Base, Env);
               Target    : Fitness_Value;
            begin
               if Fitness_Value'Last - Base_Eval >= Threshold then
                  Target := Base_Eval + Threshold;
               else
                  Target := Fitness_Value'Last;
               end if;

               if Cand_Eval >= Target then
                  declare
                     Result : Agent_State := Candidates (I);
                  begin
                     Result.Level := Heuristic;
                     return Result;
                  end;
               end if;
            end;
         end if;
      end loop;

      return Base;
   end Evolve_Preemptive;


   function Is_Valid_Transition (Base, Next : Agent_State) return Boolean is
   begin
      -- A valid step in open-ended evolution either stays flat (identity) or progresses
      return Next.Fitness >= Base.Fitness or else Next.Id = Base.Id;
   end Is_Valid_Transition;

end Darwin_Godel_Machine;
