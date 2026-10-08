package body Automated_Theorem_Proving is

   ---------------------------------------------------------------------------
   --  Constructors and Basic Operations
   ---------------------------------------------------------------------------

   function Pos (V : Variable_ID) return Literal is
     (Var => V, Pol => Positive_Pol);

   function Neg (V : Variable_ID) return Literal is
     (Var => V, Pol => Negative_Pol);

   function Negate (L : Literal) return Literal is
   begin
      if L.Pol = Positive_Pol then
         return (Var => L.Var, Pol => Negative_Pol);
      else
         return (Var => L.Var, Pol => Positive_Pol);
      end if;
   end Negate;

   function Contains_Literal (C : Clause; L : Literal) return Boolean is
   begin
      for Item of C loop
         if Item.Var = L.Var and then Item.Pol = L.Pol then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Literal;

   function Contains_Empty_Clause (Formula : CNF_Formula) return Boolean is
   begin
      for C of Formula loop
         if C'Length = 0 then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Empty_Clause;

   ---------------------------------------------------------------------------
   --  Clause Processing Helpers
   ---------------------------------------------------------------------------

   function Is_Tautology (C : Clause) return Boolean is
   begin
      for I in C'Range loop
         for J in I + 1 .. C'Last loop
            if C (I).Var = C (J).Var and then C (I).Pol /= C (J).Pol then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Is_Tautology;

   function Remove_Duplicates (C : Clause) return Clause is
      Result : Clause (1 .. C'Length) := [others => Pos (1)];
      Count  : Natural := 0;
      Is_Dup : Boolean;
   begin
      for I in C'Range loop
         Is_Dup := False;
         for J in 1 .. Count loop
            if Result (J).Var = C (I).Var and then Result (J).Pol = C (I).Pol then
               Is_Dup := True;
               exit;
            end if;
         end loop;
         if not Is_Dup then
            Count := Count + 1;
            Result (Count) := C (I);
         end if;
      end loop;
      return Result (1 .. Count);
   end Remove_Duplicates;

   function Resolve_Clauses (C1, C2 : Clause; Pivot : Variable_ID) return Clause is
      Temp : Clause (1 .. C1'Length + C2'Length);
      Idx  : Natural := 0;
   begin
      --  Add literals from C1, excluding the pivot
      for L of C1 loop
         if L.Var /= Pivot then
            Idx := Idx + 1;
            Temp (Idx) := L;
         end if;
      end loop;
      
      --  Add literals from C2, excluding the pivot
      for L of C2 loop
         if L.Var /= Pivot then
            Idx := Idx + 1;
            Temp (Idx) := L;
         end if;
      end loop;
      
      return Remove_Duplicates (Temp (1 .. Idx));
   end Resolve_Clauses;

   ---------------------------------------------------------------------------
   --  Simplification Helpers (Unit Propagation & Pure Literal)
   ---------------------------------------------------------------------------

   function Simplify_Unit_Propagation (Formula : CNF_Formula; Unit : Literal) return CNF_Formula is
      Result     : CNF_Formula;
      Target_Neg : constant Literal := Negate (Unit);
   begin
      for C of Formula loop
         if Contains_Literal (C, Unit) then
            --  Clause evaluates to True, it is eliminated from the formula
            null; 
         elsif Contains_Literal (C, Target_Neg) then
            --  Unit is True, so Target_Neg is False. Remove Target_Neg from the clause.
            declare
               New_C : Clause (1 .. C'Length - 1);
               Idx   : Natural := 0;
            begin
               for L of C loop
                  if L.Var /= Target_Neg.Var or else L.Pol /= Target_Neg.Pol then
                     Idx := Idx + 1;
                     New_C (Idx) := L;
                  end if;
               end loop;
               Result.Append (New_C (1 .. Idx));
            end;
         else
            --  Clause unaffected
            Result.Append (C);
         end if;
      end loop;
      return Result;
   end Simplify_Unit_Propagation;

   function Simplify_Pure_Literal (Formula : CNF_Formula; Pure : Literal) return CNF_Formula is
      Result : CNF_Formula;
   begin
      for C of Formula loop
         if not Contains_Literal (C, Pure) then
            --  Only retain clauses that do NOT contain the pure literal
            Result.Append (C);
         end if;
      end loop;
      return Result;
   end Simplify_Pure_Literal;

   ---------------------------------------------------------------------------
   --  Algorithms
   ---------------------------------------------------------------------------

   function Is_Satisfiable_Exhaustive (Formula : CNF_Formula; Max_Var : Variable_ID) return Boolean is
      Max_Combinations : constant Natural := 2 ** Natural (Max_Var);
      type Assignment_Array is array (Variable_ID range 1 .. Max_Var) of Boolean;
      Assign      : Assignment_Array := [others => False];
      Val         : Natural;
      Formula_Sat : Boolean;
      Clause_Sat  : Boolean;
   begin
      if Formula.Is_Empty then
         return True;
      end if;

      for I in 0 .. Max_Combinations - 1 loop
         Val := I;
         for V in Variable_ID range 1 .. Max_Var loop
            Assign (V) := (Val mod 2) = 1;
            Val := Val / 2;
         end loop;

         Formula_Sat := True;
         for C of Formula loop
            Clause_Sat := False;
            for L of C loop
               if (L.Pol = Positive_Pol and then Assign (L.Var)) or else
                  (L.Pol = Negative_Pol and then not Assign (L.Var))
               then
                  Clause_Sat := True;
                  exit;
               end if;
            end loop;

            if not Clause_Sat then
               Formula_Sat := False;
               exit;
            end if;
         end loop;

         if Formula_Sat then
            return True;
         end if;
      end loop;

      return False;
   end Is_Satisfiable_Exhaustive;


   function Is_Satisfiable_DPLL (Formula : CNF_Formula) return Boolean is
      Max_V    : Variable_ID := 1;
      Pure_Lit : Literal := Pos (1);
      Found_Pure : Boolean := False;
   begin
      --  Base Cases
      if Formula.Is_Empty then
         return True;
      end if;
      if Contains_Empty_Clause (Formula) then
         return False;
      end if;

      --  Unit Propagation
      for C of Formula loop
         if C'Length = 1 then
            return Is_Satisfiable_DPLL (Simplify_Unit_Propagation (Formula, C (C'First)));
         end if;
      end loop;

      --  Determine highest variable ID to bound boolean arrays
      for C of Formula loop
         for L of C loop
            if L.Var > Max_V then 
               Max_V := L.Var; 
            end if;
         end loop;
      end loop;

      --  Pure Literal Elimination
      declare
         Pos_Seen : array (Variable_ID range 1 .. Max_V) of Boolean := [others => False];
         Neg_Seen : array (Variable_ID range 1 .. Max_V) of Boolean := [others => False];
      begin
         for C of Formula loop
            for L of C loop
               if L.Pol = Positive_Pol then 
                  Pos_Seen (L.Var) := True;
               else 
                  Neg_Seen (L.Var) := True;
               end if;
            end loop;
         end loop;

         for V in Variable_ID range 1 .. Max_V loop
            if Pos_Seen (V) and then not Neg_Seen (V) then
               Pure_Lit := Pos (V);
               Found_Pure := True;
               exit;
            elsif Neg_Seen (V) and then not Pos_Seen (V) then
               Pure_Lit := Neg (V);
               Found_Pure := True;
               exit;
            end if;
         end loop;
      end;

      if Found_Pure then
         return Is_Satisfiable_DPLL (Simplify_Pure_Literal (Formula, Pure_Lit));
      end if;

      --  Splitting Rule (Branching)
      declare
         First_C : constant Clause := Formula.First_Element;
      begin
         if First_C'Length > 0 then
            declare
               L       : constant Literal := First_C (First_C'First);
               F_True  : CNF_Formula := Formula;
               F_False : CNF_Formula := Formula;
               L_Clause : constant Clause (1 .. 1) := [1 => L];
               N_Clause : constant Clause (1 .. 1) := [1 => Negate (L)];
            begin
               --  Append unit clauses to branch assignments
               F_True.Append (L_Clause);
               F_False.Append (N_Clause);
               return Is_Satisfiable_DPLL (F_True) or else Is_Satisfiable_DPLL (F_False);
            end;
         else
            return False; -- Unreachable safely due to Contains_Empty_Clause check
         end if;
      end;
   end Is_Satisfiable_DPLL;


   function Is_Satisfiable_DP_Resolution (Formula : CNF_Formula) return Boolean is
      Current_F : CNF_Formula := Formula;
      Max_V     : Variable_ID := 1;
   begin
      --  Find maximum variable to eliminate
      for C of Current_F loop
         for L of C loop
            if L.Var > Max_V then
               Max_V := L.Var;
            end if;
         end loop;
      end loop;

      --  Eliminate variables iteratively
      for V in Variable_ID range 1 .. Max_V loop
         declare
            S_Pos  : CNF_Formula;
            S_Neg  : CNF_Formula;
            S_None : CNF_Formula;
         begin
            --  Partition clauses by occurrence of V
            for C of Current_F loop
               if Contains_Literal (C, Pos (V)) then
                  S_Pos.Append (C);
               elsif Contains_Literal (C, Neg (V)) then
                  S_Neg.Append (C);
               else
                  S_None.Append (C);
               end if;
            end loop;

            --  Generate resolvents
            for C1 of S_Pos loop
               for C2 of S_Neg loop
                  declare
                     Res : constant Clause := Resolve_Clauses (C1, C2, V);
                  begin
                     if not Is_Tautology (Res) then
                        S_None.Append (Res);
                     end if;
                  end;
               end loop;
            end loop;

            Current_F := S_None;
            
            --  If resolving created an empty clause, formula is unsatisfiable
            if Contains_Empty_Clause (Current_F) then
               return False;
            end if;
         end;
      end loop;

      return True;
   end Is_Satisfiable_DP_Resolution;

end Automated_Theorem_Proving;
