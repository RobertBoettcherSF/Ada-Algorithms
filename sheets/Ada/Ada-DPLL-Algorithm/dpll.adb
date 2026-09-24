package body DPLL is

   ----------------------------------------------------------------------------
   --  Helper Functions
   ----------------------------------------------------------------------------

   function Make_Pos (V : Variable_Id) return Literal is
   begin
      return Literal'(Var => V, Sign => Positive_Sign);
   end Make_Pos;

   function Make_Neg (V : Variable_Id) return Literal is
   begin
      return Literal'(Var => V, Sign => Negative_Sign);
   end Make_Neg;

   function Negate (L : Literal) return Literal is
   begin
      if L.Sign = Positive_Sign then
         return Literal'(Var => L.Var, Sign => Negative_Sign);
      else
         return Literal'(Var => L.Var, Sign => Positive_Sign);
      end if;
   end Negate;

   function Is_Valid_Formula (F : Formula) return Boolean is
   begin
      for I in 1 .. F.Num_Clauses loop
         for J in 1 .. F.Clauses (I).Length loop
            if F.Clauses (I).Lits (J).Var > F.Num_Vars then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Valid_Formula;

   function Evaluate_Clause (C : Clause; M : Valuation) return Variable_State is
      Has_Unassigned : Boolean := False;
   begin
      for I in 1 .. C.Length loop
         declare
            Lit : constant Literal := C.Lits (I);
            Val : constant Variable_State := M (Lit.Var);
         begin
            if Lit.Sign = Positive_Sign then
               if Val = Assigned_True then
                  return Assigned_True;
               elsif Val = Unassigned then
                  Has_Unassigned := True;
               end if;
            else
               if Val = Assigned_False then
                  return Assigned_True;
               elsif Val = Unassigned then
                  Has_Unassigned := True;
               end if;
            end if;
         end;
      end loop;

      if Has_Unassigned then
         return Unassigned;
      else
         return Assigned_False;
      end if;
   end Evaluate_Clause;

   function Is_Model (F : Formula; M : Valuation) return Boolean is
   begin
      for I in 1 .. F.Num_Clauses loop
         if Evaluate_Clause (F.Clauses (I), M) /= Assigned_True then
            return False;
         end if;
      end loop;
      return True;
   end Is_Model;

   ----------------------------------------------------------------------------
   --  Internal Formula Manipulation
   ----------------------------------------------------------------------------

   procedure Assign_And_Simplify
     (F_In     : Formula;
      V        : Variable_Id;
      Val      : Variable_State;
      F_Out    : out Formula;
      Conflict : out Boolean)
   is
      Out_Clause_Idx : Clause_Count := 0;
      Temp_Clauses   : Clause_Array (1 .. F_In.Num_Clauses);
   begin
      Conflict := False;

      for C_Idx in 1 .. F_In.Num_Clauses loop
         declare
            C : constant Clause := F_In.Clauses (C_Idx);
            Clause_Satisfied : Boolean := False;
            Kept_Literals    : Literal_Array (1 .. C.Length);
            Kept_Count       : Literal_Count := 0;
         begin
            for L_Idx in 1 .. C.Length loop
               declare
                  Lit : constant Literal := C.Lits (L_Idx);
               begin
                  if Lit.Var = V then
                     if (Lit.Sign = Positive_Sign and then Val = Assigned_True) or else
                        (Lit.Sign = Negative_Sign and then Val = Assigned_False)
                     then
                        Clause_Satisfied := True;
                        exit;
                     end if;
                  else
                     Kept_Count := Kept_Count + 1;
                     Kept_Literals (Kept_Count) := Lit;
                  end if;
               end;
            end loop;

            if not Clause_Satisfied then
               if Kept_Count = 0 then
                  Conflict := True;
                  F_Out := Formula'(
                     Num_Clauses => 0,
                     Num_Vars    => F_In.Num_Vars,
                     Clauses     => Temp_Clauses (1 .. 0)
                  );
                  return;
               end if;
               Out_Clause_Idx := Out_Clause_Idx + 1;
               Temp_Clauses (Out_Clause_Idx) := Clause'(
                  Length => Kept_Count,
                  Lits   => Kept_Literals (1 .. Kept_Count)
               );
            end if;
         end;
      end loop;

      F_Out := Formula'(
         Num_Clauses => Out_Clause_Idx,
         Num_Vars    => F_In.Num_Vars,
         Clauses     => Temp_Clauses (1 .. Out_Clause_Idx)
      );
   end Assign_And_Simplify;

   ----------------------------------------------------------------------------
   --  Inference Steps: Unit Propagation & Pure Literal Elimination
   ----------------------------------------------------------------------------

   procedure Apply_Unit_Propagation
     (F_Current : in out Formula;
      Model     : in out Valuation;
      Conflict  : out Boolean;
      Changed   : out Boolean)
   is
      Found_Unit : Boolean;
   begin
      Conflict := False;
      Changed := False;

      loop
         Found_Unit := False;

         for I in 1 .. F_Current.Num_Clauses loop
            if F_Current.Clauses (I).Length = 0 then
               Conflict := True;
               return;
            end if;
         end loop;

         for I in 1 .. F_Current.Num_Clauses loop
            if F_Current.Clauses (I).Length = 1 then
               declare
                  Unit_Lit : constant Literal := F_Current.Clauses (I).Lits (1);
                  New_Val  : constant Variable_State :=
                    (if Unit_Lit.Sign = Positive_Sign then Assigned_True else Assigned_False);
                  Next_F   : Formula;
               begin
                  if Model (Unit_Lit.Var) /= Unassigned and then Model (Unit_Lit.Var) /= New_Val then
                     Conflict := True;
                     return;
                  end if;

                  Model (Unit_Lit.Var) := New_Val;
                  Assign_And_Simplify (F_Current, Unit_Lit.Var, New_Val, Next_F, Conflict);
                  F_Current := Next_F;
                  Changed := True;
                  Found_Unit := True;

                  if Conflict then
                     return;
                  end if;

                  exit;
               end;
            end if;
         end loop;

         exit when not Found_Unit;
      end loop;
   end Apply_Unit_Propagation;

   procedure Apply_Pure_Literal_Rule
     (F_Current : in out Formula;
      Model     : in out Valuation;
      Conflict  : out Boolean;
      Changed   : out Boolean)
   is
      type Sign_Presence is record
         Has_Pos : Boolean := False;
         Has_Neg : Boolean := False;
      end record;

      type Presence_Map is array (Variable_Id) of Sign_Presence;
      Occurrences : Presence_Map;
      Applied_Any : Boolean := False;
   begin
      Conflict := False;
      Changed := False;

      for I in 1 .. F_Current.Num_Clauses loop
         for J in 1 .. F_Current.Clauses (I).Length loop
            declare
               Lit : constant Literal := F_Current.Clauses (I).Lits (J);
            begin
               if Lit.Sign = Positive_Sign then
                  Occurrences (Lit.Var).Has_Pos := True;
               else
                  Occurrences (Lit.Var).Has_Neg := True;
               end if;
            end;
         end loop;
      end loop;

      for V in 1 .. F_Current.Num_Vars loop
         if Model (V) = Unassigned then
            if Occurrences (V).Has_Pos and not Occurrences (V).Has_Neg then
               Model (V) := Assigned_True;
               declare
                  Next_F : Formula;
               begin
                  Assign_And_Simplify (F_Current, V, Assigned_True, Next_F, Conflict);
                  F_Current := Next_F;
                  Applied_Any := True;
                  if Conflict then
                     Changed := True;
                     return;
                  end if;
               end;
            elsif Occurrences (V).Has_Neg and not Occurrences (V).Has_Pos then
               Model (V) := Assigned_False;
               declare
                  Next_F : Formula;
               begin
                  Assign_And_Simplify (F_Current, V, Assigned_False, Next_F, Conflict);
                  F_Current := Next_F;
                  Applied_Any := True;
                  if Conflict then
                     Changed := True;
                     return;
                  end if;
               end;
            end if;
         end if;
      end loop;

      Changed := Applied_Any;
   end Apply_Pure_Literal_Rule;

   ----------------------------------------------------------------------------
   --  Branching Heuristics
   ----------------------------------------------------------------------------

   function Select_Branch_Variable
     (F         : Formula;
      Model     : Valuation;
      Heuristic : Branching_Heuristic) return Variable_Id
   is
   begin
      case Heuristic is
         when First_Unassigned =>
            for V in 1 .. F.Num_Vars loop
               if Model (V) = Unassigned then
                  return V;
               end if;
            end loop;

         when Max_Occurrences =>
            declare
               type Count_Array is array (Variable_Id) of Natural;
               Counts    : Count_Array := [others => 0];
               Best_Var  : Variable_Id := 1;
               Max_Count : Integer := -1;
            begin
               for I in 1 .. F.Num_Clauses loop
                  for J in 1 .. F.Clauses (I).Length loop
                     declare
                        V : constant Variable_Id := F.Clauses (I).Lits (J).Var;
                     begin
                        if Model (V) = Unassigned then
                           Counts (V) := Counts (V) + 1;
                        end if;
                     end;
                  end loop;
               end loop;

               for V in 1 .. F.Num_Vars loop
                  if Model (V) = Unassigned and then Integer (Counts (V)) > Max_Count then
                     Max_Count := Integer (Counts (V));
                     Best_Var  := V;
                  end if;
               end loop;

               return Best_Var;
            end;

         when MOMS =>
            declare
               Min_Len : Literal_Count := Literal_Count'Last;
               type Count_Array is array (Variable_Id) of Natural;
               Counts    : Count_Array := [others => 0];
               Best_Var  : Variable_Id := 1;
               Max_Count : Integer := -1;
            begin
               for I in 1 .. F.Num_Clauses loop
                  if F.Clauses (I).Length < Min_Len and F.Clauses (I).Length > 0 then
                     Min_Len := F.Clauses (I).Length;
                  end if;
               end loop;

               for I in 1 .. F.Num_Clauses loop
                  if F.Clauses (I).Length = Min_Len then
                     for J in 1 .. F.Clauses (I).Length loop
                        declare
                           V : constant Variable_Id := F.Clauses (I).Lits (J).Var;
                        begin
                           if Model (V) = Unassigned then
                              Counts (V) := Counts (V) + 1;
                           end if;
                        end;
                     end loop;
                  end if;
               end loop;

               for V in 1 .. F.Num_Vars loop
                  if Model (V) = Unassigned and then Integer (Counts (V)) > Max_Count then
                     Max_Count := Integer (Counts (V));
                     Best_Var  := V;
                  end if;
               end loop;

               if Max_Count >= 0 then
                  return Best_Var;
               else
                  for V in 1 .. F.Num_Vars loop
                     if Model (V) = Unassigned then
                        return V;
                     end if;
                  end loop;
               end if;
            end;
      end case;

      return 1;
   end Select_Branch_Variable;

   ----------------------------------------------------------------------------
   --  Core Recursive Solver
   ----------------------------------------------------------------------------

   function Solve_Internal
     (F                : Formula;
      Current_Model    : Valuation;
      Use_Pure_Literal : Boolean;
      Heuristic        : Branching_Heuristic) return Solver_Result
   is
      Work_F     : Formula := F;
      Work_Model : Valuation := Current_Model;
      Conflict   : Boolean := False;
      Changed    : Boolean;
   begin
      loop
         Apply_Unit_Propagation (Work_F, Work_Model, Conflict, Changed);
         if Conflict then
            return Solver_Result'(Status => Unsatisfiable);
         end if;

         if Use_Pure_Literal then
            declare
               Pure_Changed : Boolean;
            begin
               Apply_Pure_Literal_Rule (Work_F, Work_Model, Conflict, Pure_Changed);
               if Conflict then
                  return Solver_Result'(Status => Unsatisfiable);
               end if;
               Changed := Changed or Pure_Changed;
            end;
         end if;

         exit when not Changed;
      end loop;

      if Work_F.Num_Clauses = 0 then
         for V in 1 .. Work_F.Num_Vars loop
            if Work_Model (V) = Unassigned then
               Work_Model (V) := Assigned_True;
            end if;
         end loop;
         return Solver_Result'(Status => Satisfiable, Model => Work_Model);
      end if;

      for I in 1 .. Work_F.Num_Clauses loop
         if Work_F.Clauses (I).Length = 0 then
            return Solver_Result'(Status => Unsatisfiable);
         end if;
      end loop;

      declare
         Branch_Var : constant Variable_Id := Select_Branch_Variable (Work_F, Work_Model, Heuristic);
         Branch_F   : Formula;
         Res        : Solver_Result;
      begin
         Assign_And_Simplify (Work_F, Branch_Var, Assigned_True, Branch_F, Conflict);
         if not Conflict then
            declare
               Next_Model : Valuation := Work_Model;
            begin
               Next_Model (Branch_Var) := Assigned_True;
               Res := Solve_Internal (Branch_F, Next_Model, Use_Pure_Literal, Heuristic);
               if Res.Status = Satisfiable then
                  return Res;
               end if;
            end;
         end if;

         Assign_And_Simplify (Work_F, Branch_Var, Assigned_False, Branch_F, Conflict);
         if not Conflict then
            declare
               Next_Model : Valuation := Work_Model;
            begin
               Next_Model (Branch_Var) := Assigned_False;
               Res := Solve_Internal (Branch_F, Next_Model, Use_Pure_Literal, Heuristic);
               if Res.Status = Satisfiable then
                  return Res;
               end if;
            end;
         end if;

         return Solver_Result'(Status => Unsatisfiable);
      end;
   end Solve_Internal;

   ----------------------------------------------------------------------------
   --  Public Subprogram Implementations
   ----------------------------------------------------------------------------

   function Solve_DPLL
     (F         : Formula;
      Heuristic : Branching_Heuristic := First_Unassigned) return Solver_Result
   is
      Initial_Model : constant Valuation := [others => Unassigned];
   begin
      if not Is_Valid_Formula (F) then
         raise Invalid_Formula_Error;
      end if;
      return Solve_Internal (F, Initial_Model, Use_Pure_Literal => True, Heuristic => Heuristic);
   end Solve_DPLL;

   function Solve_Without_Pure_Literal
     (F         : Formula;
      Heuristic : Branching_Heuristic := First_Unassigned) return Solver_Result
   is
      Initial_Model : constant Valuation := [others => Unassigned];
   begin
      if not Is_Valid_Formula (F) then
         raise Invalid_Formula_Error;
      end if;
      return Solve_Internal (F, Initial_Model, Use_Pure_Literal => False, Heuristic => Heuristic);
   end Solve_Without_Pure_Literal;

   function Unit_Propagation_Only (F : Formula) return Solver_Result is
      Work_F     : Formula := F;
      Work_Model : Valuation := [others => Unassigned];
      Conflict   : Boolean := False;
      Changed    : Boolean := False;
   begin
      if not Is_Valid_Formula (F) then
         raise Invalid_Formula_Error;
      end if;

      Apply_Unit_Propagation (Work_F, Work_Model, Conflict, Changed);

      if Conflict then
         return Solver_Result'(Status => Unsatisfiable);
      elsif Work_F.Num_Clauses = 0 then
         for V in 1 .. Work_F.Num_Vars loop
            if Work_Model (V) = Unassigned then
               Work_Model (V) := Assigned_True;
            end if;
         end loop;
         return Solver_Result'(Status => Satisfiable, Model => Work_Model);
      else
         return Solver_Result'(Status => Unsatisfiable);
      end if;
   end Unit_Propagation_Only;

   function Pure_Literal_Only (F : Formula) return Solver_Result is
      Work_F     : Formula := F;
      Work_Model : Valuation := [others => Unassigned];
      Conflict   : Boolean := False;
      Changed    : Boolean := False;
   begin
      if not Is_Valid_Formula (F) then
         raise Invalid_Formula_Error;
      end if;

      Apply_Pure_Literal_Rule (Work_F, Work_Model, Conflict, Changed);

      if Conflict then
         return Solver_Result'(Status => Unsatisfiable);
      elsif Work_F.Num_Clauses = 0 then
         for V in 1 .. Work_F.Num_Vars loop
            if Work_Model (V) = Unassigned then
               Work_Model (V) := Assigned_True;
            end if;
         end loop;
         return Solver_Result'(Status => Satisfiable, Model => Work_Model);
      else
         return Solver_Result'(Status => Unsatisfiable);
      end if;
   end Pure_Literal_Only;

end DPLL;
