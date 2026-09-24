-- bluestein.adb
with Ada.Numerics;
with Ada.Numerics.Complex_Elementary_Functions;
use Ada.Numerics.Complex_Elementary_Functions;
with Interfaces;
use type Interfaces.Unsigned_32; -- Makes the 'and' operator visible for Unsigned_32

package body Bluestein is

   Pi : constant Float := Ada.Numerics.Pi;

   -- Helper: Calculate Next Power of Two for Zero Padding
   function Next_Power_Of_Two (N : Positive) return Positive is
      M : Positive := 1;
   begin
      while M < N loop
         M := M * 2;
      end loop;
      return M;
   end Next_Power_Of_Two;

   -- Helper: Raise complex number to float power
   function "**" (Left : Complex; Right : Float) return Complex is
   begin
      if Left.Re = 0.0 and then Left.Im = 0.0 then
         return (if Right = 0.0 then (1.0, 0.0) else (0.0, 0.0));
      end if;
      return Exp (Right * Log (Left));
   end "**";

   -- Radix-2 Cooley-Tukey FFT
   function Radix2_FFT (Input : Complex_Array; Inverse : Boolean := False) return Complex_Array is
      N : constant Integer := Input'Length;
      Result : Complex_Array (0 .. N - 1);
   begin
      if N = 0 then
         raise Invalid_Size with "Radix2_FFT input cannot be empty";
      elsif N = 1 then
         Result(0) := Input(Input'First);
         return Result;
      end if;

      -- Use Unsigned_32 bitwise operations to efficiently check for power of 2
      if (Interfaces.Unsigned_32(N) and Interfaces.Unsigned_32(N - 1)) /= 0 then
         raise Invalid_Size with "Radix2_FFT requires power of 2 length";
      end if;

      declare
         Even, Odd : Complex_Array (0 .. N / 2 - 1);
         Even_FFT, Odd_FFT : Complex_Array (0 .. N / 2 - 1);
         Angle, Sign : Float;
         W_Factor, T : Complex;
      begin
         Sign := (if Inverse then 1.0 else -1.0);

         for I in 0 .. N / 2 - 1 loop
            Even(I) := Input(Input'First + 2 * I);
            Odd(I)  := Input(Input'First + 2 * I + 1);
         end loop;

         Even_FFT := Radix2_FFT (Even, Inverse);
         Odd_FFT  := Radix2_FFT (Odd, Inverse);

         for I in 0 .. N / 2 - 1 loop
            Angle := Sign * 2.0 * Pi * Float(I) / Float(N);
            W_Factor := Compose_From_Polar (1.0, Angle);
            T := W_Factor * Odd_FFT(I);

            -- Automatically scale by 1/2 at each step if inverse
            if Inverse then
               Result(I) := (Even_FFT(I) + T) / Complex'(2.0, 0.0);
               Result(I + N / 2) := (Even_FFT(I) - T) / Complex'(2.0, 0.0);
            else
               Result(I) := Even_FFT(I) + T;
               Result(I + N / 2) := Even_FFT(I) - T;
            end if;
         end loop;

         return Result;
      end;
   end Radix2_FFT;

   -- Helper: Convolution using Radix-2 FFT
   function Convolve (A, B : Complex_Array) return Complex_Array is
      M : constant Positive := A'Length;
      FA : Complex_Array := Radix2_FFT (A, False);
      FB : Complex_Array := Radix2_FFT (B, False);
      FC : Complex_Array (0 .. M - 1);
   begin
      for I in 0 .. M - 1 loop
         FC(I) := FA(I) * FB(I);
      end loop;
      return Radix2_FFT (FC, True);
   end Convolve;

   -- Core Bluestein Transformation Engine
   function Bluestein_Core (Input : Complex_Array; Inverse : Boolean) return Complex_Array is
      N : constant Integer := Input'Length;
   begin
      if N = 0 then
         raise Invalid_Size with "Input sequence is empty";
      elsif N = 1 then
         declare
            Res : Complex_Array(0..0);
         begin
            Res(0) := Input(Input'First);
            return Res;
         end;
      end if;

      declare
         M : constant Positive := Next_Power_Of_Two (2 * N - 1);
         Arr_A, Arr_B, Arr_C : Complex_Array (0 .. M - 1) := (others => (0.0, 0.0));
         Result : Complex_Array (0 .. N - 1);
         Angle, Sign : Float;
         Val : Complex;
      begin
         Sign := (if Inverse then 1.0 else -1.0);

         -- Prepare sequence a_n
         for I in 0 .. N - 1 loop
            Angle := Sign * Pi * Float(I * I) / Float(N);
            Arr_A(I) := Input(Input'First + I) * Compose_From_Polar(1.0, Angle);
         end loop;

         -- Prepare sequence b_n
         Arr_B(0) := (1.0, 0.0);
         for I in 1 .. N - 1 loop
            Angle := -Sign * Pi * Float(I * I) / Float(N);
            Val := Compose_From_Polar(1.0, Angle);
            Arr_B(I) := Val;
            Arr_B(M - I) := Val;
         end loop;

         -- Perform cyclic convolution
         Arr_C := Convolve (Arr_A, Arr_B);

         -- Post-multiply and extract
         for I in 0 .. N - 1 loop
            Angle := Sign * Pi * Float(I * I) / Float(N);
            Val := Compose_From_Polar(1.0, Angle);
            Result(I) := Arr_C(I) * Val;
            if Inverse then
               Result(I) := Result(I) / Complex'(Float(N), 0.0);
            end if;
         end loop;

         return Result;
      end;
   end Bluestein_Core;

   -- Variant 1
   function Forward_FFT (Input : Complex_Array) return Complex_Array is
   begin
      return Bluestein_Core (Input, False);
   end Forward_FFT;

   -- Variant 2
   function Inverse_FFT (Input : Complex_Array) return Complex_Array is
   begin
      return Bluestein_Core (Input, True);
   end Inverse_FFT;

   -- Variant 3: General CZT
   function Chirp_Z_Transform (Input : Complex_Array; A, W : Complex; M_Out : Positive) return Complex_Array is
      N : constant Integer := Input'Length;
   begin
      if N = 0 then
         raise Invalid_Size with "Input cannot be empty";
      end if;

      declare
         L : constant Positive := Next_Power_Of_Two (N + M_Out - 1);
         Arr_A, Arr_B, Arr_C : Complex_Array (0 .. L - 1) := (others => (0.0, 0.0));
         Result : Complex_Array (0 .. M_Out - 1);
      begin
         for I in 0 .. N - 1 loop
            Arr_A(I) := Input(Input'First + I) * (A ** (-Float(I))) * (W ** (Float(I * I) / 2.0));
         end loop;

         for I in 0 .. M_Out - 1 loop
            Arr_B(I) := W ** (-Float(I * I) / 2.0);
         end loop;

         for I in 1 .. N - 1 loop
            Arr_B(L - I) := W ** (-Float(I * I) / 2.0);
         end loop;

         Arr_C := Convolve (Arr_A, Arr_B);

         for I in 0 .. M_Out - 1 loop
            Result(I) := Arr_C(I) * (W ** (Float(I * I) / 2.0));
         end loop;

         return Result;
      end;
   end Chirp_Z_Transform;

end Bluestein;
