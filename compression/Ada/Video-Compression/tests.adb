-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Video_Compression; use Video_Compression;

procedure Tests is
   Unit_Block  : constant Block_8x8 := (others => (others => 64.0));
   
   Identity_Q  : constant Quant_Matrix := (others => (others => 1));
   Zero_Q      : constant Quant_Matrix := (others => (others => 0));
   
   Test_Plane_4x4 : constant Image_Plane(1 .. 4, 1 .. 4) :=
     ((10, 20, 10, 20),
      (10, 20, 10, 20),
      (30, 40, 30, 40),
      (30, 40, 30, 40));
      
   Empty_Plane : constant Image_Plane(1 .. 0, 1 .. 0) := (others => (others => 0));
   Odd_Plane   : constant Image_Plane(1 .. 3, 1 .. 3) := (others => (others => 0));
begin
   Put_Line("--- RUNNING VIDEO COMPRESSION TEST SUITE ---");

   -- TEST 1: Forward DCT
   Put_Line("TEST 1 - DCT Spatial Energy Preservation");
   Put_Line("  1.1 Assume DCT loses spatial energy. Test: DC component holds average.");
   declare
      Res : constant Block_8x8 := Forward_DCT(Unit_Block);
   begin
      -- For an all 64.0 block, the DC coeff (0,0) should be approx 64 * 8 = 512
      Assert(Res(0,0) > 511.0 and Res(0,0) < 513.0, "DCT Failed at DC coefficient");
      Put_Line("     PASS");
   end;

   -- TEST 2: Inverse DCT Round Trip
   Put_Line("TEST 2 - DCT -> IDCT Round-Trip Data Loss");
   Put_Line("  2.1 Assume IDCT cannot restore block. Test: IDCT(DCT(X)) == X (with epsilon)");
   declare
      DCT_Res  : constant Block_8x8 := Forward_DCT(Unit_Block);
      IDCT_Res : constant Block_8x8 := Inverse_DCT(DCT_Res);
   begin
      Assert(abs(IDCT_Res(0,0) - 64.0) < 0.1, "IDCT round-trip failed");
      Put_Line("     PASS");
   end;

   -- TEST 3 & 4: Quantization
   Put_Line("TEST 3 - Quantization Integrity");
   Put_Line("  3.1 Assume Q-matrix changes data when Q=1. Test: Result equals float rounding.");
   declare
      Res : constant Integer_Block_8x8 := Quantize(Unit_Block, Identity_Q);
   begin
      Assert(Res(0,0) = 64, "Identity Quantization failed");
      Put_Line("     PASS");
   end;

   Put_Line("TEST 4 - Quantization Downscaling");
   Put_Line("  4.1 Assume Q-matrix doesn't compress data. Test: Result scaled down correctly.");
   declare
      Scale_Q : constant Quant_Matrix := (others => (others => 8));
      Res     : constant Integer_Block_8x8 := Quantize(Unit_Block, Scale_Q);
   begin
      Assert(Res(0,0) = 8, "Quantization downscaling failed");
      Put_Line("     PASS");
   end;

   -- TEST 5: Edge Case - Divide by Zero
   Put_Line("TEST 5 - Zero Quantization Matrix Fault Injection");
   Put_Line("  5.1 Assume algorithm crashes on division by 0. Test: Raises safe exception.");
   begin
      declare
         Res : constant Integer_Block_8x8 := Quantize(Unit_Block, Zero_Q);
         pragma Unreferenced (Res);
      begin
         Assert(False, "Should have raised Quantization_Zero_Error");
      end;
   exception
      when Quantization_Zero_Error => Put_Line("     PASS");
   end;

   -- TEST 6: Dequantization
   Put_Line("TEST 6 - Dequantization Restoration");
   Put_Line("  6.1 Assume dequantization math is broken. Test: Scales int back up to float.");
   declare
      Int_B   : constant Integer_Block_8x8 := (others => (others => 10));
      Scale_Q : constant Quant_Matrix := (others => (others => 5));
      Res     : constant Block_8x8 := Dequantize(Int_B, Scale_Q);
   begin
      Assert(abs(Res(0,0) - 50.0) < 0.01, "Dequantization failed");
      Put_Line("     PASS");
   end;

   -- TEST 7: 4:4:4 Subsampling
   Put_Line("TEST 7 - YUV_444 Subsampling Integrity");
   Put_Line("  7.1 Assume Subsample damages 4:4:4 planes. Test: Dimensions remain equal.");
   declare
      Res : constant Image_Plane := Subsample(Test_Plane_4x4, YUV_444);
   begin
      Assert(Res'Length(1) = 4 and Res'Length(2) = 4, "4:4:4 dimension error");
      Put_Line("     PASS");
   end;

   -- TEST 8: 4:2:2 Subsampling
   Put_Line("TEST 8 - YUV_422 Subsampling Logic");
   Put_Line("  8.1 Assume 4:2:2 doesn't halve width correctly. Test: Cols = Width/2.");
   declare
      Res : constant Image_Plane := Subsample(Test_Plane_4x4, YUV_422);
   begin
      Assert(Res'Length(1) = 4 and Res'Length(2) = 2, "4:2:2 dimension error");
      Assert(Res(1, 1) = 15, "4:2:2 math error"); -- (10+20)/2 = 15
      Put_Line("     PASS");
   end;

   -- TEST 9: 4:2:0 Subsampling
   Put_Line("TEST 9 - YUV_420 Subsampling Logic");
   Put_Line("  9.1 Assume 4:2:0 doesn't halve both dims. Test: Rows = H/2, Cols = W/2.");
   declare
      Res : constant Image_Plane := Subsample(Test_Plane_4x4, YUV_420);
   begin
      Assert(Res'Length(1) = 2 and Res'Length(2) = 2, "4:2:0 dimension error");
      Put_Line("     PASS");
   end;

   -- TEST 10: Empty Array Subsampling
   Put_Line("TEST 10 - Empty Array Subsampling Tolerance");
   Put_Line("  10.1 Assume empty array causes memory fault. Test: Handled gracefully.");
   declare
      Res : constant Image_Plane := Subsample(Empty_Plane, YUV_420);
   begin
      Assert(Res'Length(1) = 0, "Empty array handling failed");
      Put_Line("     PASS");
   end;

   -- TEST 11: Invalid Array Size Subsampling
   Put_Line("TEST 11 - Odd-Size Array Rejection in 4:2:0");
   Put_Line("  11.1 Assume odd dimensions bypass checks. Test: Raises Invalid_Input_Error.");
   begin
      declare
         Res : constant Image_Plane := Subsample(Odd_Plane, YUV_420);
         pragma Unreferenced (Res);
      begin
         Assert(False, "Should have raised Invalid_Input_Error");
      end;
   exception
      when Invalid_Input_Error => Put_Line("     PASS");
   end;

   -- TEST 12: RLE Constant Value
   Put_Line("TEST 12 - RLE on Constant Plane");
   Put_Line("  12.1 Assume RLE stores unnecessary arrays. Test: 1 record, Count = 64.");
   declare
      Int_B : constant Integer_Block_8x8 := (others => (others => 0));
      Res   : constant RLE_Array := RLE_Encode(Int_B);
   begin
      Assert(Res'Length = 1 and Res(1).Count = 64, "RLE constant packing failed");
      Put_Line("     PASS");
   end;

   -- TEST 13: RLE Edge Cases - Alternating Values
   Put_Line("TEST 13 - RLE on Alternating/Distinct Values");
   Put_Line("  13.1 Assume RLE misses end blocks. Test: 64 distinct values.");
   declare
      Int_B   : Integer_Block_8x8;
      Counter : Integer := 1;
   begin
      for X in Index_8 loop
         for Y in Index_8 loop
            Int_B(X,Y) := Counter;
            Counter := Counter + 1;
         end loop;
      end loop;
      declare
         Res : constant RLE_Array := RLE_Encode(Int_B);
      begin
         Assert(Res'Length = 64 and Res(64).Count = 1, "RLE distinct packing failed");
         Put_Line("     PASS");
      end;
   end;
   
   Put_Line("--- ALL TESTS COMPLETED SUCCESSFULLY ---");
end Tests;
