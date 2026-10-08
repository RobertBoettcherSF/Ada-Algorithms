with Ada.Numerics;
use Ada.Numerics;
with Interfaces;

package body Cooley_Tukey is

   -------------------------------------------------------------------------
   -- Is_Power_Of_Two
   -- Uses Interfaces.Unsigned_32 to safely perform bitwise operations 
   -- (N and (N - 1) == 0) for standard integer power-of-two validation.
   -------------------------------------------------------------------------
   function Is_Power_Of_Two (N : Integer) return Boolean is
      use type Interfaces.Unsigned_32;
      U : Interfaces.Unsigned_32;
   begin
      if N <= 0 then
         return False;
      end if;
      U := Interfaces.Unsigned_32 (N);
      return (U and (U - 1)) = 0;
   end Is_Power_Of_Two;

   -------------------------------------------------------------------------
   -- Bit_Reverse
   -- In-place bit-reversal permutation. Iterates through the array and swaps
   -- elements if their current index is less than their bit-reversed index.
   -------------------------------------------------------------------------
   procedure Bit_Reverse (Data : in out Complex_Array) is
      N : constant Integer := Data'Length;
      J : Integer := 0;
      Temp : Complex;
      M : Integer;
   begin
      for I in 0 .. N - 1 loop
         if I < J then
            Temp := Data (Data'First + I);
            Data (Data'First + I) := Data (Data'First + J);
            Data (Data'First + J) := Temp;
         end if;
         
         M := N / 2;
         while J >= M and M > 0 loop
            J := J - M;
            M := M / 2;
         end loop;
         J := J + M;
      end loop;
   end Bit_Reverse;

   -------------------------------------------------------------------------
   -- FFT_Iterative
   -- Bottom-up approach applying Cooley-Tukey butterfly computations.
   -------------------------------------------------------------------------
   procedure FFT_Iterative (Data : in out Complex_Array) is
      N         : constant Integer := Data'Length;
      Step      : Integer;
      Half_Step : Integer;
      W_M, W, T, U : Complex;
      Angle     : Float;
   begin
      if not Is_Power_Of_Two (N) then
         raise Invalid_Size_Error with "FFT Iterative: Array length must be a power of two";
      end if;

      -- 1. Permute the array using bit-reversal
      Bit_Reverse (Data);

      -- 2. Perform the butterfly operations bottom-up
      Step := 2;
      while Step <= N loop
         Half_Step := Step / 2;
         -- Twiddle factor multiplier for this stage
         Angle := -2.0 * Pi / Float (Step);
         W_M := Compose_From_Polar (1.0, Angle);
         
         for K in 0 .. (N / Step) - 1 loop
            W := Compose_From_Cartesian (1.0, 0.0);
            for J in 0 .. Half_Step - 1 loop
               declare
                  Even_Idx : constant Integer := Data'First + K * Step + J;
                  Odd_Idx  : constant Integer := Even_Idx + Half_Step;
               begin
                  -- Butterfly computation
                  T := W * Data (Odd_Idx);
                  U := Data (Even_Idx);
                  
                  Data (Even_Idx) := U + T;
                  Data (Odd_Idx)  := U - T;
                  
                  -- Update twiddle factor
                  W := W * W_M;
               end;
            end loop;
         end loop;
         Step := Step * 2;
      end loop;
   end FFT_Iterative;

   -------------------------------------------------------------------------
   -- FFT_Recursive
   -- Top-down divide and conquer algorithm separating even and odd elements.
   -------------------------------------------------------------------------
   procedure FFT_Recursive (Data : in out Complex_Array) is
      N : constant Integer := Data'Length;
   begin
      -- Base Case
      if N <= 1 then
         return;
      end if;

      if not Is_Power_Of_Two (N) then
         raise Invalid_Size_Error with "FFT Recursive: Array length must be a power of two";
      end if;

      declare
         Half_N : constant Integer := N / 2;
         Even   : Complex_Array (0 .. Half_N - 1);
         Odd    : Complex_Array (0 .. Half_N - 1);
      begin
         -- Split into Even and Odd indices
         for I in 0 .. Half_N - 1 loop
            Even (I) := Data (Data'First + I * 2);
            Odd (I)  := Data (Data'First + I * 2 + 1);
         end loop;

         -- Recursive calls
         FFT_Recursive (Even);
         FFT_Recursive (Odd);

         -- Combine results using twiddle factors
         for I in 0 .. Half_N - 1 loop
            declare
               Angle : constant Float := -2.0 * Pi * Float (I) / Float (N);
               W     : constant Complex := Compose_From_Polar (1.0, Angle);
               T     : constant Complex := W * Odd (I);
            begin
               Data (Data'First + I)          := Even (I) + T;
               Data (Data'First + I + Half_N) := Even (I) - T;
            end;
         end loop;
      end;
   end FFT_Recursive;

   -------------------------------------------------------------------------
   -- IFFT (Inverse Fast Fourier Transform)
   -------------------------------------------------------------------------
   procedure IFFT (Data : in out Complex_Array) is
      N : constant Integer := Data'Length;
   begin
      -- 1. Take the complex conjugate of the signal
      for I in Data'Range loop
         Data (I) := Conjugate (Data (I));
      end loop;

      -- 2. Run standard forward FFT (Iterative chosen for speed)
      FFT_Iterative (Data);

      -- 3. Take conjugate again and normalize by N
      for I in Data'Range loop
         Data (I) := Conjugate (Data (I)) / Float (N);
      end loop;
   end IFFT;

end Cooley_Tukey;
