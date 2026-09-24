-- video_compression.adb
with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body Video_Compression is
   use Ada.Numerics.Elementary_Functions;

   Pi : constant Float := Ada.Numerics.Pi;

   -- Computes the Forward Discrete Cosine Transform for an 8x8 block
   function Forward_DCT (Input : Block_8x8) return Block_8x8 is
      Result : Block_8x8 := (others => (others => 0.0));
      Cu, Cv, Sum : Float;
   begin
      for U in Index_8 loop
         for V in Index_8 loop
            Cu := (if U = 0 then 1.0 / Sqrt(2.0) else 1.0);
            Cv := (if V = 0 then 1.0 / Sqrt(2.0) else 1.0);
            Sum := 0.0;
            
            for X in Index_8 loop
               for Y in Index_8 loop
                  Sum := Sum + Input(X, Y) *
                         Cos(Float(2 * X + 1) * Float(U) * Pi / 16.0) *
                         Cos(Float(2 * Y + 1) * Float(V) * Pi / 16.0);
               end loop;
            end loop;
            Result(U, V) := 0.25 * Cu * Cv * Sum;
         end loop;
      end loop;
      return Result;
   end Forward_DCT;

   -- Computes the Inverse Discrete Cosine Transform for an 8x8 block
   function Inverse_DCT (Input : Block_8x8) return Block_8x8 is
      Result : Block_8x8 := (others => (others => 0.0));
      Cu, Cv, Sum : Float;
   begin
      for X in Index_8 loop
         for Y in Index_8 loop
            Sum := 0.0;
            for U in Index_8 loop
               for V in Index_8 loop
                  Cu := (if U = 0 then 1.0 / Sqrt(2.0) else 1.0);
                  Cv := (if V = 0 then 1.0 / Sqrt(2.0) else 1.0);
                  Sum := Sum + Cu * Cv * Input(U, V) *
                         Cos(Float(2 * X + 1) * Float(U) * Pi / 16.0) *
                         Cos(Float(2 * Y + 1) * Float(V) * Pi / 16.0);
               end loop;
            end loop;
            Result(X, Y) := 0.25 * Sum;
         end loop;
      end loop;
      return Result;
   end Inverse_DCT;

   -- Applies Quantization Matrix
   function Quantize (Input : Block_8x8; Q : Quant_Matrix) return Integer_Block_8x8 is
      Result : Integer_Block_8x8;
   begin
      for X in Index_8 loop
         for Y in Index_8 loop
            if Q(X, Y) = 0 then
               raise Quantization_Zero_Error with "Quantization matrix contains zero";
            end if;
            Result(X, Y) := Integer(Float'Rounding(Input(X, Y) / Float(Q(X, Y))));
         end loop;
      end loop;
      return Result;
   end Quantize;

   -- Restores values based on Quantization Matrix
   function Dequantize (Input : Integer_Block_8x8; Q : Quant_Matrix) return Block_8x8 is
      Result : Block_8x8;
   begin
      for X in Index_8 loop
         for Y in Index_8 loop
            Result(X, Y) := Float(Input(X, Y) * Q(X, Y));
         end loop;
      end loop;
      return Result;
   end Dequantize;

   -- Chroma Subsampling
   function Subsample (Plane : Image_Plane; Format : Chroma_Format) return Image_Plane is
   begin
      if Plane'Length(1) = 0 or Plane'Length(2) = 0 then
         return Plane; -- Edge case: Empty plane
      end if;

      case Format is
         when YUV_444 =>
            return Plane; -- Full resolution
            
         when YUV_422 =>
            if Plane'Length(2) mod 2 /= 0 then
               raise Invalid_Input_Error with "Width must be even for 4:2:2";
            end if;
            declare
               Result : Image_Plane(Plane'First(1) .. Plane'Last(1), 1 .. Plane'Length(2) / 2);
            begin
               for R in Plane'Range(1) loop
                  for C in Result'Range(2) loop
                     Result(R, C) := (Plane(R, Plane'First(2) + (C - 1) * 2) + 
                                      Plane(R, Plane'First(2) + (C - 1) * 2 + 1)) / 2;
                  end loop;
               end loop;
               return Result;
            end;
            
         when YUV_420 =>
            if Plane'Length(1) mod 2 /= 0 or Plane'Length(2) mod 2 /= 0 then
               raise Invalid_Input_Error with "Dimensions must be even for 4:2:0";
            end if;
            declare
               Result : Image_Plane(1 .. Plane'Length(1) / 2, 1 .. Plane'Length(2) / 2);
               Sum : Integer;
            begin
               for R in Result'Range(1) loop
                  for C in Result'Range(2) loop
                     Sum := Plane(Plane'First(1) + (R - 1) * 2, Plane'First(2) + (C - 1) * 2) +
                            Plane(Plane'First(1) + (R - 1) * 2, Plane'First(2) + (C - 1) * 2 + 1) +
                            Plane(Plane'First(1) + (R - 1) * 2 + 1, Plane'First(2) + (C - 1) * 2) +
                            Plane(Plane'First(1) + (R - 1) * 2 + 1, Plane'First(2) + (C - 1) * 2 + 1);
                     Result(R, C) := Sum / 4;
                  end loop;
               end loop;
               return Result;
            end;
      end case;
   end Subsample;

   -- Run-Length Encoding
   function RLE_Encode (Input : Integer_Block_8x8) return RLE_Array is
      Temp : RLE_Array(1 .. 64);
      Count : Natural := 0;
      Current_Val : Integer := Input(0, 0);
      Run : Positive := 1;
   begin
      for X in Index_8 loop
         for Y in Index_8 loop
            if X = 0 and Y = 0 then
               null; -- Skip first element, already initialized
            elsif Input(X, Y) = Current_Val then
               Run := Run + 1;
            else
               Count := Count + 1;
               Temp(Count) := (Value => Current_Val, Count => Run);
               Current_Val := Input(X, Y);
               Run := 1;
            end if;
         end loop;
      end loop;
      Count := Count + 1;
      Temp(Count) := (Value => Current_Val, Count => Run);
      return Temp(1 .. Count);
   end RLE_Encode;

end Video_Compression;
