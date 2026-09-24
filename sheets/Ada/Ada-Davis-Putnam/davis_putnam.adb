--  Davis_Putnam — classical resolution-based CNF-SAT (educational).

pragma Ada_2022;

with Ada.Characters.Handling;

package body Davis_Putnam
  with SPARK_Mode => Off
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

   function Clause_Contains (C : Clause; L : Literal) return Boolean is
   begin
      for I in 1 .. C.Length loop
         if C.Lits (I) = L then
            return True;
         end if;
      end loop;
      return False;
   end Clause_Contains;

   function Clause_Mentions_Var (C : Clause; V : Variable_Id) return Boolean is
   begin
      return Clause_Contains (C, Literal (V))
        or else Clause_Contains (C, Literal (-Integer (V)));
   end Clause_Mentions_Var;

   ---------------------------------------------------------------------
   -- Internal: validate clause / grow Num_Vars
   ---------------------------------------------------------------------

   procedure Validate_And_Absorb_Clause
     (F : in out Formula;
      C : Clause)
   is
      Seen  : array (Variable_Id) of Boolean := [others => False];
      V     : Variable_Id;
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
         F.Num_Vars := Max_V;
      end if;
   end Validate_And_Absorb_Clause;

   --  Remove literal L from clause C (compact); no-op if absent.
   procedure Delete_Literal_From_Clause (C : in out Clause; L : Literal) is
      J : Clause_Length := 0;
   begin
      for I in 1 .. C.Length loop
         if C.Lits (I) /= L then
            J := J + 1;
            C.Lits (J) := C.Lits (I);
         end if;
      end loop;
      for K in J + 1 .. C.Length loop
         C.Lits (K) := 0;
      end loop;
      C.Length := J;
   end Delete_Literal_From_Clause;

   type Keep_Mask is array (Clause_Id) of Boolean;

   --  Compact formula using a keep-mask over current clause indices.
   procedure Compact_Clauses
     (F    : in out Formula;
      Keep : Keep_Mask)
   is
      New_N : Clause_Count := 0;
      Tmp   : Clause_Array := [others => <>];
   begin
      for C in 1 .. F.Num_Clauses loop
         if Keep (C) then
            New_N := New_N + 1;
            Tmp (New_N) := F.Clauses (C);
         end if;
      end loop;
      F.Num_Clauses := New_N;
      F.Clauses := Tmp;
   end Compact_Clauses;


   ---------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------

   procedure Clear (F : out Formula) is
   begin
      F := (Num_Vars => 0, Num_Clauses => 0, Clauses => [others => <>]);
   end Clear;

   procedure Set_Num_Vars (F : in out Formula; N : Variable_Count) is
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

   procedure Add_Clause (F : in out Formula; C : Clause) is
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
   is
      C : Clause;
   begin
      C.Length := Len;
      for I in 1 .. Len loop
         C.Lits (I) := Lits (I);
      end loop;
      Add_Clause (F, C);
   end Add_Clause_From_Literals;

   procedure From_DIMACS_Lite (F : out Formula; Text : String) is
      use Ada.Characters.Handling;

      I      : Natural := Text'First;
      Last   : constant Natural := Text'Last;
      NVars  : Variable_Count := 0;
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
         Sign         : Integer := 1;
         Val          : Integer := 0;
         Digit_Count  : Natural := 0;
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

   function Clause_Is_Empty (C : Clause) return Boolean is
   begin
      return C.Length = 0;
   end Clause_Is_Empty;

   function Has_Empty_Clause (F : Formula) return Boolean is
   begin
      for C in 1 .. F.Num_Clauses loop
         if Clause_Is_Empty (F.Clauses (C)) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Empty_Clause;

   function Is_Unit_Clause (C : Clause) return Boolean is
   begin
      return C.Length = 1;
   end Is_Unit_Clause;

   function Find_Unit_Literal (F : Formula) return Literal is
   begin
      for C in 1 .. F.Num_Clauses loop
         if Is_Unit_Clause (F.Clauses (C)) then
            return F.Clauses (C).Lits (1);
         end if;
      end loop;
      return 0;
   end Find_Unit_Literal;

   function Find_Pure_Literal (F : Formula) return Literal is
      type Polarity_Seen is (None, Pos_Only, Neg_Only, Both);
      Seen : array (Variable_Id) of Polarity_Seen := [others => None];
      V    : Variable_Id;
      L    : Literal;
   begin
      for C in 1 .. F.Num_Clauses loop
         for I in 1 .. F.Clauses (C).Length loop
            L := F.Clauses (C).Lits (I);
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
         end loop;
      end loop;
      for V in 1 .. F.Num_Vars loop
         case Seen (V) is
            when Pos_Only =>
               return Literal (V);
            when Neg_Only =>
               return Literal (-Integer (V));
            when None | Both =>
               null;
         end case;
      end loop;
      return 0;
   end Find_Pure_Literal;

   procedure Collect_Pures (F : Formula; Pures : out Pure_List) is
      type Polarity_Seen is (None, Pos_Only, Neg_Only, Both);
      Seen : array (Variable_Id) of Polarity_Seen := [others => None];
      V    : Variable_Id;
      L    : Literal;
   begin
      Pures := (Length => 0, Lits => [others => 0]);
      for C in 1 .. F.Num_Clauses loop
         for I in 1 .. F.Clauses (C).Length loop
            L := F.Clauses (C).Lits (I);
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
         end loop;
      end loop;
      for V in 1 .. F.Num_Vars loop
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
      end loop;
   end Collect_Pures;

   function Choose_Variable (F : Formula) return Variable_Count is
   begin
      for V in 1 .. F.Num_Vars loop
         for C in 1 .. F.Num_Clauses loop
            if Clause_Mentions_Var (F.Clauses (C), V) then
               return Variable_Count (V);
            end if;
         end loop;
      end loop;
      return 0;
   end Choose_Variable;

   function Count_Pos_Occurrences
     (F : Formula; V : Variable_Id) return Natural
   is
      N : Natural := 0;
   begin
      for C in 1 .. F.Num_Clauses loop
         if Clause_Contains (F.Clauses (C), Literal (V)) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count_Pos_Occurrences;

   function Count_Neg_Occurrences
     (F : Formula; V : Variable_Id) return Natural
   is
      N : Natural := 0;
   begin
      for C in 1 .. F.Num_Clauses loop
         if Clause_Contains (F.Clauses (C), Literal (-Integer (V))) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count_Neg_Occurrences;

   ---------------------------------------------------------------------
   -- Classical DP steps
   ---------------------------------------------------------------------

   procedure Apply_Unit_Literal
     (F  : in out Formula;
      L  : Literal;
      Ok : out Boolean)
   is
      Keep : Keep_Mask := [others => True];
      Neg  : constant Literal := Negate (L);
   begin
      Ok := True;
      for C in 1 .. F.Num_Clauses loop
         if Clause_Contains (F.Clauses (C), L) then
            --  Clause satisfied by L — delete it.
            Keep (C) := False;
         elsif Clause_Contains (F.Clauses (C), Neg) then
            Delete_Literal_From_Clause (F.Clauses (C), Neg);
         end if;
      end loop;
      Compact_Clauses (F, Keep);
   end Apply_Unit_Literal;

   procedure Unit_Propagate_Rule
     (F         : in out Formula;
      Got_Empty : out Boolean)
   is
      U  : Literal;
      Ok : Boolean;
   begin
      loop
         if Has_Empty_Clause (F) then
            Got_Empty := True;
            return;
         end if;
         U := Find_Unit_Literal (F);
         exit when U = 0;
         Apply_Unit_Literal (F, U, Ok);
         if not Ok then
            Got_Empty := True;
            return;
         end if;
      end loop;
      Got_Empty := Has_Empty_Clause (F);
   end Unit_Propagate_Rule;

   procedure Apply_Pure_Literal (F : in out Formula; L : Literal) is
      Keep : Keep_Mask := [others => True];
   begin
      for C in 1 .. F.Num_Clauses loop
         if Clause_Contains (F.Clauses (C), L) then
            Keep (C) := False;
         end if;
      end loop;
      Compact_Clauses (F, Keep);
   end Apply_Pure_Literal;

   procedure Pure_Literal_Rule
     (F       : in out Formula;
      Changed : out Boolean)
   is
      L     : Literal;
      Steps : Natural := 0;
   begin
      Changed := False;
      loop
         L := Find_Pure_Literal (F);
         exit when L = 0;
         Apply_Pure_Literal (F, L);
         Changed := True;
         Steps := Steps + 1;
         exit when Steps > Max_Vars;
      end loop;
   end Pure_Literal_Rule;

   procedure Resolve_Clauses
     (C_Pos, C_Neg : Clause;
      V            : Variable_Id;
      Resolvent    : out Clause;
      Is_Tautology : out Boolean;
      Ok           : out Boolean)
   is
      Pos_Lit : constant Literal := Literal (V);
      Neg_Lit : constant Literal := Literal (-Integer (V));
      Seen    : array (Variable_Id) of Integer := [others => 0];
      --  Seen (v) = +1 if +v added, -1 if -v added, 0 absent.
      L       : Literal;
      W       : Variable_Id;
   begin
      Resolvent := (Length => 0, Lits => [others => 0]);
      Is_Tautology := False;
      Ok := True;

      --  Copy C_Pos without +V.
      for I in 1 .. C_Pos.Length loop
         L := C_Pos.Lits (I);
         if L /= Pos_Lit then
            W := Var_Of (L);
            if Seen (W) = 0 then
               if Resolvent.Length = Max_Clause_Len then
                  Ok := False;
                  return;
               end if;
               Resolvent.Length := Resolvent.Length + 1;
               Resolvent.Lits (Resolvent.Length) := L;
               Seen (W) := (if Is_Positive (L) then 1 else -1);
            elsif (Is_Positive (L) and then Seen (W) < 0)
              or else (not Is_Positive (L) and then Seen (W) > 0)
            then
               Is_Tautology := True;
               return;
            end if;
            --  duplicate same polarity: ignore
         end if;
      end loop;

      --  Merge C_Neg without −V.
      for I in 1 .. C_Neg.Length loop
         L := C_Neg.Lits (I);
         if L /= Neg_Lit then
            W := Var_Of (L);
            if Seen (W) = 0 then
               if Resolvent.Length = Max_Clause_Len then
                  Ok := False;
                  return;
               end if;
               Resolvent.Length := Resolvent.Length + 1;
               Resolvent.Lits (Resolvent.Length) := L;
               Seen (W) := (if Is_Positive (L) then 1 else -1);
            elsif (Is_Positive (L) and then Seen (W) < 0)
              or else (not Is_Positive (L) and then Seen (W) > 0)
            then
               Is_Tautology := True;
               return;
            end if;
         end if;
      end loop;
   end Resolve_Clauses;

   procedure Eliminate_Variable
     (F  : in out Formula;
      V  : Variable_Id;
      Ok : out Boolean)
   is
      type Idx_List is array (1 .. Max_Clauses) of Clause_Id;
      Pos_Idx : Idx_List;
      Neg_Idx : Idx_List;
      Pos_N   : Clause_Count := 0;
      Neg_N   : Clause_Count := 0;
      Neither : Clause_Array := [others => <>];
      Neither_N : Clause_Count := 0;
      Resolvents : array (1 .. Max_Resolvents) of Clause := [others => <>];
      Res_N   : Resolvent_Count := 0;
      R       : Clause;
      Taut    : Boolean;
      R_Ok    : Boolean;
      Pos_Lit : constant Literal := Literal (V);
      Neg_Lit : constant Literal := Literal (-Integer (V));
      New_N   : Natural;
   begin
      Ok := True;

      --  Partition clauses.
      for C in 1 .. F.Num_Clauses loop
         if Clause_Contains (F.Clauses (C), Pos_Lit) then
            Pos_N := Pos_N + 1;
            Pos_Idx (Pos_N) := C;
         elsif Clause_Contains (F.Clauses (C), Neg_Lit) then
            Neg_N := Neg_N + 1;
            Neg_Idx (Neg_N) := C;
         else
            Neither_N := Neither_N + 1;
            Neither (Neither_N) := F.Clauses (C);
         end if;
      end loop;

      --  Blow-up pre-check: up to Pos_N * Neg_N resolvents.
      if Natural (Pos_N) * Natural (Neg_N) > Max_Resolvents then
         Ok := False;
         return;
      end if;

      for I in 1 .. Pos_N loop
         for J in 1 .. Neg_N loop
            Resolve_Clauses
              (F.Clauses (Pos_Idx (I)),
               F.Clauses (Neg_Idx (J)),
               V, R, Taut, R_Ok);
            if not R_Ok then
               Ok := False;
               return;
            end if;
            if not Taut then
               if Res_N = Max_Resolvents then
                  Ok := False;
                  return;
               end if;
               Res_N := Res_N + 1;
               Resolvents (Res_N) := R;
            end if;
         end loop;
      end loop;

      New_N := Natural (Neither_N) + Natural (Res_N);
      if New_N > Max_Clauses then
         Ok := False;
         return;
      end if;

      --  Rebuild formula: neither + resolvents.
      F.Num_Clauses := 0;
      F.Clauses := [others => <>];
      for I in 1 .. Neither_N loop
         F.Num_Clauses := F.Num_Clauses + 1;
         F.Clauses (F.Num_Clauses) := Neither (I);
      end loop;
      for I in 1 .. Res_N loop
         F.Num_Clauses := F.Num_Clauses + 1;
         F.Clauses (F.Num_Clauses) := Resolvents (I);
      end loop;
   end Eliminate_Variable;

   function Solve (F : Formula) return Status is
      Work      : Formula := F;
      Got_Empty : Boolean;
      Changed   : Boolean;
      V         : Variable_Count;
      Ok        : Boolean;
      Guard     : Natural := 0;
      --  Safety iteration cap: each elim removes a var; units/pures shrink.
      Max_Steps : constant Natural :=
        Max_Vars * 4 + Max_Clauses * 2 + 32;
   begin
      loop
         Guard := Guard + 1;
         if Guard > Max_Steps then
            return Failed;
         end if;

         --  Empty formula ⇒ SAT.
         if Work.Num_Clauses = 0 then
            return Satisfiable;
         end if;

         --  Empty clause ⇒ UNSAT.
         if Has_Empty_Clause (Work) then
            return Unsatisfiable;
         end if;

         --  1. Unit / one-literal rule to fixpoint.
         Unit_Propagate_Rule (Work, Got_Empty);
         if Got_Empty then
            return Unsatisfiable;
         end if;
         if Work.Num_Clauses = 0 then
            return Satisfiable;
         end if;

         --  2. Pure-literal rule (may cascade; loop a few times).
         loop
            Pure_Literal_Rule (Work, Changed);
            exit when not Changed;
            if Work.Num_Clauses = 0 then
               return Satisfiable;
            end if;
         end loop;

         if Has_Empty_Clause (Work) then
            return Unsatisfiable;
         end if;

         --  Re-apply units that pures may have exposed.
         Unit_Propagate_Rule (Work, Got_Empty);
         if Got_Empty then
            return Unsatisfiable;
         end if;
         if Work.Num_Clauses = 0 then
            return Satisfiable;
         end if;

         --  3. Choose a variable and eliminate by resolution.
         V := Choose_Variable (Work);
         if V = 0 then
            --  No variable occurs ⇒ all clauses empty or formula empty.
            if Has_Empty_Clause (Work) then
               return Unsatisfiable;
            else
               return Satisfiable;
            end if;
         end if;

         Eliminate_Variable (Work, Variable_Id (V), Ok);
         if not Ok then
            return Failed;
         end if;
      end loop;
   end Solve;

   function Is_Satisfiable (F : Formula) return Boolean is
   begin
      return Solve (F) = Satisfiable;
   end Is_Satisfiable;

   ---------------------------------------------------------------------
   -- Classic tiny examples
   ---------------------------------------------------------------------

   procedure Build_Two_Clause_Sat (F : out Formula) is
      C : Clause;
   begin
      Clear (F);
      F.Num_Vars := 2;
      C := (Length => 2, Lits => [1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, 2, others => 0]);
      Add_Clause (F, C);
   end Build_Two_Clause_Sat;

   procedure Build_Contradictory_Units (F : out Formula) is
      C : Clause;
   begin
      Clear (F);
      F.Num_Vars := 1;
      C := (Length => 1, Lits => [1, others => 0]);
      Add_Clause (F, C);
      C := (Length => 1, Lits => [-1, others => 0]);
      Add_Clause (F, C);
   end Build_Contradictory_Units;

   procedure Build_Empty_Clause (F : out Formula) is
      C : constant Clause := (Length => 0, Lits => [others => 0]);
   begin
      Clear (F);
      F.Num_Vars := 0;
      Add_Clause (F, C);
   end Build_Empty_Clause;

   procedure Build_Empty_Formula (F : out Formula) is
   begin
      Clear (F);
   end Build_Empty_Formula;

   procedure Build_Small_3SAT_Sat (F : out Formula) is
      C : Clause;
   begin
      --  (x1 ∨ x2 ∨ x3) ∧ (¬x1 ∨ x2 ∨ x3) ∧ (x1 ∨ ¬x2 ∨ x3) ∧ (¬x1 ∨ ¬x2 ∨ ¬x3)
      --  Satisfiable e.g. x1=T, x2=T, x3=F.
      Clear (F);
      F.Num_Vars := 3;
      C := (Length => 3, Lits => [1, 2, 3, others => 0]);
      Add_Clause (F, C);
      C := (Length => 3, Lits => [-1, 2, 3, others => 0]);
      Add_Clause (F, C);
      C := (Length => 3, Lits => [1, -2, 3, others => 0]);
      Add_Clause (F, C);
      C := (Length => 3, Lits => [-1, -2, -3, others => 0]);
      Add_Clause (F, C);
   end Build_Small_3SAT_Sat;

   procedure Build_Small_3SAT_Unsat (F : out Formula) is
      C : Clause;
   begin
      --  All 8 possible 3-lit polarity patterns on {1,2,3} → unsat.
      --  Compact unsat: (a)(¬a∨b)(¬b) style chain plus extras.
      --  Classic: (¬x1∨¬x2)∧(¬x1∨¬x3)∧(¬x2∨¬x3)∧(x1∨x2)∧(x1∨x3)∧(x2∨x3)
      --  forces exactly two true among three → contradiction with pairs.
      --  Simpler pigeon: force all equal and unequal.
      Clear (F);
      F.Num_Vars := 3;
      --  (x1 ∨ x2) ∧ (x1 ∨ ¬x2) ∧ (¬x1 ∨ x2) ∧ (¬x1 ∨ ¬x2)  — unsat on x1,x2
      C := (Length => 2, Lits => [1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [1, -2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-1, -2, others => 0]);
      Add_Clause (F, C);
   end Build_Small_3SAT_Unsat;

   procedure Build_Pure_Only_Sat (F : out Formula) is
      C : Clause;
   begin
      --  (a ∨ b) ∧ (a ∨ ¬b) — a pure positive; b appears both ways.
      Clear (F);
      F.Num_Vars := 2;
      C := (Length => 2, Lits => [1, 2, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [1, -2, others => 0]);
      Add_Clause (F, C);
   end Build_Pure_Only_Sat;

   procedure Build_Blowup_Risk (F : out Formula) is
      C : Clause;
      Neg_Partners : constant array (1 .. 10) of Literal :=
        [12, 13, 14, 15, 16, 12, 13, 14, 15, 16];
   begin
      --  10×(1 ∨ v) for v=2..11 and 10×(¬1 ∨ w) for w in {12..16}
      --  ⇒ Pos*Neg = 100 > Max_Resolvents (96).
      --  Extra binary (¬u ∨ ¬v) pairs so every partner has both polarities
      --  (otherwise pure-literal rule would delete the formula before
      --  elimination and Solve would never hit the blow-up guard).
      Clear (F);
      F.Num_Vars := 16;
      for K in 2 .. 11 loop
         C := (Length => 2, Lits => [1, K, others => 0]);
         Add_Clause (F, C);
      end loop;
      for I in Neg_Partners'Range loop
         C :=
           (Length => 2,
            Lits   => [-1, Neg_Partners (I), others => 0]);
         Add_Clause (F, C);
      end loop;
      --  Anti-pure among 2..11
      C := (Length => 2, Lits => [-2, -3, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-4, -5, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-6, -7, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-8, -9, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-10, -11, others => 0]);
      Add_Clause (F, C);
      --  Anti-pure among 12..16
      C := (Length => 2, Lits => [-12, -13, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-14, -15, others => 0]);
      Add_Clause (F, C);
      C := (Length => 2, Lits => [-16, -12, others => 0]);
      Add_Clause (F, C);
   end Build_Blowup_Risk;

end Davis_Putnam;
