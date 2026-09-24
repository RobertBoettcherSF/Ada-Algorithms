package body Packrat_Parser is

   ----------------------------------------------------------------------------
   --  Validation helper
   ----------------------------------------------------------------------------
   function Is_Valid_Grammar (Grammar : Grammar_Array) return Boolean is
     (for all Rule of Grammar =>
        (case Rule.Kind is
           when Match_Char | Match_Any => True,
           when Sequence | Choice =>
              Rule.Left_Rule in Grammar'Range and then
              Rule.Right_Rule in Grammar'Range,
           when Zero_Or_More | Not_Predicate =>
              Rule.Child_Rule in Grammar'Range));

   ----------------------------------------------------------------------------
   --  Shared Generic Evaluator
   --  This generic abstracts the parsing logic of standard PEG operators so
   --  it can be shared across all three parsing strategy variants without
   --  code duplication.
   ----------------------------------------------------------------------------
   generic
      with function Eval (R : Rule_ID; Pos : Text_Index) return Parse_Result;
   function Generic_Compute
     (Grammar : Grammar_Array;
      Input   : String;
      R       : Rule_ID;
      Pos     : Text_Index) return Parse_Result;

   function Generic_Compute
     (Grammar : Grammar_Array;
      Input   : String;
      R       : Rule_ID;
      Pos     : Text_Index) return Parse_Result
   is
      Rule : constant Rule_Def := Grammar (R);
   begin
      case Rule.Kind is
         when Match_Char =>
            if Integer (Pos) <= Input'Last
              and then Input (Integer (Pos)) = Rule.Target_Char
            then
               return (Success, Pos + 1);
            else
               return (Status => Failure);
            end if;

         when Match_Any =>
            if Integer (Pos) <= Input'Last then
               return (Success, Pos + 1);
            else
               return (Status => Failure);
            end if;

         when Sequence =>
            declare
               L_Res : constant Parse_Result := Eval (Rule.Left_Rule, Pos);
            begin
               if L_Res.Status = Success then
                  return Eval (Rule.Right_Rule, L_Res.Next_Index);
               else
                  return (Status => Failure);
               end if;
            end;

         when Choice =>
            declare
               L_Res : constant Parse_Result := Eval (Rule.Left_Rule, Pos);
            begin
               if L_Res.Status = Success then
                  return L_Res;
               else
                  return Eval (Rule.Right_Rule, Pos);
               end if;
            end;

         when Zero_Or_More =>
            --  Greedy consumption for the star operator
            declare
               Cur_Pos : Text_Index := Pos;
            begin
               loop
                  declare
                     Child_Res : constant Parse_Result := Eval (Rule.Child_Rule, Cur_Pos);
                  begin
                     exit when Child_Res.Status = Failure;
                     --  Prevent infinite loop if a rule matches the empty string
                     exit when Child_Res.Next_Index = Cur_Pos;
                     Cur_Pos := Child_Res.Next_Index;
                  end;
               end loop;
               return (Success, Cur_Pos);
            end;

         when Not_Predicate =>
            --  Looks ahead without consuming characters
            declare
               Child_Res : constant Parse_Result := Eval (Rule.Child_Rule, Pos);
            begin
               if Child_Res.Status = Success then
                  return (Status => Failure);
               else
                  return (Success, Pos);
               end if;
            end;
      end case;
   end Generic_Compute;


   ----------------------------------------------------------------------------
   --  VARIANT 1: Naive Top-Down Recursive Descent
   ----------------------------------------------------------------------------
   function Parse_Naive
     (Grammar : Grammar_Array;
      Text    : String;
      Start   : Rule_ID) return Parse_Result
   is
      Input : constant String (1 .. Text'Length) := Text;
      subtype Internal_Index is Text_Index range 1 .. Text_Index (Input'Length + 1);

      --  Used solely to detect infinite recursion (left-recursion) and fail gracefully
      Visiting : array (Grammar'Range, Internal_Index) of Boolean :=
        [others => [others => False]];

      function Eval (R : Rule_ID; Pos : Text_Index) return Parse_Result;
      function Compute is new Generic_Compute (Eval);

      function Eval (R : Rule_ID; Pos : Text_Index) return Parse_Result is
         Idx : constant Internal_Index := Pos;
      begin
         if Visiting (R, Idx) then
            return (Status => Failure);
         end if;

         Visiting (R, Idx) := True;
         declare
            Res : constant Parse_Result := Compute (Grammar, Input, R, Pos);
         begin
            Visiting (R, Idx) := False;
            return Res;
         end;
      end Eval;
   begin
      if not Is_Valid_Grammar (Grammar) then
         raise Invalid_Grammar with "Grammar contains invalid references.";
      end if;
      return Eval (Start, 1);
   end Parse_Naive;


   ----------------------------------------------------------------------------
   --  VARIANT 2: Standard Packrat Parser
   ----------------------------------------------------------------------------
   function Parse_Packrat
     (Grammar : Grammar_Array;
      Text    : String;
      Start   : Rule_ID) return Parse_Result
   is
      Input : constant String (1 .. Text'Length) := Text;
      subtype Internal_Index is Text_Index range 1 .. Text_Index (Input'Length + 1);

      type Memo_Status is (Unknown, Evaluating, Success, Failure);
      type Memo_Record is record
         Status     : Memo_Status := Unknown;
         Next_Index : Text_Index := 1;
      end record;

      --  Memoization table ensuring O(1) repeated lookups
      Table : array (Grammar'Range, Internal_Index) of Memo_Record :=
        [others => [others => (Status => Unknown, Next_Index => 1)]];

      function Eval (R : Rule_ID; Pos : Text_Index) return Parse_Result;
      function Compute is new Generic_Compute (Eval);

      function Eval (R : Rule_ID; Pos : Text_Index) return Parse_Result is
         Idx : constant Internal_Index := Pos;
      begin
         case Table (R, Idx).Status is
            when Unknown =>
               --  Mark as Evaluating to detect direct left-recursive cycles
               Table (R, Idx).Status := Evaluating;
               declare
                  Res : constant Parse_Result := Compute (Grammar, Input, R, Pos);
               begin
                  if Res.Status = Success then
                     Table (R, Idx) := (Status => Success, Next_Index => Res.Next_Index);
                  else
                     Table (R, Idx) := (Status => Failure, Next_Index => Pos);
                  end if;
               end;
            when Evaluating =>
               --  Left-recursion detected natively without growth support => FAIL
               return (Status => Failure);
            when Success | Failure =>
               null;
         end case;

         if Table (R, Idx).Status = Success then
            return (Success, Table (R, Idx).Next_Index);
         else
            return (Status => Failure);
         end if;
      end Eval;
   begin
      if not Is_Valid_Grammar (Grammar) then
         raise Invalid_Grammar with "Grammar contains invalid references.";
      end if;
      return Eval (Start, 1);
   end Parse_Packrat;


   ----------------------------------------------------------------------------
   --  VARIANT 3: Packrat Parser with Left Recursion Support
   ----------------------------------------------------------------------------
   function Parse_Packrat_Left_Rec
     (Grammar : Grammar_Array;
      Text    : String;
      Start   : Rule_ID) return Parse_Result
   is
      Input : constant String (1 .. Text'Length) := Text;
      subtype Internal_Index is Text_Index range 1 .. Text_Index (Input'Length + 1);

      type Memo_Status is (Unknown, Success, Failure);
      type Memo_Record is record
         Status     : Memo_Status := Unknown;
         Next_Index : Text_Index := 1;
      end record;

      Table : array (Grammar'Range, Internal_Index) of Memo_Record :=
        [others => [others => (Status => Unknown, Next_Index => 1)]];

      function Eval (R : Rule_ID; Pos : Text_Index) return Parse_Result;
      function Compute is new Generic_Compute (Eval);

      function Eval (R : Rule_ID; Pos : Text_Index) return Parse_Result is
         Idx : constant Internal_Index := Pos;
      begin
         --  1. Return immediately if previously memoized
         if Table (R, Idx).Status /= Unknown then
            if Table (R, Idx).Status = Success then
               return (Success, Table (R, Idx).Next_Index);
            else
               return (Status => Failure);
            end if;
         end if;

         --  2. Seed with Failure to break recursive cycles cleanly
         Table (R, Idx) := (Status => Failure, Next_Index => Pos);

         --  3. First evaluation pass
         declare
            Res : constant Parse_Result := Compute (Grammar, Input, R, Pos);
         begin
            if Res.Status = Failure then
               return Res;
            end if;

            --  4. Growth phase for left-recursion handling
            Table (R, Idx) := (Status => Success, Next_Index => Res.Next_Index);

            loop
               --  Clear the memo table for other rules at this position so they can
               --  re-evaluate and use the newly grown seed of R.
               for K in Grammar'Range loop
                  if K /= R then
                     Table (K, Idx).Status := Unknown;
                  end if;
               end loop;

               declare
                  Next_Res : constant Parse_Result := Compute (Grammar, Input, R, Pos);
               begin
                  if Next_Res.Status = Failure then
                     exit;
                  end if;
                  --  Exit if the parse no longer consumes more input
                  if Next_Res.Next_Index <= Table (R, Idx).Next_Index then
                     exit;
                  end if;
                  --  Record longer match and iterate again
                  Table (R, Idx) := (Status => Success, Next_Index => Next_Res.Next_Index);
               end;
            end loop;

            return (Success, Table (R, Idx).Next_Index);
         end;
      end Eval;
   begin
      if not Is_Valid_Grammar (Grammar) then
         raise Invalid_Grammar with "Grammar contains invalid references.";
      end if;
      return Eval (Start, 1);
   end Parse_Packrat_Left_Rec;

end Packrat_Parser;
