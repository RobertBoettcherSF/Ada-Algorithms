-- discrete_fourier_transform.adb
-- Implementation of the DFT variants using O(N^2) direct sum definitions.
with Ada.Numerics.Elementary_Functions;

package body Discrete_Fourier_Transformation is
   use Ada.Numerics;
   use Ada.Numerics.Elementary_Functions;

   -- Helper Function: Compute the twiddle factor (complex exponential) W = e^(i * angle)
   function Twiddle_Factor (K, N_Idx, N : Integer; Is_Inverse : Boolean) return Complex is
      Angle : Float;
   begin
      -- Standard DFT uses negative exponent; Inverse uses positive
      if Is_Inverse then
         Angle := 2.0 * Pi * Float (K * N_Idx) / Float (N);
      else
         Angle := -2.0 * Pi * Float (K * N_Idx) / Float (N);
      end if;
      -- Compose_From_Polar(r, theta) -> r*e^(i*theta)
      return Compose_From_Polar (1.0, Angle);
   end Twiddle_Factor;

   -- Variant 1: Standard Forward 1D DFT
   function Forward_DFT (Input : Complex_Array) return Complex_Array is
      N      : constant Integer := Input'Length;
      Result : Complex_Array (Input'Range);
   begin
      if N = 0 then raise Empty_Array_Error; end if;

      for K in 0 .. N - 1 loop
         Result (Input'First + K) := (0.0, 0.0);
         for N_Idx in 0 .. N - 1 loop
            Result (Input'First + K) := Result (Input'First + K) +
              Input (Input'First + N_Idx) * Twiddle_Factor (K, N_Idx, N, False);
         end loop;
      end loop;
      return Result;
   end Forward_DFT;

   -- Variant 2: Standard Inverse 1D DFT
   function Inverse_DFT (Input : Complex_Array) return Complex_Array is
      N      : constant Integer := Input'Length;
      Result : Complex_Array (Input'Range);
   begin
      if N = 0 then raise Empty_Array_Error; end if;

      for K in 0 .. N - 1 loop
         Result (Input'First + K) := (0.0, 0.0);
         for N_Idx in 0 .. N - 1 loop
            Result (Input'First + K) := Result (Input'First + K) +
              Input (Input'First + N_Idx) * Twiddle_Factor (K, N_Idx, N, True);
         end loop;
         -- Inverse scaling factor 1/N
         Result (Input'First + K) := Result (Input'First + K) / Complex'(Float (N), 0.0);
      end loop;
      return Result;
   end Inverse_DFT;

   -- Variant 3: Unitary Forward 1D DFT
   function Unitary_Forward_DFT (Input : Complex_Array) return Complex_Array is
      N            : constant Integer := Input'Length;
      Result       : Complex_Array := Forward_DFT (Input);
      Scale_Factor : constant Float := 1.0 / Sqrt (Float (N));
   begin
      for I in Result'Range loop
         Result (I) := Result (I) * Complex'(Scale_Factor, 0.0);
      end loop;
      return Result;
   end Unitary_Forward_DFT;

   -- Variant 4: Unitary Inverse 1D DFT
   function Unitary_Inverse_DFT (Input : Complex_Array) return Complex_Array is
      N            : constant Integer := Input'Length;
      Result       : Complex_Array (Input'Range);
      Scale_Factor : constant Float := 1.0 / Sqrt (Float (N));
   begin
      if N = 0 then raise Empty_Array_Error; end if;

      for K in 0 .. N - 1 loop
         Result (Input'First + K) := (0.0, 0.0);
         for N_Idx in 0 .. N - 1 loop
            Result (Input'First + K) := Result (Input'First + K) +
              Input (Input'First + N_Idx) * Twiddle_Factor (K, N_Idx, N, True);
         end loop;
         -- Unitary scale factor 1/sqrt(N)
         Result (Input'First + K) := Result (Input'First + K) * Complex'(Scale_Factor, 0.0);
      end loop;
      return Result;
   end Unitary_Inverse_DFT;

   -- Variant 5: Real-Valued Forward 1D DFT
   function Real_Forward_DFT (Input : Real_Array) return Complex_Array is
      Complex_Input : Complex_Array (Input'Range);
   begin
      -- Map real values to complex numbers with 0 imaginary part
      for I in Input'Range loop
         Complex_Input (I) := Compose_From_Cartesian (Input (I), 0.0);
      end loop;
      return Forward_DFT (Complex_Input);
   end Real_Forward_DFT;

   -- Variant 6: Multidimensional (2D) Forward DFT
   function Forward_2D_DFT (Input : Complex_Matrix) return Complex_Matrix is
      Rows   : constant Integer := Input'Length (1);
      Cols   : constant Integer := Input'Length (2);
      Result : Complex_Matrix (Input'Range (1), Input'Range (2));
      Temp   : Complex;
      Angle_Row, Angle_Col : Float;
   begin
      if Rows = 0 or Cols = 0 then raise Empty_Array_Error; end if;

      for U in 0 .. Rows - 1 loop
         for V in 0 .. Cols - 1 loop
            Temp := (0.0, 0.0);
            for X in 0 .. Rows - 1 loop
               for Y in 0 .. Cols - 1 loop
                  Angle_Row := -2.0 * Pi * Float (U * X) / Float (Rows);
                  Angle_Col := -2.0 * Pi * Float (V * Y) / Float (Cols);
                  Temp := Temp + Input (Input'First(1) + X, Input'First(2) + Y) *
                    Compose_From_Polar (1.0, Angle_Row + Angle_Col);
               end loop;
            end loop;
            Result (Input'First(1) + U, Input'First(2) + V) := Temp;
         end loop;
      end loop;
      return Result;
   end Forward_2D_DFT;

end Discrete_Fourier_Transformation;
