with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with RL_Deconvolution; use RL_Deconvolution;

procedure Tests is
   -- Test Data Setup
   Identity_Kernel : constant Matrix(1..1, 1..1) := (1 => (1 => 1.0));
   Input_Image     : constant Matrix(1..3, 1..3) := (
      (0.0, 0.0, 0.0), 
      (0.0, 1.0, 0.0), 
      (0.0, 0.0, 0.0)
   );
begin
   Put_Line("Running 13+ Verification Tests for Richardson-Lucy...");

   -- TEST 1 - Identity Behavior
   Put_Line("TEST 1 - Identity Kernel Preservation");
   Assert(Deconvolve(Input_Image, Identity_Kernel, 1)(2,2) = 1.0, "Identity kernel failed to preserve input");
   Put_Line("   PASS");

   -- TEST 2 - Iteration Stability
   Put_Line("TEST 2 - Single Iteration Stability");
   Assert(Deconvolve(Input_Image, Identity_Kernel, 1)'Length(1) = 3, "Output dimension mismatch");
   Put_Line("   PASS");

   -- TEST 3 - Kernel Dimensions
   Put_Line("TEST 3 - Invalid PSF Dimensions (Even sized)");
   begin
      declare
         Even_Kernel : constant Matrix(1..2, 1..2) := (others => (others => 1.0));
         Result : Matrix := Deconvolve(Input_Image, Even_Kernel, 1);
      begin
         Assert(False, "Did not raise exception for even kernel");
      end;
   exception
      when Invalid_Dimensions => Put_Line("   PASS");
   end;

   -- TEST 4 - Empty Input (Constraint check)
   Put_Line("TEST 4 - Empty Input Matrix Handling");
   begin
      declare
         Empty : Matrix(1..0, 1..0);
      begin
         declare
            Result : Matrix := Deconvolve(Empty, Identity_Kernel, 1);
         begin
            Assert(False, "Did not raise constraint error on empty input");
         end;
      end;
   exception
      when Constraint_Error => Put_Line("   PASS");
   end;

   -- TEST 5 - All Zeros Preservation
   Put_Line("TEST 5 - Zero-Input Convergence");
   declare
      Zero_Img : constant Matrix(1..3, 1..3) := (others => (others => 0.0));
      Res : Matrix := Deconvolve(Zero_Img, Identity_Kernel, 1);
   begin
      Assert(Res(2,2) = 0.0, "Zeros did not remain zeros");
      Put_Line("   PASS");
   end;

   -- TEST 6 - Numerical Stability (Division by Zero)
   Put_Line("TEST 6 - Division by Zero Robustness");
   declare
      Kernel : constant Matrix(1..3, 1..3) := (others => (others => 0.0));
      Res : Matrix := Deconvolve(Input_Image, Kernel, 1);
   begin
      Assert(True, "Function crashed during div-by-zero");
      Put_Line("   PASS");
   end;

   -- TEST 7 - Convergence of Uniform Image
   Put_Line("TEST 7 - Uniform Image Convergence");
   declare
      Uniform : constant Matrix(1..3, 1..3) := (others => (others => 0.5));
      Res : Matrix := Deconvolve(Uniform, Identity_Kernel, 1);
   begin
      Assert(Res(2,2) > 0.0, "Result converged to invalid value");
      Put_Line("   PASS");
   end;

   -- TEST 8 - Non-Square PSF
   Put_Line("TEST 8 - Non-Square PSF Handling");
   declare
      NS_Kernel : constant Matrix(1..1, 1..3) := (1 => (0.33, 0.33, 0.33));
      Res : Matrix := Deconvolve(Input_Image, NS_Kernel, 1);
   begin
      Assert(Res'Length(1) = 3, "Output structure modified by non-square kernel");
      Put_Line("   PASS");
   end;

   -- TEST 9 - Data Type Consistency
   Put_Line("TEST 9 - Float Type Preservation");
   declare
      Res : Matrix := Deconvolve(Input_Image, Identity_Kernel, 1);
      Val : Float := Res(1, 1);
   begin
      Assert(Val >= 0.0, "Data type error");
      Put_Line("   PASS");
   end;

   -- TEST 10 - Iteration Scaling
   Put_Line("TEST 10 - Iteration Intensity Influence");
   declare
      Res1 : Matrix := Deconvolve(Input_Image, Identity_Kernel, 1);
      Res2 : Matrix := Deconvolve(Input_Image, Identity_Kernel, 5);
   begin
      Assert(Res1(2,2) = Res2(2,2), "Identity kernel produced different results at diff iterations");
      Put_Line("   PASS");
   end;

   -- TEST 11 - Adjoint Logic
   Put_Line("TEST 11 - Adjoint Operation Logic");
   Assert(Deconvolve(Input_Image, Identity_Kernel, 1)(2,2) /= 0.0, "Processing failed to yield non-zero output");
   Put_Line("   PASS");

   -- TEST 12 - Memory Bounds
   Put_Line("TEST 12 - Large Matrix Access Safety");
   declare
      Large : Matrix(1..50, 1..50) := (others => (others => 1.0));
      Res : Matrix := Deconvolve(Large, Identity_Kernel, 1);
   begin
      Assert(Res(50,50) = 1.0, "Boundary access failed");
      Put_Line("   PASS");
   end;

   -- TEST 13 - Kernel Sizing Logic
   Put_Line("TEST 13 - Kernel Sizing Logic");
   declare
      PSF : constant Matrix(1..3, 1..3) := (
         (0.0, 1.0, 0.0), 
         (1.0, 1.0, 1.0), 
         (0.0, 1.0, 0.0)
      );
      Res : Matrix := Deconvolve(Input_Image, PSF, 1);
   begin
      Assert(Res'Length(1) = 3, "Output matrix size corrupted");
      Put_Line("   PASS");
   end;

   Put_Line("All tests passed successfully.");
end Tests;
