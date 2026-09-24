-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Summed_Area_Table; use Summed_Area_Table;

procedure Tests is
   Grid_In_2D : constant Grid_2D (1 .. 3, 1 .. 3) :=
     ((1, 2, 3),
      (4, 5, 6),
      (7, 8, 9));
   Grid_Out_2D : Grid_2D (1 .. 3, 1 .. 3);
   Grid_Out_2D_Fast : Grid_2D (1 .. 3, 1 .. 3);
   
   Grid_In_3D : constant Grid_3D (1 .. 2, 1 .. 2, 1 .. 2) :=
     (((1, 1), (1, 1)),
      ((1, 1), (1, 1)));
   Grid_Out_3D : Grid_3D (1 .. 2, 1 .. 2, 1 .. 2);

   Offset_Grid_In : constant Grid_2D (5 .. 6, 10 .. 11) :=
     ((1, 2),
      (3, 4));
   Offset_Grid_Out : Grid_2D (5 .. 6, 10 .. 11);

   Result : Value_Type;
begin
   Put_Line ("Starting Summed Area Table (SAT) Validation...");
   Put_Line ("----------------------------------------------");

   -- TEST 1 - Basic 2D SAT Calculation
   Put_Line ("TEST 1 - Basic 2D SAT Generation");
   Put_Line ("  1.1 Assert computed bottom-right corner equals total sum of grid");
   Compute_2D_SAT (Grid_In_2D, Grid_Out_2D);
   Assert (Grid_Out_2D(3, 3) = 45, "Total sum incorrect (expected 45)");
   Put_Line ("     PASS");

   -- TEST 2 - Fast/Cascaded 2D SAT Generation matches Standard
   Put_Line ("TEST 2 - Fast Cascaded 2D SAT vs Standard");
   Put_Line ("  2.1 Assert Fast computation perfectly matches standard formula output");
   Compute_2D_SAT_Fast (Grid_In_2D, Grid_Out_2D_Fast);
   Assert (Grid_Out_2D = Grid_Out_2D_Fast, "Fast SAT differs from standard SAT");
   Put_Line ("     PASS");

   -- TEST 3 - Query Entire 2D Region
   Put_Line ("TEST 3 - Query Entire 2D Region");
   Put_Line ("  3.1 Assert querying (1,1) to (3,3) returns 45");
   Result := Query_2D_Region (Grid_Out_2D, 1, 1, 3, 3);
   Assert (Result = 45, "Entire region query failed");
   Put_Line ("     PASS");

   -- TEST 4 - Query Single Element 2D Region
   Put_Line ("TEST 4 - Query Single 2D Element");
   Put_Line ("  4.1 Assert querying (2,2) to (2,2) returns 5 (original value)");
   Result := Query_2D_Region (Grid_Out_2D, 2, 2, 2, 2);
   Assert (Result = 5, "Single element query failed");
   Put_Line ("     PASS");

   -- TEST 5 - Query 2D Sub-Region
   Put_Line ("TEST 5 - Query 2D Sub-Region");
   Put_Line ("  5.1 Assert querying (2,2) to (3,3) returns 5+6+8+9 = 28");
   Result := Query_2D_Region (Grid_Out_2D, 2, 2, 3, 3);
   Assert (Result = 28, "Sub-region query failed");
   Put_Line ("     PASS");

   -- TEST 6 - Query Invalid Coordinates (Reversed)
   Put_Line ("TEST 6 - Robustness: Query with Reversed Coordinates");
   Put_Line ("  6.1 Assert querying X1 > X2 raises Invalid_Coordinates");
   begin
      Result := Query_2D_Region (Grid_Out_2D, 3, 3, 1, 1);
      Assert (False, "Expected Invalid_Coordinates exception");
   exception
      when Invalid_Coordinates =>
         Put_Line ("     PASS");
   end;

   -- TEST 7 - Query Out of Bounds
   Put_Line ("TEST 7 - Robustness: Query Out of Bounds");
   Put_Line ("  7.1 Assert querying outside grid bounds raises Invalid_Coordinates");
   begin
      Result := Query_2D_Region (Grid_Out_2D, 1, 1, 5, 5);
      Assert (False, "Expected Invalid_Coordinates exception");
   exception
      when Invalid_Coordinates =>
         Put_Line ("     PASS");
   end;

   -- TEST 8 - Squared SAT Calculation (Higher order)
   Put_Line ("TEST 8 - Higher-Order Squared 2D SAT Calculation");
   Put_Line ("  8.1 Assert 2x2 squared sub-grid computes correct squared sums");
   Compute_2D_Squared_SAT (Grid_In_2D, Grid_Out_2D);
   -- 1^2 + 2^2 + 4^2 + 5^2 = 1 + 4 + 16 + 25 = 46
   Result := Query_2D_Region (Grid_Out_2D, 1, 1, 2, 2);
   Assert (Result = 46, "Squared SAT calculation failed");
   Put_Line ("     PASS");

   -- TEST 9 - Invalid Dimensions (Mismatch between Input and Output Grids)
   Put_Line ("TEST 9 - Robustness: Mismatched Input/Output Array Bounds");
   Put_Line ("  9.1 Assert passing mismatched grids to Compute_2D_SAT raises Invalid_Dimensions");
   declare
      Bad_Output : Grid_2D (1 .. 4, 1 .. 4);
   begin
      Compute_2D_SAT (Grid_In_2D, Bad_Output);
      Assert (False, "Expected Invalid_Dimensions exception");
   exception
      when Invalid_Dimensions =>
         Put_Line ("     PASS");
   end;

   -- TEST 10 - Custom Arbitrary Array Offsets
   Put_Line ("TEST 10 - Custom Array Bounds/Offsets");
   Put_Line (" 10.1 Assert SAT handles arbitrary array start indices seamlessly");
   Compute_2D_SAT (Offset_Grid_In, Offset_Grid_Out);
   Result := Query_2D_Region (Offset_Grid_Out, 5, 10, 6, 11);
   Assert (Result = 10, "Arbitrary bound offset calculation failed");
   Put_Line ("     PASS");

   -- TEST 11 - 3D SAT Generation
   Put_Line ("TEST 11 - Multi-dimensional 3D SAT Generation");
   Put_Line (" 11.1 Assert 3D integral volume computes correct maximal sum");
   Compute_3D_SAT (Grid_In_3D, Grid_Out_3D);
   -- Grid is 2x2x2 of all 1s = volume of 8
   Assert (Grid_Out_3D(2, 2, 2) = 8, "3D SAT Generation failed");
   Put_Line ("     PASS");

   -- TEST 12 - 3D Sub-Volume Query
   Put_Line ("TEST 12 - 3D Region/Volume Query");
   Put_Line (" 12.1 Assert querying sub-cube (1,1,1) to (2,2,1) gives volume = 4");
   Result := Query_3D_Region (Grid_Out_3D, 1, 1, 1, 2, 2, 1);
   Assert (Result = 4, "3D Sub-volume query failed");
   Put_Line ("     PASS");

   -- TEST 13 - 3D Single Element Query
   Put_Line ("TEST 13 - 3D Single Voxel Query");
   Put_Line (" 13.1 Assert querying (2,2,2) to (2,2,2) gives original value = 1");
   Result := Query_3D_Region (Grid_Out_3D, 2, 2, 2, 2, 2, 2);
   Assert (Result = 1, "3D Single Voxel Query failed");
   Put_Line ("     PASS");

   Put_Line ("----------------------------------------------");
   Put_Line ("ALL 13 TESTS PASSED SUCCESSFULLY.");
end Tests;
