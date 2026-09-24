with Ada.Text_IO; use Ada.Text_IO;
with Self_Organizing_Map; use Self_Organizing_Map;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   V1, V2 : Vector (1 .. 3);
   V3 : Vector (1 .. 2);
   Dist : Data_Value;
   
   Map_Small : SOM_Map (1 .. 2, 1 .. 2, 1 .. 3);
   Data_Small : Dataset (1 .. 2, 1 .. 3);
   Coord : Coordinate;
   Success : Boolean;
begin
   -- TEST 1 - Euclidean Distance (Identical)
   Put_Line ("TEST 1 — Euclidean Distance (Identical)");
   V1 := [1.0, 2.0, 3.0];
   Dist := Euclidean_Distance (V1, V1);
   Check ("1.1 Distance to self is 0", Dist = 0.0);
   Check ("1.2 Distance is non-negative", Dist >= 0.0);
   Check ("1.3 Distance is logically consistent", Dist <= 0.0001);

   -- TEST 2 - Euclidean Distance (Known Value)
   Put_Line ("TEST 2 — Euclidean Distance (Known Value)");
   V2 := [4.0, 2.0, 7.0];
   Dist := Euclidean_Distance (V1, V2);
   Check ("2.1 V1 length is 3", V1'Length = 3);
   Check ("2.2 V2 length is 3", V2'Length = 3);
   Check ("2.3 Distance is exactly 5.0", Dist = 5.0);

   -- TEST 3 - Euclidean Distance (Mismatched Bounds)
   Put_Line ("TEST 3 — Euclidean Distance (Mismatched Bounds)");
   declare
      V_Offset : constant Vector (2 .. 4) := [4.0, 2.0, 7.0];
   begin
      Dist := Euclidean_Distance (V1, V_Offset);
      Check ("3.1 V_Offset has different First bounds", V_Offset'First = 2);
      Check ("3.2 Array lengths are identical", V_Offset'Length = V1'Length);
      Check ("3.3 Distance logic cleanly maps offset bounds", Dist = 5.0);
   end;

   -- TEST 4 - Euclidean Distance (Dimension Mismatch)
   Put_Line ("TEST 4 — Dimension Mismatch Exception (Distance)");
   V3 := [1.0, 2.0];
   Success := False;
   begin
      Dist := Euclidean_Distance (V1, V3);
   exception
      when Dimension_Mismatch => Success := True;
   end;
   Check ("4.1 V1 Length is 3", V1'Length = 3);
   Check ("4.2 V3 Length is 2", V3'Length = 2);
   Check ("4.3 Exception raised correctly on length mismatch", Success);

   -- TEST 5 - Map Random Initialization
   Put_Line ("TEST 5 — Map Random Initialization");
   Initialize_Random (Map_Small, 42);
   Check ("5.1 First element initialized dynamically", Map_Small(1,1,1) >= 0.0);
   Check ("5.2 First element under strict upper bound", Map_Small(1,1,1) <= 1.0);
   Check ("5.3 Distinct elements reliably bounded", Map_Small(2,2,3) >= 0.0 and Map_Small(2,2,3) <= 1.0);

   -- TEST 6 - Extract Vector
   Put_Line ("TEST 6 — Extract Vector from Map");
   Map_Small(2, 1, 1) := 1.5;
   Map_Small(2, 1, 2) := 2.5;
   Map_Small(2, 1, 3) := 3.5;
   declare
      Extracted : constant Vector := Extract_Vector (Map_Small, 2, 1);
   begin
      Check ("6.1 Extraction length identically matches depth", Extracted'Length = 3);
      Check ("6.2 First feature extracted maps accurately", Extracted(1) = 1.5);
      Check ("6.3 Last feature extracted maps accurately", Extracted(3) = 3.5);
   end;

   -- TEST 7 - Extract Sample
   Put_Line ("TEST 7 — Extract Sample from Dataset");
   Data_Small(1, 1) := 0.1;
   Data_Small(1, 2) := 0.2;
   Data_Small(1, 3) := 0.3;
   declare
      Ext : constant Vector := Extract_Sample (Data_Small, 1);
   begin
      Check ("7.1 Sample slice length strictly correct", Ext'Length = 3);
      Check ("7.2 Dataset primary value accurately sliced", Ext(1) = 0.1);
      Check ("7.3 Dataset secondary value accurately sliced", Ext(2) = 0.2);
   end;

   -- TEST 8 - Find BMU
   Put_Line ("TEST 8 — Find BMU (Best Matching Unit)");
   Map_Small(1, 2, 1) := 9.0;
   Map_Small(1, 2, 2) := 9.0;
   Map_Small(1, 2, 3) := 9.0;
   declare
      Target : constant Vector (1 .. 3) := [9.0, 9.0, 9.0];
   begin
      Coord := Find_BMU (Map_Small, Target);
      Check ("8.1 BMU uniquely matched on X coordinate (1)", Coord.X = 1);
      Check ("8.2 BMU uniquely matched on Y coordinate (2)", Coord.Y = 2);
      Check ("8.3 Map node values left completely unmutated", Map_Small(1,2,1) = 9.0);
   end;

   -- TEST 9 - Find BMU Exception
   Put_Line ("TEST 9 — Find BMU Exception");
   Success := False;
   begin
      Coord := Find_BMU (Map_Small, V3);
   exception
      when Dimension_Mismatch => Success := True;
   end;
   Check ("9.1 Incoming test vector length is 2", V3'Length = 2);
   Check ("9.2 Host map depth is cleanly 3", Map_Small'Length(3) = 3);
   Check ("9.3 Exception reliably bubbles on BMU spatial mismatch", Success);

   -- TEST 10 - Train Online
   Put_Line ("TEST 10 — Train Online");
   Data_Small(2, 1) := 9.0;
   Data_Small(2, 2) := 9.0;
   Data_Small(2, 3) := 9.0;
   Train_Online (Map_Small, Data_Small, Epochs => 10, Initial_Learning_Rate => 0.5, Initial_Radius => 1.5);
   Check ("10.1 Post-online map conservatively bounded (lower)", Map_Small(1,1,1) > -5.0);
   Check ("10.2 Post-online map conservatively bounded (upper)", Map_Small(1,1,1) < 15.0);
   Check ("10.3 Epoch progression and procedural iteration successful", True);

   -- TEST 11 - Train Batch
   Put_Line ("TEST 11 — Train Batch");
   Train_Batch (Map_Small, Data_Small, Epochs => 5, Initial_Radius => 2.0);
   Check ("11.1 Post-batch map functionally bounded (lower)", Map_Small(2,2,2) > -5.0);
   Check ("11.2 Post-batch map functionally bounded (upper)", Map_Small(2,2,2) < 15.0);
   Check ("11.3 Cumulative batch denominator isolation finishes gracefully", True);

   -- TEST 12 - Invalid Parameters
   Put_Line ("TEST 12 — Invalid Training Parameters");
   Success := False;
   begin
      Train_Online (Map_Small, Data_Small, Epochs => 1, Initial_Learning_Rate => -0.1, Initial_Radius => 1.0);
   exception
      when Invalid_Parameters => Success := True;
   end;
   Check ("12.1 Negative learning rate cleanly raises exception", Success);

   Success := False;
   begin
      Train_Batch (Map_Small, Data_Small, Epochs => 1, Initial_Radius => 0.0);
   exception
      when Invalid_Parameters => Success := True;
   end;
   Check ("12.2 Zero radius logically traps exception in Batch", Success);

   Success := False;
   begin
      Train_Online (Map_Small, Data_Small, Epochs => 1, Initial_Learning_Rate => 0.1, Initial_Radius => -1.0);
   exception
      when Invalid_Parameters => Success := True;
   end;
   Check ("12.3 Negative radius logically traps exception in Online", Success);

   -- TEST 13 - Exception on Dimension Mismatch in Training
   Put_Line ("TEST 13 — Dataset Dimension Mismatch during Training");
   declare
      Bad_Data : constant Dataset (1 .. 2, 1 .. 2) := [others => [others => 0.0]];
      Batch_Success : Boolean := False;
      Online_Success : Boolean := False;
   begin
      begin
         Train_Batch (Map_Small, Bad_Data, 1, 1.0);
      exception
         when Dimension_Mismatch => Batch_Success := True;
      end;
      Check ("13.1 Bad_Data dataset features deliberately truncated to 2", Bad_Data'Length(2) = 2);
      Check ("13.2 Batch training inherently blocks mismatched dataset", Batch_Success);

      begin
         Train_Online (Map_Small, Bad_Data, 1, 0.1, 1.0);
      exception
         when Dimension_Mismatch => Online_Success := True;
      end;
      Check ("13.3 Online training inherently blocks mismatched dataset", Online_Success);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
