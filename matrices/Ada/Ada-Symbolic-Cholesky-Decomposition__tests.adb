-- tests.adb
-- Extensive Test suite to verify the V&V properties of the codebase.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Symbolic_Cholesky; use Symbolic_Cholesky;

procedure Tests is
   Empty_Mat : constant Matrix (1 .. 0, 1 .. 0) := (others => (others => False));
   
   -- Base case matrix: 1x1 
   Mat_1x1 : constant Matrix (1 .. 1, 1 .. 1) := (1 => (1 => True));
   
   -- Identity Matrix: 2x2 (No off-diagonal edges = no fill in)
   Mat_Id_2x2 : constant Matrix (1 .. 2, 1 .. 2) := 
     (1 => (True, False), 
      2 => (False, True));
      
   -- Star Graph: 3x3 where node 1 is connected to 2 and 3. 
   -- Expectation: Eliminating 1 causes fill-in between 2 and 3.
   Mat_Star_3x3 : constant Matrix (1 .. 3, 1 .. 3) :=
     (1 => (True, True, True),
      2 => (True, True, False),
      3 => (True, False, True));
      
   -- Path Graph: 3x3 where 1-2 and 2-3 are connected. 
   -- Expectation: No fill-in generated from node 1.
   Mat_Path_3x3 : constant Matrix (1 .. 3, 1 .. 3) :=
     (1 => (True, True, False),
      2 => (True, True, True),
      3 => (False, True, True));

begin
   Put_Line ("Starting V&V Test Suite - Assuming Implementation is Defective...");
   Put_Line ("------------------------------------------------------------------");

   Put_Line ("TEST 1 - Robustness: Matrix Shape Validation");
   Put_Line ("  1.1 Assert rectangular matrix raises Invalid_Matrix during Game");
   begin
      declare
         Bad_Mat : Matrix (1 .. 2, 1 .. 3) := (others => (others => False));
         Res : Matrix := Elimination_Game (Bad_Mat);
      begin
         Assert (False, "Should have raised exception");
      end;
   exception
      when Invalid_Matrix => Put_Line ("      PASS");
   end;

   Put_Line ("  1.2 Assert rectangular matrix raises Invalid_Matrix during Tree computation");
   begin
      declare
         Bad_Mat : Matrix (1 .. 2, 1 .. 3) := (others => (others => False));
         Res : Tree_Array := Compute_Elimination_Tree (Bad_Mat);
      begin
         Assert (False, "Should have raised exception");
      end;
   exception
      when Invalid_Matrix => Put_Line ("      PASS");
   end;


   Put_Line ("TEST 2 - Boundary Value Analysis: Empty Matrix");
   Put_Line ("  2.1 Assert empty matrix evaluates to empty pattern L");
   declare
      Res : constant Matrix := Elimination_Game (Empty_Mat);
   begin
      Assert (Res'Length(1) = 0, "Matrix not empty");
      Put_Line ("      PASS");
   end;

   Put_Line ("  2.2 Assert empty matrix computes to empty Tree");
   declare
      T : constant Tree_Array := Compute_Elimination_Tree (Empty_Mat);
   begin
      Assert (T'Length = 0, "Tree not empty");
      Put_Line ("      PASS");
   end;


   Put_Line ("TEST 3 - Base Case Functional Correctness (1x1)");
   declare
      L_1x1 : constant Matrix := Elimination_Game (Mat_1x1);
      T_1x1 : constant Tree_Array := Compute_Elimination_Tree (L_1x1);
   begin
      Put_Line ("  3.1 Assert 1x1 matrix generates True diagonal in L");
      Assert (L_1x1(1, 1) = True, "Diagonal failed");
      Put_Line ("      PASS");
      
      Put_Line ("  3.2 Assert 1x1 matrix has root 0 in Tree (no parent)");
      Assert (T_1x1(1) = 0, "Root dependency failed");
      Put_Line ("      PASS");
   end;


   Put_Line ("TEST 4 - Diagonal Matrix (2x2 Identity) Check");
   declare
      L_Id : constant Matrix := Elimination_Game (Mat_Id_2x2);
      T_Id : constant Tree_Array := Compute_Elimination_Tree (L_Id);
   begin
      Put_Line ("  4.1 Assert L(2,1) is False (no false fill-ins)");
      Assert (L_Id(2, 1) = False, "False fill-in generated");
      Put_Line ("      PASS");
      
      Put_Line ("  4.2 Assert nodes 1 and 2 are roots in Tree");
      Assert (T_Id(1) = 0 and T_Id(2) = 0, "False dependency created");
      Put_Line ("      PASS");
   end;


   Put_Line ("TEST 5 - Fill-in Generation (Parter's Algorithm)");
   declare
      L_Star : constant Matrix := Elimination_Game (Mat_Star_3x3);
      T_Star : constant Tree_Array := Compute_Elimination_Tree (L_Star);
   begin
      Put_Line ("  5.1 Assert Diagonal L(1,1) is True");
      Assert (L_Star(1, 1) = True, "Diagonal element missed");
      Put_Line ("      PASS");

      Put_Line ("  5.2 Assert original lower-triangular L(2,1) and L(3,1) remain True");
      Assert (L_Star(2, 1) = True and L_Star(3, 1) = True, "Original edges lost");
      Put_Line ("      PASS");

      Put_Line ("  5.3 Assert Parter's clique addition works - Fill-in L(3,2) must be True");
      Assert (L_Star(3, 2) = True, "Algorithm failed to compute fill-in");
      Put_Line ("      PASS");
      
      Put_Line ("  5.4 Assert Elimination Tree correctly resolves dependencies");
      Assert (T_Star(1) = 2, "Parent of 1 should be 2");
      Assert (T_Star(2) = 3, "Parent of 2 should be 3 (because of fill-in)");
      Assert (T_Star(3) = 0, "Parent of 3 should be 0 (root)");
      Put_Line ("      PASS");
   end;


   Put_Line ("TEST 6 - Path Graph Dynamics");
   declare
      L_Path : constant Matrix := Elimination_Game (Mat_Path_3x3);
   begin
      Put_Line ("  6.1 Assert L(3,1) remains False (node 1 doesn't cause fill-in for node 3)");
      Assert (L_Path(3, 1) = False, "Erroneous transitive fill-in detected");
      Put_Line ("      PASS");
   end;

   Put_Line ("------------------------------------------------------------------");
   Put_Line ("ALL 13+ ASSUMPTIONS DISPROVEN - SYSTEM VERIFIED.");
end Tests;
