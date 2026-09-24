with Ada.Unchecked_Deallocation;
with Ada.Strings.Fixed;

package body Program_Synthesis is

   procedure Free_AST is new Ada.Unchecked_Deallocation (AST_Node, AST_Ptr);

   procedure Free (Program : in out AST_Ptr) is
   begin
      if Program /= null then
         case Program.Kind is
            when Var_X | Var_Out | Const_Val | Hole =>
               null;
            when Op_Add | Op_Sub =>
               Free (Program.Left);
               Free (Program.Right);
         end case;
         Free_AST (Program);
      end if;
   end Free;

   function Clone (Program : AST_Ptr) return AST_Ptr is
   begin
      case Program.Kind is
         when Var_X =>
            return new AST_Node'(Kind => Var_X);
         when Var_Out =>
            return new AST_Node'(Kind => Var_Out);
         when Const_Val =>
            return new AST_Node'(Kind => Const_Val, Value => Program.Value);
         when Hole =>
            return new AST_Node'(Kind => Hole, Hole_Id => Program.Hole_Id);
         when Op_Add =>
            return new AST_Node'(Kind => Op_Add,
                                 Left => Clone (Program.Left),
                                 Right => Clone (Program.Right));
         when Op_Sub =>
            return new AST_Node'(Kind => Op_Sub,
                                 Left => Clone (Program.Left),
                                 Right => Clone (Program.Right));
      end case;
   end Clone;

   function Evaluate_With_Holes 
     (Program : AST_Ptr; 
      X       : Value_Type; 
      Holes   : Hole_Values) return Value_Type 
   is
   begin
      case Program.Kind is
         when Var_X =>
            return X;
         when Var_Out =>
            raise Evaluation_Error; -- Cannot evaluate an isolated output variable
         when Const_Val =>
            return Program.Value;
         when Hole =>
            if Program.Hole_Id in Holes'Range then
               return Holes (Program.Hole_Id);
            else
               raise Evaluation_Error;
            end if;
         when Op_Add =>
            return Evaluate_With_Holes (Program.Left, X, Holes) + 
                   Evaluate_With_Holes (Program.Right, X, Holes);
         when Op_Sub =>
            return Evaluate_With_Holes (Program.Left, X, Holes) - 
                   Evaluate_With_Holes (Program.Right, X, Holes);
      end case;
   exception
      when Constraint_Error => 
         raise Evaluation_Error;
   end Evaluate_With_Holes;

   function Evaluate (Program : AST_Ptr; X : Value_Type) return Value_Type is
   begin
      return Evaluate_With_Holes (Program, X, Empty_Holes);
   end Evaluate;

   function Satisfies (Program : AST_Ptr; Examples : Example_Array) return Boolean is
   begin
      for E of Examples loop
         begin
            if Evaluate (Program, E.Input) /= E.Output then
               return False;
            end if;
         exception
            when Evaluation_Error =>
               return False;
         end;
      end loop;
      return True;
   end Satisfies;

   function Satisfies_With_Holes 
     (Program  : AST_Ptr; 
      Examples : Example_Array; 
      Holes    : Hole_Values) return Boolean 
   is
   begin
      for E of Examples loop
         begin
            if Evaluate_With_Holes (Program, E.Input, Holes) /= E.Output then
               return False;
            end if;
         exception
            when Evaluation_Error =>
               return False;
         end;
      end loop;
      return True;
   end Satisfies_With_Holes;

   -- Helper for Enumerative Synthesis
   procedure Generate_AST
     (Budget  : Positive;
      Handler : access procedure (Program : AST_Ptr; Stop : out Boolean);
      Stop    : out Boolean)
   is
   begin
      Stop := False;
      if Budget = 1 then
         declare
            P : AST_Ptr := new AST_Node'(Kind => Var_X);
         begin
            Handler (P, Stop);
            Free (P);
            if Stop then return; end if;
         end;
         -- Prioritize simplest non-negative constants (0, 1, 2) before negative values (-1)
         for C in Value_Type range 0 .. 2 loop
            declare
               P : AST_Ptr := new AST_Node'(Kind => Const_Val, Value => C);
            begin
               Handler (P, Stop);
               Free (P);
               if Stop then return; end if;
            end;
         end loop;
         declare
            P : AST_Ptr := new AST_Node'(Kind => Const_Val, Value => -1);
         begin
            Handler (P, Stop);
            Free (P);
            if Stop then return; end if;
         end;
      elsif Budget >= 3 then
         for L_B in 1 .. Budget - 2 loop
            declare
               R_B : constant Positive := Budget - 1 - L_B;
               
               procedure Handle_Left (L : AST_Ptr; S1 : out Boolean) is
                  procedure Handle_Right (R : AST_Ptr; S2 : out Boolean) is
                     P_Add : AST_Ptr := new AST_Node'(Op_Add, Clone (L), Clone (R));
                     P_Sub : AST_Ptr := new AST_Node'(Op_Sub, Clone (L), Clone (R));
                  begin
                     Handler (P_Add, S2);
                     if not S2 then Handler (P_Sub, S2); end if;
                     Free (P_Add);
                     Free (P_Sub);
                  end Handle_Right;
               begin
                  Generate_AST (R_B, Handle_Right'Access, S1);
               end Handle_Left;
               
               S_Left : Boolean := False;
            begin
               Generate_AST (L_B, Handle_Left'Access, S_Left);
               if S_Left then
                  Stop := True;
                  return;
               end if;
            end;
         end loop;
      end if;
   end Generate_AST;

   function Synthesize_By_Example
     (Examples   : Example_Array;
      Max_Budget : Positive) return AST_Ptr
   is
      Found_Program : AST_Ptr := null;
      Stop_Search   : Boolean := False;

      procedure Check_Program (Program : AST_Ptr; Stop : out Boolean) is
      begin
         if Satisfies (Program, Examples) then
            Found_Program := Clone (Program);
            Stop := True;
         else
            Stop := False;
         end if;
      end Check_Program;

   begin
      for B in 1 .. Max_Budget loop
         Generate_AST (B, Check_Program'Access, Stop_Search);
         if Stop_Search then
            return Found_Program;
         end if;
      end loop;
      raise Synthesis_Failed;
   end Synthesize_By_Example;

   -- Helper for Sketching
   function Count_Holes (Program : AST_Ptr) return Natural is
   begin
      if Program = null then
         return 0;
      end if;
      case Program.Kind is
         when Var_X | Var_Out | Const_Val =>
            return 0;
         when Hole =>
            return Program.Hole_Id;
         when Op_Add | Op_Sub =>
            return Natural'Max (Count_Holes (Program.Left), Count_Holes (Program.Right));
      end case;
   end Count_Holes;

   function Fill_Holes (Program : AST_Ptr; Holes : Hole_Values) return AST_Ptr is
   begin
      case Program.Kind is
         when Var_X | Var_Out | Const_Val =>
            return Clone (Program);
         when Hole =>
            return new AST_Node'(Kind => Const_Val, Value => Holes (Program.Hole_Id));
         when Op_Add =>
            return new AST_Node'(Op_Add, 
                                 Fill_Holes (Program.Left, Holes), 
                                 Fill_Holes (Program.Right, Holes));
         when Op_Sub =>
            return new AST_Node'(Op_Sub, 
                                 Fill_Holes (Program.Left, Holes), 
                                 Fill_Holes (Program.Right, Holes));
      end case;
   end Fill_Holes;

   function Synthesize_From_Sketch
     (Sketch    : AST_Ptr;
      Examples  : Example_Array;
      Max_Val   : Value_Type) return AST_Ptr
   is
      Max_Id : constant Natural := Count_Holes (Sketch);
      subtype Hole_Array is Hole_Values (1 .. Max_Id);
      Current_Holes : Hole_Array := [others => -Max_Val];
      Found : Boolean := False;

      procedure Enumerate_Holes (Index : Positive) is
      begin
         if Found then return; end if;
         if Index > Max_Id then
            if Satisfies_With_Holes (Sketch, Examples, Current_Holes) then
               Found := True;
            end if;
         else
            for V in -Max_Val .. Max_Val loop
               Current_Holes (Index) := V;
               Enumerate_Holes (Index + 1);
               if Found then return; end if;
            end loop;
         end if;
      end Enumerate_Holes;

   begin
      if Max_Id = 0 then
         if Satisfies (Sketch, Examples) then
            return Clone (Sketch);
         else
            raise Synthesis_Failed;
         end if;
      end if;

      Enumerate_Holes (1);
      if Found then
         return Fill_Holes (Sketch, Current_Holes);
      else
         raise Synthesis_Failed;
      end if;
   end Synthesize_From_Sketch;

   -- Helpers for Deductive Synthesis
   function Contains_Out (Program : AST_Ptr) return Boolean is
   begin
      if Program = null then return False; end if;
      case Program.Kind is
         when Var_Out => return True;
         when Var_X | Const_Val | Hole => return False;
         when Op_Add | Op_Sub =>
            return Contains_Out (Program.Left) or else Contains_Out (Program.Right);
      end case;
   end Contains_Out;

   procedure Step_Deductive (L, R : in out AST_Ptr; Progress : out Boolean) is
      New_L, New_R : AST_Ptr;
   begin
      Progress := False;
      if L.Kind = Op_Add then
         if Contains_Out (L.Left) and then not Contains_Out (L.Right) then
            -- Out + C = R  =>  Out = R - C
            New_L := Clone (L.Left);
            New_R := new AST_Node'(Op_Sub, Clone (R), Clone (L.Right));
            Free (L); Free (R);
            L := New_L; R := New_R;
            Progress := True;
         elsif Contains_Out (L.Right) and then not Contains_Out (L.Left) then
            -- C + Out = R  =>  Out = R - C
            New_L := Clone (L.Right);
            New_R := new AST_Node'(Op_Sub, Clone (R), Clone (L.Left));
            Free (L); Free (R);
            L := New_L; R := New_R;
            Progress := True;
         end if;
      elsif L.Kind = Op_Sub then
         if Contains_Out (L.Left) and then not Contains_Out (L.Right) then
            -- Out - C = R  =>  Out = R + C
            New_L := Clone (L.Left);
            New_R := new AST_Node'(Op_Add, Clone (R), Clone (L.Right));
            Free (L); Free (R);
            L := New_L; R := New_R;
            Progress := True;
         elsif Contains_Out (L.Right) and then not Contains_Out (L.Left) then
            -- C - Out = R  =>  Out = C - R
            New_L := Clone (L.Right);
            New_R := new AST_Node'(Op_Sub, Clone (L.Left), Clone (R));
            Free (L); Free (R);
            L := New_L; R := New_R;
            Progress := True;
         end if;
      end if;
   end Step_Deductive;

   function Synthesize_Deductive (Equation_Left, Equation_Right : AST_Ptr) return AST_Ptr is
      L : AST_Ptr := Clone (Equation_Left);
      R : AST_Ptr := Clone (Equation_Right);
      Progress : Boolean := True;
      Found    : Boolean := False;
   begin
      while Progress loop
         if L.Kind = Var_Out then
            Found := True;
            exit;
         end if;
         Step_Deductive (L, R, Progress);
      end loop;

      if Found then
         Free (L);
         return R;
      else
         Free (L);
         Free (R);
         raise Synthesis_Failed;
      end if;
   end Synthesize_Deductive;

   function To_String (Program : AST_Ptr) return String is
   begin
      if Program = null then 
         return "null"; 
      end if;
      case Program.Kind is
         when Var_X => 
            return "X";
         when Var_Out => 
            return "Out";
         when Const_Val => 
            return Ada.Strings.Fixed.Trim (Program.Value'Image, Ada.Strings.Left);
         when Hole => 
            return "?" & Ada.Strings.Fixed.Trim (Program.Hole_Id'Image, Ada.Strings.Left);
         when Op_Add => 
            return "(" & To_String (Program.Left) & " + " & To_String (Program.Right) & ")";
         when Op_Sub => 
            return "(" & To_String (Program.Left) & " - " & To_String (Program.Right) & ")";
      end case;
   end To_String;

end Program_Synthesis;
