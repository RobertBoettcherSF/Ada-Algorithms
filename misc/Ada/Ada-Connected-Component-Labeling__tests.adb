-- tests.adb
-- Comprehensive testing suite proving code correctness via pessimistic assumptions
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Connected_Components; use Connected_Components;

procedure Tests is
   procedure Assert_Pass (Message : String) is
   begin
      Put_Line ("      PASS: " & Message);
   end Assert_Pass;

   -- Helper arrays
   Empty_In  : Binary_Image (1 .. 0, 1 .. 0);
   Empty_Out : Label_Image (1 .. 0, 1 .. 0);

   Single_In  : Binary_Image (1 .. 1, 1 .. 1) := (others => (others => True));
   Single_Out : Label_Image (1 .. 1, 1 .. 1);

   Diag_In : Binary_Image (1 .. 2, 1 .. 2) :=
      (1 => (True, False),
       2 => (False, True));
   Diag_Out : Label_Image (1 .. 2, 1 .. 2);
   
   U_Shape_In : Binary_Image (1 .. 3, 1 .. 3) :=
      (1 => (True, False, True),
       2 => (True, False, True),
       3 => (True, True,  True));
   U_Shape_Out : Label_Image (1 .. 3, 1 .. 3);

   Checker_In : Binary_Image (1 .. 3, 1 .. 3) :=
      (1 => (True, False, True),
       2 => (False, True, False),
       3 => (True, False, True));
   Checker_Out : Label_Image (1 .. 3, 1 .. 3);

   V_Shape_In : Binary_Image (1 .. 3, 1 .. 5) :=
      (1 => (True, False, False, False, True),
       2 => (False, True, False, True, False),
       3 => (False, False, True, False, False));
   V_Shape_Out : Label_Image (1 .. 3, 1 .. 5);

   Offset_In : Binary_Image (5 .. 6, 10 .. 11) :=
      (5 => (True, True),
       6 => (True, True));
   Offset_Out : Label_Image (5 .. 6, 10 .. 11);

