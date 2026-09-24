package body CDCL is

   -- Internal Data Structures
   type Assignment_Record is record
      Value  : Truth_Value := Unassigned;
      Level  : Natural := 0;
      Reason : Natural := 0;
   end record;

   type Assignment_State is array (Variable_Id range <>) of Assignment_Record;

   type CDCL_State (Num_Vars : Variable_Id) is record
      Assignments    : Assignment_State (1 .. Num_Vars);
      Trail          : Literal_Vectors.Vector;
      Current_Level  : Natural := 0;
      Clauses        : Clause_Vectors.Vector;
      Original_Count : Natural := 0;
      Conflicts      : Natural := 0;
   end record;

   type Clause_State is (Satisfied, Conflicting, Unit, Unresolved);
   
   type Clause_Eval_Result is record
      State    : Clause_State;
      Unit_Lit : Literal;
   end record;

   -- Helpers
   function Var_Of (L : Literal) return Variable_Id is
   begin
      return Variable_Id (abs (Integer (L)));
   end Var_Of;

   function Sign_Of (L : Literal) return Boolean is
   begin
      return Integer (L) > 0;
   end Sign_Of;

   procedure Init_Formula (F : out Formula; Vars : Natural) is
   begin
      F.Variables_Count := Vars;
      F.Clauses.Clear;
   end Init_Formula;

   procedure Add_Clause (F : in out Formula; C : Clause) is
   begin
      for L of C loop
         if Integer (L) = 0 then
            raise Bad_Literal with "Literal cannot be zero";
         end if;
         if Integer (Var_Of (L)) > F.Variables_Count then
            raise Invalid_Formula with "Literal variable exceeds variable count";
         end if;
      end loop;
      F.Clauses.Append (C);
   end Add_Clause;

   function Evaluate (S : CDCL_State; C : Clause) return Clause_Eval_Result is
      Unassigned_Count : Natural := 0;
      Last_Unassigned  : Literal := 0;
   begin
      for L of C loop
         declare
            V      : constant Variable_Id := Var_Of (L);
            Val    : constant Truth_Value := S.Assignments (V).Value;
            Is_Pos : constant Boolean     := Sign_Of (L);
         begin
            if (Val = True and Is_Pos) or else (Val = False and not Is_Pos) then
               return (State => Satisfied, Unit_Lit => 0);
            elsif Val = Unassigned then
               Unassigned_Count := Unassigned_Count + 1;
               Last_Unassigned := L;
            end if;
         end;
      end loop;

      if Unassigned_Count = 0 then
         return (State => Conflicting, Unit_Lit => 0);
      elsif Unassigned_Count = 1 then
         return (State => Unit, Unit_Lit => Last_Unassigned);
      else
         return (State => Unresolved, Unit_Lit => 0);
      end if;
   end Evaluate;

   procedure Assign (S : in out CDCL_State; Lit : Literal; Level : Natural; Reason : Natural) is
      V   : constant Variable_Id := Var_Of (Lit);
      Val : constant Truth_Value := (if Sign_Of (Lit) then True else False);
   begin
      S.Assignments (V).Value  := Val;
      S.Assignments (V).Level  := Level;
      S.Assignments (V).Reason := Reason;
      S.Trail.Append (Lit);
   end Assign;

   function Propagate (S : in out CDCL_State) return Natural is
      Changed : Boolean := True;
   begin
      while Changed loop
         Changed := False;
         for I in 1 .. Natural (S.Clauses.Length) loop
            declare
               Res : constant Clause_Eval_Result := Evaluate (S, S.Clauses (I));
            begin
               if Res.State = Conflicting then
                  return I;
               elsif Res.State = Unit then
                  Assign (S, Res.Unit_Lit, S.Current_Level, I);
                  Changed := True;
               end if;
            end;
         end loop;
      end loop;
      return 0;
   end Propagate;

   function Contains (C : Clause; Lit : Literal) return Boolean is
   begin
      for L of C loop
         if L = Lit then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   function Resolve (C1, C2 : Clause; Pivot : Literal) return Clause is
      Result : Clause;
   begin
      for L of C1 loop
         if L /= Pivot and then L /= -Pivot and then not Contains (Result, L) then
            Result.Append (L);
         end if;
      end loop;
      for L of C2 loop
         if L /= Pivot and then L /= -Pivot and then not Contains (Result, L) then
            Result.Append (L);
         end if;
      end loop;
      return Result;
   end Resolve;

   procedure Analyze_Conflict (S : in out CDCL_State; Conflict_Id : Natural; Learned : out Clause; Backjump_Level : out Natural) is
      C                  : Clause := S.Clauses (Conflict_Id);
      Current_Level_Lits : Natural;
      Idx                : Natural;
   begin
      if S.Current_Level = 0 then
         Backjump_Level := 0;
         Learned := C;
         return;
      end if;

      Idx := Natural (S.Trail.Length);
      loop
         Current_Level_Lits := 0;
         for L of C loop
            if S.Assignments (Var_Of (L)).Level = S.Current_Level then
               Current_Level_Lits := Current_Level_Lits + 1;
            end if;
         end loop;

         exit when Current_Level_Lits = 1;

         declare
            Resolve_Lit : Literal := 0;
         begin
            while Idx > 0 loop
               declare
                  T_Lit : constant Literal := S.Trail (Idx);
                  T_Var : constant Variable_Id := Var_Of (T_Lit);
               begin
                  if S.Assignments (T_Var).Level = S.Current_Level then
                     if Contains (C, -T_Lit) then
                        Resolve_Lit := -T_Lit;
                        exit;
                     end if;
                  end if;
               end;
               Idx := Idx - 1;
            end loop;

            declare
               Reason_Id     : constant Natural := S.Assignments (Var_Of (Resolve_Lit)).Reason;
               Reason_Clause : constant Clause  := S.Clauses (Reason_Id);
            begin
               C := Resolve (C, Reason_Clause, Resolve_Lit);
            end;
         end;
      end loop;

      Learned := C;
      Backjump_Level := 0;
      for L of Learned loop
         declare
            Lvl : constant Natural := S.Assignments (Var_Of (L)).Level;
         begin
            if Lvl /= S.Current_Level and then Lvl > Backjump_Level then
               Backjump_Level := Lvl;
            end if;
         end;
      end loop;
   end Analyze_Conflict;

   procedure Backjump (S : in out CDCL_State; Level : Natural) is
      New_Trail : Literal_Vectors.Vector;
   begin
      for L of S.Trail loop
         if S.Assignments (Var_Of (L)).Level > Level then
            S.Assignments (Var_Of (L)).Value  := Unassigned;
            S.Assignments (Var_Of (L)).Level  := 0;
            S.Assignments (Var_Of (L)).Reason := 0;
         else
            New_Trail.Append (L);
         end if;
      end loop;
      S.Trail := New_Trail;
      S.Current_Level := Level;
   end Backjump;

   function All_Assigned (S : CDCL_State) return Boolean is
   begin
      for I in 1 .. S.Num_Vars loop
         if S.Assignments (I).Value = Unassigned then
            return False;
         end if;
      end loop;
      return True;
   end All_Assigned;

   procedure Decide (S : in out CDCL_State) is
   begin
      for I in 1 .. S.Num_Vars loop
         if S.Assignments (I).Value = Unassigned then
            S.Current_Level := S.Current_Level + 1;
            Assign (S, -Literal (I), S.Current_Level, 0);
            return;
         end if;
      end loop;
   end Decide;

   -- Core Solver Logic incorporating Variants
   function Solve_Internal (F : Formula; Assignments : out Assignment_Array; Use_Restarts : Boolean; Restart_Interval : Positive; Use_Deletion : Boolean; Max_Learned : Positive) return Solve_Status is
      S : CDCL_State (Variable_Id (F.Variables_Count));
      Conflicts_Since_Restart   : Natural := 0;
      Current_Restart_Threshold : Natural := Restart_Interval;
   begin
      S.Clauses := F.Clauses;
      S.Original_Count := Natural (F.Clauses.Length);

      loop
         declare
            Conflict_Id : constant Natural := Propagate (S);
         begin
            if Conflict_Id /= 0 then
               S.Conflicts := S.Conflicts + 1;
               if S.Current_Level = 0 then
                  return Unsatisfiable;
               end if;

               declare
                  Learned    : Clause;
                  Back_Level : Natural;
               begin
                  Analyze_Conflict (S, Conflict_Id, Learned, Back_Level);
                  S.Clauses.Append (Learned);

                  if Use_Deletion and then Natural (S.Clauses.Length) > S.Original_Count + Max_Learned then
                     S.Clauses.Delete (S.Original_Count + 1);
                  end if;

                  Backjump (S, Back_Level);

                  declare
                     Unit_Lit : Literal := 0;
                  begin
                     for L of Learned loop
                        if S.Assignments (Var_Of (L)).Value = Unassigned then
                           Unit_Lit := L;
                           exit;
                        end if;
                     end loop;
                     if Unit_Lit /= 0 then
                        Assign (S, Unit_Lit, S.Current_Level, Natural (S.Clauses.Length));
                     end if;
                  end;
               end;

               if Use_Restarts then
                  Conflicts_Since_Restart := Conflicts_Since_Restart + 1;
                  if Conflicts_Since_Restart >= Current_Restart_Threshold then
                     Backjump (S, 0);
                     Conflicts_Since_Restart := 0;
                     Current_Restart_Threshold := Current_Restart_Threshold + (Current_Restart_Threshold / 2);
                  end if;
               end if;

            else
               if All_Assigned (S) then
                  for I in 1 .. F.Variables_Count loop
                     Assignments (Variable_Id (I)) := S.Assignments (Variable_Id (I)).Value;
                  end loop;
                  return Satisfiable;
               else
                  Decide (S);
               end if;
            end if;
         end;
      end loop;
   end Solve_Internal;

   function Solve_Basic (F : Formula; Assignments : out Assignment_Array) return Solve_Status is
   begin
      return Solve_Internal (F, Assignments, Use_Restarts => False, Restart_Interval => 1, Use_Deletion => False, Max_Learned => 1);
   end Solve_Basic;

   function Solve_With_Restarts (F : Formula; Assignments : out Assignment_Array; Restart_Interval : Positive) return Solve_Status is
   begin
      return Solve_Internal (F, Assignments, Use_Restarts => True, Restart_Interval => Restart_Interval, Use_Deletion => False, Max_Learned => 1);
   end Solve_With_Restarts;

   function Solve_With_Clause_Deletion (F : Formula; Assignments : out Assignment_Array; Max_Learned : Positive) return Solve_Status is
   begin
      return Solve_Internal (F, Assignments, Use_Restarts => False, Restart_Interval => 1, Use_Deletion => True, Max_Learned => Max_Learned);
   end Solve_With_Clause_Deletion;

   function Is_Satisfied (F : Formula; Assignments : Assignment_Array) return Boolean is
   begin
      for I in 1 .. Natural (F.Clauses.Length) loop
         declare
            C : constant Clause := F.Clauses (I);
            Clause_Sat : Boolean := False;
         begin
            for L of C loop
               declare
                  V   : constant Variable_Id := Var_Of (L);
                  Val : constant Truth_Value := Assignments (V);
               begin
                  if (Val = True and then Sign_Of (L)) or else (Val = False and then not Sign_Of (L)) then
                     Clause_Sat := True;
                     exit;
                  end if;
               end;
            end loop;
            if not Clause_Sat then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Satisfied;

end CDCL;
