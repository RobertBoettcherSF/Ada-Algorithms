with Ada.Numerics.Elementary_Functions;
with Ada.Unchecked_Deallocation;

package body Shunting_Yard is

   -----------------------------------------------------------------------------
   -- Operator Helper Implementation
   -----------------------------------------------------------------------------

   function Precedence (Op : Operator_Kind) return Positive is
   begin
      case Op is
         when Power               => return 4;
         when Multiply | Divide   => return 3;
         when Add | Subtract      => return 2;
      end case;
   end Precedence;

   function Associativity (Op : Operator_Kind) return Associativity_Type is
   begin
      case Op is
         when Power  => return Right;
         when others => return Left;
      end case;
   end Associativity;

   -----------------------------------------------------------------------------
   -- Internal Stacks Infrastructure
   -----------------------------------------------------------------------------

   type Token_Stack is record
      Elements : Token_Array (1 .. Max_Tokens);
      Top      : Natural := 0;
   end record;

   procedure Push (S : in out Token_Stack; T : Token) is
   begin
      if S.Top >= Max_Tokens then
         raise Capacity_Exceeded;
      end if;
      S.Top := S.Top + 1;
      S.Elements (S.Top) := T;
   end Push;

   function Peek (S : Token_Stack) return Token is
   begin
      if S.Top = 0 then
         raise Invalid_Expression;
      end if;
      return S.Elements (S.Top);
   end Peek;

   procedure Discard (S : in out Token_Stack) is
   begin
      if S.Top > 0 then
         S.Top := S.Top - 1;
      end if;
   end Discard;

   function Is_Empty (S : Token_Stack) return Boolean is (S.Top = 0);

   procedure Push_Queue (Q : in out Token_List; T : Token) is
   begin
      if Q.Length >= Max_Tokens then
         raise Capacity_Exceeded;
      end if;
      Q.Length := Q.Length + 1;
      Q.Elements (Q.Length) := T;
   end Push_Queue;

   -----------------------------------------------------------------------------
   -- Variant 1: Shunting-yard Infix to RPN
   -----------------------------------------------------------------------------

   function To_Reverse_Polish_Notation (Infix : Token_Array) return Token_List is
      Op_Stack  : Token_Stack;
      Out_Queue : Token_List;
   begin
      for I in Infix'Range loop
         declare
            T : constant Token := Infix (I);
         begin
            case T.Class is
               when Number =>
                  Push_Queue (Out_Queue, T);
               
               when Func =>
                  Push (Op_Stack, T);
               
               when Comma =>
                  -- Pop operators to output until we hit a left parenthesis
                  loop
                     if Is_Empty (Op_Stack) then
                        raise Mismatched_Parentheses;
                     end if;
                     exit when Peek (Op_Stack).Class = Left_Paren;
                     Push_Queue (Out_Queue, Peek (Op_Stack));
                     Discard (Op_Stack);
                  end loop;
               
               when Operator =>
                  while not Is_Empty (Op_Stack) loop
                     declare
                        Top_Op : constant Token := Peek (Op_Stack);
                     begin
                        if Top_Op.Class = Operator then
                           if (Precedence (Top_Op.Op) > Precedence (T.Op)) or else
                              (Precedence (Top_Op.Op) = Precedence (T.Op) and then Associativity (T.Op) = Left)
                           then
                              Push_Queue (Out_Queue, Top_Op);
                              Discard (Op_Stack);
                           else
                              exit;
                           end if;
                        else
                           exit; -- Do not pop left parenthesis or functions over operators directly here
                        end if;
                     end;
                  end loop;
                  Push (Op_Stack, T);
               
               when Left_Paren =>
                  Push (Op_Stack, T);
               
               when Right_Paren =>
                  -- Discard operators to queue until left parenthesis
                  loop
                     if Is_Empty (Op_Stack) then
                        raise Mismatched_Parentheses;
                     end if;
                     exit when Peek (Op_Stack).Class = Left_Paren;
                     Push_Queue (Out_Queue, Peek (Op_Stack));
                     Discard (Op_Stack);
                  end loop;
                  Discard (Op_Stack); -- Pop the left parenthesis and discard
                  
                  -- If function sits right before parenthesis, output it
                  if not Is_Empty (Op_Stack) and then Peek (Op_Stack).Class = Func then
                     Push_Queue (Out_Queue, Peek (Op_Stack));
                     Discard (Op_Stack);
                  end if;
            end case;
         end;
      end loop;

      -- Unroll remaining operators
      while not Is_Empty (Op_Stack) loop
         if Peek (Op_Stack).Class = Left_Paren or else Peek (Op_Stack).Class = Right_Paren then
            raise Mismatched_Parentheses;
         end if;
         Push_Queue (Out_Queue, Peek (Op_Stack));
         Discard (Op_Stack);
      end loop;

      return Out_Queue;
   end To_Reverse_Polish_Notation;

   -----------------------------------------------------------------------------
   -- Variant 2: AST Construction
   -----------------------------------------------------------------------------

   type Node_Array is array (Positive range <>) of AST_Node_Access;
   type Node_Stack is record
      Elements : Node_Array (1 .. Max_Tokens);
      Top      : Natural := 0;
   end record;

   procedure Push_Node (S : in out Node_Stack; N : AST_Node_Access) is
   begin
      if S.Top >= Max_Tokens then
         raise Capacity_Exceeded;
      end if;
      S.Top := S.Top + 1;
      S.Elements (S.Top) := N;
   end Push_Node;

   function Pop_Node (S : in out Node_Stack) return AST_Node_Access is
   begin
      if S.Top = 0 then
         raise Invalid_Expression;
      end if;
      S.Top := S.Top - 1;
      return S.Elements (S.Top + 1);
   end Pop_Node;

   function To_AST (RPN : Token_List) return AST_Node_Access is
      Stack    : Node_Stack;
      New_Node : AST_Node_Access;
      Right, Left : AST_Node_Access;
   begin
      if RPN.Length = 0 then
         raise Invalid_Expression;
      end if;

      for I in 1 .. RPN.Length loop
         declare
            T : constant Token := RPN.Elements (I);
         begin
            case T.Class is
               when Number =>
                  New_Node := new AST_Node'(Class => Number, Value => T.Value);
                  Push_Node (Stack, New_Node);
               
               when Operator =>
                  Right := Pop_Node (Stack);
                  Left  := Pop_Node (Stack);
                  New_Node := new AST_Node'(Class       => Operator, 
                                            Op          => T.Op, 
                                            Left_Child  => Left, 
                                            Right_Child => Right);
                  Push_Node (Stack, New_Node);
               
               when Func =>
                  if T.Fun = Sin or else T.Fun = Cos then
                     Left := Pop_Node (Stack);
                     New_Node := new AST_Node'(Class => Func, Fun => T.Fun, Arg1 => Left, Arg2 => null);
                  else
                     -- Max2 requires 2 arguments
                     Right := Pop_Node (Stack);
                     Left  := Pop_Node (Stack);
                     New_Node := new AST_Node'(Class => Func, Fun => T.Fun, Arg1 => Left, Arg2 => Right);
                  end if;
                  Push_Node (Stack, New_Node);
               
               when others =>
                  raise Invalid_Expression; -- RPN cannot contain parens or commas
            end case;
         end;
      end loop;
      
      if Stack.Top /= 1 then
         raise Invalid_Expression; -- Disconnected tree fragments remain
      end if;
      
      return Pop_Node (Stack);
   end To_AST;

   -----------------------------------------------------------------------------
   -- Variant 3: Execute RPN stream
   -----------------------------------------------------------------------------

   type Value_Array is array (Positive range <>) of Float;
   type Value_Stack is record
      Elements : Value_Array (1 .. Max_Tokens);
      Top      : Natural := 0;
   end record;

   procedure Push_Value (S : in out Value_Stack; V : Float) is
   begin
      if S.Top >= Max_Tokens then
         raise Capacity_Exceeded;
      end if;
      S.Top := S.Top + 1;
      S.Elements (S.Top) := V;
   end Push_Value;

   function Pop_Value (S : in out Value_Stack) return Float is
   begin
      if S.Top = 0 then
         raise Invalid_Expression;
      end if;
      S.Top := S.Top - 1;
      return S.Elements (S.Top + 1);
   end Pop_Value;

   function Evaluate_RPN (RPN : Token_List) return Float is
      Stack : Value_Stack;
      Right, Left : Float;
   begin
      if RPN.Length = 0 then
         raise Invalid_Expression;
      end if;

      for I in 1 .. RPN.Length loop
         declare
            T : constant Token := RPN.Elements (I);
         begin
            case T.Class is
               when Number =>
                  Push_Value (Stack, T.Value);
               
               when Operator =>
                  Right := Pop_Value (Stack);
                  Left  := Pop_Value (Stack);
                  case T.Op is
                     when Add      => Push_Value (Stack, Left + Right);
                     when Subtract => Push_Value (Stack, Left - Right);
                     when Multiply => Push_Value (Stack, Left * Right);
                     when Power    => Push_Value (Stack, Ada.Numerics.Elementary_Functions."**" (Left, Right));
                     when Divide   =>
                        if Right = 0.0 then
                           raise Math_Error;
                        end if;
                        Push_Value (Stack, Left / Right);
                  end case;
               
               when Func =>
                  if T.Fun = Sin then
                     Push_Value (Stack, Ada.Numerics.Elementary_Functions.Sin (Pop_Value (Stack)));
                  elsif T.Fun = Cos then
                     Push_Value (Stack, Ada.Numerics.Elementary_Functions.Cos (Pop_Value (Stack)));
                  elsif T.Fun = Max2 then
                     Right := Pop_Value (Stack);
                     Left  := Pop_Value (Stack);
                     Push_Value (Stack, Float'Max (Left, Right));
                  end if;
                  
               when others =>
                  raise Invalid_Expression;
            end case;
         end;
      end loop;
      
      if Stack.Top /= 1 then
         raise Invalid_Expression;
      end if;
      
      return Pop_Value (Stack);
   end Evaluate_RPN;

   -----------------------------------------------------------------------------
   -- Variant 4: Execute AST Evaluator
   -----------------------------------------------------------------------------

   function Evaluate_AST (Node : AST_Node_Access) return Float is
      Left, Right : Float;
   begin
      case Node.Class is
         when Number =>
            return Node.Value;
            
         when Operator =>
            Left  := Evaluate_AST (Node.Left_Child);
            Right := Evaluate_AST (Node.Right_Child);
            case Node.Op is
               when Add      => return Left + Right;
               when Subtract => return Left - Right;
               when Multiply => return Left * Right;
               when Power    => return Ada.Numerics.Elementary_Functions."**" (Left, Right);
               when Divide   =>
                  if Right = 0.0 then
                     raise Math_Error;
                  end if;
                  return Left / Right;
            end case;
            
         when Func =>
            Left := Evaluate_AST (Node.Arg1);
            if Node.Fun = Max2 then
               Right := Evaluate_AST (Node.Arg2);
               return Float'Max (Left, Right);
            elsif Node.Fun = Sin then
               return Ada.Numerics.Elementary_Functions.Sin (Left);
            else
               return Ada.Numerics.Elementary_Functions.Cos (Left);
            end if;
            
         when others =>
            raise Invalid_Expression;
      end case;
   end Evaluate_AST;

   -----------------------------------------------------------------------------
   -- Memory Management Helper
   -----------------------------------------------------------------------------

   procedure Free is new Ada.Unchecked_Deallocation (AST_Node, AST_Node_Access);

   procedure Free_AST (Node : in out AST_Node_Access) is
   begin
      if Node /= null then
         if Node.Class = Operator then
            Free_AST (Node.Left_Child);
            Free_AST (Node.Right_Child);
         elsif Node.Class = Func then
            Free_AST (Node.Arg1);
            if Node.Arg2 /= null then
               Free_AST (Node.Arg2);
            end if;
         end if;
         Free (Node);
      end if;
   end Free_AST;

end Shunting_Yard;
