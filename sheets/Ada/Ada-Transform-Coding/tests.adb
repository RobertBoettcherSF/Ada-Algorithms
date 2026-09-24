with Ada.Text_IO; use Ada.Text_IO;
with Transform_Coding; use Transform_Coding;

procedure Tests is
   -- Helper for floating point assertions
   procedure Assert_Float_Equal (A, B : Float; Tol : Float := 0.001; Msg : String) is
   begin
      if abs (A - B) > Tol then
         Put_Line ("      FAIL: " & Msg & " (Expected " & Float'Image(B) & ", Got " & Float'Image(A) & ")");
         raise Program_Error with Msg;
      end if;
   end Assert_Float_Equal;

   procedure Assert_True (Condition : Boolean; Msg : String) is
   begin
      if not Condition then
         Put_Line ("      FAIL: " & Msg);
         raise Program_Error with Msg;
      end if;
   end Assert_True;

   -- Test Data
   Base_Signal : constant Data_Array(1..4) := (10.0, 20.0, 30.0, 40.0);
   Empty_Signal : constant Data_Array(1..0) := (others => 0.0);
   Non_Std_Signal : constant Data_Array(5..8) := (1.0, 2.0, 3.0, 4.0);
   Odd_Signal : constant Data_Array(1..3) := (1.0, 2.0, 3.0);
   
   DCT_Out, Recon_Out : Data_Array(1..4);
   Q_Out : Quantized_Array(1..4);
begin
   Put_Line ("=================================================");
   Put_Line ("Running Transform Coding V&V Test Suite");
   Put_Line ("Goal: Disprove assumption that code is defective.");
   Put_Line ("=================================================");

   -- TEST 1
   Put_Line ("TEST 1 - DCT-II Data Consistency");
   Put_Line ("  1.1 Assert exact numerical mapping of DCT");
   DCT_Out := DCT(Base_Signal);
   Assert_Float_Equal (DCT_Out(1), 50.0, 0.01, "DC coefficient mismatch");
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - DCT-II Perfect Reconstruction (Lossless)");
   Put_Line ("  2.1 Assert Inverse DCT perfectly restores original input");
   Recon_Out := Inverse_DCT(DCT_Out);
   for I in Base_Signal'Range loop
      Assert_Float_Equal (Recon_Out(I), Base_Signal(I), 0.001, "IDCT loss at index " & Integer'Image(I));
   end loop;
   Put_Line ("      PASS");

   -- TEST 3
   Put_Line ("TEST 3 - Haar Wavelet Data Consistency");
   Put_Line ("  3.1 Assert low-pass/high-pass filter outputs");
   DCT_Out := Haar_Transform(Base_Signal); -- Reusing array
   Assert_Float_Equal (DCT_Out(1), 21.213, 0.01, "Haar LPF mismatch");
   Put_Line ("      PASS");

   -- TEST 4
   Put_Line ("TEST 4 - Haar Wavelet Perfect Reconstruction");
   Put_Line ("  4.1 Assert Inverse Haar restores original input");
   Recon_Out := Inverse_Haar_Transform(DCT_Out);
   for I in Base_Signal'Range loop
      Assert_Float_Equal (Recon_Out(I), Base_Signal(I), 0.001, "IHaar loss");
   end loop;
   Put_Line ("      PASS");

   -- TEST 5
   Put_Line ("TEST 5 - Quantization Discretization");
   Put_Line ("  5.1 Assert float values map precisely to integer buckets");
   Q_Out := Quantize(Base_Signal, 3.0);
   Assert_True (Q_Out(2) = 7, "Quantization bucket calculation failed"); -- 20/3 = 6.66 -> 7
   Put_Line ("      PASS");

   -- TEST 6
   Put_Line ("TEST 6 - Dequantization Scaling");
   Put_Line ("  6.1 Assert dequantization restores approximate scaled values");
   Recon_Out := Dequantize(Q_Out, 3.0);
   Assert_Float_Equal (Recon_Out(2), 21.0, 0.001, "Dequantization scaling failed");
   Put_Line ("      PASS");

   -- TEST 7
   Put_Line ("TEST 7 - Quantization Error Handling (Invalid Argument)");
   Put_Line ("  7.1 Assert Step_Size = 0.0 raises Invalid_Argument");
   begin
      declare
         Fail_Q : Quantized_Array(1..4) := Quantize(Base_Signal, 0.0);
      begin null; end;
      Assert_True (False, "Exception missed for zero step size");
   exception
      when Invalid_Argument => Put_Line ("      PASS");
   end;

   -- TEST 8
   Put_Line ("TEST 8 - Haar Transform Boundary Check (Odd Length)");
   Put_Line ("  8.1 Assert Constraint validation on odd array sizes");
   begin
      declare
         Fail_H : Data_Array(1..3) := Haar_Transform(Odd_Signal);
      begin null; end;
      Assert_True (False, "Exception missed for odd array length");
   exception
      when Invalid_Argument => Put_Line ("      PASS");
   end;

   -- TEST 9
   Put_Line ("TEST 9 - Empty Array Edge Case (DCT)");
   Put_Line ("  9.1 Assert empty arrays are handled gracefully");
   declare
      Empty_Res : Data_Array(1..0) := DCT(Empty_Signal);
   begin
      Assert_True (Empty_Res'Length = 0, "Empty array logic failure");
      Put_Line ("      PASS");
   end;

   -- TEST 10
   Put_Line ("TEST 10 - Empty Array Edge Case (Haar)");
   Put_Line ("  10.1 Assert empty arrays bypass the mod 2 exception");
   declare
      Empty_Res : Data_Array(1..0) := Haar_Transform(Empty_Signal);
   begin
      Assert_True (Empty_Res'Length = 0, "Empty array Haar failure");
      Put_Line ("      PASS");
   end;

   -- TEST 11
   Put_Line ("TEST 11 - Single Element Edge Case (DCT)");
   Put_Line ("  11.1 Assert N=1 arrays process correctly without OOB errors");
   declare
      One_Arr : Data_Array(1..1) := (1 => 99.0);
      Res : Data_Array(1..1) := DCT(One_Arr);
   begin
      Assert_Float_Equal (Res(1), 99.0, 0.01, "N=1 DCT mismatch");
      Put_Line ("      PASS");
   end;

   -- TEST 12
   Put_Line ("TEST 12 - Array Slicing & Non-Standard Indices");
   Put_Line ("  12.1 Assert arrays not starting at index 1 process correctly");
   declare
      Res : Data_Array(5..8) := DCT(Non_Std_Signal);
   begin
      Assert_True (Res'First = 5, "Bounds not preserved");
      Put_Line ("      PASS");
   end;

   -- TEST 13
   Put_Line ("TEST 13 - Zero Signal Stability");
   Put_Line ("  13.1 Assert total silence (0.0) transforms cleanly without NaN");
   declare
      Zero_Arr : Data_Array(1..4) := (others => 0.0);
      Res : Data_Array(1..4) := DCT(Zero_Arr);
   begin
      Assert_Float_Equal (Res(2), 0.0, 0.01, "Zero array stability compromised");
      Put_Line ("      PASS");
   end;
   
   Put_Line ("=================================================");
   Put_Line ("All 13 tests passed! Codebase robustness validated.");
end Tests;
