-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Sethi_Ullman; use Sethi_Ullman;

procedure Tests is
   N1, N2, N3, N4, N5 : AST_Ptr;
   Insts : Instr_List;
begin
   Put_Line ("Starting Sethi-Ullman Verification & Validation Suite...");
   Put_Line ("========================================================");

   -- TEST 1 - Exception Handling
   Put_Line ("TEST 1 - Null Tree Handling");
   Put_Line ("  1.1 Assume: Code crashes on null tree input.");
   begin
      Label_Tree (null);
      Assert (False, "Null_Tree_Error not raised");
   exception
      when Null_Tree_Error =>
         Put_Line ("      PASS: Null tree gracefully rejected.");
   end;

   -- TEST 2 - Base Leaf Labeling
   Put_Line ("TEST 2 - Leaf Node Labeling (Standard)");
   Put_Line ("  2.1 Assume: Leaf nodes compute incorrect register weights.");
   N1 := new AST_Node'(Kind => Leaf_Node, Label => 0, Id => 10);
   Label_Tree (N1, Standard_Model, True);
   Assert (N1.Label = 1, "Left leaf should need 1 register");
   Put_Line ("      PASS: Left leaf weight is 1.");

   -- TEST 3 - Memory Operand Variant Labeling
   Put_Line ("TEST 3 - Memory Operand Asymmetry");
   Put_Line ("  3.1 Assume: Right-sided memory optimizations are ignored.");
   N2 := new AST_Node'(Kind => Leaf_Node, Label => 0, Id => 20);
   Label_Tree (N2, Memory_Operand, False);
   Assert (N2.Label = 0, "Right leaf in Mem Model should need 0 registers");
   Put_Line ("      PASS: Memory operand right leaf correctly assigned 0.");

   -- TEST 4 - Symmetric Tree Labeling
   Put_Line ("TEST 4 - Symmetric Tree Evaluation (L = R)");
   Put_Line ("  4.1 Assume: Algorithm fails L == R constraint (L+1).");
   N3 := new AST_Node'(Kind => Op_Node, Label => 0, Op => Op_Add, Left => N1, Right => N2);
   Label_Tree (N3, Standard_Model, True);
   Assert (N3.Label = 2, "1 + 1 should require 2 registers");
   Put_Line ("      PASS: L==R condition correctly increments max requirement.");

   -- TEST 5 - Asymmetric Tree Labeling
   Put_Line ("TEST 5 - Asymmetric Tree Evaluation (L /= R)");
   Put_Line ("  5.1 Assume: Max(L, R) logic is broken.");
   N4 := new AST_Node'(Kind => Leaf_Node, Label => 0, Id => 30);
   N5 := new AST_Node'(Kind => Op_Node, Label => 0, Op => Op_Mul, Left => N3, Right => N4);
   Label_Tree (N5, Standard_Model, True);
   Assert (N5.Label = 2, "Max(2, 1) should require 2 registers");
   Put_Line ("      PASS: Max function correctly determines weight.");

   -- TEST 6 - Standard Code Generation (No Spill)
   Put_Line ("TEST 6 - Unspilled Code Generation Length");
   Put_Line ("  6.1 Assume: Generates incorrect number of instructions.");
   Generate_Code (N3, 2, Insts);
   Assert (Natural(Insts.Length) = 3, "Add(L, L) should generate 3 instructions (Load, Load, Add)");
   Put_Line ("      PASS: Base tree code emission matches expected length.");

   -- TEST 7 - Instruction Output Verification
   Put_Line ("TEST 7 - Instruction Correctness");
   Put_Line ("  7.1 Assume: Opcode generation maps incorrectly.");
   Assert (Insts.Element(3).Opcode = Add, "Final instruction must be ADD");
   Put_Line ("      PASS: Map_Op correctly mapped Op_Add to Add instruction.");

   -- TEST 8 - Register Allocation Consistency
   Put_Line ("TEST 8 - Register Non-Overlapping");
   Put_Line ("  8.1 Assume: Registers overwrite each other.");
   Assert (Insts.Element(1).Dest.Value /= Insts.Element(2).Dest.Value, "Dest registers must differ");
   Put_Line ("      PASS: Register destinations are distinct.");

   -- TEST 9 - Left-Heavy Generation Order
   Put_Line ("TEST 9 - Left-Heavy Traversal Order");
   Put_Line ("  9.1 Assume: Code gen evaluates right child first unconditionally.");
   Generate_Code (N5, 3, Insts);
   -- N5 is Mul( N3(Add), N4(Leaf) ). Left is heavier.
   -- Should generate N3 first, then N4.
   Assert (Insts.Element(1).Src1.Value = 10, "Should load N1 (leftmost) first");
   Put_Line ("      PASS: Heavier left subtree generated first.");

   -- TEST 10 - Register Spilling Trigger
   Put_Line ("TEST 10 - Register Spilling Bounds");
   Put_Line ("  10.1 Assume: Spilling to memory never triggers when registers exhausted.");
   -- N5 requires 2 registers. Let's provide only 1 available register.
   Generate_Code (N5, 1, Insts);
   declare
      Has_Store : Boolean := False;
   begin
      for I in 1 .. Natural(Insts.Length) loop
         if Insts.Element(I).Opcode = Store then
            Has_Store := True;
         end if;
      end loop;
      Assert (Has_Store, "Spill to memory (STORE) missing");
      Put_Line ("      PASS: Exceeding available registers correctly triggered spilling.");
   end;

   -- TEST 11 - Register Spill Restoration
   Put_Line ("TEST 11 - Spilled Memory Restoration");
   Put_Line ("  11.1 Assume: Spilled registers are never reloaded.");
   declare
      Has_LoadMem : Boolean := False;
   begin
      for I in 1 .. Natural(Insts.Length) loop
         if Insts.Element(I).Opcode = Load_Mem then
            Has_LoadMem := True;
         end if;
      end loop;
      Assert (Has_LoadMem, "Load_Mem missing after spill");
      Put_Line ("      PASS: Memory successfully restored via Load_Mem.");
   end;

   -- TEST 12 - Commutative Optimization Swapping
   Put_Line ("TEST 12 - Commutative Optimization");
   Put_Line ("  12.1 Assume: Optimization fails to swap right-heavy trees.");
   -- Force N5 to be Right-Heavy
   N5.Op := Op_Add; 
   N5.Right := N3; -- Label 2
   N5.Left  := N4; -- Label 1
   Optimize_Commutative (N5);
   Assert (N5.Left.Label = 2, "Left child should now be heavier due to swap");
   Put_Line ("      PASS: Add operation children successfully swapped.");

   -- TEST 13 - Non-Commutative Safety
   Put_Line ("TEST 13 - Non-Commutative Safety Override");
   Put_Line ("  13.1 Assume: Algorithm illegally swaps subtraction.");
   N5.Op := Op_Sub;
   N5.Right := N3;
   N5.Left  := N4;
   Optimize_Commutative (N5);
   Assert (N5.Left.Label = 1, "Sub operation must NOT be swapped");
   Put_Line ("      PASS: Subtraction operation bypassed commutative swap.");

   -- TEST 14 - Memory Cleanup Validation
   Put_Line ("TEST 14 - Memory Leak Prevention");
   Put_Line ("  14.1 Assume: Free_Tree does not nullify root access.");
   Free_Tree (N5);
   Assert (N5 = null, "Tree root pointer should be null after free");
   Put_Line ("      PASS: AST safely deallocated.");

   Put_Line ("========================================================");
   Put_Line ("ALL TESTS PASSED SUCCESSFULLY.");
end Tests;
