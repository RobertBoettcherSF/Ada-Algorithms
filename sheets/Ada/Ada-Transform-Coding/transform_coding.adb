package body Transform_Coding is

   -----------------------------------------------------------------------------
   -- Discrete Cosine Transform (Orthogonal DCT-II)
   -----------------------------------------------------------------------------
   function DCT (Input : Data_Array) return Data_Array is
      N        : constant Integer := Input'Length;
      Result   : Data_Array (Input'Range) := (others => 0.0);
      Pi       : constant Float := Ada.Numerics.Pi;
      Factor   : Float;
      Sum      : Float;
      In_First : constant Integer := Input'First;
   begin
      if N = 0 then
         return Result; -- Edge case: empty input
      end if;

      for K in 0 .. N - 1 loop
         Sum := 0.0;
         for n_idx in 0 .. N - 1 loop
            Sum := Sum + Input(In_First + n_idx) *
                   Ada.Numerics.Elementary_Functions.Cos (Pi / Float(N) * (Float(n_idx) + 0.5) * Float(K));
         end loop;

         -- Orthonormal scaling
         if K = 0 then
            Factor := 1.0 / Ada.Numerics.Elementary_Functions.Sqrt (Float(N));
         else
            Factor := Ada.Numerics.Elementary_Functions.Sqrt (2.0 / Float(N));
         end if;

         Result(In_First + K) := Factor * Sum;
      end loop;
      return Result;
   end DCT;

   -----------------------------------------------------------------------------
   -- Inverse Discrete Cosine Transform (Orthogonal IDCT-II)
   -----------------------------------------------------------------------------
   function Inverse_DCT (Input : Data_Array) return Data_Array is
      N        : constant Integer := Input'Length;
      Result   : Data_Array (Input'Range) := (others => 0.0);
      Pi       : constant Float := Ada.Numerics.Pi;
      Factor   : Float;
      Sum      : Float;
      In_First : constant Integer := Input'First;
   begin
      if N = 0 then
         return Result;
      end if;

      for n_idx in 0 .. N - 1 loop
         Sum := 0.0;
         for K in 0 .. N - 1 loop
            if K = 0 then
               Factor := 1.0 / Ada.Numerics.Elementary_Functions.Sqrt (Float(N));
            else
               Factor := Ada.Numerics.Elementary_Functions.Sqrt (2.0 / Float(N));
            end if;

            Sum := Sum + Factor * Input(In_First + K) *
                   Ada.Numerics.Elementary_Functions.Cos (Pi / Float(N) * (Float(n_idx) + 0.5) * Float(K));
         end loop;
         Result(In_First + n_idx) := Sum;
      end loop;
      return Result;
   end Inverse_DCT;

   -----------------------------------------------------------------------------
   -- Haar Wavelet Transform (Averages and Details)
   -----------------------------------------------------------------------------
   function Haar_Transform (Input : Data_Array) return Data_Array is
      N        : constant Integer := Input'Length;
      Result   : Data_Array (Input'Range) := (others => 0.0);
      In_First : constant Integer := Input'First;
      Half_N   : constant Integer := N / 2;
      Sqrt2    : constant Float := Ada.Numerics.Elementary_Functions.Sqrt (2.0);
   begin
      if N = 0 then
         return Result;
      end if;
      if N mod 2 /= 0 then
         raise Invalid_Argument with "Haar Transform requires an even array length.";
      end if;

      for I in 0 .. Half_N - 1 loop
         Result(In_First + I)          := (Input(In_First + 2*I) + Input(In_First + 2*I + 1)) / Sqrt2;
         Result(In_First + Half_N + I) := (Input(In_First + 2*I) - Input(In_First + 2*I + 1)) / Sqrt2;
      end loop;
      return Result;
   end Haar_Transform;

   -----------------------------------------------------------------------------
   -- Inverse Haar Wavelet Transform
   -----------------------------------------------------------------------------
   function Inverse_Haar_Transform (Input : Data_Array) return Data_Array is
      N        : constant Integer := Input'Length;
      Result   : Data_Array (Input'Range) := (others => 0.0);
      In_First : constant Integer := Input'First;
      Half_N   : constant Integer := N / 2;
      Sqrt2    : constant Float := Ada.Numerics.Elementary_Functions.Sqrt (2.0);
   begin
      if N = 0 then
         return Result;
      end if;
      if N mod 2 /= 0 then
         raise Invalid_Argument with "Haar Transform requires an even array length.";
      end if;

      for I in 0 .. Half_N - 1 loop
         Result(In_First + 2*I)     := (Input(In_First + I) + Input(In_First + Half_N + I)) / Sqrt2;
         Result(In_First + 2*I + 1) := (Input(In_First + I) - Input(In_First + Half_N + I)) / Sqrt2;
      end loop;
      return Result;
   end Inverse_Haar_Transform;

   -----------------------------------------------------------------------------
   -- Uniform Scalar Quantization
   -----------------------------------------------------------------------------
   function Quantize (Input : Data_Array; Step_Size : Float) return Quantized_Array is
      Result : Quantized_Array (Input'Range);
   begin
      if Step_Size <= 0.0 then
         raise Invalid_Argument with "Quantization step size must be strictly positive.";
      end if;
      for I in Input'Range loop
         -- Round to nearest integer multiple of Step_Size
         Result(I) := Integer (Float'Rounding (Input(I) / Step_Size));
      end loop;
      return Result;
   end Quantize;

   -----------------------------------------------------------------------------
   -- Dequantization (Reconstruction)
   -----------------------------------------------------------------------------
   function Dequantize (Input : Quantized_Array; Step_Size : Float) return Data_Array is
      Result : Data_Array (Input'Range);
   begin
      if Step_Size <= 0.0 then
         raise Invalid_Argument with "Quantization step size must be strictly positive.";
      end if;
      for I in Input'Range loop
         Result(I) := Float (Input(I)) * Step_Size;
      end loop;
      return Result;
   end Dequantize;

end Transform_Coding;
