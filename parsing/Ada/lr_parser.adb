package body LR_Parser is

   ---------------------
   -- Validate_Engine --
   ---------------------
   function Validate_Engine (Engine : LR_Parser_Engine) return Boolean is
      Has_Accept : Boolean := False;
   begin
      --  Verify there is at least one Accept action to terminate parsing
      for S in 0 .. Engine.Max_State loop
         for T in 0 .. Engine.Max_Terminal loop
            if Engine.Actions (S, T).Kind = Accept_Action then
               Has_Accept := True;
            end if;
         end loop;
      end loop;

      --  Verify that all productions map to valid Nonterminal bounds
      for R in 1 .. Engine.Max_Rule loop
         if Engine.Rules (R).LHS > Engine.Max_Nonterminal then
            return False;
         end if;
      end loop;

      return Has_Accept;
   end Validate_Engine;

   -----------------------
   -- Initialize_Parser --
   -----------------------
   function Initialize_Parser return Parser_Execution_State is
      State : Parser_Execution_State;
   begin
      --  Standard LR engines start by pushing state 0
      State.Stack.Append (0);
      return State;
   end Initialize_Parser;

   ----------------
   -- Feed_Token --
   ----------------
   procedure Feed_Token (
      Engine : LR_Parser_Engine;
      State  : in out Parser_Execution_State;
      Token  : Symbol_Id
   ) is
      Top_State : State_Id;
      Act       : Action_Type;
      Pr        : Production_Rule;
   begin
      --  Token validity bounds check
      if Token > Engine.Max_Terminal then
         State.Status := Syntax_Error;
         return;
      end if;

      loop
         if State.Stack.Is_Empty then
            State.Status := Syntax_Error;
            return;
         end if;
         
         Top_State := State.Stack.Last_Element;
         Act := Engine.Actions (Top_State, Token);

         case Act.Kind is
            when Shift =>
               --  Push the new state and consume the token (exit the loop)
               State.Stack.Append (Act.Next_State);
               return;

            when Reduce =>
               Pr := Engine.Rules (Act.Rule);
               
               --  Pop RHS length off the stack
               for I in 1 .. Pr.Length loop
                  if State.Stack.Is_Empty then
                     State.Status := Syntax_Error;
                     return;
                  end if;
                  State.Stack.Delete_Last;
               end loop;
               
               if State.Stack.Is_Empty then
                  State.Status := Syntax_Error;
                  return;
               end if;
               Top_State := State.Stack.Last_Element;

               --  Safety guard
               if Pr.LHS > Engine.Max_Nonterminal then
                  State.Status := Syntax_Error;
                  return;
               end if;

               declare
                  Next_S : constant State_Id := Engine.Gotos (Top_State, Pr.LHS);
               begin
                  if Next_S = Invalid_State then
                     State.Status := Syntax_Error;
                     return;
                  end if;
                  
                  --  Push Goto state and track derivation
                  State.Stack.Append (Next_S);
                  State.Derivation.Append (Act.Rule);
               end;
               --  We intentionally do not return here; the same token is re-evaluated
               --  against the new top state.

            when Accept_Action =>
               State.Status := Accepted;
               return;

            when Error =>
               State.Status := Syntax_Error;
               return;
         end case;
      end loop;
   end Feed_Token;

   -----------
   -- Parse --
   -----------
   function Parse (Engine : LR_Parser_Engine; Input : Symbol_Array) return Derivation_Sequence is
      State : Parser_Execution_State := Initialize_Parser;
   begin
      for I in Input'Range loop
         Feed_Token (Engine, State, Input (I));
         
         if State.Status = Syntax_Error then
            raise Syntax_Error_Exception;
         elsif State.Status = Accepted then
            --  Standard LR parsers halt immediately on Accept. If trailing input 
            --  exists beyond what the grammar recognizes as EOF, it's an error.
            if I < Input'Last then
               raise Syntax_Error_Exception;
            end if;
            return State.Derivation;
         end if;
      end loop;

      --  If we run out of tokens and haven't hit Accept, we're stuck waiting
      if State.Status = Running then
         raise Syntax_Error_Exception;
      end if;

      return State.Derivation;
   end Parse;

end LR_Parser;
