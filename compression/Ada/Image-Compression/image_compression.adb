-- image_compression.adb
-- Package body implementing the compression algorithms.

package body Image_Compression is

   -- =========================================================================
   -- Run-Length Encoding (RLE) Implementation
   -- =========================================================================
   
   function Compress_RLE (Img : Image_1D) return RLE_Sequence is
      Distinct_Count : Natural := 0;
   begin
      if Img'Length = 0 then
         raise Empty_Image_Error with "Cannot compress empty image.";
      end if;
      
      -- Pass 1: Determine the number of distinct runs to size our return array
      Distinct_Count := 1;
      for I in Img'First + 1 .. Img'Last loop
         if Img(I) /= Img(I - 1) then
            Distinct_Count := Distinct_Count + 1;
         end if;
      end loop;
      
      -- Pass 2: Populate the RLE array
      declare
         Result : RLE_Sequence (1 .. Distinct_Count);
         R_Idx  : Positive := 1;
         Count  : Positive := 1;
      begin
         for I in Img'First + 1 .. Img'Last loop
            if Img(I) = Img(I - 1) then
               Count := Count + 1;
            else
               Result(R_Idx) := (Count => Count, Val => Img(I - 1));
               R_Idx := R_Idx + 1;
               Count := 1;
            end if;
         end loop;
         -- Handle the final run
         Result(R_Idx) := (Count => Count, Val => Img(Img'Last));
         return Result;
      end;
   end Compress_RLE;

   function Decompress_RLE (Seq : RLE_Sequence) return Image_1D is
      Total_Pixels : Natural := 0;
   begin
      if Seq'Length = 0 then
         raise Invalid_Data_Error with "Cannot decompress empty RLE sequence.";
      end if;

      -- Calculate total decompressed size
      for I in Seq'Range loop
         Total_Pixels := Total_Pixels + Seq(I).Count;
      end loop;
      
      declare
         Result : Image_1D (1 .. Total_Pixels);
         Idx    : Positive := 1;
      begin
         -- Rebuild the image array
         for I in Seq'Range loop
            for J in 1 .. Seq(I).Count loop
               Result(Idx) := Seq(I).Val;
               Idx := Idx + 1;
            end loop;
         end loop;
         return Result;
      end;
   end Decompress_RLE;

   -- =========================================================================
   -- Delta Encoding Implementation
   -- =========================================================================
   
   function Compress_Delta (Img : Image_1D) return Delta_Sequence is
   begin
      if Img'Length = 0 then
         raise Empty_Image_Error with "Cannot compress empty image with Delta.";
      end if;
      
      -- A 1-pixel image has 0 deltas.
      if Img'Length = 1 then
         declare
            Empty_Seq : Delta_Sequence(1 .. 0);
         begin
            return Empty_Seq;
         end;
      end if;
      
      declare
         Result : Delta_Sequence (1 .. Img'Length - 1);
         Idx : Positive := 1;
      begin
         for I in Img'First + 1 .. Img'Last loop
            Result(Idx).dR := Color_Diff(Integer(Img(I).R) - Integer(Img(I - 1).R));
            Result(Idx).dG := Color_Diff(Integer(Img(I).G) - Integer(Img(I - 1).G));
            Result(Idx).dB := Color_Diff(Integer(Img(I).B) - Integer(Img(I - 1).B));
            Idx := Idx + 1;
         end loop;
         return Result;
      end;
   end Compress_Delta;

   function Decompress_Delta (Seq : Delta_Sequence; First_Pixel : Pixel) return Image_1D is
      Result : Image_1D (1 .. Seq'Length + 1);
   begin
      Result(1) := First_Pixel;
      
      for I in Seq'Range loop
         -- Reconstruct values by adding diff to previous pixel
         Result(I + 1).R := Color_Value(Integer(Result(I).R) + Integer(Seq(I).dR));
         Result(I + 1).G := Color_Value(Integer(Result(I).G) + Integer(Seq(I).dG));
         Result(I + 1).B := Color_Value(Integer(Result(I).B) + Integer(Seq(I).dB));
      end loop;
      
      return Result;
   end Decompress_Delta;

   -- =========================================================================
   -- Color Quantization Implementation (Lossy)
   -- =========================================================================
   
   procedure Quantize_Colors (Img : in out Image_1D; Levels_To_Drop : Natural) is
      Mask : Color_Value;
   begin
      if Levels_To_Drop >= 8 then
         -- All bits dropped, image turns black
         for I in Img'Range loop
            Img(I) := (R => 0, G => 0, B => 0);
         end loop;
         return;
      end if;
      
      if Levels_To_Drop = 0 then
         return; -- No loss
      end if;
      
      -- Create a mask to zero-out lower bits
      -- e.g., Drop 2 bits: 11111100 in binary = 252
      Mask := Color_Value'Last and not (2**Levels_To_Drop - 1);
      
      for I in Img'Range loop
         Img(I).R := Img(I).R and Mask;
         Img(I).G := Img(I).G and Mask;
         Img(I).B := Img(I).B and Mask;
      end loop;
   end Quantize_Colors;

end Image_Compression;
