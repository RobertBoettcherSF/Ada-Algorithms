-- sethi_ullman.adb
with Ada.Unchecked_Deallocation;

package body Sethi_Ullman is

   procedure Free is new Ada.Unchecked_Deallocation (AST_Node, AST_Ptr);

   procedure Free_Tree (Root : in out AST_Ptr) is
   begin
      if Root /= null then
         if Root.Kind = Op_Node then
            Free_Tree (Root.Left);
            Free_Tree (Root.Right);
         end if;
         Free (Root);
      end if;
   end Free_Tree;

   procedure Label_Tree 
     (Root    : AST_Ptr; 
      Model   : Machine_Model := Standard_Model; 
      Is_Left : Boolean := True) is
   begin
      if Root = null then
         raise Null_Tree_Error;
      end if;

      case Root.Kind is
         when Leaf_Node =>
            -- Variant: Memory-operand machines can use 0 registers for right-child leaves
            if Model = Memory_Operand and not Is_Left then
               Root.Label := 0;
            else
               Root.Label := 1;
            end if;
            
         when Op_Node =>
            Label_Tree (Root.Left, Model, True);
            Label_Tree (Root.Right, Model, False);
            
            if Root.Left.Label = Root.Right.Label then
               Root.Label := Root.Left.Label + 1;
            else
               Root.Label := Natural'Max(Root.Left.Label, Root.Right.Label);
            end if;
      end case;
   end Label_Tree;

   procedure Optimize_Commutative (Root : AST_Ptr) is
      Temp : AST_Ptr;
   begin
      if Root = null or else Root.Kind = Leaf_Node then
         return;
      end if;
      
      Optimize_Commutative (Root.Left);
      Optimize_Commutative (Root.Right);
      
      -- If operation is commutative and right child is heavier, swap them
      -- This ensures left-heavy evaluation, often reducing register pressure.
      if Root.Op = Op_Add or Root.Op = Op_Mul then
         if Root.Right.Label > Root.Left.Label then
            Temp       := Root.Left;
            Root.Left  := Root.Right;
            Root.Right := Temp;
         end if;
      end if;
   end Optimize_Commutative;

   function Map_Op (O : Op_Kind) return Instr_Op is
   begin
      case O is
         when Op_Add => return Add;
         when Op_Sub => return Sub;
         when Op_Mul => return Mul;
         when Op_Div => return Div;
      end case;
   end Map_Op;

   procedure Generate_Code
     (Root          : AST_Ptr;
      Available_Reg : Positive;
      Instructions  : out Instr_List) 
   is
      Spill_Count : Natural := 0;

      -- Recursive Helper
      procedure Gen (Node : AST_Ptr; Base_Reg : Positive; Max_Reg : Positive) is
         L, R : AST_Ptr;
      begin
         if Node = null then
            raise Null_Tree_Error;
         end if;

         if Node.Kind = Leaf_Node then
            Instructions.Append
              ((Opcode => Load, 
                Dest   => (Reg, Base_Reg), 
                Src1   => (Imm, Node.Id), 
                Src2   => (Imm, 0)));
         else
            L := Node.Left;
            R := Node.Right;

            -- VARIANT: Spilling to Memory (when registers are exhausted)
            if Node.Label > Max_Reg then
               if L.Label >= R.Label then
                  Gen (L, Base_Reg, Max_Reg);
                  Spill_Count := Spill_Count + 1;
                  Instructions.Append
                    ((Opcode => Store, 
                      Dest   => (Mem, Spill_Count), 
                      Src1   => (Reg, Base_Reg), 
                      Src2   => (Imm, 0)));
                  
                  Gen (R, Base_Reg, Max_Reg);
                  Instructions.Append
                    ((Opcode => Load_Mem, 
                      Dest   => (Reg, Base_Reg + 1), 
                      Src1   => (Mem, Spill_Count), 
                      Src2   => (Imm, 0)));
                      
                  Instructions.Append
                    ((Opcode => Map_Op(Node.Op), 
                      Dest   => (Reg, Base_Reg), 
                      Src1   => (Reg, Base_Reg), 
                      Src2   => (Reg, Base_Reg + 1)));
               else
                  -- Right is heavier, evaluate it first
                  Gen (R, Base_Reg, Max_Reg);
                  Spill_Count := Spill_Count + 1;
                  Instructions.Append
                    ((Opcode => Store, 
                      Dest   => (Mem, Spill_Count), 
                      Src1   => (Reg, Base_Reg), 
                      Src2   => (Imm, 0)));
                      
                  Gen (L, Base_Reg, Max_Reg);
                  Instructions.Append
                    ((Opcode => Load_Mem, 
                      Dest   => (Reg, Base_Reg + 1), 
                      Src1   => (Mem, Spill_Count), 
                      Src2   => (Imm, 0)));
                      
                  Instructions.Append
                    ((Opcode => Map_Op(Node.Op), 
                      Dest   => (Reg, Base_Reg), 
                      Src1   => (Reg, Base_Reg + 1), 
                      Src2   => (Reg, Base_Reg)));
               end if;
            else
               -- VARIANT: Standard Code Gen (No Spilling)
               if L.Label >= R.Label then
                  Gen (L, Base_Reg, Max_Reg);
                  Gen (R, Base_Reg + 1, Max_Reg);
                  Instructions.Append
                    ((Opcode => Map_Op(Node.Op), 
                      Dest   => (Reg, Base_Reg), 
                      Src1   => (Reg, Base_Reg), 
                      Src2   => (Reg, Base_Reg + 1)));
               else
                  Gen (R, Base_Reg, Max_Reg);
                  Gen (L, Base_Reg + 1, Max_Reg);
                  Instructions.Append
                    ((Opcode => Map_Op(Node.Op), 
                      Dest   => (Reg, Base_Reg), 
                      Src1   => (Reg, Base_Reg + 1), 
                      Src2   => (Reg, Base_Reg)));
               end if;
            end if;
         end if;
      end Gen;

   begin
      Instructions.Clear;
      if Root = null then
         raise Null_Tree_Error;
      end if;
      Gen (Root, 1, Available_Reg); -- Assume registers start at index 1
   end Generate_Code;

end Sethi_Ullman;
