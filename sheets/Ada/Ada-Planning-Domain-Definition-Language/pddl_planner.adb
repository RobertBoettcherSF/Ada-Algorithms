with Ada.Containers.Doubly_Linked_Lists;
with Ada.Containers.Ordered_Sets;

package body PDDL_Planner is

   ----------------
   -- Make_State --
   ----------------
   function Make_State (Props : Proposition_Array) return State is
      S : State := Empty_State;
   begin
      for P of Props loop
         S (P) := True;
      end loop;
      return S;
   end Make_State;

   -------------------
   -- Is_Applicable --
   -------------------
   function Is_Applicable (Current : State; Act : Action) return Boolean is
   begin
      --  All positive preconditions must be True in Current
      if (Current and Act.Pre_Pos) /= Act.Pre_Pos then
         return False;
      end if;

      --  All negative preconditions must be False in Current
      if ((not Current) and Act.Pre_Neg) /= Act.Pre_Neg then
         return False;
      end if;

      return True;
   end Is_Applicable;

   ------------------
   -- Apply_Action --
   ------------------
   function Apply_Action (Current : State; Act : Action) return State is
      Result : State;
   begin
      if not Is_Applicable (Current, Act) then
         raise Invalid_Action with "Action not applicable in current state";
      end if;

      --  Bitwise implementation of STRIPS logic
      Result := Current and (not Act.Eff_Del);
      Result := Result or Act.Eff_Add;
      
      return Result;
   end Apply_Action;

   -----------------
   -- Is_Goal_Met --
   -----------------
   function Is_Goal_Met (Current : State; Goal_Pos, Goal_Neg : State) return Boolean is
   begin
      return (Current and Goal_Pos) = Goal_Pos and then
             ((not Current) and Goal_Neg) = Goal_Neg;
   end Is_Goal_Met;

   -----------------------
   -- Search Structures --
   -----------------------
   type Search_Node is record
      Current : State;
      Path    : Plan;
   end record;

   package Node_Queues is new Ada.Containers.Doubly_Linked_Lists (Element_Type => Search_Node);
   
   --  Ada naturally provides "<" for 1D arrays of discrete types (like Boolean),
   --  so we can directly instantiate Ordered_Sets with State.
   package Visited_Sets is new Ada.Containers.Ordered_Sets (Element_Type => State);

   ---------------
   -- Solve_BFS --
   ---------------
   function Solve_BFS (Dom : Domain; Prob : Problem) return Plan is
      Queue        : Node_Queues.List;
      Visited      : Visited_Sets.Set;
      Current_Node : Search_Node;
   begin
      if Is_Goal_Met (Prob.Initial, Prob.Goal_Pos, Prob.Goal_Neg) then
         return Empty_Plan;
      end if;

      Queue.Append ((Current => Prob.Initial, Path => Empty_Plan));
      Visited.Insert (Prob.Initial);

      while not Queue.Is_Empty loop
         Current_Node := Queue.First_Element;
         Queue.Delete_First;

         for Act of Dom loop
            if Is_Applicable (Current_Node.Current, Act) then
               declare
                  Next_State : constant State := Apply_Action (Current_Node.Current, Act);
               begin
                  if not Visited.Contains (Next_State) then
                     if Is_Goal_Met (Next_State, Prob.Goal_Pos, Prob.Goal_Neg) then
                        declare
                           Final_Path : Plan := Current_Node.Path;
                        begin
                           Final_Path.Steps.Append (Act.ID);
                           return Final_Path;
                        end;
                     end if;

                     Visited.Insert (Next_State);
                     declare
                        Next_Path : Plan := Current_Node.Path;
                     begin
                        Next_Path.Steps.Append (Act.ID);
                        Queue.Append ((Current => Next_State, Path => Next_Path));
                     end;
                  end if;
               end;
            end if;
         end loop;
      end loop;

      raise No_Plan_Found with "BFS exhausted search space without finding a plan";
   end Solve_BFS;

   ---------------
   -- Solve_DFS --
   ---------------
   function Solve_DFS (Dom : Domain; Prob : Problem; Max_Depth : Natural := 20) return Plan is
      Visited      : Visited_Sets.Set;
      Current_Plan : Plan;
      Found        : Boolean := False;

      procedure DFS (Current : State; Depth : Natural) is
      begin
         if Found then
            return;
         end if;

         if Is_Goal_Met (Current, Prob.Goal_Pos, Prob.Goal_Neg) then
            Found := True;
            return;
         end if;

         if Depth >= Max_Depth then
            return;
         end if;

         for Act of Dom loop
            if Is_Applicable (Current, Act) then
               declare
                  Next_State : constant State := Apply_Action (Current, Act);
               begin
                  if not Visited.Contains (Next_State) then
                     Visited.Insert (Next_State);
                     Current_Plan.Steps.Append (Act.ID);

                     DFS (Next_State, Depth + 1);

                     if Found then
                        return;
                     end if;

                     --  Backtrack for plan reconstruction
                     Current_Plan.Steps.Delete_Last;
                     
                     --  Note: Standard state-space reachability DFS leaves states in 
                     --  Visited to avoid cycles and redundant long paths.
                  end if;
               end;
            end if;
         end loop;
      end DFS;

   begin
      Visited.Insert (Prob.Initial);
      DFS (Prob.Initial, 0);

      if not Found then
         raise No_Plan_Found with "DFS failed to find a plan within depth limit";
      end if;

      return Current_Plan;
   end Solve_DFS;

end PDDL_Planner;
