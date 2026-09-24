-- tests.adb
-- Validation & Verification suite for the Context Tree Weighting package.
-- Over 13 test cases to disprove the assumption that the code is non-functional.

with Ada.Text_IO; use Ada.Text_IO;
with Context_Tree_Weighting; use Context_Tree_Weighting;

procedure Tests is

   procedure Assert_Float_Eq 
     (Actual, Expected : Long_Float; 
      Message : String) 
   is
      Tolerance : constant Long_Float := 0.000001;
   begin
      if abs (Actual - Expected) > Tolerance then
         Put_Line ("      FAIL: " & Message);
         raise Program_Error;
      else
         Put_Line ("      PASS: " & Message);
      end if;
   end Assert_Float_Eq;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("      FAIL: " & Message);
         raise Program_Error;
      else
         Put_Line ("      PASS: " & Message);
      end if;
   end Assert;

   Tree          : Context_Tree;
   Empty_Context : constant Bit_Array (1 .. 0) := (others => 0);
   Ctx_0         : constant Bit_Array (1 .. 1) := (1 => 0);
   Ctx_1         : constant Bit_Array (1 .. 1) := (1 => 1);
   Ctx_Long      : constant Bit_Array (1 .. 3) := (0, 1, 0);

begin
   Put_Line ("--- Starting CTW Test Suite ---");

   -- TEST 1
   Put_Line ("TEST 1 - Initialization");
   Tree := Initialize_Tree (Max_Depth => 2);
   Assert_Float_Eq 
     (Get_Weighted_Probability (Tree), 
      1.0, "Empty P_w = 1.0");
   Assert_Float_Eq 
     (Get_KT_Probability (Tree), 
      1.0, "Empty P_e = 1.0");

   -- TEST 2
   Put_Line ("TEST 2 - Zero-Order Update");
   Free_Tree (Tree);
   Tree := Initialize_Tree (Max_Depth => 0);
   Update (Tree, Empty_Context, 0);
   Assert_Float_Eq 
     (Get_KT_Probability (Tree), 
      0.5, "P_e 1 = 0.5");
   Assert_Float_Eq 
     (Get_Weighted_Probability (Tree), 
      0.5, "P_w 1 = 0.5");

   -- TEST 3
   Put_Line ("TEST 3 - Zero-Order Sequence 0 0");
   Update (Tree, Empty_Context, 0);
   Assert_Float_Eq 
     (Get_KT_Probability (Tree), 
      0.375, "P_e 2 = 0.375");

   -- TEST 4
   Put_Line ("TEST 4 - Zero-Order Mixed Sequence");
   Free_Tree (Tree);
   Tree := Initialize_Tree (Max_Depth => 0);
   Update (Tree, Empty_Context, 0);
   Update (Tree, Empty_Context, 1);
   Assert_Float_Eq 
     (Get_KT_Probability (Tree), 
      0.125, "P_e mixed");

   -- TEST 5
   Put_Line ("TEST 5 - Depth 1 No Context Traverse");
   Free_Tree (Tree);
   Tree := Initialize_Tree (Max_Depth => 1);
   Update (Tree, Empty_Context, 0);
   Assert_Float_Eq 
     (Get_Weighted_Probability (Tree), 
      0.75, "P_w depth 1 empty");

   -- TEST 6
   Put_Line ("TEST 6 - Depth 1 Traversal Child 0");
   Free_Tree (Tree);
   Tree := Initialize_Tree (Max_Depth => 1);
   Update (Tree, Ctx_0, 0);
   Assert_Float_Eq 
     (Get_Weighted_Probability (Tree), 
      0.5, "P_w child 0");

   -- TEST 7
   Put_Line ("TEST 7 - Depth 1 Traversal Child 1");
   Free_Tree (Tree);
   Tree := Initialize_Tree (Max_Depth => 1);
   Update (Tree, Ctx_1, 1);
   Assert_Float_Eq 
     (Get_Weighted_Probability (Tree), 
      0.5, "P_w child 1");

   -- TEST 8
   Put_Line ("TEST 8 - Uninitialized Fault");
   declare
      Uninit_Tree : Context_Tree;
      Caught      : Boolean := False;
   begin
      begin
         Update (Uninit_Tree, Ctx_0, 0);
      exception
         when Tree_Uninitialized => Caught := True;
      end;
      Assert (Caught, "Caught exception");
   end;

   -- TEST 9
   Put_Line ("TEST 9 - Depth Limit Enforcement");
   Free_Tree (Tree);
   Tree := Initialize_Tree (Max_Depth => 1);
   Update (Tree, Ctx_Long, 1); 
   Assert_Float_Eq 
     (Get_Weighted_Probability (Tree), 
      0.5, "Max Depth 1 cap");

   -- TEST 10
   Put_Line ("TEST 10 - Memory Freeing Integrity");
   Free_Tree (Tree);
   declare
      Caught : Boolean := False;
   begin
      begin
         Update (Tree, Ctx_0, 0);
      exception
         when Tree_Uninitialized => Caught := True;
      end;
      Assert (Caught, "Tree uninitialized");
   end;

   -- TEST 11
   Put_Line ("TEST 11 - Pattern Degradation");
   Tree := Initialize_Tree (0);
   Update (Tree, Empty_Context, 0);
   Update (Tree, Empty_Context, 1);
   Update (Tree, Empty_Context, 0);
   Assert_Float_Eq 
     (Get_KT_Probability (Tree), 
      0.0625, "P_e 3 ops");
   Update (Tree, Empty_Context, 1);
   Assert_Float_Eq 
     (Get_KT_Probability (Tree), 
      0.0234375, "P_e 4 ops");

   -- TEST 12
   Put_Line ("TEST 12 - Context Array Alignment");
   Free_Tree (Tree);
   Tree := Initialize_Tree (Max_Depth => 2);
   declare
      Shifted_Ctx : constant Bit_Array (4 .. 5) := 
        (4 => 1, 5 => 0);
   begin
      Update (Tree, Shifted_Ctx, 1);
      Assert_Float_Eq 
        (Get_Weighted_Probability (Tree), 
         0.5, "Shift index");
   end;

   -- TEST 13
   Put_Line ("TEST 13 - Float Underflow Check");
   Free_Tree (Tree);
   Tree := Initialize_Tree (Max_Depth => 0);
   for I in 1 .. 50 loop
      Update (Tree, Empty_Context, 0);
   end loop;
   Assert (Get_KT_Probability (Tree) > 0.0, "P_e > 0.0");
   Assert (Get_KT_Probability (Tree) < 0.1, "P_e < 0.1");

   Put_Line ("--- All Tests Executed Successfully ---");
end Tests;
