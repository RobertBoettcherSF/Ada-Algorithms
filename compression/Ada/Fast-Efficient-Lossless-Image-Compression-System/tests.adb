-- tests.adb
-- Standalone test suite verifying functional correctness, edge cases, and robustness (13+ tests).

with Ada.Text_IO;    use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Felics;         use Felics;

procedure Tests is
   Failed_Count : Natural := 0;
begin
   Put_Line("==================================================");
   Put_Line("       FELICS ADA TEST SUITE (13+ Tests)         ");
   Put_Line("==================================================");

   -- TEST 1 - Context Calculation with Identical Neighbors
   Put_Line("TEST 1 - Context Calculation with Identical Neighbors");
   Put_Line("  1.1 Assert Lower equals neighbor value");
   Put_Line("  1.2 Assert Higher equals neighbor value");
   Put_Line("  1.3 Assert Delta equals zero");
   begin
      declare
         Ctx : constant Context_Record := Compute_Context(100, 100);
      begin
         Assert(Ctx.Lower = 100, "Lower mismatch");
         Assert(Ctx.Higher = 100, "Higher mismatch");
         Assert(Ctx.Delta_Value = 0, "Delta should be zero");
         Put_Line("     PASS");
      end;
   exception
      when others =>
         Failed_Count := Failed_Count + 1;
         Put_Line("     FAIL");
   end;

   -- TEST 2 - Context Calculation with Distinct Neighbors
   Put_Line("TEST 2 - Context Calculation with Distinct Neighbors");
   Put_Line("  2.1 Assert Lower correctly finds minimum");
   Put_Line("  2.2 Assert Higher correctly finds maximum");
   Put_Line("  2.3 Assert Delta correctly computes difference");
   begin
      declare
         Ctx : constant Context_Record := Compute_Context(50, 120);
      begin
         Assert(Ctx.Lower = 50, "Lower mismatch");
         Assert(Ctx.Higher = 120, "Higher mismatch");
         Assert(Ctx.Delta_Value = 70, "Delta mismatch");
         Put_Line("     PASS");
      end;
   exception
      when others =>
         Failed_Count := Failed_Count + 1;
         Put_Line("     FAIL");
   end;

   -- TEST 3 - Pixel Encoding Inside Range
   Put_Line("TEST 3 - Pixel Encoding Inside Range");
   Put_Line("  3.1 Assert Region is Inside_Range");
   Put_Line("  3.2 Assert Code represents offset from lower");
   begin
      declare
         Ctx : constant Context_Record := (Lower => 10, Higher => 20, Delta_Value => 10);
         Sym : constant Encoded_Symbol := Encode_Pixel(15, Ctx);
      begin
         Assert(Sym.Region = Inside_Range, "Region mismatch");
         Assert(Sym.Code = 5, "Code mismatch");
         Put_Line("     PASS");
      end;
   exception
      when others =>
         Failed_Count := Failed_Count + 1;
         Put_Line("     FAIL");
   end;

   -- TEST 4 - Pixel Encoding Below Range
   Put_Line("TEST 4 - Pixel Encoding Below Range");
   Put_Line("  4.1 Assert Region is Below_Range");
   Put_Line("  4.2 Assert Code reflects distance below lower");
   begin
      declare
         Ctx : constant Context_Record := (Lower => 20, Higher => 40, Delta_Value => 20);
         Sym : constant Encoded_Symbol := Encode_Pixel(15, Ctx);
      begin
         Assert(Sym.Region = Below_Range, "Region mismatch");
         Assert(Sym.Code = 4, "Code mismatch");
         Put_Line("     PASS");
      end;
   exception
      when others =>
         Failed_Count := Failed_Count + 1;
         Put_Line("     FAIL");
   end;

   -- TEST 5 - Pixel Encoding Above Range
   Put_Line("TEST 5 - Pixel Encoding Above Range");
   Put_Line("  5.1 Assert Region is Above_Range");
   Put_Line("  5.2 Assert Code reflects distance above higher");
   begin
      declare
         Ctx : constant Context_Record := (Lower => 20, Higher => 40, Delta_Value => 20);
         Sym : constant Encoded_Symbol := Encode_Pixel(45, Ctx);
      begin
         Assert(Sym.Region = Above_Range, "Region mismatch");
         Assert(Sym.Code = 4, "Code mismatch");
         Put_Line("     PASS");
      end;
   exception
      when others =>
         Failed_Count := Failed_Count + 1;
         Put_Line("     FAIL");
   end;

   -- TEST 6 - Symbol Decoding Inside Range
   Put_Line("TEST 6 - Symbol Decoding Inside Range");
   Put_Line("  6.1 Assert decoded pixel matches original inside value");
   begin
      declare
         Ctx : constant Context_Record := (Lower => 50, Higher => 80, Delta_Value => 30);
         Sym : constant Encoded_Symbol := (Region => Inside_Range, Code => 12, Bits => 31);
         Pix : constant Pixel_Value := Decode_Symbol(Sym, Ctx);
      begin
         Assert(Pix = 62, "Decoded pixel mismatch");
         Put_Line("     PASS");
      end;
   exception
      when others =>
         Failed_Count := Failed_Count + 1;
         Put_Line("     FAIL");
   end;

   -- TEST 7 - Symbol Decoding Below Range
   Put_Line("TEST 7 - Symbol Decoding Below Range");
   Put_Line("  7.1 Assert decoded pixel matches original below value");
   begin
      declare
         Ctx : constant Context_Record := (Lower => 50, Higher => 80, Delta_Value => 30);
         Sym : constant Encoded_Symbol := (Region => Below_Range, Code => 4, Bits => 8);
         Pix : constant Pixel_Value := Decode_Symbol(Sym, Ctx);
      begin
         Assert(Pix = 45, "Decoded pixel mismatch");
         Put_Line("     PASS");
      end;
   exception
      when others =>
         Failed_Count := Failed_Count + 1;
         Put_Line("     FAIL");
   end;

   -- TEST 8 - Symbol Decoding Above Range
   Put_Line("TEST 8 - Symbol Decoding Above Range");
   Put_Line("  8.1 Assert decoded pixel matches original above value");
   begin
      declare
         Ctx : constant Context_Record := (Lower => 50, Higher => 80, Delta_Value => 30);
         Sym : constant Encoded_Symbol := (Region => Above_Range, Code => 4, Bits => 8);
         Pix : constant Pixel_Value := Decode_Symbol(Sym, Ctx);
      begin
         Assert(Pix = 85, "Decoded pixel mismatch");
         Put_Line("     PASS");
      end;
   exception
      when others =>
         Failed_Count := Failed_Count + 1;
         Put_Line("     FAIL");
   end;

   -- TEST 9 - Boundary Edge Case: Zero Pixel Value
   Put_Line("TEST 9 - Boundary Edge Case: Zero Pixel Value");
   Put_Line("  9.1 Assert encoding and decoding zero value works correctly");
   begin
      declare
         Img : constant Pixel_Matrix(1 .. 2, 1 .. 2) := ((0, 0), (0, 0));
         Stm : Encoded_Stream := Compress_Image(Img);
         Rec : Pixel_Matrix(1 .. 2, 1 .. 2) := Decompress_Image(Stm, 2, 2);
      begin
         Assert(Rec(2, 2) = 0, "Zero boundary recovery failed");
         Put_Line("     PASS");
      end;
   exception
      when others =>
         Failed_Count := Failed_Count + 1;
         Put_Line("     FAIL");
   end;

   -- TEST 10 - Boundary Edge Case: Maximum Pixel Value (255)
   Put_Line("TEST 10 - Boundary Edge Case: Maximum Pixel Value (255)");
   Put_Line("  10.1 Assert encoding and decoding 255 value works correctly");
   begin
      declare
         Img : constant Pixel_Matrix(1 .. 2, 1 .. 2) := ((255, 255), (255, 255));
         Stm : Encoded_Stream := Compress_Image(Img);
         Rec : Pixel_Matrix(1 .. 2, 1 .. 2) := Decompress_Image(Stm, 2, 2);
      begin
         Assert(Rec(2, 2) = 255, "Maximum boundary recovery failed");
         Put_Line("     PASS");
      end;
   exception
      when others =>
         Failed_Count := Failed_Count + 1;
         Put_Line("     FAIL");
   end;

   -- TEST 11 - Error Handling: Invalid Image Dimensions on Decompression
   Put_Line("TEST 11 - Error Handling: Invalid Image Dimensions on Decompression");
   Put_Line("  11.1 Assert mismatched stream length raises Invalid_Image_Dimensions");
   begin
      declare
         Img : constant Pixel_Matrix(1 .. 2, 1 .. 2) := ((10, 20), (30, 40));
         Stm : Encoded_Stream := Compress_Image(Img);
         Rec : Pixel_Matrix(1 .. 3, 1 .. 3);
      begin
         Rec := Decompress_Image(Stm, 3, 3);
         Assert(False, "Expected exception not raised");
      end;
   exception
      when Invalid_Image_Dimensions =>
         Put_Line("     PASS");
      when others =>
         Failed_Count := Failed_Count + 1;
         Put_Line("     FAIL");
   end;

   -- TEST 12 - Round-Trip Lossless Compression Check on Gradient Matrix
   Put_Line("TEST 12 - Round-Trip Lossless Compression Check on Gradient Matrix");
   Put_Line("  12.1 Assert entire gradient matrix matches perfectly after round trip");
   begin
      declare
         Img : constant Pixel_Matrix(1 .. 3, 1 .. 3) := 
           ((10, 20, 30),
            (40, 50, 60),
            (70, 80, 90));
         Stm : Encoded_Stream := Compress_Image(Img);
         Rec : Pixel_Matrix(1 .. 3, 1 .. 3) := Decompress_Image(Stm, 3, 3);
         Perfect : Boolean := True;
      begin
         for R in Img'Range(1) loop
            for C in Img'Range(2) loop
               if Img(R, C) /= Rec(R, C) then
                  Perfect := False;
               end if;
            end loop;
         end loop;
         Assert(Perfect, "Gradient round-trip mismatch");
         Put_Line("     PASS");
      end;
   exception
      when others =>
         Failed_Count := Failed_Count + 1;
         Put_Line("     FAIL");
   end;

   -- TEST 13 - Neighbor Extraction Boundary Check
   Put_Line("TEST 13 - Neighbor Extraction Boundary Check");
   Put_Line("  13.1 Assert top-left corner uses default fallback neighbors");
   begin
      declare
         Img : constant Pixel_Matrix(1 .. 2, 1 .. 2) := ((150, 160), (170, 180));
         P1, P2 : Pixel_Value;
      begin
         Get_Neighbors(Img, 1, 1, P1, P2);
         Assert(P1 = 128 and P2 = 128, "Top-left fallback mismatch");
         Put_Line("     PASS");
      end;
   exception
      when others =>
         Failed_Count := Failed_Count + 1;
         Put_Line("     FAIL");
   end;

   Put_Line("==================================================");
   if Failed_Count = 0 then
      Put_Line("ALL TESTS PASSED SUCCESSFULLY.");
   else
      Put_Line("SOME TESTS FAILED: " & Natural'Image(Failed_Count));
      raise Program_Error;
   end if;
end Tests;
