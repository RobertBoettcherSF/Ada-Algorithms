-- canonical_lr_parser.adb
-- Body implementation for Canonical LR(1) Parser in Ada 2023

package body Canonical_LR_Parser is

   use type Item_Sets.Set;

   function "<" (Left, Right : LR1_Item) return Boolean is
   begin
      if Left.Rule_No /= Right.Rule_No then
         return Left.Rule_No < Right.Rule_No;
      elsif Left.Dot_Pos /= Right.Dot_Pos then
         return Left.Dot_Pos < Right.Dot_Pos;
      else
         return Left.Lookahead < Right.Lookahead;
      end if;
   end "<";

   function "<" (Left, Right : Table_Key) return Boolean is
   begin
      if Left.State /= Right.State then
         return Left.State < Right.State;
      else
         return Left.Symbol < Right.Symbol;
      end if;
   end "<";

   procedure Validate_Grammar (G : in Grammar_Definition) is
   begin
      if G.Productions.Is_Empty then
         raise Grammar_Error with "Grammar has no production rules.";
      end if;
      for I in 1 .. G.Productions.Last_Index loop
         declare
            Prod : constant Production_Record := G.Productions.Element (I);
         begin
            if Prod.LHS = 0 then
               raise Grammar_Error with "Invalid left-hand side symbol in production.";
            end if;
         end;
      end loop;
   end Validate_Grammar;

   procedure Build_Parsing_Table 
     (G     : in  Grammar_Definition;
      Table : out Parsing_Table)
   is
      Max_Sym : constant Symbol_Index := G.Terminal_Count + G.Nonterminal_Count + 2;
      type Symbol_Set is array (Symbol_Index range 0 .. Max_Sym) of Boolean;
      type First_Sets_Type is array (Symbol_Index range 0 .. Max_Sym) of Symbol_Set;

      Firsts : First_Sets_Type := [others => [others => False]];

      procedure Compute_Firsts is
         Added : Boolean := True;
      begin
         for I in 0 .. Max_Sym loop
            if I <= G.Terminal_Count or else I = G.EOF_Symbol then
               Firsts (I)(I) := True;
            end if;
         end loop;
         
         while Added loop
            Added := False;
            for P of G.Productions loop
               if not P.RHS.Is_Empty then
                  declare
                     First_RHS : constant Symbol_Index := P.RHS.First_Element;
                  begin
                     for T in 0 .. Max_Sym loop
                        if Firsts (First_RHS)(T) and then not Firsts (P.LHS)(T) then
                           Firsts (P.LHS)(T) := True;
                           Added := True;
                        end if;
                     end loop;
                  end;
               end if;
            end loop;
         end loop;
      end Compute_Firsts;

      function Closure (I : in Item_Sets.Set) return Item_Sets.Set is
         Result : Item_Sets.Set := I;
         To_Add : Item_Sets.Set;
         Added  : Boolean := True;
      begin
         while Added loop
            Added := False;
            To_Add.Clear;

            for Item of Result loop
               if Item.Dot_Pos < G.Productions.Element (Item.Rule_No).RHS.Last_Index then
                  declare
                     Prod_RHS : constant Symbol_Vectors.Vector := 
                       G.Productions.Element (Item.Rule_No).RHS;
                     Next_Sym : constant Symbol_Index := Prod_RHS.Element (Item.Dot_Pos + 1);
                  begin
                     if Next_Sym > G.Terminal_Count and then Next_Sym /= G.EOF_Symbol then
                        declare
                           Lookahead_Set : Symbol_Set := [others => False];
                        begin
                           if Item.Dot_Pos + 1 < Prod_RHS.Last_Index then
                              declare
                                 Beta_1 : constant Symbol_Index := Prod_RHS.Element (Item.Dot_Pos + 2);
                              begin
                                 Lookahead_Set := Firsts (Beta_1);
                              end;
                           else
                              Lookahead_Set (Item.Lookahead) := True;
                           end if;

                           for J in 1 .. G.Productions.Last_Index loop
                              if G.Productions.Element (J).LHS = Next_Sym then
                                 for LA in 0 .. Max_Sym loop
                                    if Lookahead_Set (LA) then
                                       declare
                                          New_Item : constant LR1_Item := 
                                            (Rule_No => J, Dot_Pos => 0, Lookahead => LA);
                                       begin
                                          if not Result.Contains (New_Item) and then not To_Add.Contains (New_Item) then
                                             To_Add.Insert (New_Item);
                                             Added := True;
                                          end if;
                                       end;
                                    end if;
                                 end loop;
                              end if;
                           end loop;
                        end;
                     end if;
                  end;
               end if;
            end loop;

            for New_Item of To_Add loop
               Result.Insert (New_Item);
            end loop;
         end loop;
         return Result;
      end Closure;

      function Goto_Set (I : in Item_Sets.Set; X : Symbol_Index) return Item_Sets.Set is
         Moved : Item_Sets.Set;
      begin
         for Item of I loop
            if Item.Dot_Pos < G.Productions.Element (Item.Rule_No).RHS.Last_Index then
               declare
                  Prod_RHS : constant Symbol_Vectors.Vector := 
                    G.Productions.Element (Item.Rule_No).RHS;
                  Next_Sym : constant Symbol_Index := Prod_RHS.Element (Item.Dot_Pos + 1);
               begin
                  if Next_Sym = X then
                     Moved.Insert ((Rule_No => Item.Rule_No, 
                                    Dot_Pos => Item.Dot_Pos + 1, 
                                    Lookahead => Item.Lookahead));
                  end if;
               end;
            end if;
         end loop;
         return Closure (Moved);
      end Goto_Set;

      Initial_Item : constant LR1_Item := (Rule_No => 1, Dot_Pos => 0, Lookahead => G.EOF_Symbol);
      Initial_Set  : Item_Sets.Set;
   begin
      Validate_Grammar (G);
      Compute_Firsts;
      
      Initial_Set.Insert (Initial_Item);
      Initial_Set := Closure (Initial_Set);

      Table.States.Append (Initial_Set);

      declare
         Idx : State_Index := 0;
      begin
         while Idx <= Table.States.Last_Index loop
            declare
               Current_State : constant Item_Sets.Set := Table.States.Element (Idx);
            begin
               for Sym_Val in 0 .. Max_Sym loop
                  declare
                     Next_S : constant Item_Sets.Set := Goto_Set (Current_State, Sym_Val);
                  begin
                     if not Next_S.Is_Empty then
                        declare
                           Existing_Idx : Integer := -1;
                        begin
                           for S_Idx in Table.States.First_Index .. Table.States.Last_Index loop
                              if Table.States.Element (S_Idx) = Next_S then
                                 Existing_Idx := S_Idx;
                                 exit;
                              end if;
                           end loop;

                           if Existing_Idx = -1 then
                              Table.States.Append (Next_S);
                              Existing_Idx := Table.States.Last_Index;
                           end if;

                           if Sym_Val <= G.Terminal_Count or else Sym_Val = G.EOF_Symbol then
                              Table.Actions.Include 
                                ((State => Idx, Symbol => Sym_Val),
                                 (Kind => Shift, Target_State => Existing_Idx));
                           else
                              Table.Gotos.Include 
                                ((State => Idx, Symbol => Sym_Val), Existing_Idx);
                           end if;
                        end;
                     end if;
                  end;
               end loop;
            end;
            Idx := Idx + 1;
         end loop;
      end;

      for S_Idx in Table.States.First_Index .. Table.States.Last_Index loop
         declare
            St : constant Item_Sets.Set := Table.States.Element (S_Idx);
         begin
            for Item of St loop
               declare
                  Prod : constant Production_Record := G.Productions.Element (Item.Rule_No);
               begin
                  if Item.Dot_Pos = Prod.RHS.Last_Index then
                     if Item.Rule_No = 1 and then Item.Lookahead = G.EOF_Symbol then
                        Table.Actions.Include 
                          ((State => S_Idx, Symbol => G.EOF_Symbol),
                           (Kind => Accept_Action));
                     else
                        Table.Actions.Include 
                          ((State => S_Idx, Symbol => Item.Lookahead),
                           (Kind => Reduce, Production => Item.Rule_No));
                     end if;
                  end if;
               end;
            end loop;
         end;
      end loop;
   end Build_Parsing_Table;

   procedure Parse
     (Table    : in  Parsing_Table;
      G        : in  Grammar_Definition;
      Tokens   : in  Symbol_Vectors.Vector;
      Accepted : out Boolean)
   is
      package State_Vectors is new Ada.Containers.Vectors
        (Index_Type => Positive, Element_Type => State_Index);

      State_Stack : State_Vectors.Vector;
      Token_Idx   : Positive := 1;
      Current_Tok : Symbol_Index;
   begin
      Accepted := False;
      State_Stack.Append (0);

      loop
         if Token_Idx <= Tokens.Last_Index then
            Current_Tok := Tokens.Element (Token_Idx);
         else
            Current_Tok := G.EOF_Symbol;
         end if;

         declare
            Top_State : constant State_Index := State_Stack.Last_Element;
            Key       : constant Table_Key := (State => Top_State, Symbol => Current_Tok);
         begin
            if Table.Actions.Contains (Key) then
               declare
                  Act : constant Action_Type := Table.Actions.Element (Key);
               begin
                  case Act.Kind is
                     when Shift =>
                        State_Stack.Append (Act.Target_State);
                        if Token_Idx <= Tokens.Last_Index then
                           Token_Idx := Token_Idx + 1;
                        end if;

                     when Reduce =>
                        declare
                           Prod : constant Production_Record := G.Productions.Element (Act.Production);
                           Pop_Count : constant Natural := Prod.RHS.Last_Index;
                        begin
                           for I in 1 .. Pop_Count loop
                              if not State_Stack.Is_Empty then
                                 State_Stack.Delete_Last;
                              end if;
                           end loop;

                           declare
                              New_Top : constant State_Index := State_Stack.Last_Element;
                              Goto_Key : constant Table_Key := (State => New_Top, Symbol => Prod.LHS);
                           begin
                              if Table.Gotos.Contains (Goto_Key) then
                                 State_Stack.Append (Table.Gotos.Element (Goto_Key));
                              else
                                 raise Syntax_Error with "Invalid GOTO transition during reduction.";
                              end if;
                           end;
                        end;

                     when Accept_Action =>
                        Accepted := True;
                        exit;

                     when Error_Action =>
                        raise Syntax_Error with "Syntax error encountered during parsing.";
                  end case;
               end;
            else
               raise Syntax_Error with "No action found for state and token combination.";
            end if;
         end;
      end loop;
   end Parse;

   procedure Create_Expression_Grammar (G : out Grammar_Definition) is
      R1, R2, R3, R4, R5, R6, R7 : Production_Record;
      RHS1, RHS2, RHS3, RHS4, RHS5, RHS6, RHS7 : Symbol_Vectors.Vector;
   begin
      G.Terminal_Count := 5;
      G.Nonterminal_Count := 4;
      G.EOF_Symbol := 0;
      G.Start_Symbol := 6;

      -- Rule 1: S' -> E
      RHS1.Append (7);
      R1 := (LHS => 6, RHS => RHS1);
      G.Productions.Append (R1);

      -- Rule 2: E -> E + T
      RHS2.Append (7);
      RHS2.Append (2);
      RHS2.Append (8);
      R2 := (LHS => 7, RHS => RHS2);
      G.Productions.Append (R2);

      -- Rule 3: E -> T
      RHS3.Append (8);
      R3 := (LHS => 7, RHS => RHS3);
      G.Productions.Append (R3);

      -- Rule 4: T -> T * F
      RHS4.Append (8);
      RHS4.Append (3);
      RHS4.Append (9);
      R4 := (LHS => 8, RHS => RHS4);
      G.Productions.Append (R4);

      -- Rule 5: T -> F
      RHS5.Append (9);
      R5 := (LHS => 8, RHS => RHS5);
      G.Productions.Append (R5);

      -- Rule 6: F -> ( E )
      RHS6.Append (4);
      RHS6.Append (7);
      RHS6.Append (5);
      R6 := (LHS => 9, RHS => RHS6);
      G.Productions.Append (R6);

      -- Rule 7: F -> id
      RHS7.Append (1);
      R7 := (LHS => 9, RHS => RHS7);
      G.Productions.Append (R7);
   end Create_Expression_Grammar;

end Canonical_LR_Parser;
