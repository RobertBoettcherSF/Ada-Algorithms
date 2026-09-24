--  Constraint_Satisfaction body — CSP survey: domains, consistency,
--  backtracking, forward checking, tiny AC filter, min-conflicts step,
--  map / N-queens demos, method taxonomy.

pragma Ada_2022;

package body Constraint_Satisfaction
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain helpers
   ---------------------------------------------------------------------------

   function Empty_Domain return Domain is
   begin
      return [others => False];
   end Empty_Domain;

   function Full_Domain (Dmax : Dom_Size) return Domain is
      D : Domain := Empty_Domain;
   begin
      for V in Value range 1 .. Value (Dmax) loop
         D (V) := True;
      end loop;
      return D;
   end Full_Domain;

   function Domain_Size (D : Domain) return Dom_Size is
      N : Dom_Size := 0;
   begin
      for V in Value loop
         if D (V) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Domain_Size;

   function Is_Empty (D : Domain) return Boolean is
   begin
      return Domain_Size (D) = 0;
   end Is_Empty;

   function Contains (D : Domain; V : Value) return Boolean is
   begin
      return D (V);
   end Contains;

   procedure Remove_Value (D : in out Domain; V : Value) is
   begin
      D (V) := False;
   end Remove_Value;

   function First_Value (D : Domain) return Natural is
   begin
      for V in Value loop
         if D (V) then
            return V;
         end if;
      end loop;
      return 0;
   end First_Value;

   ---------------------------------------------------------------------------
   -- Constraint satisfaction
   ---------------------------------------------------------------------------

   function Satisfies
     (C      : Constraint;
      Vi, Vj : Value) return Boolean
   is
   begin
      case C.Kind is
         when Not_Equal =>
            return Vi /= Vj;
         when Allowed_Pairs =>
            return C.Allowed (Vi, Vj);
      end case;
   end Satisfies;

   function Pair_OK
     (C      : Constraint;
      A, B   : Variable_Id;
      Va, Vb : Value) return Boolean
   is
   --  Orient (Va,Vb) to match constraint storage (Left, Right).
   begin
      if C.Left = A and then C.Right = B then
         return Satisfies (C, Va, Vb);
      elsif C.Left = B and then C.Right = A then
         return Satisfies (C, Vb, Va);
      else
         return True;
      end if;
   end Pair_OK;

   ---------------------------------------------------------------------------
   -- CSP builders
   ---------------------------------------------------------------------------

   procedure Init
     (Problem  : out CSP;
      Num_Vars : Var_Count;
      Dmax     : Dom_Size)
   is
      D : constant Domain := Full_Domain (Dmax);
   begin
      if Num_Vars = 0 or else Dmax = 0 then
         raise Invalid_Argument;
      end if;
      Problem :=
        (Num_Vars        => Num_Vars,
         Num_Constraints => 0,
         Domains         => [others => Empty_Domain],
         Constraints     =>
           [others => (1, 1, Not_Equal, [others => [others => False]])]);
      for I in Variable_Id range 1 .. Variable_Id (Num_Vars) loop
         Problem.Domains (I) := D;
      end loop;
   end Init;

   procedure Set_Domain
     (Problem : in out CSP;
      Var     : Variable_Id;
      D       : Domain)
   is
   begin
      if Var > Problem.Num_Vars then
         raise Invalid_Argument;
      end if;
      Problem.Domains (Var) := D;
   end Set_Domain;

   procedure Append_Constraint
     (Problem : in out CSP;
      C       : Constraint)
   is
   begin
      if Problem.Num_Constraints = Max_Constraints then
         raise Capacity_Exceeded;
      end if;
      Problem.Num_Constraints := Problem.Num_Constraints + 1;
      Problem.Constraints (Problem.Num_Constraints) := C;
   end Append_Constraint;

   procedure Add_Not_Equal
     (Problem : in out CSP;
      A, B    : Variable_Id)
   is
   begin
      if A > Problem.Num_Vars or else B > Problem.Num_Vars or else A = B then
         raise Invalid_Argument;
      end if;
      Append_Constraint
        (Problem,
         (Left => A, Right => B, Kind => Not_Equal,
          Allowed => [others => [others => False]]));
   end Add_Not_Equal;

   procedure Add_Allowed_Pairs
     (Problem : in out CSP;
      A, B    : Variable_Id;
      Allowed : Allowed_Matrix)
   is
   begin
      if A > Problem.Num_Vars or else B > Problem.Num_Vars or else A = B then
         raise Invalid_Argument;
      end if;
      Append_Constraint
        (Problem,
         (Left => A, Right => B, Kind => Allowed_Pairs, Allowed => Allowed));
   end Add_Allowed_Pairs;

   procedure Add_All_Different (Problem : in out CSP) is
   begin
      if Problem.Num_Vars < 2 then
         raise Invalid_Argument;
      end if;
      for A in Variable_Id range 1 .. Variable_Id (Problem.Num_Vars - 1) loop
         for B in Variable_Id range A + 1 .. Variable_Id (Problem.Num_Vars) loop
            Add_Not_Equal (Problem, A, B);
         end loop;
      end loop;
   end Add_All_Different;

   ---------------------------------------------------------------------------
   -- Assignment helpers
   ---------------------------------------------------------------------------

   function Is_Assigned (A : Assignment; Var : Variable_Id) return Boolean is
   begin
      return A (Var) /= 0;
   end Is_Assigned;

   function Is_Consistent
     (Problem : CSP;
      A       : Assignment) return Boolean
   is
      C  : Constraint;
      Va : Natural;
      Vb : Natural;
   begin
      for I in 1 .. Problem.Num_Constraints loop
         C  := Problem.Constraints (Cons_Index (I));
         Va := A (C.Left);
         Vb := A (C.Right);
         if Va /= 0 and then Vb /= 0 then
            if not Satisfies (C, Value (Va), Value (Vb)) then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Is_Consistent;

   function Is_Complete
     (Problem : CSP;
      A       : Assignment) return Boolean
   is
   begin
      for V in Variable_Id range 1 .. Variable_Id (Problem.Num_Vars) loop
         if A (V) = 0 then
            return False;
         end if;
      end loop;
      return True;
   end Is_Complete;

   function Is_Solution
     (Problem : CSP;
      A       : Assignment) return Boolean
   is
   begin
      return Is_Complete (Problem, A) and then Is_Consistent (Problem, A);
   end Is_Solution;

   --  Domain values still legal for Var given partial assignment A.
   function Remaining_Domain
     (Problem : CSP;
      A       : Assignment;
      Var     : Variable_Id) return Domain
   is
      D : Domain := Problem.Domains (Var);
      C : Constraint;
   begin
      for I in 1 .. Problem.Num_Constraints loop
         C := Problem.Constraints (Cons_Index (I));
         if C.Left = Var and then A (C.Right) /= 0 then
            for V in Value loop
               if D (V) and then
                 not Satisfies (C, V, Value (A (C.Right)))
               then
                  D (V) := False;
               end if;
            end loop;
         elsif C.Right = Var and then A (C.Left) /= 0 then
            for V in Value loop
               if D (V) and then
                 not Satisfies (C, Value (A (C.Left)), V)
               then
                  D (V) := False;
               end if;
            end loop;
         end if;
      end loop;
      return D;
   end Remaining_Domain;

   function Select_Unassigned
     (Problem : CSP;
      A       : Assignment;
      Use_MRV : Boolean) return Natural
   is
      Best      : Natural := 0;
      Best_Size : Dom_Size := Dom_Size'Last;
      Sz        : Dom_Size;
   begin
      if not Use_MRV then
         for V in Variable_Id range 1 .. Variable_Id (Problem.Num_Vars) loop
            if A (V) = 0 then
               return V;
            end if;
         end loop;
         return 0;
      end if;

      for V in Variable_Id range 1 .. Variable_Id (Problem.Num_Vars) loop
         if A (V) = 0 then
            Sz := Domain_Size (Remaining_Domain (Problem, A, V));
            if Best = 0 or else Sz < Best_Size then
               Best      := Natural (V);
               Best_Size := Sz;
            end if;
         end if;
      end loop;
      return Best;
   end Select_Unassigned;

   ---------------------------------------------------------------------------
   -- Backtracking
   ---------------------------------------------------------------------------

   procedure Backtrack_Solve
     (Problem : CSP;
      Result  : out Solve_Result;
      Use_MRV : Boolean := False)
   is
      A     : Assignment := [others => 0];
      Found : Boolean   := False;

      procedure Search is
         Var : Natural;
         Dom : Domain;
      begin
         if Found then
            return;
         end if;
         Result.Nodes := Result.Nodes + 1;
         Var := Select_Unassigned (Problem, A, Use_MRV);
         if Var = 0 then
            if Is_Consistent (Problem, A) then
               Found := True;
               Result.Status := Solved;
               Result.Solution := A;
            end if;
            return;
         end if;

         Dom := Remaining_Domain (Problem, A, Variable_Id (Var));
         for V in Value loop
            if Dom (V) then
               A (Variable_Id (Var)) := V;
               if Is_Consistent (Problem, A) then
                  Search;
                  if Found then
                     return;
                  end if;
               end if;
               A (Variable_Id (Var)) := 0;
               Result.Backtracks := Result.Backtracks + 1;
            end if;
         end loop;
      end Search;

   begin
      Result := (Status => Unsatisfiable, Solution => [others => 0],
                 Nodes => 0, Backtracks => 0);
      Search;
      if not Found then
         Result.Status := Unsatisfiable;
      end if;
   end Backtrack_Solve;

   procedure Count_Solutions
     (Problem : CSP;
      Result  : out Count_Result;
      Use_MRV : Boolean := False)
   is
      A : Assignment := [others => 0];

      procedure Search is
         Var : Natural;
         Dom : Domain;
      begin
         Result.Nodes := Result.Nodes + 1;
         Var := Select_Unassigned (Problem, A, Use_MRV);
         if Var = 0 then
            if Is_Consistent (Problem, A) then
               Result.Count := Result.Count + 1;
            end if;
            return;
         end if;

         Dom := Remaining_Domain (Problem, A, Variable_Id (Var));
         for V in Value loop
            if Dom (V) then
               A (Variable_Id (Var)) := V;
               if Is_Consistent (Problem, A) then
                  Search;
               end if;
               A (Variable_Id (Var)) := 0;
               Result.Backtracks := Result.Backtracks + 1;
            end if;
         end loop;
      end Search;

   begin
      Result := (Count => 0, Nodes => 0, Backtracks => 0);
      Search;
   end Count_Solutions;

   ---------------------------------------------------------------------------
   -- Forward checking
   ---------------------------------------------------------------------------

   procedure Forward_Check_Solve
     (Problem : CSP;
      Result  : out Solve_Result;
      Use_MRV : Boolean := False)
   is
      --  Working domains (forward-check pruning); restored on backtrack.
      Domains : Domain_Array := Problem.Domains;
      A       : Assignment := [others => 0];
      Found   : Boolean := False;

      function FC_Select return Natural is
         Best      : Natural := 0;
         Best_Size : Dom_Size := Dom_Size'Last;
         Sz        : Dom_Size;
      begin
         if not Use_MRV then
            for V in Variable_Id range 1 .. Variable_Id (Problem.Num_Vars) loop
               if A (V) = 0 then
                  return V;
               end if;
            end loop;
            return 0;
         end if;
         for V in Variable_Id range 1 .. Variable_Id (Problem.Num_Vars) loop
            if A (V) = 0 then
               Sz := Domain_Size (Domains (V));
               if Best = 0 or else Sz < Best_Size then
                  Best      := Natural (V);
                  Best_Size := Sz;
               end if;
            end if;
         end loop;
         return Best;
      end FC_Select;

      --  After assigning Xi := Vi, prune neighbours; return False on wipeout.
      function Forward_Check
        (Xi : Variable_Id;
         Vi : Value) return Boolean
      is
         C : Constraint;
         Xj : Variable_Id;
      begin
         for I in 1 .. Problem.Num_Constraints loop
            C := Problem.Constraints (Cons_Index (I));
            if C.Left = Xi then
               Xj := C.Right;
            elsif C.Right = Xi then
               Xj := C.Left;
            else
               goto Next_Cons;
            end if;
            if A (Xj) = 0 then
               for V in Value loop
                  if Domains (Xj) (V)
                    and then not Pair_OK (C, Xi, Xj, Vi, V)
                  then
                     Domains (Xj) (V) := False;
                  end if;
               end loop;
               if Is_Empty (Domains (Xj)) then
                  return False;
               end if;
            end if;
            <<Next_Cons>>
         end loop;
         return True;
      end Forward_Check;

      procedure Search is
         Var     : Natural;
         Xi      : Variable_Id;
         Saved   : Domain_Array;
         Dom_Snap : Domain;
      begin
         if Found then
            return;
         end if;
         Result.Nodes := Result.Nodes + 1;
         Var := FC_Select;
         if Var = 0 then
            Found := True;
            Result.Status := Solved;
            Result.Solution := A;
            return;
         end if;

         Xi := Variable_Id (Var);
         Dom_Snap := Domains (Xi);
         for V in Value loop
            if Dom_Snap (V) then
               Saved := Domains;
               A (Xi) := V;
               Domains (Xi) := Empty_Domain;
               Domains (Xi) (V) := True;
               if Forward_Check (Xi, V) then
                  Search;
                  if Found then
                     return;
                  end if;
               end if;
               A (Xi) := 0;
               Domains := Saved;
               Result.Backtracks := Result.Backtracks + 1;
            end if;
         end loop;
      end Search;

   begin
      Result := (Status => Unsatisfiable, Solution => [others => 0],
                 Nodes => 0, Backtracks => 0);
      Search;
      if not Found then
         Result.Status := Unsatisfiable;
      end if;
   end Forward_Check_Solve;

   ---------------------------------------------------------------------------
   -- Tiny AC filter
   ---------------------------------------------------------------------------

   function Constraints_Link
     (Problem : CSP;
      Xi, Xj  : Variable_Id;
      Vi, Vj  : Value) return Boolean
   is
      C : Constraint;
      Any : Boolean := False;
   begin
      for I in 1 .. Problem.Num_Constraints loop
         C := Problem.Constraints (Cons_Index (I));
         if (C.Left = Xi and then C.Right = Xj)
           or else (C.Left = Xj and then C.Right = Xi)
         then
            Any := True;
            if not Pair_OK (C, Xi, Xj, Vi, Vj) then
               return False;
            end if;
         end if;
      end loop;
      return Any;
   end Constraints_Link;

   function Has_Support
     (Problem : CSP;
      Xi, Xj  : Variable_Id;
      Vi      : Value) return Boolean
   is
   begin
      if not Problem.Domains (Xi) (Vi) then
         return False;
      end if;
      for Vj in Value loop
         if Problem.Domains (Xj) (Vj)
           and then Constraints_Link (Problem, Xi, Xj, Vi, Vj)
         then
            return True;
         end if;
      end loop;
      --  If no constraint links Xi,Xj, every Vi is "supported".
      for I in 1 .. Problem.Num_Constraints loop
         declare
            C : constant Constraint := Problem.Constraints (Cons_Index (I));
         begin
            if (C.Left = Xi and then C.Right = Xj)
              or else (C.Left = Xj and then C.Right = Xi)
            then
               return False;  -- linked but no support found above
            end if;
         end;
      end loop;
      return True;
   end Has_Support;

   function Revise
     (Problem : in out CSP;
      Xi, Xj  : Variable_Id) return Boolean
   is
      Changed : Boolean := False;
   begin
      for V in Value loop
         if Problem.Domains (Xi) (V)
           and then not Has_Support (Problem, Xi, Xj, V)
         then
            Problem.Domains (Xi) (V) := False;
            Changed := True;
         end if;
      end loop;
      return Changed;
   end Revise;

   procedure AC_Filter
     (Problem : in out CSP;
      Result  : out AC_Result)
   is
      C : Constraint;
   begin
      Result := (Status => Success, Revisions => 0);
      for I in 1 .. Problem.Num_Constraints loop
         C := Problem.Constraints (Cons_Index (I));
         if Revise (Problem, C.Left, C.Right) then
            Result.Revisions := Result.Revisions + 1;
         end if;
         if Is_Empty (Problem.Domains (C.Left)) then
            Result.Status := Domain_Wipeout;
            return;
         end if;
         if Revise (Problem, C.Right, C.Left) then
            Result.Revisions := Result.Revisions + 1;
         end if;
         if Is_Empty (Problem.Domains (C.Right)) then
            Result.Status := Domain_Wipeout;
            return;
         end if;
      end loop;
   end AC_Filter;

   ---------------------------------------------------------------------------
   -- Min-conflicts step
   ---------------------------------------------------------------------------

   function Conflict_Count
     (Problem : CSP;
      A       : Assignment) return Natural
   is
      N : Natural := 0;
      C : Constraint;
   begin
      for I in 1 .. Problem.Num_Constraints loop
         C := Problem.Constraints (Cons_Index (I));
         if A (C.Left) /= 0 and then A (C.Right) /= 0
           and then not Satisfies (C, Value (A (C.Left)), Value (A (C.Right)))
         then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Conflict_Count;

   function Conflicts_For_Var
     (Problem : CSP;
      A       : Assignment;
      Var     : Variable_Id;
      Val     : Value) return Natural
   is
      N : Natural := 0;
      C : Constraint;
      Other : Variable_Id;
      Ov    : Natural;
   begin
      for I in 1 .. Problem.Num_Constraints loop
         C := Problem.Constraints (Cons_Index (I));
         if C.Left = Var then
            Other := C.Right;
            Ov := A (Other);
            if Ov /= 0 and then not Satisfies (C, Val, Value (Ov)) then
               N := N + 1;
            end if;
         elsif C.Right = Var then
            Other := C.Left;
            Ov := A (Other);
            if Ov /= 0 and then not Satisfies (C, Value (Ov), Val) then
               N := N + 1;
            end if;
         end if;
      end loop;
      return N;
   end Conflicts_For_Var;

   procedure Min_Conflicts_Step
     (Problem : CSP;
      A       : in out Assignment;
      Var     : Variable_Id;
      Changed : out Boolean)
   is
      Best_Val : Value := Value (A (Var));
      Best_C   : Natural := Natural'Last;
      Cnt      : Natural;
      Old      : constant Natural := A (Var);
   begin
      Changed := False;
      for V in Value loop
         if Problem.Domains (Var) (V) then
            Cnt := Conflicts_For_Var (Problem, A, Var, V);
            if Cnt < Best_C then
               Best_C := Cnt;
               Best_Val := V;
            end if;
         end if;
      end loop;
      A (Var) := Best_Val;
      Changed := A (Var) /= Old;
   end Min_Conflicts_Step;

   ---------------------------------------------------------------------------
   -- Demos
   ---------------------------------------------------------------------------

   procedure Build_Map_Coloring
     (Problem : out CSP;
      Regions : Positive;
      Colors  : Dom_Size)
   is
   begin
      Init (Problem, Var_Count (Regions), Colors);
      for I in Variable_Id range 1 .. Variable_Id (Regions - 1) loop
         Add_Not_Equal (Problem, I, I + 1);
      end loop;
   end Build_Map_Coloring;

   procedure Build_Australia_Map (Problem : out CSP) is
      --  1=WA 2=NT 3=SA 4=Q 5=NSW 6=V 7=T
   begin
      Init (Problem, 7, 3);
      Add_Not_Equal (Problem, 1, 2);  -- WA-NT
      Add_Not_Equal (Problem, 1, 3);  -- WA-SA
      Add_Not_Equal (Problem, 2, 3);  -- NT-SA
      Add_Not_Equal (Problem, 2, 4);  -- NT-Q
      Add_Not_Equal (Problem, 3, 4);  -- SA-Q
      Add_Not_Equal (Problem, 3, 5);  -- SA-NSW
      Add_Not_Equal (Problem, 3, 6);  -- SA-V
      Add_Not_Equal (Problem, 4, 5);  -- Q-NSW
      Add_Not_Equal (Problem, 5, 6);  -- NSW-V
      --  T isolated (no edges)
   end Build_Australia_Map;

   procedure Build_N_Queens
     (Problem : out CSP;
      N       : Positive)
   is
      Allowed : Allowed_Matrix;
   begin
      if N > 5 then
         raise Invalid_Argument;
      end if;
      Init (Problem, Var_Count (N), Dom_Size (N));
      if N = 1 then
         return;  --  single queen, any column; no binary constraints
      end if;
      for R1 in Variable_Id range 1 .. Variable_Id (N - 1) loop
         for R2 in Variable_Id range R1 + 1 .. Variable_Id (N) loop
            Allowed := [others => [others => False]];
            for C1 in Value range 1 .. Value (N) loop
               for C2 in Value range 1 .. Value (N) loop
                  if C1 /= C2
                    and then abs (Integer (C1) - Integer (C2))
                      /= Integer (R2) - Integer (R1)
                  then
                     Allowed (C1, C2) := True;
                  end if;
               end loop;
            end loop;
            Add_Allowed_Pairs (Problem, R1, R2, Allowed);
         end loop;
      end loop;
   end Build_N_Queens;

   ---------------------------------------------------------------------------
   -- Taxonomy
   ---------------------------------------------------------------------------

   function Pad_Family (S : String) return String is
      R : String (1 .. 16) := [others => ' '];
   begin
      if S'Length <= 16 then
         R (1 .. S'Length) := S;
      else
         R := S (S'First .. S'First + 15);
      end if;
      return R;
   end Pad_Family;

   function Classify (Kind : Method_Kind) return Method_Info is
   begin
      case Kind is
         when Backtracking =>
            return (Kind => Backtracking, Implemented => True,
                    Forthcoming => False, Family => Pad_Family ("Search"));
         when Forward_Checking =>
            return (Kind => Forward_Checking, Implemented => True,
                    Forthcoming => False, Family => Pad_Family ("Search"));
         when Arc_Consistency =>
            return (Kind => Arc_Consistency, Implemented => True,
                    Forthcoming => False, Family => Pad_Family ("Inference"));
         when Min_Conflicts_Local =>
            --  Tiny step embedded; full local-search solver is sibling.
            return (Kind => Min_Conflicts_Local, Implemented => True,
                    Forthcoming => False, Family => Pad_Family ("Local_Search"));
         when SAT_Encoding =>
            return (Kind => SAT_Encoding, Implemented => False,
                    Forthcoming => True, Family => Pad_Family ("Encoding"));
      end case;
   end Classify;

   function Method_Name (Kind : Method_Kind) return String is
   begin
      case Kind is
         when Backtracking        => return "Backtracking";
         when Forward_Checking    => return "Forward_Checking";
         when Arc_Consistency     => return "Arc_Consistency";
         when Min_Conflicts_Local => return "Min_Conflicts_Local";
         when SAT_Encoding        => return "SAT_Encoding";
      end case;
   end Method_Name;

   function Implemented (Kind : Method_Kind) return Boolean is
   begin
      return Classify (Kind).Implemented;
   end Implemented;

   function Forthcoming (Kind : Method_Kind) return Boolean is
   begin
      return Classify (Kind).Forthcoming;
   end Forthcoming;

end Constraint_Satisfaction;
