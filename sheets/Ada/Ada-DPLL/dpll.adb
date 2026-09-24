--  DPLL — classical Davis–Putnam–Logemann–Loveland CNF-SAT (educational).

pragma Ada_2022;

with Ada.Characters.Handling;

package body DPLL
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------
   -- Literal helpers
   ---------------------------------------------------------------------

   function Var_Of (L : Literal) return Variable_Id is
   begin
      if L > 0 then
         return Variable_Id (L);
      else
         return Variable_Id (-L);
      end if;
   end Var_Of;

   function Is_Positive (L : Literal) return Boolean is
   begin
      return L > 0;
   end Is_Positive;

   function Negate (L : Literal) return Literal is
   begin
      return -L;
   end Negate;

   function Make_Literal
     (V : Variable_Id; Positive_Pol : Boolean) return Literal
   is
   begin
      if Positive_Pol then
         return Literal (V);
      else
         return Literal (-Integer (V));
      end if;
   end Make_Literal;

   function Lit_Is_True (L : Literal; A : Assignment) return Boolean is
      V : constant Variable_Id := Var_Of (L);
   begin
      if A (V) = Unassigned then
         return False;
      elsif Is_Positive (L) then
         return A (V) = Is_True;
      else
         return A (V) = Is_False;
      end if;
   end Lit_Is_True;

   function Lit_Is_False (L : Literal; A : Assignment) return Boolean is
      V : constant Variable_Id := Var_Of (L);
   begin
      if A (V) = Unassigned then
         return False;
      elsif Is_Positive (L) then
         return A (V) = Is_False;
      else
         return A (V) = Is_True;
      end if;
   end Lit_Is_False;

   function Lit_Is_Unassigned (L : Literal; A : Assignment) return Boolean is
   begin
      return A (Var_Of (L)) = Unassigned;
   end Lit_Is_Unassigned;

   ---------------------------------------------------------------------
   -- Internal clause validation / grow Num_Vars
   ---------------------------------------------------------------------

   procedure Validate_And_Absorb_Clause
     (F : in out Formula;
      C : Clause)
   with SPARK_Mode => Off
   is
      Seen : array (Variable_Id) of Boolean := [others => False];
      V    : Variable_Id;
      Max_V : Variable_Count := F.Num_Vars;
   begin
      for I in 1 .. C.Length loop
         if C.Lits (I) = 0 then
            raise Invalid_Argument;
         end if;
         V := Var_Of (C.Lits (I));
         if Seen (V) then
            raise Invalid_Argument;
         end if;
         Seen (V) := True;
         if Variable_Count (V) > Max_V then
            Max_V := Variable_Count (V);
         end if;
      end loop;
      if F.Num_Vars = 0 then
         F.Num_Vars := Max_V;
      elsif Max_V > F.Num_Vars then
         --  Auto-extend declared universe when caller omitted Set_Num_Vars.
         F.Num_Vars := Max_V;
      end if;
   end Validate_And_Absorb_Clause;

   ---------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------

   procedure Clear (F : out Formula) is
   begin
      F := (Num_Vars => 0, Num_Clauses => 0, Clauses => [others => <>]);
   end Clear;

   procedure Set_Num_Vars (F : in out Formula; N : Variable_Count)
   with SPARK_Mode => Off is
   begin
      for C in 1 .. F.Num_Clauses loop
         for I in 1 .. F.Clauses (C).Length loop
            if Variable_Count (Var_Of (F.Clauses (C).Lits (I))) > N then
               raise Invalid_Argument;
            end if;
         end loop;
      end loop;
      F.Num_Vars := N;
   end Set_Num_Vars;

   procedure Add_Clause (F : in out Formula; C : Clause)
   with SPARK_Mode => Off is
   begin
      if F.Num_Clauses = Max_Clauses then
         raise Capacity_Exceeded;
      end if;
      Validate_And_Absorb_Clause (F, C);
      F.Num_Clauses := F.Num_Clauses + 1;
      F.Clauses (F.Num_Clauses) := C;
   end Add_Clause;

   procedure Add_Clause_From_Literals
     (F    : in out Formula;
      Lits : Literal_List;
      Len  : Clause_Length)
   with SPARK_Mode => Off
   is
      C : Clause;
   begin
      C.Length := Len;
      for I in 1 .. Len loop
         C.Lits (I) := Lits (I);
      end loop;
      Add_Clause (F, C);
   end Add_Clause_From_Literals;

   procedure From_DIMACS_Lite (F : out Formula; Text : String)
   with SPARK_Mode => Off is
      use Ada.Characters.Handling;

      I     : Natural := Text'First;
      Last  : constant Natural := Text'Last;
      NVars : Variable_Count := 0;
      Have_P : Boolean := False;

      procedure Skip_Spaces is
      begin
         while I <= Last
           and then (Text (I) = ' ' or else Text (I) = ASCII.HT)
         loop
            I := I + 1;
         end loop;
      end Skip_Spaces;

      procedure Skip_Line is
      begin
         while I <= Last and then Text (I) /= ASCII.LF
           and then Text (I) /= ASCII.CR
         loop
            I := I + 1;
         end loop;
         if I <= Last and then Text (I) = ASCII.CR then
            I := I + 1;
         end if;
         if I <= Last and then Text (I) = ASCII.LF then
            I := I + 1;
         end if;
      end Skip_Line;

      function Parse_Int return Integer is
         Sign   : Integer := 1;
         Val    : Integer := 0;
         Digit_Count : Natural := 0;
      begin
         Skip_Spaces;
         if I > Last then
            raise Parse_Error;
         end if;
         if Text (I) = '-' then
            Sign := -1;
            I := I + 1;
         elsif Text (I) = '+' then
            I := I + 1;
         end if;
         while I <= Last and then Text (I) in '0' .. '9' loop
            Val := Val * 10 + (Character'Pos (Text (I)) - Character'Pos ('0'));
            Digit_Count := Digit_Count + 1;
            I := I + 1;
         end loop;
         if Digit_Count = 0 then
            raise Parse_Error;
         end if;
         return Sign * Val;
      end Parse_Int;

      procedure Expect_Token (Tok : String) is
      begin
         Skip_Spaces;
         if I + Tok'Length - 1 > Last then
            raise Parse_Error;
         end if;
         for K in Tok'Range loop
            if To_Lower (Text (I + K - Tok'First)) /= To_Lower (Tok (K)) then
               raise Parse_Error;
            end if;
         end loop;
         I := I + Tok'Length;
      end Expect_Token;

      Cur      : Clause;
      Lit_Val  : Integer;
      Decl_Cls : Natural := 0;
   begin
      Clear (F);
      while I <= Last loop
         Skip_Spaces;
         if I > Last then
            exit;
         elsif Text (I) = ASCII.LF or else Text (I) = ASCII.CR then
            Skip_Line;
         elsif Text (I) = 'c' or else Text (I) = 'C' then
            Skip_Line;
         elsif (Text (I) = 'p' or else Text (I) = 'P')
           and then not Have_P
         then
            Expect_Token ("p");
            Expect_Token ("cnf");
            Lit_Val := Parse_Int;
            if Lit_Val < 0 or else Lit_Val > Max_Vars then
               raise Capacity_Exceeded;
            end if;
            NVars := Variable_Count (Lit_Val);
            Lit_Val := Parse_Int;
            if Lit_Val < 0 then
               raise Parse_Error;
            end if;
            Decl_Cls := Natural (Lit_Val);
            if Decl_Cls > Max_Clauses then
               raise Capacity_Exceeded;
            end if;
            Have_P := True;
            F.Num_Vars := NVars;
            Skip_Line;
         else
            --  Clause line: integers ending with 0
            Cur := (Length => 0, Lits => [others => 0]);
            loop
               Lit_Val := Parse_Int;
               if Lit_Val = 0 then
                  exit;
               end if;
               if Lit_Val < -Max_Vars or else Lit_Val > Max_Vars then
                  raise Capacity_Exceeded;
               end if;
               if Cur.Length = Max_Clause_Len then
                  raise Capacity_Exceeded;
               end if;
               Cur.Length := Cur.Length + 1;
               Cur.Lits (Cur.Length) := Literal (Lit_Val);
            end loop;
            Add_Clause (F, Cur);
            Skip_Spaces;
            if I <= Last
              and then (Text (I) = ASCII.LF or else Text (I) = ASCII.CR)
            then
               Skip_Line;
            end if;
         end if;
      end loop;
   end From_DIMACS_Lite;

   ---------------------------------------------------------------------
   -- Clause / formula queries
   ---------------------------------------------------------------------

   function Valid_Clause (C : Clause) return Boolean is
   begin
      for I in 1 .. C.Length loop
         if C.Lits (I) = 0 then
            return False;
         end if;
      end loop;
      return True;
   end Valid_Clause;

   function Clause_Is_Empty (C : Clause) return Boolean is
   begin
      return C.Length = 0;
   end Clause_Is_Empty;

   function Clause_Is_Satisfied (C : Clause; A : Assignment) return Boolean is
   begin
      for I in 1 .. C.Length loop
         if C.Lits (I) /= 0 and then Lit_Is_True (C.Lits (I), A) then
            return True;
         end if;
      end loop;
      return False;
   end Clause_Is_Satisfied;

   function Clause_Is_Conflict (C : Clause; A : Assignment) return Boolean is
   begin
      if C.Length = 0 then
         return True;
      end if;
      for I in 1 .. C.Length loop
         if C.Lits (I) = 0 or else not Lit_Is_False (C.Lits (I), A) then
            return False;
         end if;
      end loop;
      return True;
   end Clause_Is_Conflict;

   function Unit_Literal (C : Clause; A : Assignment) return Literal is
      Open_Count : Natural := 0;
      Open_Lit   : Literal := 0;
   begin
      if Clause_Is_Satisfied (C, A) then
         return 0;
      end if;
      for I in 1 .. C.Length loop
         if C.Lits (I) = 0 then
            return 0;
         elsif Lit_Is_Unassigned (C.Lits (I), A) then
            Open_Count := Open_Count + 1;
            Open_Lit := C.Lits (I);
            if Open_Count > 1 then
               return 0;
            end if;
         elsif not Lit_Is_False (C.Lits (I), A) then
            return 0;
         end if;
      end loop;
      if Open_Count = 1 then
         return Open_Lit;
      end if;
      return 0;
   end Unit_Literal;

   function Has_Empty_Clause (F : Formula) return Boolean is
   begin
      for C in 1 .. F.Num_Clauses loop
         if F.Clauses (C).Length = 0 then
            return True;
         end if;
      end loop;
      return False;
   end Has_Empty_Clause;

   function All_Clauses_Satisfied
     (F : Formula; A : Assignment) return Boolean
   is
   begin
      for C in 1 .. F.Num_Clauses loop
         if not Clause_Is_Satisfied (F.Clauses (C), A) then
            return False;
         end if;
      end loop;
      return True;
   end All_Clauses_Satisfied;

   function Formula_Has_Conflict
     (F : Formula; A : Assignment) return Boolean
   is
   begin
      for C in 1 .. F.Num_Clauses loop
         if Clause_Is_Conflict (F.Clauses (C), A) then
            return True;
         end if;
      end loop;
      return False;
   end Formula_Has_Conflict;

   function Model_Satisfies (F : Formula; M : Model) return Boolean is
   begin
      if M.Num_Vars < F.Num_Vars then
         return False;
      end if;
      for V in 1 .. F.Num_Vars loop
         if M.Values (V) = Unassigned then
            --  Allow don't-cares only if variable never appears? For
            --  strict educational check require assignment of all vars
            --  that appear; here require all Num_Vars assigned.
            return False;
         end if;
      end loop;
      return All_Clauses_Satisfied (F, M.Values);
   end Model_Satisfies;

   ---------------------------------------------------------------------
   -- Assign / propagate / pure / choose
   ---------------------------------------------------------------------

   procedure Assign_Literal
     (A  : in out Assignment;
      L  : Literal;
      Ok : out Boolean)
   is
      V : constant Variable_Id := Var_Of (L);
      Want : constant Truth_Value :=
        (if Is_Positive (L) then Is_True else Is_False);
   begin
      if A (V) = Unassigned then
         A (V) := Want;
         Ok := True;
      elsif A (V) = Want then
         Ok := True;
      else
         Ok := False;
      end if;
   end Assign_Literal;

   procedure Unit_Propagate
     (F        : Formula;
      A        : in out Assignment;
      Conflict : out Boolean)
   is
      Changed : Boolean;
      U       : Literal;
      Ok      : Boolean;
   begin
      if Has_Empty_Clause (F) then
         Conflict := True;
         return;
      end if;
      loop
         Changed := False;
         if Formula_Has_Conflict (F, A) then
            Conflict := True;
            return;
         end if;
         for C in 1 .. F.Num_Clauses loop
            U := Unit_Literal (F.Clauses (C), A);
            if U /= 0 then
               Assign_Literal (A, U, Ok);
               if not Ok then
                  Conflict := True;
                  return;
               end if;
               Changed := True;
            end if;
         end loop;
         exit when not Changed;
      end loop;
      Conflict := Formula_Has_Conflict (F, A);
   end Unit_Propagate;

   procedure Pure_Literals
     (F     : Formula;
      A     : Assignment;
      Pures : out Pure_List)
   with SPARK_Mode => Off
   is
      type Polarity_Seen is (None, Pos_Only, Neg_Only, Both);
      Seen : array (Variable_Id) of Polarity_Seen := [others => None];
      V    : Variable_Id;
      L    : Literal;
   begin
      Pures := (Length => 0, Lits => [others => 0]);
      for C in 1 .. F.Num_Clauses loop
         if not Clause_Is_Satisfied (F.Clauses (C), A) then
            for I in 1 .. F.Clauses (C).Length loop
               L := F.Clauses (C).Lits (I);
               if Lit_Is_Unassigned (L, A) then
                  V := Var_Of (L);
                  if Is_Positive (L) then
                     case Seen (V) is
                        when None =>
                           Seen (V) := Pos_Only;
                        when Neg_Only =>
                           Seen (V) := Both;
                        when Pos_Only | Both =>
                           null;
                     end case;
                  else
                     case Seen (V) is
                        when None =>
                           Seen (V) := Neg_Only;
                        when Pos_Only =>
                           Seen (V) := Both;
                        when Neg_Only | Both =>
                           null;
                     end case;
                  end if;
               end if;
            end loop;
         end if;
      end loop;
      for V in 1 .. F.Num_Vars loop
         if A (V) = Unassigned then
            case Seen (V) is
               when Pos_Only =>
                  Pures.Length := Pures.Length + 1;
                  Pures.Lits (Pures.Length) := Literal (V);
               when Neg_Only =>
                  Pures.Length := Pures.Length + 1;
                  Pures.Lits (Pures.Length) := Literal (-Integer (V));
               when None | Both =>
                  null;
            end case;
         end if;
      end loop;
   end Pure_Literals;

   procedure Eliminate_Pures
     (F        : Formula;
      A        : in out Assignment;
      Conflict : out Boolean)
   with SPARK_Mode => Off
   is
      Pures : Pure_List;
      Ok    : Boolean;
      Changed : Boolean;
   begin
      loop
         Changed := False;
         Pure_Literals (F, A, Pures);
         exit when Pures.Length = 0;
         for I in 1 .. Pures.Length loop
            Assign_Literal (A, Pures.Lits (I), Ok);
            if not Ok then
               Conflict := True;
               return;
            end if;
            Changed := True;
         end loop;
         Unit_Propagate (F, A, Conflict);
         if Conflict then
            return;
         end if;
         exit when not Changed;
      end loop;
      Conflict := False;
   end Eliminate_Pures;

   function Choose_Variable
     (F : Formula; A : Assignment) return Variable_Count
   with SPARK_Mode => Off
   is
      Best : Variable_Count := 0;
      V    : Variable_Id;
      L    : Literal;
   begin
      --  Smallest unassigned variable that occurs in an unsatisfied clause.
      for C in 1 .. F.Num_Clauses loop
         if not Clause_Is_Satisfied (F.Clauses (C), A) then
            for I in 1 .. F.Clauses (C).Length loop
               L := F.Clauses (C).Lits (I);
               if Lit_Is_Unassigned (L, A) then
                  V := Var_Of (L);
                  if Best = 0 or else Variable_Count (V) < Best then
                     Best := Variable_Count (V);
                  end if;
               end if;
            end loop;
         end if;
      end loop;
      return Best;
   end Choose_Variable;

   ---------------------------------------------------------------------
   -- Core recursive DPLL
   ---------------------------------------------------------------------

   procedure DPLL_Search
     (F       : Formula;
      A       : in out Assignment;
      Success : out Boolean)
   with SPARK_Mode => Off
   is
      Conflict : Boolean;
      V        : Variable_Count;
      Saved    : Assignment;
   begin
      Unit_Propagate (F, A, Conflict);
      if Conflict then
         Success := False;
         return;
      end if;

      Eliminate_Pures (F, A, Conflict);
      if Conflict then
         Success := False;
         return;
      end if;

      if All_Clauses_Satisfied (F, A) then
         --  Fill remaining don't-care vars with False for a total model.
         for K in 1 .. F.Num_Vars loop
            if A (K) = Unassigned then
               A (K) := Is_False;
            end if;
         end loop;
         Success := True;
         return;
      end if;

      V := Choose_Variable (F, A);
      if V = 0 then
         --  No open literal in unsatisfied clauses → conflict or sat.
         Success := not Formula_Has_Conflict (F, A)
           and then All_Clauses_Satisfied (F, A);
         return;
      end if;

      Saved := A;
      declare
         Ok : Boolean;
      begin
         Assign_Literal (A, Literal (V), Ok);
         if Ok then
            DPLL_Search (F, A, Success);
            if Success then
               return;
            end if;
         end if;
      end;

      A := Saved;
      declare
         Ok : Boolean;
      begin
         Assign_Literal (A, Literal (-Integer (V)), Ok);
         if Ok then
            DPLL_Search (F, A, Success);
            if Success then
               return;
            end if;
         end if;
      end;

      A := Saved;
      Success := False;
   end DPLL_Search;

   function Solve (F : Formula) return Solve_Result
   with SPARK_Mode => Off is
      A       : Assignment := [others => Unassigned];
      Success : Boolean;
      R       : Solve_Result;
   begin
      if Has_Empty_Clause (F) then
         R.Status := Unsatisfiable;
         R.Result_Model  := (Num_Vars => F.Num_Vars, Values => A);
         return R;
      end if;
      if F.Num_Clauses = 0 then
         R.Status := Satisfiable;
         R.Result_Model  :=
           (Num_Vars => F.Num_Vars,
            Values   => [others => Is_False]);
         --  Vacuous: assign False to declared vars (or leave empty).
         if F.Num_Vars = 0 then
            R.Result_Model.Values := [others => Unassigned];
         end if;
         return R;
      end if;

      DPLL_Search (F, A, Success);
      if Success then
         R.Status := Satisfiable;
         R.Result_Model  := (Num_Vars => F.Num_Vars, Values => A);
      else
         R.Status := Unsatisfiable;
         R.Result_Model  := (Num_Vars => F.Num_Vars, Values => [others => Unassigned]);
      end if;
      return R;
   end Solve;

   function Is_Satisfiable (F : Formula) return Boolean
   with SPARK_Mode => Off is
      R : constant Solve_Result := Solve (F);
   begin
      return R.Status = Satisfiable;
   end Is_Satisfiable;

   ---------------------------------------------------------------------
   -- Classic examples
   ---------------------------------------------------------------------

   procedure Build_Two_Clause_Sat (F : out Formula)
   with SPARK_Mode => Off is
      C1, C2 : Clause;
   begin
      Clear (F);
      F.Num_Vars := 2;
      C1 := (Length => 2, Lits => [1, 2, others => 0]);
      C2 := (Length => 2, Lits => [-1, 2, others => 0]);
      Add_Clause (F, C1);
      Add_Clause (F, C2);
   end Build_Two_Clause_Sat;

   procedure Build_Contradictory_Units (F : out Formula)
   with SPARK_Mode => Off is
      C1, C2 : Clause;
   begin
      Clear (F);
      F.Num_Vars := 1;
      C1 := (Length => 1, Lits => [1, others => 0]);
      C2 := (Length => 1, Lits => [-1, others => 0]);
      Add_Clause (F, C1);
      Add_Clause (F, C2);
   end Build_Contradictory_Units;

   procedure Build_Empty_Clause (F : out Formula)
   with SPARK_Mode => Off is
      C : Clause;
   begin
      Clear (F);
      F.Num_Vars := 0;
      C := (Length => 0, Lits => [others => 0]);
      Add_Clause (F, C);
   end Build_Empty_Clause;

   procedure Build_Empty_Formula (F : out Formula)
   with SPARK_Mode => Off is
   begin
      Clear (F);
   end Build_Empty_Formula;

   procedure Build_Small_3SAT_Sat (F : out Formula)
   with SPARK_Mode => Off is
      --  (x1 ∨ x2 ∨ x3) ∧ (¬x1 ∨ x2 ∨ ¬x3) ∧ (x1 ∨ ¬x2 ∨ x3)
      --  ∧ (¬x1 ∨ ¬x2 ∨ ¬x3)  — satisfiable e.g. x1=T,x2=T,x3=F
      C : Clause;
   begin
      Clear (F);
      F.Num_Vars := 3;
      C := (Length => 3, Lits => [1, 2, 3, others => 0]);
      Add_Clause (F, C);
      C := (Length => 3, Lits => [-1, 2, -3, others => 0]);
      Add_Clause (F, C);
      C := (Length => 3, Lits => [1, -2, 3, others => 0]);
      Add_Clause (F, C);
      C := (Length => 3, Lits => [-1, -2, -3, others => 0]);
      Add_Clause (F, C);
   end Build_Small_3SAT_Sat;

   procedure Build_Small_3SAT_Unsat (F : out Formula)
   with SPARK_Mode => Off is
      --  All 8 possible 3-literal clauses over 3 vars → unsat
      --  (encodes forcing every truth assignment to hit a falsified clause).
      --  Compact unsat: (a)∧(¬a∨b)∧(¬b∨c)∧(¬c) unit-chains to conflict,
      --  plus a 3-SAT flavour: classic pigeon / contradiction set.
      C : Clause;
   begin
      Clear (F);
      F.Num_Vars := 3;
      --  (¬x1 ∨ ¬x2) ∧ (¬x1 ∨ ¬x3) ∧ (¬x2 ∨ ¬x3)
      --  ∧ (x1 ∨ x2) ∧ (x1 ∨ x3) ∧ (x2 ∨ x3)  — unsat (no 2 of 3 true
      --  and false simultaneously; actually this is "exactly the edges
      --  of K3 both ways" → forces all equal and unequal).
      C := (Length => 2, Lits => [-1, -2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, -3, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-2, -3, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [1, 3, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [2, 3, others => 0]);
      Add_Clause (F, C);
   end Build_Small_3SAT_Unsat;

end DPLL;
