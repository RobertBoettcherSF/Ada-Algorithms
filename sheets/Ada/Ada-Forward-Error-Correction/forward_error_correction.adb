package body Forward_Error_Correction is

   -----------------------------------------------------------------------------
   -- Repetition Code
   -----------------------------------------------------------------------------

   function Repetition_Encode (Data : Bit_Array; Times : Positive := 3) return Bit_Array is
      Norm_Data : constant Bit_Array (1 .. Data'Length) := Data;
      Result    : Bit_Array (1 .. Data'Length * Times);
      Out_Idx   : Natural := 1;
   begin
      if Data'Length = 0 then
         return Result;
      end if;
      
      for I in Norm_Data'Range loop
         for J in 1 .. Times loop
            pragma Unreferenced (J);
            Result (Out_Idx) := Norm_Data (I);
            Out_Idx := Out_Idx + 1;
         end loop;
      end loop;
      return Result;
   end Repetition_Encode;

   function Repetition_Decode (Codeword : Bit_Array; Times : Positive := 3) return Bit_Array is
      Norm_Code : constant Bit_Array (1 .. Codeword'Length) := Codeword;
      Blocks    : constant Natural := Codeword'Length / Times;
      Result    : Bit_Array (1 .. Blocks);
      Sum       : Natural;
   begin
      if Blocks = 0 then
         return Result;
      end if;

      for I in 0 .. Blocks - 1 loop
         Sum := 0;
         for J in 1 .. Times loop
            Sum := Sum + Natural (Norm_Code (I * Times + J));
         end loop;
         
         -- Majority vote
         if Sum > Times / 2 then
            Result (I + 1) := 1;
         else
            Result (I + 1) := 0;
         end if;
      end loop;
      return Result;
   end Repetition_Decode;

   -----------------------------------------------------------------------------
   -- Hamming(7,4) Code
   -----------------------------------------------------------------------------

   function Hamming_74_Encode (Data : Nibble) return Hamming_Block is
      Result : Hamming_Block;
      D1 : constant Bit := Data (1);
      D2 : constant Bit := Data (2);
      D3 : constant Bit := Data (3);
      D4 : constant Bit := Data (4);
   begin
      -- Standard Hamming(7,4) parity bit generation
      -- P1 = D1 + D2 + D4
      -- P2 = D1 + D3 + D4
      -- P3 = D2 + D3 + D4
      -- Note: Cast to Natural before addition to prevent Constraint_Error on Bit type
      Result (1) := Bit ((Natural (D1) + Natural (D2) + Natural (D4)) mod 2); -- P1
      Result (2) := Bit ((Natural (D1) + Natural (D3) + Natural (D4)) mod 2); -- P2
      Result (3) := D1;
      Result (4) := Bit ((Natural (D2) + Natural (D3) + Natural (D4)) mod 2); -- P3
      Result (5) := D2;
      Result (6) := D3;
      Result (7) := D4;
      return Result;
   end Hamming_74_Encode;

   function Hamming_74_Decode (Codeword : Hamming_Block) return Nibble is
      C : constant Hamming_Block := Codeword;
      S1, S2, S3 : Bit;
      Error_Pos  : Natural;
      Corrected  : Hamming_Block := C;
   begin
      -- Calculate Syndrome
      S1 := Bit ((Natural (C (1)) + Natural (C (3)) + Natural (C (5)) + Natural (C (7))) mod 2);
      S2 := Bit ((Natural (C (2)) + Natural (C (3)) + Natural (C (6)) + Natural (C (7))) mod 2);
      S3 := Bit ((Natural (C (4)) + Natural (C (5)) + Natural (C (6)) + Natural (C (7))) mod 2);
      
      -- Syndrome maps directly to the 1-based error position
      Error_Pos := Natural (S1) + Natural (S2) * 2 + Natural (S3) * 4;

      -- If Syndrome is non-zero, correct the bit at the error position
      if Error_Pos /= 0 then
         Corrected (Error_Pos) := Bit ((Natural (Corrected (Error_Pos)) + 1) mod 2);
      end if;

      return [Corrected (3), Corrected (5), Corrected (6), Corrected (7)];
   end Hamming_74_Decode;

   function Hamming_Encode_Message (Data : Bit_Array) return Bit_Array is
      Norm_Data : constant Bit_Array (1 .. Data'Length) := Data;
      Blocks    : constant Natural := Data'Length / 4;
      Result    : Bit_Array (1 .. Blocks * 7);
   begin
      if Blocks = 0 then
         return Result;
      end if;

      for I in 0 .. Blocks - 1 loop
         declare
            Nib : constant Nibble := Norm_Data (I * 4 + 1 .. I * 4 + 4);
            Enc : constant Hamming_Block := Hamming_74_Encode (Nib);
         begin
            Result (I * 7 + 1 .. I * 7 + 7) := Enc;
         end;
      end loop;
      return Result;
   end Hamming_Encode_Message;

   function Hamming_Decode_Message (Codeword : Bit_Array) return Bit_Array is
      Norm_Code : constant Bit_Array (1 .. Codeword'Length) := Codeword;
      Blocks    : constant Natural := Codeword'Length / 7;
      Result    : Bit_Array (1 .. Blocks * 4);
   begin
      if Blocks = 0 then
         return Result;
      end if;

      for I in 0 .. Blocks - 1 loop
         declare
            Enc : constant Hamming_Block := Norm_Code (I * 7 + 1 .. I * 7 + 7);
            Nib : constant Nibble := Hamming_74_Decode (Enc);
         begin
            Result (I * 4 + 1 .. I * 4 + 4) := Nib;
         end;
      end loop;
      return Result;
   end Hamming_Decode_Message;

   -----------------------------------------------------------------------------
   -- Interleaving
   -----------------------------------------------------------------------------

   function Interleave (Data : Bit_Array; Block_Size : Positive) return Bit_Array is
      Norm_Data : constant Bit_Array (1 .. Data'Length) := Data;
      Result    : Bit_Array (1 .. Data'Length);
      Rows      : constant Natural := Data'Length / Block_Size;
      Cols      : constant Natural := Block_Size;
      In_Idx    : Natural := 1;
   begin
      if Data'Length = 0 then
         return Result;
      end if;
      
      for R in 0 .. Rows - 1 loop
         for C in 0 .. Cols - 1 loop
            Result (C * Rows + R + 1) := Norm_Data (In_Idx);
            In_Idx := In_Idx + 1;
         end loop;
      end loop;
      return Result;
   end Interleave;

   function Deinterleave (Data : Bit_Array; Block_Size : Positive) return Bit_Array is
      Norm_Data : constant Bit_Array (1 .. Data'Length) := Data;
      Result    : Bit_Array (1 .. Data'Length);
      Rows      : constant Natural := Data'Length / Block_Size;
      Cols      : constant Natural := Block_Size;
      In_Idx    : Natural := 1;
   begin
      if Data'Length = 0 then
         return Result;
      end if;

      for C in 0 .. Cols - 1 loop
         for R in 0 .. Rows - 1 loop
            Result (R * Cols + C + 1) := Norm_Data (In_Idx);
            In_Idx := In_Idx + 1;
         end loop;
      end loop;
      return Result;
   end Deinterleave;

end Forward_Error_Correction;
