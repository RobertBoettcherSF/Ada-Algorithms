with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Region_Growing; use Region_Growing;

procedure Tests is

   -- Helper function to print test results
   procedure Print_Assert (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Put_Line ("      [PASS] " & Message);
      else
         Put_Line ("      [FAIL] " & Message);
         Assert (Condition, Message);
      end if;
   end Print_Assert;

   -- Test Data
   Img_Uniform : constant Image(1..3, 1..3) := (others => (others => 10));
   Img_Split   : constant Image(1..3, 1..3) := (1 => (10, 10, 10), 
                                                2 => (50, 50, 50), 
                                                3 => (90, 90, 90));
   Img_Check   : constant Image(1..3, 1..3) := (1 => (10, 20, 10), 
                                                2 => (20, 10, 20), 
                                                3 => (10, 20, 10));
                                                
   Seeds_Center : constant Point_Array(1..1) := (1 => (2, 2));
   Seeds_Empty  : constant Point_Array(1..0) := (others => (1,1));
   Seeds_Out    : constant Point_Array(1..1) := (1 => (5, 5));
   
   Res_Mask : Mask(1..3, 1..3);
   Res_Map  : Region_Map(1..3, 1..3);

begin
   Put_Line ("=================================================");
   Put_Line (" REGION GROWING ALGORITHM V&V TEST SUITE         ");
   Put_Line ("=================================================");
   Put_Line ("Assumption: Code is broken. Tests must prove it works.");
   Put_Line ("");

   -- TEST 1: Seeded Local - Exact Match
   Put_Line ("TEST 1 - Seeded Local (Exact Match / Threshold 0)");
   Res_Mask := Seeded_Local (Img_Uniform, Seeds_Center, 0, Four_Connected);
   Print_Assert (Res_Mask(1,1) = True, "1.1 Assumes uniform image segments entirely.");
   Print_Assert (Res_Mask(3,3) = True, "1.2 Assumes corners are reached in 4-connected uniform data.");

   -- TEST 2: Seeded Local - Boundary Constraints
   Put_Line ("TEST 2 - Seeded Local (Boundary constraints on non-uniform data)");
   Res_Mask := Seeded_Local (Img_Split, Seeds_Center, 5, Four_Connected);
   Print_Assert (Res_Mask(2,1) = True and Res_Mask(2,3) = True, "2.1 Assumes same-row pixels are captured.");
   Print_Assert (Res_Mask(1,2) = False and Res_Mask(3,2) = False, "2.2 Assumes threshold prevents out-of-region growth.");

   -- TEST 3: Edge Case - Invalid Seed
   Put_Line ("TEST 3 - Error Handling (Invalid Seed Out of Bounds)");
   begin
      Res_Mask := Seeded_Local (Img_Uniform, Seeds_Out, 10);
      Print_Assert (False, "3.1 Assumes out-of-bounds seed raises Invalid_Seed_Error.");
   exception
      when Invalid_Seed_Error =>
         Print_Assert (True, "3.1 Assumes out-of-bounds seed raises Invalid_Seed_Error.");
   end;

   -- TEST 4: Edge Case - Empty Seed Array
   Put_Line ("TEST 4 - Robustness (Empty Seed Array)");
   Res_Mask := Seeded_Local (Img_Uniform, Seeds_Empty, 10);
   Print_Assert (Res_Mask(2,2) = False, "4.1 Assumes empty seed returns empty mask safely.");

   -- TEST 5: Connectivity Differences
   Put_Line ("TEST 5 - Connectivity Variants (4-conn vs 8-conn)");
   Res_Mask := Seeded_Local (Img_Check, Seeds_Center, 5, Four_Connected);
   Print_Assert (Res_Mask(1,1) = False, "5.1 Assumes 4-connected misses diagonal similarities.");
   Res_Mask := Seeded_Local (Img_Check, Seeds_Center, 5, Eight_Connected);
   Print_Assert (Res_Mask(1,1) = True, "5.2 Assumes 8-connected catches diagonal similarities.");

   -- TEST 6: Seeded Average - Dynamic updating
   Put_Line ("TEST 6 - Seeded Average (Dynamic average check)");
   declare
      Img_Grad : constant Image(1..1, 1..4) := (1 => (10, 15, 20, 50));
      S : constant Point_Array(1..1) := (1 => (1,1));
      Local_Res_Mask : Mask(1..1, 1..4);
   begin
      Local_Res_Mask := Seeded_Average(Img_Grad, S, 10, Four_Connected);
      -- 10 and 15 (Avg 12.5). Next is 20. Diff to 12 is 8 <= 10. (Included). Avg becomes 15. Next is 50. Diff is 35 > 10 (Excluded).
      Print_Assert (Local_Res_Mask(1,3) = True, "6.1 Assumes sliding average pulls in gradient values.");
      Print_Assert (Local_Res_Mask(1,4) = False, "6.2 Assumes large spikes are rejected by average.");
   end;

   -- TEST 7: Seeded Average - Multiple Seeds
   Put_Line ("TEST 7 - Seeded Average (Multiple Disjoint Seeds)");
   declare
      S2 : constant Point_Array(1..2) := (1 => (1,1), 2 => (3,3));
   begin
      Res_Mask := Seeded_Average(Img_Split, S2, 5, Four_Connected);
      Print_Assert (Res_Mask(1,1) = True and Res_Mask(3,3) = True, "7.1 Assumes both initial seeds are initialized true.");
   end;

   -- TEST 8: Unseeded - Pure Uniform
   Put_Line ("TEST 8 - Unseeded Region Growing (Uniform Image)");
   Res_Map := Unseeded (Img_Uniform, 0, Four_Connected);
   Print_Assert (Res_Map(1,1) = 1 and Res_Map(3,3) = 1, "8.1 Assumes entire uniform image becomes Region 1.");

   -- TEST 9: Unseeded - Striped
   Put_Line ("TEST 9 - Unseeded Region Growing (Distinct Regions)");
   Res_Map := Unseeded (Img_Split, 0, Four_Connected);
   Print_Assert (Res_Map(1,1) /= Res_Map(2,1), "9.1 Assumes distinctly valued adjacent areas get different IDs.");
   Print_Assert (Res_Map(1,1) = Res_Map(1,3), "9.2 Assumes similar adjacent areas get the same ID.");

   -- TEST 10: Unseeded - Checkerboard (Connectivity Impact)
   Put_Line ("TEST 10 - Unseeded Region Growing (Checkerboard Connectivity)");
   Res_Map := Unseeded (Img_Check, 0, Four_Connected);
   Print_Assert (Res_Map(1,1) /= Res_Map(2,2), "10.1 Assumes 4-connected assigns different IDs to diagonal matches.");

   -- TEST 11: Seeded Local - Large Threshold
   Put_Line ("TEST 11 - Functional Limits (Large Threshold)");
   Res_Mask := Seeded_Local (Img_Split, Seeds_Center, 100, Four_Connected);
   Print_Assert (Res_Mask(1,1) = True and Res_Mask(3,3) = True, "11.1 Assumes infinite threshold captures entire image.");

   -- TEST 12: 1x1 Image Edge Case
   Put_Line ("TEST 12 - Boundary Testing (1x1 Image)");
   declare
      Img_Tiny : constant Image(1..1, 1..1) := (others => (others => 99));
      S_Tiny : constant Point_Array(1..1) := (1 => (1,1));
      Res_Tiny : Mask(1..1, 1..1);
   begin
      Res_Tiny := Seeded_Local (Img_Tiny, S_Tiny, 10);
      Print_Assert (Res_Tiny(1,1) = True, "12.1 Assumes 1x1 array processes safely without boundary crash.");
   end;

   -- TEST 13: Asymmetric Image Verification
   Put_Line ("TEST 13 - Array Asymmetry Check");
   declare
      Img_Asym : constant Image(1..2, 1..4) := (1 => (1,2,3,4), 2 => (1,2,3,4));
      Res_Asym : Region_Map(1..2, 1..4);
   begin
      Res_Asym := Unseeded(Img_Asym, 0);
      Print_Assert (Res_Asym(1,1) = Res_Asym(2,1), "13.1 Assumes vertical scanning maps correctly.");
      Print_Assert (Res_Asym(1,1) /= Res_Asym(1,2), "13.2 Assumes horizontal distinct elements segment correctly.");
   end;

   -- TEST 14: Unseeded - High Threshold
   Put_Line ("TEST 14 - Unseeded Region Growing (High Threshold Merging)");
   Res_Map := Unseeded (Img_Split, 100, Four_Connected);
   Print_Assert (Res_Map(1,1) = Res_Map(3,3), "14.1 Assumes high threshold merges distinct areas into 1 region.");

   Put_Line ("");
   Put_Line ("All assumptions disproved. V&V Tests Completed Successfully.");
end Tests;
