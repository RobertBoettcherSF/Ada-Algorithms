with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Three_Dc is

   -- Helper to generate the 8 palette colors based on endpoints
   type Palette_Array is array (0 .. 7) of Byte;
   
   function Generate_Palette (C0, C1 : Byte) return Palette_Array is
      P : Palette_Array;
   begin
      P(0) := C0;
      P(1) := C1;
      
      -- Standard 3Dc / BC4 interpolation (8 values)
      -- Using floating point to avoid complex integer rounding edge cases
      if C0 > C1 then
         for I in 2 .. 7 loop
            P(I) := Byte (Float'Rounding ((Float (8 - I) * Float (C0) + Float (I - 1) * Float (C1)) / 7.0));
         end loop;
      else
         -- Fallback if C0 <= C1 (usually 6 interpolated + 0 and 255 in BC4, but 3Dc specifically targets normal maps)
         for I in 2 .. 5 loop
            P(I) := Byte (Float'Rounding ((Float (6 - I) * Float (C0) + Float (I - 1) * Float (C1)) / 5.0));
         end loop;
         P(6) := 0;
         P(7) := 255;
      end if;
      return P;
   end Generate_Palette;

   -- Helper to find the closest palette index
   function Find_Closest (Val : Byte; Palette : Palette_Array) return Unsigned_64 is
      Min_Diff : Integer := 256;
      Best_Idx : Unsigned_64 := 0;
      Diff : Integer;
   begin
      for I in 0 .. 7 loop
         Diff := abs (Integer (Val) - Integer (Palette (I)));
         if Diff < Min_Diff then
            Min_Diff := Diff;
            Best_Idx := Unsigned_64 (I);
         end if;
      end loop;
      return Best_Idx;
   end Find_Closest;

   -- Compress a single channel
   procedure Compress_3Dc_Plus (Input : in Block_1D; Output : out Compressed_Block_1D) is
      Min_Val : Byte := 255;
      Max_Val : Byte := 0;
      Palette : Palette_Array;
      Packed_Indices : Unsigned_64 := 0;
      Shift : Natural := 0;
      Idx : Unsigned_64;
   begin
      -- 1. Find min and max
      for I in Input'Range loop
         if Input (I) > Max_Val then Max_Val := Input (I); end if;
         if Input (I) < Min_Val then Min_Val := Input (I); end if;
      end loop;
      
      -- Ensure Max > Min for 8-color interpolation mode
      if Max_Val = Min_Val and then Max_Val < 255 then
         Max_Val := Max_Val + 1;
      elsif Max_Val = Min_Val then
         Min_Val := Min_Val - 1;
      end if;
      
      Output(0) := Max_Val;
      Output(1) := Min_Val;
      
      -- 2. Generate palette
      Palette := Generate_Palette (Max_Val, Min_Val);
      
      -- 3. Map pixels to palette and pack 3-bit indices
      for I in Input'Range loop
         Idx := Find_Closest (Input (I), Palette);
         Packed_Indices := Packed_Indices or Shift_Left (Idx, Shift);
         Shift := Shift + 3;
      end loop;
      
      -- 4. Store the 48 bits of indices into the remaining 6 bytes
      for I in 2 .. 7 loop
         Output (I) := Byte (Packed_Indices and 16#FF#);
         Packed_Indices := Shift_Right (Packed_Indices, 8);
      end loop;
   end Compress_3Dc_Plus;

   -- Decompress a single channel
   procedure Decompress_3Dc_Plus (Input : in Compressed_Block_1D; Output : out Block_1D) is
      Palette : Palette_Array;
      Packed_Indices : Unsigned_64 := 0;
      Idx : Natural;
   begin
      Palette := Generate_Palette (Input(0), Input(1));
      
      -- Unpack 48 bits
      for I in reverse 2 .. 7 loop
         Packed_Indices := Shift_Left (Packed_Indices, 8) or Unsigned_64 (Input(I));
      end loop;
      
      for I in Output'Range loop
         Idx := Natural (Packed_Indices and 2#111#);
         Output (I) := Palette (Idx);
         Packed_Indices := Shift_Right (Packed_Indices, 3);
      end loop;
   end Decompress_3Dc_Plus;

   -- Compress two channels independently
   procedure Compress_3Dc (Input : in Block_2D; Output : out Compressed_Block_2D) is
   begin
      Compress_3Dc_Plus (Input.X, Output.X);
      Compress_3Dc_Plus (Input.Y, Output.Y);
   end Compress_3Dc;

   -- Decompress two channels independently
   procedure Decompress_3Dc (Input : in Compressed_Block_2D; Output : out Block_2D) is
   begin
      Decompress_3Dc_Plus (Input.X, Output.X);
      Decompress_3Dc_Plus (Input.Y, Output.Y);
   end Decompress_3Dc;

   -- Reconstruct Z channel from X and Y
   procedure Reconstruct_Z (Input_X : in Block_1D; Input_Y : in Block_1D; Output_Z : out Block_Z) is
      Nx, Ny, Nz_Sq : Float;
   begin
      for I in 0 .. 15 loop
         -- Map 0..255 to -1.0 .. 1.0
         Nx := (Float (Input_X(I)) / 127.5) - 1.0;
         Ny := (Float (Input_Y(I)) / 127.5) - 1.0;
         
         Nz_Sq := 1.0 - (Nx * Nx) - (Ny * Ny);
         if Nz_Sq <= 0.0 then
            Output_Z(I) := 0.0; -- Clamp to avoid imaginary numbers from quantization errors
         else
            Output_Z(I) := Sqrt (Nz_Sq);
         end if;
      end loop;
   end Reconstruct_Z;

end Three_Dc;
