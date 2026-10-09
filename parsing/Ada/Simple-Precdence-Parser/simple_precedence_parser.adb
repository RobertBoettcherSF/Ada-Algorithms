package body Simple_Precedence_Parser is

   -----------------------------------------------------------------------------
   -- Helper: Find_Production
   -- Scans the production array for an exact RHS match and outputs the LHS.
   -----------------------------------------------------------------------------
   function Find_Production 
     (P : Parser; RHS : String; LHS : out Symbol) return Boolean 
     with Global => null
   is
   begin
      LHS := End_Marker; -- Default initialization to prevent warnings
      for I in 1 .. P.Max_Prods loop
         if To_String (P.Prods (I).RHS) = RHS then
            LHS := P.Prods (I).LHS;
            return True;
         end if;
      end loop;
      return False;
   end Find_Production;

   -----------------------------------------------------------------------------
   -- Create_Parser
   -----------------------------------------------------------------------------
   function Create_Parser
     (Start_Symbol : Symbol;
      Prods        : Production_Array;
      Matrix       : Relation_Matrix) return Parser
   is
      Result : Parser (Max_Prods => Prods'Length);
   begin
      Result.Start_Symbol := Start_Symbol;
      for I in Prods'Range loop
         -- Map variable 1-based indexing of input to the record's strict range
         Result.Prods (I - Prods'First + 1) := Prods (I);
      end loop;
      Result.Matrix := Matrix;
      return Result;
   end Create_Parser;

   -----------------------------------------------------------------------------
   -- Is_Valid_Simple_Precedence_Grammar
   -----------------------------------------------------------------------------
   function Is_Valid_Simple_Precedence_Grammar
     (Prods : Production_Array) return Boolean
   is
      type Symbol_Set is array (Symbol, Symbol) of Boolean
        with Pack;
      type Symbol_Flags is array (Symbol) of Boolean;

      Nonterminal : Symbol_Flags := [others => False];
      --  First (A, X): X starts a string derived from A in one or more
      --  steps (FIRST+); Last likewise for the end (LAST+).
      First, Last : Symbol_Set := [others => [others => False]];
      --  The three Wirth-Weber relations.
      Eq, Lt, Gt  : Symbol_Set := [others => [others => False]];
   begin
      --  No empty rule, no repeated right-hand side, no end marker.
      for I in Prods'Range loop
         if Length (Prods (I).RHS) = 0
           or else Prods (I).LHS = End_Marker
           or else Index (Prods (I).RHS, [1 => End_Marker]) /= 0
         then
            return False;
         end if;
         for J in I + 1 .. Prods'Last loop
            if Prods (I).RHS = Prods (J).RHS then
               return False;
            end if;
         end loop;
         Nonterminal (Prods (I).LHS) := True;
      end loop;

      --  FIRST+ and LAST+: direct first / last symbols, then the
      --  transitive closure through nonterminals (Warshall).
      for Pr of Prods loop
         declare
            R : constant String := To_String (Pr.RHS);
         begin
            First (Pr.LHS, R (R'First)) := True;
            Last (Pr.LHS, R (R'Last)) := True;
         end;
      end loop;
      for K in Symbol loop
         if Nonterminal (K) then
            for A in Symbol loop
               if Nonterminal (A) then
                  if First (A, K) then
                     for X in Symbol loop
                        if First (K, X) then
                           First (A, X) := True;
                        end if;
                     end loop;
                  end if;
                  if Last (A, K) then
                     for X in Symbol loop
                        if Last (K, X) then
                           Last (A, X) := True;
                        end if;
                     end loop;
                  end if;
               end if;
            end loop;
         end if;
      end loop;

      --  Relations from every adjacent pair X Y in a right-hand side:
      --  X = Y; X < Z for Z in FIRST+(Y); Z > W for Z in LAST+(X) and
      --  W = Y or W in FIRST+(Y).
      for Pr of Prods loop
         declare
            R : constant String := To_String (Pr.RHS);
         begin
            for I in R'First .. R'Last - 1 loop
               declare
                  X : constant Symbol := R (I);
                  Y : constant Symbol := R (I + 1);
               begin
                  Eq (X, Y) := True;
                  for Z in Symbol loop
                     if First (Y, Z) then
                        Lt (X, Z) := True;
                     end if;
                     if Last (X, Z) then
                        Gt (Z, Y) := True;
                        for W in Symbol loop
                           if First (Y, W) then
                              Gt (Z, W) := True;
                           end if;
                        end loop;
                     end if;
                  end loop;
               end;
            end loop;
         end;
      end loop;

      --  At most one relation per ordered pair. The end-marker relations
      --  ($ < FIRST+(S), LAST+(S) > $) cannot clash: '$' is in no rule.
      for X in Symbol loop
         for Y in Symbol loop
            if (Eq (X, Y) and then Lt (X, Y))
              or else (Eq (X, Y) and then Gt (X, Y))
              or else (Lt (X, Y) and then Gt (X, Y))
            then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Valid_Simple_Precedence_Grammar;

   -----------------------------------------------------------------------------
   -- Parse (Standard, non-allocating variant)
   -----------------------------------------------------------------------------
   function Parse
     (P     : Parser;
      Input : String) return Boolean
   is
      Max_Stack : constant := 1024;
      type Symbol_Stack is array (1 .. Max_Stack) of Symbol;
      Stack : Symbol_Stack := [others => End_Marker];
      Top   : Natural := 0;

      Input_Idx : Positive;
      Current_Input : Symbol;
      Rel : Precedence_Relation;
      
      -- Protection against cyclic malformed matrices
      Reductions_Since_Last_Shift : Natural := 0; 
      Max_Consecutive_Reductions  : constant Natural := 1000;

      procedure Push (S : Symbol) is
      begin
         if Top >= Max_Stack then
            raise Parse_Error with "Stack overflow";
         end if;
         Top := Top + 1;
         Stack (Top) := S;
      end Push;

   begin
      if Input'Length = 0 then
         return False;
      end if;

      Input_Idx := Input'First;
      Push (End_Marker);

      loop
         if Input_Idx <= Input'Last then
            Current_Input := Input (Input_Idx);
         else
            Current_Input := End_Marker;
         end if;

         -- Acceptance Condition: Stack contains exactly [End_Marker, Start_Symbol]
         -- and the entire input has been consumed.
         if Top = 2 and then
            Stack (1) = End_Marker and then
            Stack (2) = P.Start_Symbol and then
            Current_Input = End_Marker
         then
            return True;
         end if;

         Rel := P.Matrix (Stack (Top), Current_Input);

         if Rel = Takes or else Rel = Equal then
            -- SHIFT operation
            Push (Current_Input);
            Input_Idx := Input_Idx + 1;
            Reductions_Since_Last_Shift := 0;

         elsif Rel = Yields then
            -- REDUCE operation
            Reductions_Since_Last_Shift := Reductions_Since_Last_Shift + 1;
            if Reductions_Since_Last_Shift > Max_Consecutive_Reductions then
               return False;
            end if;

            declare
               Handle_Start : Natural := 0;
               Internal_Rel : Precedence_Relation;
               LHS          : Symbol;
               RHS_Str      : String (1 .. Top) := [others => End_Marker];
               RHS_Len      : Natural := 0;
            begin
               -- Find handle start by searching backwards for a 'Takes' relation
               for I in reverse 2 .. Top loop
                  Internal_Rel := P.Matrix (Stack (I - 1), Stack (I));
                  if Internal_Rel = Takes then
                     Handle_Start := I;
                     exit;
                  elsif Internal_Rel = Equal then
                     null; -- Internal relations of a handle must be Equal
                  else
                     return False; -- Invalid internal sequence
                  end if;
               end loop;

               if Handle_Start = 0 then
                  return False;
               end if;

               -- Extract the Right-Hand Side from the stack
               for I in Handle_Start .. Top loop
                  RHS_Len := RHS_Len + 1;
                  RHS_Str (RHS_Len) := Stack (I);
               end loop;

               -- Match with a production rule
               if not Find_Production (P, RHS_Str (1 .. RHS_Len), LHS) then
                  return False;
               end if;

               -- Replace handle with Left-Hand Side
               Top := Handle_Start - 1;
               Push (LHS);
            end;
         else
            -- No precedence relation implies a syntax error
            return False;
         end if;
      end loop;
   end Parse;

   -----------------------------------------------------------------------------
   -- Parse_With_Trace (Diagnostic Variant)
   -----------------------------------------------------------------------------
   function Parse_With_Trace
     (P     : Parser;
      Input : String;
      Trace : out Unbounded_String) return Boolean
   is
      Max_Stack : constant := 1024;
      type Symbol_Stack is array (1 .. Max_Stack) of Symbol;
      Stack : Symbol_Stack := [others => End_Marker];
      Top   : Natural := 0;

      Input_Idx : Positive;
      Current_Input : Symbol;
      Rel : Precedence_Relation;

      Reductions_Since_Last_Shift : Natural := 0; 
      Max_Consecutive_Reductions  : constant Natural := 1000;

      procedure Push (S : Symbol) is
      begin
         if Top >= Max_Stack then
            raise Parse_Error with "Stack overflow";
         end if;
         Top := Top + 1;
         Stack (Top) := S;
      end Push;

   begin
      Trace := Null_Unbounded_String;

      if Input'Length = 0 then
         Append (Trace, "Reject: Empty input." & ASCII.LF);
         return False;
      end if;

      Input_Idx := Input'First;
      Push (End_Marker);

      loop
         if Input_Idx <= Input'Last then
            Current_Input := Input (Input_Idx);
         else
            Current_Input := End_Marker;
         end if;

         if Top = 2 and then
            Stack (1) = End_Marker and then
            Stack (2) = P.Start_Symbol and then
            Current_Input = End_Marker
         then
            Append (Trace, "Accept." & ASCII.LF);
            return True;
         end if;

         Rel := P.Matrix (Stack (Top), Current_Input);

         if Rel = Takes or else Rel = Equal then
            Append (Trace, "Shift: " & Current_Input & ASCII.LF);
            Push (Current_Input);
            Input_Idx := Input_Idx + 1;
            Reductions_Since_Last_Shift := 0;

         elsif Rel = Yields then
            Reductions_Since_Last_Shift := Reductions_Since_Last_Shift + 1;
            if Reductions_Since_Last_Shift > Max_Consecutive_Reductions then
               Append (Trace, "Reject: Infinite reduction cycle detected." & ASCII.LF);
               return False;
            end if;

            declare
               Handle_Start : Natural := 0;
               Internal_Rel : Precedence_Relation;
               LHS          : Symbol;
               RHS_Str      : Unbounded_String := Null_Unbounded_String;
            begin
               for I in reverse 2 .. Top loop
                  Internal_Rel := P.Matrix (Stack (I - 1), Stack (I));
                  if Internal_Rel = Takes then
                     Handle_Start := I;
                     exit;
                  elsif Internal_Rel = Equal then
                     null;
                  else
                     Append (Trace, "Reject: Invalid internal relation inside handle." & ASCII.LF);
                     return False;
                  end if;
               end loop;

               if Handle_Start = 0 then
                  Append (Trace, "Reject: Could not find handle start (<)." & ASCII.LF);
                  return False;
               end if;

               for I in Handle_Start .. Top loop
                  Append (RHS_Str, Stack (I));
               end loop;

               if not Find_Production (P, To_String (RHS_Str), LHS) then
                  Append (Trace, "Reject: No production for handle " & To_String (RHS_Str) & ASCII.LF);
                  return False;
               end if;

               Append (Trace, "Reduce: " & LHS & " -> " & To_String (RHS_Str) & ASCII.LF);
               Top := Handle_Start - 1;
               Push (LHS);
            end;
         else
            Append (Trace, "Reject: No precedence relation between " &
                    Stack (Top) & " and " & Current_Input & ASCII.LF);
            return False;
         end if;
      end loop;
   end Parse_With_Trace;

end Simple_Precedence_Parser;
