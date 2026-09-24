-- trigonometric_interpolation.adb
with Ada.Numerics;

package body Trigonometric_Interpolation is

   Pi : constant Long_Float := Ada.Numerics.Pi;

   ----------------------------
   -- Calculate_Coefficients --
   ----------------------------
   function Calculate_Coefficients (Y : Real_Array) return Interpolation_Coefficients is
      N         : constant Integer := Y'Length;
      Is_Even   : Boolean;
      K         : Natural;
      Sum_A     : Long_Float;
      Sum_B     : Long_Float;
      T_n       : Long_Float;
      Multiplier: Long_Float;
   begin
      if N = 0 then
         raise Invalid_Data_Error with "Input array Y cannot be empty.";
      end if;

      -- Determine variants (Odd vs Even)
      Is_Even := (N mod 2 = 0);
      
      if Is_Even then
         K := N / 2;
      else
         K := (N - 1) / 2;
      end if;

      declare
         -- Constrain the return type with discriminant K
         Result : Interpolation_Coefficients (K);
      begin
         Result.Is_Even_N := Is_Even;

         -- Calculate A0 (Mean of all points)
         Sum_A := 0.0;
         for I in Y'Range loop
            Sum_A := Sum_A + Y (I);
         end loop;
         Result.A (0) := Sum_A / Long_Float (N);

         -- Calculate Ak and Bk for k = 1 .. K
         for Degree in 1 .. K loop
            Sum_A := 0.0;
            Sum_B := 0.0;
            
            for I in 0 .. N - 1 loop
               -- Equidistant nodes formula: t_n = 2 * Pi * n / N
               T_n := 2.0 * Pi * Long_Float (I) / Long_Float (N);
               
               -- Y_index maps to standard 0-based iteration over the array Y
               declare
                  Y_Val : constant Long_Float := Y (Y'First + I);
                  Angle : constant Long_Float := Long_Float (Degree) * T_n;
               begin
                  Sum_A := Sum_A + Y_Val * Ada.Numerics.Long_Elementary_Functions.Cos (Angle);
                  Sum_B := Sum_B + Y_Val * Ada.Numerics.Long_Elementary_Functions.Sin (Angle);
               end;
            end loop;

            -- Normalization coefficient differs based on Odd/Even and degree
            if Is_Even and then Degree = K then
               -- Highest frequency component for Even N variant is normalized by 1/N
               Multiplier := 1.0 / Long_Float (N);
               Result.A (Degree) := Sum_A * Multiplier;
               -- B(K) is effectively 0 for Even N (sin(pi*n) = 0), but we store 0.0 for safety
               Result.B (Degree) := 0.0;
            else
               -- Standard normalization by 2/N
               Multiplier := 2.0 / Long_Float (N);
               Result.A (Degree) := Sum_A * Multiplier;
               Result.B (Degree) := Sum_B * Multiplier;
            end if;
         end loop;

         return Result;
      end;
   end Calculate_Coefficients;

   --------------
   -- Evaluate --
   --------------
   function Evaluate (Coeffs : Interpolation_Coefficients; X : Long_Float) return Long_Float is
      Result : Long_Float := Coeffs.A (0);
      K      : constant Natural := Coeffs.K;
      Limit  : Natural;
      Angle  : Long_Float;
   begin
      -- For even N, the summation of full A and B terms goes up to K-1
      -- For odd N, it goes up to K
      if Coeffs.Is_Even_N then
         Limit := K - 1;
      else
         Limit := K;
      end if;

      for Degree in 1 .. Limit loop
         Angle := Long_Float (Degree) * X;
         Result := Result + Coeffs.A (Degree) * Ada.Numerics.Long_Elementary_Functions.Cos (Angle)
                          + Coeffs.B (Degree) * Ada.Numerics.Long_Elementary_Functions.Sin (Angle);
      end loop;

      -- Add the isolated highest frequency cosine term for the Even variant
      if Coeffs.Is_Even_N and then K > 0 then
         Angle := Long_Float (K) * X;
         Result := Result + Coeffs.A (K) * Ada.Numerics.Long_Elementary_Functions.Cos (Angle);
      end if;

      return Result;
   end Evaluate;

end Trigonometric_Interpolation;
