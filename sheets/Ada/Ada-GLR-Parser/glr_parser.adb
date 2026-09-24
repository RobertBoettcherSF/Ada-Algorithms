--  Implementation of the GLR Parser and its variants.
--  Uses a bounded Parse_Head list to simulate the Graph-Structured Stack (GSS).
package body GLR_Parser is

   Max_Parse_Depth : constant := 1024;
   Max_Parse_Heads : constant := 64;

   type Stack_Array is array (1 .. Max_Parse_Depth) of State_ID;

   --  Represents a single deterministic path in the non-deterministic GLR parser.
   type Parse_Head is record
      Stack : Stack_Array := [others => 0];
      Depth : Natural := 0;
      State : State_ID := 0;
      Active : Boolean := False;
   end record;

   type Head_Array is array (1 .. Max_Parse_Heads) of Parse_Head;

   --  Internal execution engine for all GLR variants
   --  Configuration flags modify behavior for RNGLR, BRNGLR, etc.
   function Execute_Engine
     (G            : Grammar;
      Input        : Token_Array;
      Allow_Nulled : Boolean;
      Enforce_Bin  : Boolean) return Parse_Result
   is
      Heads : Head_Array;
      Next_Heads : Head_Array;
      
      Success_Count : Natural := 0;
      Token_Ptr     : Token_Index := Input'First;

      procedure Push (H : in out Parse_Head; S : State_ID) is
      begin
         if H.Depth >= Max_Parse_Depth then
            raise Invalid_State with "Stack overflow";
         end if;
         H.Depth := H.Depth + 1;
         H.Stack (H.Depth) := S;
         H.State := S;
      end Push;

      procedure Pop (H : in out Parse_Head; Count : Natural) is
      begin
         if Count > H.Depth then
            raise Invalid_State with "Stack underflow";
         end if;
         H.Depth := H.Depth - Count;
         if H.Depth = 0 then
            H.State := 0;
         else
            H.State := H.Stack (H.Depth);
         end if;
      end Pop;

      --  Forks a parse head when a conflict (multiple actions) is encountered
      function Fork_Head (Source : Parse_Head) return Positive is
      begin
         for I in Heads'Range loop
            if not Heads (I).Active then
               Heads (I) := Source;
               return I;
            end if;
         end loop;
         raise Invalid_State with "Out of parse heads (Ambiguity too high)";
      end Fork_Head;

   begin
      --  Initialize first head at State 0
      Heads (1).Active := True;
      Push (Heads (1), 0);

      --  Process each token
      while Token_Ptr <= Input'Last loop
         declare
            Current_Token : constant Symbol_ID := Input (Token_Ptr);
            
            --  We use a copy array to stage heads for the next token shift
            Next_Heads_Count : Natural := 0;
         begin
            if Current_Token > G.Max_Symbol then
               return Parse_Syntax_Error;
            end if;

            Next_Heads := [others => (Stack => [others => 0], Depth => 0, State => 0, Active => False)];

            --  Process epsilon-reductions/reductions until all active heads either Shift or Error
            loop
               declare
                  Any_Reduced : Boolean := False;
               begin
                  for I in Heads'Range loop
                     if Heads (I).Active then
                        declare
                           H : constant Parse_Head := Heads (I);
                           Cell : constant Action_Cell := G.Actions (H.State, Current_Token);
                        begin
                           if Cell.Count = 0 then
                              --  Syntax Error on this specific path
                              Heads (I).Active := False;
                           else
                              Heads (I).Active := False; -- Will replace with fork(s)
                              
                              for A in 1 .. Cell.Count loop
                                 declare
                                    Act : constant Action_Record := Cell.Actions (A);
                                    New_Idx : Positive;
                                 begin
                                    case Act.Kind is
                                       when Action_Shift =>
                                          --  Shifts consume the token, move to next round
                                          New_Idx := Fork_Head (H);
                                          Push (Heads (New_Idx), Act.Next_State);
                                          
                                          Next_Heads_Count := Next_Heads_Count + 1;
                                          Next_Heads (Next_Heads_Count) := Heads (New_Idx);
                                          Heads (New_Idx).Active := False;
                                          
                                       when Action_Reduce =>
                                          declare
                                             Prod : constant Production := G.Productions (Act.Prod_Ref);
                                          begin
                                             if Enforce_Bin and then Prod.Length > 2 then
                                                --  BRNGLR constraint violation
                                                null;
                                             elsif not Allow_Nulled and then Prod.Length = 0 then
                                                --  Standard GLR blocking right-nulled
                                                null;
                                             else
                                                New_Idx := Fork_Head (H);
                                                Pop (Heads (New_Idx), Prod.Length);
                                                
                                                --  Goto next state based on LHS
                                                declare
                                                   Goto_State : constant State_ID := 
                                                     G.Gotos (Heads (New_Idx).State, Prod.LHS.ID);
                                                begin
                                                   Push (Heads (New_Idx), Goto_State);
                                                   Any_Reduced := True;
                                                end;
                                             end if;
                                          end;
                                          
                                       when Action_Accept =>
                                          Success_Count := Success_Count + 1;
                                          
                                       when Action_Error =>
                                          null;
                                    end case;
                                 end;
                              end loop;
                           end if;
                        end;
                     end if;
                  end loop;

                  exit when not Any_Reduced;
               end;
            end loop;

            --  If no heads are waiting for the next token and we haven't accepted, it's an error
            if Next_Heads_Count = 0 and then Success_Count = 0 then
               return Parse_Syntax_Error;
            end if;

            --  Advance token pointer and set active heads for the new token
            Heads := Next_Heads;
            Token_Ptr := Token_Ptr + 1;
         end;
      end loop;

      if Success_Count = 1 then
         return Parse_Success;
      elsif Success_Count > 1 then
         return Parse_Ambiguous;
      else
         return Parse_Syntax_Error;
      end if;
      
   exception
      when Invalid_State =>
         return Parse_Syntax_Error;
   end Execute_Engine;

   ---------------------------------------------------------------------------
   --  Variant Implementations
   ---------------------------------------------------------------------------

   function Parse_GLR (G : Grammar; Input : Token_Array) return Parse_Result is
   begin
      --  Standard Tomita GLR; Right nulled usually unsupported natively without looping
      return Execute_Engine (G, Input, Allow_Nulled => False, Enforce_Bin => False);
   end Parse_GLR;

   function Parse_RNGLR (G : Grammar; Input : Token_Array) return Parse_Result is
   begin
      --  Right Nulled GLR supports zero-length reductions natively
      return Execute_Engine (G, Input, Allow_Nulled => True, Enforce_Bin => False);
   end Parse_RNGLR;

   function Parse_BRNGLR (G : Grammar; Input : Token_Array) return Parse_Result is
   begin
      --  Binary Right Nulled GLR restricts grammar rules to max length 2
      for I in G.Productions'Range loop
         if G.Productions (I).Length > 2 then
            raise Grammar_Error with "BRNGLR requires productions of length <= 2";
         end if;
      end loop;
      return Execute_Engine (G, Input, Allow_Nulled => True, Enforce_Bin => True);
   end Parse_BRNGLR;

   function Parse_SGLR (G : Grammar; Input : String) return Parse_Result is
      Tokens : Token_Array (1 .. Token_Index (Input'Length));
   begin
      --  Scannerless GLR (SGLR) reads characters as lexical tokens directly.
      for I in Input'Range loop
         --  Map characters to symbols. Assume direct mapping for ASCII for simplicity.
         declare
            Val : constant Natural := Character'Pos (Input (I));
         begin
            if Val > Natural (G.Max_Symbol) then
               return Parse_Lexical_Error;
            end if;
            Tokens (Token_Index (I)) := Symbol_ID (Val);
         end;
      end loop;
      return Execute_Engine (G, Tokens, Allow_Nulled => True, Enforce_Bin => False);
   end Parse_SGLR;

   function Parse_RIGLR (G : Grammar; Input : Token_Array) return Parse_Result is
   begin
      --  Reduction Incorporated GLR - engine logic behaves identically structurally here, 
      --  but theoretically relies on pre-computed inlined reduction states in the tables.
      return Execute_Engine (G, Input, Allow_Nulled => True, Enforce_Bin => False);
   end Parse_RIGLR;

end GLR_Parser;
