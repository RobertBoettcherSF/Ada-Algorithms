--  Chaff — watched-literal BCP + VSIDS sketch (educational).

pragma Ada_2022;

with Ada.Characters.Handling;

package body Chaff
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

   function Slot_Of (L : Literal) return Lit_Slot is
      V : constant Variable_Id := Var_Of (L);
   begin
      if Is_Positive (L) then
         return Lit_Slot (2 * Integer (V) - 1);
      else
         return Lit_Slot (2 * Integer (V));
      end if;
   end Slot_Of;

   ---------------------------------------------------------------------
   -- Internal builders helpers
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

   begin
      Clear (F);
      while I <= Last loop
         Skip_Spaces;
         if I > Last then
            exit;
         end if;
         if Text (I) = 'c' or else Text (I) = 'C' then
            Skip_Line;
         elsif Text (I) = 'p' or else Text (I) = 'P' then
            I := I + 1;
            Skip_Spaces;
            if I + 2 > Last
              or else To_Lower (Text (I)) /= 'c'
              or else To_Lower (Text (I + 1)) /= 'n'
              or else To_Lower (Text (I + 2)) /= 'f'
            then
               raise Parse_Error;
            end if;
            I := I + 3;
            declare
               Nv : constant Integer := Parse_Int;
               Nc : constant Integer := Parse_Int;
            begin
               if Nv < 0 or else Nv > Max_Vars or else Nc < 0 then
                  raise Capacity_Exceeded;
               end if;
               NVars := Variable_Count (Nv);
               F.Num_Vars := NVars;
               Have_P := True;
               pragma Unreferenced (Nc);
            end;
            Skip_Line;
         elsif Text (I) = ASCII.LF or else Text (I) = ASCII.CR then
            Skip_Line;
         else
            declare
               C   : Clause;
               Lit : Integer;
            begin
               C.Length := 0;
               loop
                  Lit := Parse_Int;
                  if Lit = 0 then
                     exit;
                  end if;
                  if Lit < -Max_Vars or else Lit > Max_Vars then
                     raise Capacity_Exceeded;
                  end if;
                  if C.Length = Max_Clause_Len then
                     raise Capacity_Exceeded;
                  end if;
                  C.Length := C.Length + 1;
                  C.Lits (C.Length) := Literal (Lit);
               end loop;
               Skip_Line;
               Add_Clause (F, C);
            end;
         end if;
      end loop;
      if Have_P and then F.Num_Vars < NVars then
         F.Num_Vars := NVars;
      end if;
   end From_DIMACS_Lite;

   ---------------------------------------------------------------------
   -- Clause / formula queries
   ---------------------------------------------------------------------

   function Clause_Is_Empty (C : Clause) return Boolean is
   begin
      return C.Length = 0;
   end Clause_Is_Empty;

   function Clause_Is_Satisfied (C : Clause; A : Assignment) return Boolean is
   begin
      for I in 1 .. C.Length loop
         if Lit_Is_True (C.Lits (I), A) then
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
         if not Lit_Is_False (C.Lits (I), A) then
            return False;
         end if;
      end loop;
      return True;
   end Clause_Is_Conflict;

   function Unit_Literal (C : Clause; A : Assignment) return Literal is
      Unk : Literal := 0;
      N   : Natural := 0;
   begin
      for I in 1 .. C.Length loop
         if Lit_Is_True (C.Lits (I), A) then
            return 0;
         elsif Lit_Is_Unassigned (C.Lits (I), A) then
            N := N + 1;
            Unk := C.Lits (I);
            if N > 1 then
               return 0;
            end if;
         end if;
      end loop;
      if N = 1 then
         return Unk;
      end if;
      return 0;
   end Unit_Literal;

   function Has_Empty_Clause (F : Formula) return Boolean is
   begin
      for C in 1 .. F.Num_Clauses loop
         if Clause_Is_Empty (F.Clauses (C)) then
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
            return False;
         end if;
      end loop;
      return All_Clauses_Satisfied (F, M.Values);
   end Model_Satisfies;

   ---------------------------------------------------------------------
   -- Watch list helpers
   ---------------------------------------------------------------------

   procedure Bucket_Add
     (S : in out Solver_State;
      L : Literal;
      C : Clause_Id)
   is
      Sl : constant Lit_Slot := Slot_Of (L);
      B  : Watch_Bucket renames S.Buckets (Sl);
   begin
      if B.Length = Max_Clauses then
         raise Capacity_Exceeded;
      end if;
      B.Length := B.Length + 1;
      B.Refs (B.Length) := C;
   end Bucket_Add;

   procedure Bucket_Remove_At
     (S     : in out Solver_State;
      Sl    : Lit_Slot;
      Index : Clause_Count)
   is
      B : Watch_Bucket renames S.Buckets (Sl);
   begin
      B.Refs (Index) := B.Refs (B.Length);
      B.Length := B.Length - 1;
   end Bucket_Remove_At;

   function Bucket_Contains
     (S : Solver_State;
      L : Literal;
      C : Clause_Id) return Boolean
   is
      Sl : constant Lit_Slot := Slot_Of (L);
      B  : Watch_Bucket renames S.Buckets (Sl);
   begin
      for I in 1 .. B.Length loop
         if B.Refs (I) = C then
            return True;
         end if;
      end loop;
      return False;
   end Bucket_Contains;

   procedure Init_Watches (F : Formula; S : out Solver_State) is
   begin
      S :=
        (Watches         => [others => <>],
         Buckets         => [others => <>],
         Activities      => [others => 0.0],
         Trail           => [others => 0],
         Trail_Len       => 0,
         Queue_Head      => 1,
         Initialized     => True,
         Decay_Countdown => Decay_Interval);

      for Ci in 1 .. F.Num_Clauses loop
         declare
            C : Clause renames F.Clauses (Ci);
         begin
            if C.Length = 0 then
               S.Watches (Ci) := (W1 => 0, W2 => 0);
            elsif C.Length = 1 then
               S.Watches (Ci) := (W1 => 1, W2 => 1);
               Bucket_Add (S, C.Lits (1), Ci);
            else
               S.Watches (Ci) := (W1 => 1, W2 => 2);
               Bucket_Add (S, C.Lits (1), Ci);
               Bucket_Add (S, C.Lits (2), Ci);
            end if;
         end;
      end loop;
   end Init_Watches;

   function Get_Watch_Pair
     (S : Solver_State; C : Clause_Id) return Watch_Pair
   is
   begin
      return S.Watches (C);
   end Get_Watch_Pair;

   function Watches_Invariant
     (F : Formula; S : Solver_State) return Boolean
   is
   begin
      if not S.Initialized then
         return False;
      end if;
      for Ci in 1 .. F.Num_Clauses loop
         declare
            C  : Clause renames F.Clauses (Ci);
            Wp : constant Watch_Pair := S.Watches (Ci);
         begin
            if C.Length = 0 then
               if Wp.W1 /= 0 or else Wp.W2 /= 0 then
                  return False;
               end if;
            elsif C.Length = 1 then
               if Wp.W1 /= 1 or else Wp.W2 /= 1 then
                  return False;
               end if;
               if not Bucket_Contains (S, C.Lits (1), Ci) then
                  return False;
               end if;
            else
               if Wp.W1 < 1 or else Wp.W1 > C.Length
                 or else Wp.W2 < 1 or else Wp.W2 > C.Length
               then
                  return False;
               end if;
               if Wp.W1 = Wp.W2 then
                  return False;
               end if;
               if not Bucket_Contains (S, C.Lits (Wp.W1), Ci) then
                  return False;
               end if;
               if not Bucket_Contains (S, C.Lits (Wp.W2), Ci) then
                  return False;
               end if;
            end if;
         end;
      end loop;
      return True;
   end Watches_Invariant;

   procedure Enqueue
     (A        : in out Assignment;
      S        : in out Solver_State;
      L        : Literal;
      Conflict : in out Boolean)
   is
      V : Variable_Id;
   begin
      if not S.Initialized then
         raise Not_Initialized;
      end if;
      if Conflict or else L = 0 then
         return;
      end if;
      V := Var_Of (L);
      if A (V) = Unassigned then
         if Is_Positive (L) then
            A (V) := Is_True;
         else
            A (V) := Is_False;
         end if;
         if S.Trail_Len = Max_Vars then
            raise Capacity_Exceeded;
         end if;
         S.Trail_Len := S.Trail_Len + 1;
         S.Trail (S.Trail_Len) := L;
      elsif Lit_Is_False (L, A) then
         Conflict := True;
      end if;
   end Enqueue;

   --  Try to re-watch clause Ci after watched literal at False_Idx became false.
   --  Other_Idx is the surviving watch index. Returns True if conflict.
   function Propagate_Clause
     (F         : Formula;
      A         : in out Assignment;
      S         : in out Solver_State;
      Ci        : Clause_Id;
      False_Idx : Clause_Length;
      Other_Idx : Clause_Length) return Boolean
   is
      C          : Clause renames F.Clauses (Ci);
      Other_Lit  : constant Literal := C.Lits (Other_Idx);
      New_Idx    : Clause_Length := 0;
   begin
      --  Seek a replacement non-false literal (not the other watch).
      for I in 1 .. C.Length loop
         if I /= Other_Idx and then not Lit_Is_False (C.Lits (I), A) then
            New_Idx := I;
            exit;
         end if;
      end loop;

      if New_Idx /= 0 then
         --  Move watch from False_Idx to New_Idx.
         if S.Watches (Ci).W1 = False_Idx then
            S.Watches (Ci).W1 := New_Idx;
         else
            S.Watches (Ci).W2 := New_Idx;
         end if;
         Bucket_Add (S, C.Lits (New_Idx), Ci);
         return False;  --  caller removes old bucket entry
      end if;

      --  No replacement: Other_Lit must be unit (or conflict if false).
      if Lit_Is_False (Other_Lit, A) then
         return True;  --  conflict; keep old watches
      elsif Lit_Is_Unassigned (Other_Lit, A) then
         declare
            Conf : Boolean := False;
         begin
            Enqueue (A, S, Other_Lit, Conf);
            return Conf;
         end;
      else
         --  Other watch already true — clause satisfied; keep watches.
         return False;
      end if;
   end Propagate_Clause;

   function Still_Watches_False
     (F : Formula; S : Solver_State; Ci : Clause_Id; L_False : Literal)
      return Boolean
   is
      C  : Clause renames F.Clauses (Ci);
      Wp : constant Watch_Pair := S.Watches (Ci);
   begin
      if C.Length = 0 then
         return False;
      end if;
      if Wp.W1 >= 1 and then Wp.W1 <= C.Length
        and then C.Lits (Wp.W1) = L_False
      then
         return True;
      end if;
      if Wp.W2 >= 1 and then Wp.W2 <= C.Length
        and then C.Lits (Wp.W2) = L_False
      then
         return True;
      end if;
      return False;
   end Still_Watches_False;

   procedure Propagate
     (F        : Formula;
      A        : in out Assignment;
      S        : in out Solver_State;
      Conflict : out Boolean)
   is
   begin
      if not S.Initialized then
         raise Not_Initialized;
      end if;
      Conflict := False;

      while S.Queue_Head <= S.Trail_Len loop
         declare
            L_Assigned : constant Literal := S.Trail (S.Queue_Head);
            L_False    : constant Literal := Negate (L_Assigned);
            Sl         : constant Lit_Slot := Slot_Of (L_False);
            I          : Clause_Count := 1;
         begin
            S.Queue_Head := S.Queue_Head + 1;

            while I <= S.Buckets (Sl).Length loop
               declare
                  Ci      : constant Clause_Id := S.Buckets (Sl).Refs (I);
                  Wp      : Watch_Pair renames S.Watches (Ci);
                  C       : Clause renames F.Clauses (Ci);
                  W_Idx   : Clause_Length := 0;
                  O_Idx   : Clause_Length := 0;
                  Advance : Boolean := True;
               begin
                  if C.Length = 0 then
                     Conflict := True;
                     return;
                  elsif C.Length = 1 then
                     if Lit_Is_False (C.Lits (1), A) then
                        Conflict := True;
                        return;
                     end if;
                  else
                     if Wp.W1 >= 1 and then Wp.W1 <= C.Length
                       and then C.Lits (Wp.W1) = L_False
                     then
                        W_Idx := Wp.W1;
                        O_Idx := Wp.W2;
                     elsif Wp.W2 >= 1 and then Wp.W2 <= C.Length
                       and then C.Lits (Wp.W2) = L_False
                     then
                        W_Idx := Wp.W2;
                        O_Idx := Wp.W1;
                     else
                        Bucket_Remove_At (S, Sl, I);
                        Advance := False;
                     end if;

                     if Advance then
                        if Propagate_Clause (F, A, S, Ci, W_Idx, O_Idx) then
                           Conflict := True;
                           return;
                        end if;

                        if Still_Watches_False (F, S, Ci, L_False) then
                           null;
                        else
                           Bucket_Remove_At (S, Sl, I);
                           Advance := False;
                        end if;
                     end if;
                  end if;

                  if Advance then
                     I := I + 1;
                  end if;
               end;
            end loop;
         end;
      end loop;
   end Propagate;

   ---------------------------------------------------------------------
   -- VSIDS
   ---------------------------------------------------------------------

   procedure Decay_Activities (S : in out Solver_State) is
   begin
      for V in Variable_Id loop
         S.Activities (V) := S.Activities (V) * Decay_Factor;
      end loop;
      S.Decay_Countdown := Decay_Interval;
   end Decay_Activities;

   procedure Bump_Activity
     (S : in out Solver_State;
      V : Variable_Id)
   is
   begin
      S.Activities (V) := S.Activities (V) + Bump_Amount;
      if S.Decay_Countdown > 0 then
         S.Decay_Countdown := S.Decay_Countdown - 1;
         if S.Decay_Countdown = 0 then
            Decay_Activities (S);
         end if;
      end if;
   end Bump_Activity;

   procedure Bump_Clause_Activities
     (F : Formula;
      S : in out Solver_State;
      C : Clause_Id)
   is
   begin
      for I in 1 .. F.Clauses (C).Length loop
         Bump_Activity (S, Var_Of (F.Clauses (C).Lits (I)));
      end loop;
   end Bump_Clause_Activities;

   function Get_Activity
     (S : Solver_State; V : Variable_Id) return Float
   is
   begin
      return S.Activities (V);
   end Get_Activity;

   function Choose_VSIDS
     (F : Formula;
      A : Assignment;
      S : Solver_State) return Variable_Count
   is
      Best_V   : Variable_Count := 0;
      Best_Act : Float := -1.0;
      Occurs   : array (Variable_Id) of Boolean := [others => False];
   begin
      for Ci in 1 .. F.Num_Clauses loop
         if not Clause_Is_Satisfied (F.Clauses (Ci), A) then
            for I in 1 .. F.Clauses (Ci).Length loop
               Occurs (Var_Of (F.Clauses (Ci).Lits (I))) := True;
            end loop;
         end if;
      end loop;

      for V in 1 .. F.Num_Vars loop
         if A (V) = Unassigned and then Occurs (V) then
            if Best_V = 0
              or else S.Activities (V) > Best_Act
              or else (S.Activities (V) = Best_Act
                       and then Variable_Count (V) < Best_V)
            then
               Best_V := Variable_Count (V);
               Best_Act := S.Activities (V);
            end if;
         end if;
      end loop;

      --  If every open clause is satisfied but some vars free, pick any
      --  unassigned by activity (don't-care completion).
      if Best_V = 0 then
         for V in 1 .. F.Num_Vars loop
            if A (V) = Unassigned then
               if Best_V = 0
                 or else S.Activities (V) > Best_Act
                 or else (S.Activities (V) = Best_Act
                          and then Variable_Count (V) < Best_V)
               then
                  Best_V := Variable_Count (V);
                  Best_Act := S.Activities (V);
               end if;
            end if;
         end loop;
      end if;
      return Best_V;
   end Choose_VSIDS;

   function Choose_Variable
     (F : Formula;
      A : Assignment;
      S : Solver_State) return Variable_Count
   is
   begin
      return Choose_VSIDS (F, A, S);
   end Choose_Variable;

   procedure Assign_Literal
     (A  : in out Assignment;
      L  : Literal;
      Ok : out Boolean)
   is
      V : constant Variable_Id := Var_Of (L);
   begin
      Ok := True;
      if A (V) = Unassigned then
         if Is_Positive (L) then
            A (V) := Is_True;
         else
            A (V) := Is_False;
         end if;
      elsif Lit_Is_False (L, A) then
         Ok := False;
      end if;
   end Assign_Literal;

   ---------------------------------------------------------------------
   -- Search (watched BCP + VSIDS + chronological backtrack)
   ---------------------------------------------------------------------

   procedure Backtrack_To
     (A    : in out Assignment;
      S    : in out Solver_State;
      Mark : Trail_Index)
   is
   begin
      while S.Trail_Len > Mark loop
         declare
            L : constant Literal := S.Trail (S.Trail_Len);
         begin
            A (Var_Of (L)) := Unassigned;
            S.Trail (S.Trail_Len) := 0;
            S.Trail_Len := S.Trail_Len - 1;
         end;
      end loop;
      S.Queue_Head := S.Trail_Len + 1;
   end Backtrack_To;

   function Find_Conflict_Clause
     (F : Formula; A : Assignment) return Clause_Count
   is
   begin
      for Ci in 1 .. F.Num_Clauses loop
         if Clause_Is_Conflict (F.Clauses (Ci), A) then
            return Clause_Count (Ci);
         end if;
      end loop;
      return 0;
   end Find_Conflict_Clause;

   function Search
     (F : Formula;
      A : in out Assignment;
      S : in out Solver_State) return Boolean
   is
      Conflict : Boolean;
      V        : Variable_Count;
      Mark     : Trail_Index;
      Conf_C   : Clause_Count;
   begin
      Propagate (F, A, S, Conflict);
      if Conflict then
         Conf_C := Find_Conflict_Clause (F, A);
         if Conf_C > 0 then
            Bump_Clause_Activities (F, S, Clause_Id (Conf_C));
         end if;
         return False;
      end if;

      if All_Clauses_Satisfied (F, A) then
         return True;
      end if;

      V := Choose_VSIDS (F, A, S);
      if V = 0 then
         return All_Clauses_Satisfied (F, A)
           or else not Formula_Has_Conflict (F, A);
      end if;

      Mark := S.Trail_Len;

      --  Branch true
      declare
         Conf : Boolean := False;
      begin
         Enqueue (A, S, Make_Literal (Variable_Id (V), True), Conf);
         if not Conf and then Search (F, A, S) then
            return True;
         end if;
         if Conf then
            Bump_Activity (S, Variable_Id (V));
         end if;
      end;
      Backtrack_To (A, S, Mark);

      --  Branch false
      declare
         Conf : Boolean := False;
      begin
         Enqueue (A, S, Make_Literal (Variable_Id (V), False), Conf);
         if not Conf and then Search (F, A, S) then
            return True;
         end if;
         if Conf then
            Bump_Activity (S, Variable_Id (V));
         end if;
      end;
      Backtrack_To (A, S, Mark);
      return False;
   end Search;

   function Solve (F : Formula) return Solve_Result is
      A   : Assignment := [others => Unassigned];
      S   : Solver_State;
      Res : Solve_Result;
      Conf : Boolean := False;
   begin
      Res.Status := Unsatisfiable;
      Res.Result_Model :=
        (Num_Vars => F.Num_Vars, Values => [others => Unassigned]);

      if Has_Empty_Clause (F) then
         return Res;
      end if;

      if F.Num_Clauses = 0 then
         Res.Status := Satisfiable;
         Res.Result_Model.Num_Vars := F.Num_Vars;
         for V in 1 .. F.Num_Vars loop
            Res.Result_Model.Values (V) := Is_False;
         end loop;
         return Res;
      end if;

      Init_Watches (F, S);

      --  Seed occurrence activity lightly (educational warm-start).
      for Ci in 1 .. F.Num_Clauses loop
         for I in 1 .. F.Clauses (Ci).Length loop
            S.Activities (Var_Of (F.Clauses (Ci).Lits (I))) :=
              S.Activities (Var_Of (F.Clauses (Ci).Lits (I))) + 0.1;
         end loop;
      end loop;

      --  Enqueue unary clauses.
      for Ci in 1 .. F.Num_Clauses loop
         if F.Clauses (Ci).Length = 1 then
            Enqueue (A, S, F.Clauses (Ci).Lits (1), Conf);
            if Conf then
               return Res;
            end if;
         end if;
      end loop;

      if Search (F, A, S) then
         Res.Status := Satisfiable;
         Res.Result_Model.Num_Vars := F.Num_Vars;
         for V in 1 .. F.Num_Vars loop
            if A (V) = Unassigned then
               Res.Result_Model.Values (V) := Is_False;
            else
               Res.Result_Model.Values (V) := A (V);
            end if;
         end loop;
      end if;
      return Res;
   end Solve;

   function Is_Satisfiable (F : Formula) return Boolean is
      R : constant Solve_Result := Solve (F);
   begin
      return R.Status = Satisfiable;
   end Is_Satisfiable;

   ---------------------------------------------------------------------
   -- Classic examples
   ---------------------------------------------------------------------

   procedure Build_Two_Clause_Sat (F : out Formula) is
   begin
      Clear (F);
      Set_Num_Vars (F, 2);
      Add_Clause_From_Literals (F, [1, 2, others => 0], 2);
      Add_Clause_From_Literals (F, [-1, 2, others => 0], 2);
   end Build_Two_Clause_Sat;

   procedure Build_Contradictory_Units (F : out Formula) is
   begin
      Clear (F);
      Set_Num_Vars (F, 1);
      Add_Clause_From_Literals (F, [1, others => 0], 1);
      Add_Clause_From_Literals (F, [-1, others => 0], 1);
   end Build_Contradictory_Units;

   procedure Build_Empty_Clause (F : out Formula) is
      C : Clause;
   begin
      Clear (F);
      Set_Num_Vars (F, 1);
      C.Length := 0;
      Add_Clause (F, C);
   end Build_Empty_Clause;

   procedure Build_Empty_Formula (F : out Formula) is
   begin
      Clear (F);
      Set_Num_Vars (F, 0);
   end Build_Empty_Formula;

   procedure Build_Small_3SAT_Sat (F : out Formula) is
   begin
      Clear (F);
      Set_Num_Vars (F, 3);
      --  (a ∨ b ∨ c) ∧ (¬a ∨ b) ∧ (¬b ∨ c) ∧ (a ∨ ¬c)  — sat
      Add_Clause_From_Literals (F, [1, 2, 3, others => 0], 3);
      Add_Clause_From_Literals (F, [-1, 2, others => 0], 2);
      Add_Clause_From_Literals (F, [-2, 3, others => 0], 2);
      Add_Clause_From_Literals (F, [1, -3, others => 0], 2);
   end Build_Small_3SAT_Sat;

   procedure Build_Small_3SAT_Unsat (F : out Formula) is
   begin
      Clear (F);
      Set_Num_Vars (F, 2);
      --  All four binary clauses on {a,¬a}×{b,¬b} → unsat
      Add_Clause_From_Literals (F, [1, 2, others => 0], 2);
      Add_Clause_From_Literals (F, [1, -2, others => 0], 2);
      Add_Clause_From_Literals (F, [-1, 2, others => 0], 2);
      Add_Clause_From_Literals (F, [-1, -2, others => 0], 2);
   end Build_Small_3SAT_Unsat;

   procedure Build_Chain_Units (F : out Formula) is
   begin
      Clear (F);
      Set_Num_Vars (F, 3);
      Add_Clause_From_Literals (F, [1, others => 0], 1);
      Add_Clause_From_Literals (F, [-1, 2, others => 0], 2);
      Add_Clause_From_Literals (F, [-2, 3, others => 0], 2);
   end Build_Chain_Units;

end Chaff;
