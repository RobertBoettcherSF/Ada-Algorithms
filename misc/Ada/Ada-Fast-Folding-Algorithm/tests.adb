with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Fast_Folding; use Fast_Folding;

procedure Tests is
   procedure Run_Tests is
      Empty_Data         : Signal_Array (1 .. 0);
      Basic_Data         : Signal_Array (1 .. 8) := (1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0);
      Profile_Res        : Profile_Array (1 .. 4);
      Profile_Res_Short  : Profile_Array (1 .. 2);
      Matrix_Res         : Profile_Matrix (1 .. 2, 1 .. 4);
      Matrix_Res_Invalid : Profile_Matrix (1 .. 3, 1 .. 4);
      Total_Sum          : Signal_Value := 0.0;
   begin
      Put_Line ("========================================");
      Put_Line ("Starting Test Suite for Fast Folding");
      Put_Line ("========================================");

      Put_Line ("TEST 1 - Constant Period Fold (Valid Basic Data)");
      Constant_Period_Fold (Basic_Data, 4, Profile_Res);
      Put_Line ("  1.1 Assert Phase 1 sums correctly");
      Assert (Profile_Res (1) = 2.0, "Phase 1 failed");
      Put_Line ("     PASS");
      Put_Line ("  1.2 Assert Phase 4 sums correctly");
      Assert (Profile_Res (4) = 8.0, "Phase 4 failed");
      Put_Line ("     PASS");
      
      Put_Line ("TEST 2 - Constant Period Fold (Dimension Mismatch)");
      Put_Line ("  2.1 Assert raising Invalid_Period_Error when lengths misalign");
      begin
         Constant_Period_Fold (Basic_Data, 4, Profile_Res_Short);
         Assert (False, "Expected Invalid_Period_Error not raised");
      exception
         when Invalid_Period_Error => Put_Line ("     PASS");
      end;
      
      Put_Line ("TEST 3 - Constant Period Fold (Empty Data Boundary)");
      Constant_Period_Fold (Empty_Data, 4, Profile_Res);
      Put_Line ("  3.1 Assert empty data safely yields all zeros");
      Assert (Profile_Res (1) = 0.0 and Profile_Res (4) = 0.0, "Empty data did not yield zeros");
      Put_Line ("     PASS");

      Put_Line ("TEST 4 - Fast Fold (Valid Base Execution)");
      Fast_Fold (Basic_Data, 4, 2, Matrix_Res);
      Put_Line ("  4.1 Assert Matrix Row 1 Phase 1 is correct (Shift 0)");
      Assert (Matrix_Res (1, 1) = 2.0, "Matrix (1,1) failed");
      Put_Line ("     PASS");

      Put_Line ("TEST 5 - Fast Fold (Non Power-of-2 Segments)");
      Put_Line ("  5.1 Assert raising Invalid_Segments_Error for Segments = 3");
      begin
         Fast_Fold (Basic_Data, 4, 3, Matrix_Res_Invalid);
         Assert (False, "Expected Invalid_Segments_Error not raised");
      exception
         when Invalid_Segments_Error => Put_Line ("     PASS");
      end;

      Put_Line ("TEST 6 - Fast Fold (Output Dimension Mismatch)");
      Put_Line ("  6.1 Assert raising Invalid_Period_Error for bad Result matrix");
      begin
         declare
            Bad_Res : Profile_Matrix (1 .. 2, 1 .. 3);
         begin
            Fast_Fold (Basic_Data, 4, 2, Bad_Res);
            Assert (False, "Expected Invalid_Period_Error not raised");
         end;
      exception
         when Invalid_Period_Error => Put_Line ("     PASS");
      end;

      Put_Line ("TEST 7 - Constant Period Fold (Single Element)");
      Put_Line ("  7.1 Assert algorithm folds correctly for a size-1 array");
      declare
         Single_Data : Signal_Array (1 .. 1) := (1 => 5.5);
         Single_Res  : Profile_Array (1 .. 2);
      begin
         Constant_Period_Fold (Single_Data, 2, Single_Res);
         Assert (Single_Res (1) = 5.5, "Single element Phase 1 failed");
         Assert (Single_Res (2) = 0.0, "Single element Phase 2 failed");
         Put_Line ("     PASS");
      end;

      Put_Line ("TEST 8 - Fast Fold (Energy Conservation Check)");
      Put_Line ("  8.1 Assert total sum of matrix row 1 equals sum of all inputs");
      Total_Sum := Matrix_Res (1, 1) + Matrix_Res (1, 2) + Matrix_Res (1, 3) + Matrix_Res (1, 4);
      Assert (Total_Sum = 20.0, "Energy conservation check failed");
      Put_Line ("     PASS");

      Put_Line ("TEST 9 - Constant Period Fold (Custom Array Bounds)");
      Put_Line ("  9.1 Assert custom array offsets do not corrupt folding index mapping");
      declare
         Offset_Data : Signal_Array (10 .. 17) := (1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0);
      begin
         Constant_Period_Fold (Offset_Data, 4, Profile_Res);
         Assert (Profile_Res (1) = 2.0, "Offset Phase 1 failed");
         Put_Line ("     PASS");
      end;

      Put_Line ("TEST 10 - Fast Fold (Shift Validation on Bottom Branch)");
      Put_Line ("  10.1 Assert bottom branch of butterfly applies cyclic shift correctly");
      Assert (Matrix_Res (2, 1) = 5.0, "Bottom branch shift Phase 1 failed");
      Put_Line ("     PASS");

      Put_Line ("TEST 11 - Fast Fold (Zero Padding on Uneven Lengths)");
      Put_Line ("  11.1 Assert trailing periods missing from dataset are padded with zero");
      declare
         Uneven_Data : Signal_Array (1 .. 6) := (1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
         Res_Uneven  : Profile_Matrix (1 .. 2, 1 .. 4);
      begin
         Fast_Fold (Uneven_Data, 4, 2, Res_Uneven);
         Assert (Res_Uneven(1, 3) = 1.0, "Zero padding Phase 3 failed");
         Assert (Res_Uneven(1, 4) = 1.0, "Zero padding Phase 4 failed");
         Put_Line ("     PASS");
      end;
      
      Put_Line ("TEST 12 - Zero Period Edge Case");
      Put_Line ("  12.1 Assert failure catches invalid logical combinations securely");
      begin
         declare
            Zero_Res : Profile_Array (1 .. 0);
         begin
            Constant_Period_Fold (Basic_Data, 1, Zero_Res); 
            Assert (False, "Should have failed earlier");
         end;
      exception
         when Invalid_Period_Error => Put_Line ("     PASS");
      end;
      
      Put_Line ("TEST 13 - Large Data Struct Memory Scaling");
      Put_Line ("  13.1 Assert the algorithmic logic scales without memory corruption");
      declare
         Large_Data : Signal_Array (1 .. 1024) := (others => 1.0);
         Large_Res  : Profile_Matrix (1 .. 8, 1 .. 128);
      begin
         Fast_Fold (Large_Data, 128, 8, Large_Res);
         Assert (Large_Res (1, 1) = 8.0, "Large data scaling failed");
         Put_Line ("     PASS");
      end;

      Put_Line ("========================================");
      Put_Line ("ALL TESTS PASSED SUCCESSFULLY");
      Put_Line ("========================================");
   end Run_Tests;

begin
   Run_Tests;
end Tests;