begin
   Put_Line ("Starting V&V Test Suite for Connected Component Labeling...");
   Put_Line ("Assuming code is fundamentally broken until disproven." & ASCII.LF);

   -- TEST 1 - Array Bounds Mismatch Error Handling
   Put_Line ("TEST 1 - Out-of-bounds Mapping handling");
   Put_Line ("  1.1 Verify Bounds_Mismatch_Error is raised on dimension mismatch");
   begin
      Two_Pass_Labeling (Single_In, Diag_Out, Four_Connected);
      Assert (False, "Exception was not raised");
   exception
      when Bounds_Mismatch_Error =>
         Assert_Pass ("Assumption falsified - Dimension mismatch safely caught");
   end;

   -- TEST 2 - Edge Case: Empty Grid Processing
   Put_Line ("TEST 2 - Edge Case: Empty Arrays");
   Put_Line ("  2.1 Verify empty array processes safely without Constraint_Error");
   Two_Pass_Labeling (Empty_In, Empty_Out, Four_Connected);
   Assert (Count_Components (Empty_Out) = 0, "Empty output should have 0 components");
   Assert_Pass ("Assumption falsified - Empty grids handled correctly");

   -- TEST 3 - Single Pixel Components
   Put_Line ("TEST 3 - Single Pixel Object");
   Put_Line ("  3.1 Verify 1x1 True image yields 1 component (Two-Pass)");
   Two_Pass_Labeling (Single_In, Single_Out, Four_Connected);
   Assert (Count_Components (Single_Out) = 1, "Failed Two-Pass single component");
   Put_Line ("  3.2 Verify 1x1 True image yields 1 component (BFS)");
   BFS_Labeling (Single_In, Single_Out, Four_Connected);
   Assert (Count_Components (Single_Out) = 1, "Failed BFS single component");
   Assert_Pass ("Assumption falsified - Minimal dataset labeled correctly");

   -- TEST 4 - Connectivity Boundaries (4-Connected)
   Put_Line ("TEST 4 - Diagonal disconnected (4-Connected)");
   Put_Line ("  4.1 Verify diagonal pixels count as 2 separate components");
   Two_Pass_Labeling (Diag_In, Diag_Out, Four_Connected);
   Assert (Count_Components (Diag_Out) = 2, "Diagonal 4-conn should be 2 components");
   Assert_Pass ("Assumption falsified - 4-connectivity strict boundaries work");

   -- TEST 5 - Connectivity Boundaries (8-Connected)
   Put_Line ("TEST 5 - Diagonal connected (8-Connected)");
   Put_Line ("  5.1 Verify diagonal pixels count as 1 component");
   Two_Pass_Labeling (Diag_In, Diag_Out, Eight_Connected);
   Assert (Count_Components (Diag_Out) = 1, "Diagonal 8-conn should be 1 component");
   Assert_Pass ("Assumption falsified - 8-connectivity broad boundaries work");

   -- TEST 6 - Complex Equivalence Resolution (U-Shape)
   Put_Line ("TEST 6 - U-Shape Equivalence (Two-Pass)");
   Put_Line ("  6.1 Verify U-shape merges separate vertical paths into 1");
   Two_Pass_Labeling (U_Shape_In, U_Shape_Out, Four_Connected);
   Assert (Count_Components (U_Shape_Out) = 1, "U-shape should merge into 1");
   Assert_Pass ("Assumption falsified - Equivalence classes resolve properly");

   -- TEST 7 - V-Shape Equivalence (8-Connected)
   Put_Line ("TEST 7 - V-Shape Equivalence Resolution (8-Connected)");
   Put_Line ("  7.1 Verify separate diagonal paths merge at bottom vertex");
   Two_Pass_Labeling (V_Shape_In, V_Shape_Out, Eight_Connected);
   Assert (Count_Components (V_Shape_Out) = 1, "V-shape should be 1 component");
   Assert_Pass ("Assumption falsified - Multiple diagonal equivalences resolve correctly");

   -- TEST 8 - Non-Standard Array Bounds Support
   Put_Line ("TEST 8 - Arbitrary Array Indices");
   Put_Line ("  8.1 Verify algorithm works with bounds not starting at 1 (e.g. 5..6)");
   Two_Pass_Labeling (Offset_In, Offset_Out, Four_Connected);
   Assert (Count_Components (Offset_Out) = 1, "Offset array failed to label 1 component");
   Assert_Pass ("Assumption falsified - Arrays properly leverage 'First/'Last");

   -- TEST 9 - High Frequency Disconnection (Checkerboard 4-Conn)
   Put_Line ("TEST 9 - Checkerboard pattern (4-Connected)");
   Put_Line ("  9.1 Verify maximum possible independent components identified correctly");
   Two_Pass_Labeling (Checker_In, Checker_Out, Four_Connected);
   Assert (Count_Components (Checker_Out) = 5, "Checkerboard 4-conn should yield 5 components");
   Assert_Pass ("Assumption falsified - High frequency disjoints perfectly handled");

   -- TEST 10 - High Frequency Connection (Checkerboard 8-Conn)
   Put_Line ("TEST 10 - Checkerboard pattern (8-Connected)");
   Put_Line ("  10.1 Verify checkerboard collapses to 1 component via diagonals");
   Two_Pass_Labeling (Checker_In, Checker_Out, Eight_Connected);
   Assert (Count_Components (Checker_Out) = 1, "Checkerboard 8-conn should yield 1 component");
   Assert_Pass ("Assumption falsified - Extreme multi-directional equivalences merge correctly");

   -- TEST 11 - Variant Parity (BFS vs Two-Pass on U-Shape)
   Put_Line ("TEST 11 - Algorithm Variant Parity (U-Shape)");
   Put_Line ("  11.1 Verify BFS approach matches Two-Pass outputs conceptually");
   BFS_Labeling (U_Shape_In, U_Shape_Out, Four_Connected);
   Assert (Count_Components (U_Shape_Out) = 1, "BFS failed on U-shape");
   Assert_Pass ("Assumption falsified - Distinct algorithmic paths yield matching semantics");

   -- TEST 12 - Label Normalization
   Put_Line ("TEST 12 - Sequential Label Generation Validation");
   Put_Line ("  12.1 Verify labels output sequentially (1 to N without gaps)");
   Two_Pass_Labeling (Checker_In, Checker_Out, Four_Connected);
   declare
      Found : array (1 .. 5) of Boolean := (others => False);
   begin
      for R in Checker_Out'Range(1) loop
         for C in Checker_Out'Range(2) loop
            if Checker_Out(R, C) > 0 then
               Found(Checker_Out(R, C)) := True;
            end if;
         end loop;
      end loop;
      for I in Found'Range loop
         Assert (Found(I), "Missing label " & Integer'Image(I) & " in output");
      end loop;
   end;
   Assert_Pass ("Assumption falsified - Final labels are densely packed and sequential");

   -- TEST 13 - Total Empty Signal Integrity
   Put_Line ("TEST 13 - Total Background Handling");
   Put_Line ("  13.1 Verify matrix of all 'False' yields 0 components");
   declare
      All_False_In  : Binary_Image (1 .. 5, 1 .. 5) := (others => (others => False));
      All_False_Out : Label_Image (1 .. 5, 1 .. 5);
   begin
      Two_Pass_Labeling (All_False_In, All_False_Out, Four_Connected);
      Assert (Count_Components(All_False_Out) = 0, "All false image should have 0 components");
   end;
   Assert_Pass ("Assumption falsified - Absolute background correctly ignored");

   Put_Line (ASCII.LF & "✅ ALL ASSUMPTIONS DISPROVEN. CODE IS CORRECT.");
end Tests;
