package body LALR_Parser is

   function Parse (
      Actions     : Action_Table;
      Gotos       : Goto_Table;
      Rules       : Rule_Array;
      Input       : Token_Array;
      Start_State : State_ID
   ) return Boolean
   is
      --  Fixed-size stack for state tracking to avoid dynamic allocation overhead
      type State_Stack is array (1 .. 10_000) of State_ID;
      
      Stack         : State_Stack := [others => 0];
      Top           : Natural := 0;
      Input_Idx     : Positive;
      Current_State : State_ID;
      Current_Token : Terminal_ID;
      Act           : Action_Record;
   begin
      --  Validate input prerequisites manually for robustness
      if Input'Length = 0 or else Input (Input'Last) /= EOF_Symbol then
         raise Parse_Error;
      end if;

      Input_Idx := Input'First;
      Top := 1;
      Stack (Top) := Start_State;

      loop
         Current_State := Stack (Top);

         if Input_Idx > Input'Last then
            raise Parse_Error; --  Input stream ended without Action_Accept
         end if;
         Current_Token := Input (Input_Idx);

         --  Bounds checking for table lookups
         if Current_State not in Actions'Range (1) or else
            Current_Token not in Actions'Range (2)
         then
            raise Invalid_Table_Error;
         end if;

         Act := Actions (Current_State, Current_Token);

         case Act.Kind is
            when Action_Shift =>
               Top := Top + 1;
               if Top > Stack'Last then
                  raise Parse_Error; --  Stack overflow
               end if;
               
               Stack (Top) := Act.Next_State;
               Input_Idx := Input_Idx + 1;

            when Action_Reduce =>
               declare
                  R       : Rule_Def;
                  Next_St : State_ID;
               begin
                  if Act.Rule not in Rules'Range then
                     raise Invalid_Table_Error;
                  end if;
                  R := Rules (Act.Rule);

                  --  Ensure we have enough states to pop
                  if Top <= R.RHS_Length then
                     raise Parse_Error; --  Stack underflow
                  end if;
                  
                  Top := Top - R.RHS_Length;
                  Current_State := Stack (Top);

                  --  Lookup Next State in Goto table
                  if Current_State not in Gotos'Range (1) or else
                     R.LHS not in Gotos'Range (2)
                  then
                     raise Invalid_Table_Error;
                  end if;

                  Next_St := Gotos (Current_State, R.LHS);
                  if Next_St = Invalid_State then
                     raise Parse_Error;
                  end if;

                  Top := Top + 1;
                  if Top > Stack'Last then
                     raise Parse_Error;
                  end if;
                  Stack (Top) := Next_St;
               end;

            when Action_Accept =>
               return True;

            when Action_Error =>
               return False;
         end case;
      end loop;
   end Parse;

   function Generate_LALR_Mapping (LR1_States : LR1_State_Array) return LALR_Map is
      Result          : LALR_Map (LR1_States'Range) := [others => 0];
      Next_LALR_State : State_ID := 0;
      Found           : Boolean;
   begin
      if LR1_States'Length = 0 then
         return Result;
      end if;

      for I in LR1_States'Range loop
         Found := False;
         
         --  Check if a state with the identical core has already been assigned
         --  an LALR state ID. If so, merge this LR(1) state into it.
         for J in LR1_States'First .. I - 1 loop
            if LR1_States (J).Core_ID = LR1_States (I).Core_ID then
               Result (I) := Result (J);
               Found := True;
               exit;
            end if;
         end loop;

         --  If this is a newly discovered core, allocate a new LALR State ID
         if not Found then
            Result (I) := Next_LALR_State;
            if Next_LALR_State < State_ID'Last then
               Next_LALR_State := Next_LALR_State + 1;
            end if;
         end if;
      end loop;

      return Result;
   end Generate_LALR_Mapping;

end LALR_Parser;
