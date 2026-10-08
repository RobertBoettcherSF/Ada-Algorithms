-- fft.adb
with Ada.Numerics; use Ada.Numerics;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body FFT is

   -------------------------------------------------
   -- Helper Functions
   -------------------------------------------------
   function Is_Power_Of_2 (N : Natural) return Boolean is
      Temp : Natural := N;
   begin
      if Temp = 0 then 
         return False; 
      end if;
      
      while Temp mod 2 = 0 loop
         Temp := Temp / 2;
      end loop;
      
      return Temp = 1;
   end Is_Power_Of_2;

   function Next_Power_Of_2 (N : Natural) return Natural is
      Result : Natural := 1;
   begin
      while Result < N loop
         Result := Result * 2;
      end loop;
      return Result;
   end Next_Power_Of_2;

   function Complex_Conjugate (C : Complex) return Complex is
   begin
      return (Re => C.Re, Im => -C.Im);
   end Complex_Conjugate;

   -------------------------------------------------
   -- Variant 1: Recursive DIT (Decimation In Time)
   -------------------------------------------------
   function FFT_Recursive_DIT (Input : Complex_Array) return Complex_Array is
      N : constant Integer := Input'Length;
      Result : Complex_Array (0 .. N - 1);
   begin
      -- Base and Edge Cases
      if N = 0 then return Result; end if;
      if not Is_Power_Of_2 (N) then
         raise FFT_Error with "Input length must be a power of 2 for Radix-2 FFT";
      end if;
      if N = 1 then
         Result (0) := Input (Input'First);
         return Result;
      end if;

      declare
         Half_N   : constant Integer := N / 2;
         Even     : Complex_Array (0 .. Half_N - 1);
         Odd      : Complex_Array (0 .. Half_N - 1);
         Even_FFT : Complex_Array (0 .. Half_N - 1);
         Odd_FFT  : Complex_Array (0 .. Half_N - 1);
         Angle    : Float;
         W, T     : Complex;
      begin
         -- Separate into even and odd indices
         for I in 0 .. Half_N - 1 loop
            Even (I) := Input (Input'First + 2 * I);
            Odd (I)  := Input (Input'First + 2 * I + 1);
         end loop;

         Even_FFT := FFT_Recursive_DIT (Even);
         Odd_FFT  := FFT_Recursive_DIT (Odd);

         -- Butterfly operations
         for K in 0 .. Half_N - 1 loop
            Angle := -2.0 * Pi * Float (K) / Float (N);
            W     := (Re => Cos (Angle), Im => Sin (Angle)); -- Twiddle factor
            T     := W * Odd_FFT (K);
            Result (K)          := Even_FFT (K) + T;
            Result (K + Half_N) := Even_FFT (K) - T;
         end loop;
      end;
      return Result;
   end FFT_Recursive_DIT;

   -------------------------------------------------
   -- Variant 2: Recursive DIF (Decimation In Frequency)
   -------------------------------------------------
   function FFT_Recursive_DIF (Input : Complex_Array) return Complex_Array is
      N : constant Integer := Input'Length;
      Result : Complex_Array (0 .. N - 1);
   begin
      if N = 0 then return Result; end if;
      if not Is_Power_Of_2 (N) then raise FFT_Error; end if;
      if N = 1 then
         Result (0) := Input (Input'First);
         return Result;
      end if;

      declare
         Half_N      : constant Integer := N / 2;
         First_Half  : Complex_Array (0 .. Half_N - 1);
         Second_Half : Complex_Array (0 .. Half_N - 1);
         First_FFT   : Complex_Array (0 .. Half_N - 1);
         Second_FFT  : Complex_Array (0 .. Half_N - 1);
         Angle       : Float;
         W           : Complex;
      begin
         -- Pre-butterfly computations for DIF
         for I in 0 .. Half_N - 1 loop
            First_Half (I) := Input (Input'First + I) + Input (Input'First + I + Half_N);
            Angle          := -2.0 * Pi * Float (I) / Float (N);
            W              := (Re => Cos (Angle), Im => Sin (Angle));
            Second_Half (I) := (Input (Input'First + I) - Input (Input'First + I + Half_N)) * W;
         end loop;

         First_FFT  := FFT_Recursive_DIF (First_Half);
         Second_FFT := FFT_Recursive_DIF (Second_Half);

         -- Interleave results
         for K in 0 .. Half_N - 1 loop
            Result (2 * K)     := First_FFT (K);
            Result (2 * K + 1) := Second_FFT (K);
         end loop;
      end;
      return Result;
   end FFT_Recursive_DIF;

   -------------------------------------------------
   -- Variant 3: Iterative DIT with Bit-Reversal
   -------------------------------------------------
   function FFT_Iterative (Input : Complex_Array) return Complex_Array is
      N : constant Integer := Input'Length;
      Result : Complex_Array (0 .. N - 1);
      Bits : Natural := 0;
      Temp_N : Natural := N;
      Bit_Rev_Idx : Natural;
      Temp, U, W : Complex;
      Step, Half_Step, J : Natural;
      Angle : Float;
   begin
      if N = 0 then return Result; end if;
      if not Is_Power_Of_2 (N) then raise FFT_Error; end if;

      -- Calculate log2(N)
      while Temp_N > 1 loop
         Bits := Bits + 1;
         Temp_N := Temp_N / 2;
      end loop;

      -- Bit-reversal permutation copy
      for I in 0 .. N - 1 loop
         Bit_Rev_Idx := 0;
         declare
            Val : Natural := I;
         begin
            for B in 1 .. Bits loop
               Bit_Rev_Idx := Bit_Rev_Idx * 2 + (Val mod 2);
               Val := Val / 2;
            end loop;
         end;
         Result (Bit_Rev_Idx) := Input (Input'First + I);
      end loop;

      -- Iterative Butterfly Stages
      Step := 2;
      while Step <= N loop
         Half_Step := Step / 2;
         for K in 0 .. Half_Step - 1 loop
            Angle := -2.0 * Pi * Float (K) / Float (Step);
            W     := (Re => Cos (Angle), Im => Sin (Angle));
            J     := K;
            while J < N loop
               Temp                  := W * Result (J + Half_Step);
               U                     := Result (J);
               Result (J)            := U + Temp;
               Result (J + Half_Step) := U - Temp;
               J                     := J + Step;
            end loop;
         end loop;
         Step := Step * 2;
      end loop;
      return Result;
   end FFT_Iterative;

   -------------------------------------------------
   -- Variant 4: Inverse FFT
   -------------------------------------------------
   function IFFT (Input : Complex_Array) return Complex_Array is
      N : constant Integer := Input'Length;
      Result : Complex_Array (0 .. N - 1);
      Conjugated : Complex_Array (0 .. N - 1);
      Scaler : constant Float := Float (N);
   begin
      if N = 0 then return Result; end if;

      -- Conjugate the input
      for I in 0 .. N - 1 loop
         Conjugated (I) := Complex_Conjugate (Input (Input'First + I));
      end loop;

      -- Perform standard Forward FFT
      Result := FFT_Recursive_DIT (Conjugated);

      -- Conjugate output and scale by 1/N
      for I in 0 .. N - 1 loop
         Result (I) := Complex_Conjugate (Result (I));
         Result (I).Re := Result (I).Re / Scaler;
         Result (I).Im := Result (I).Im / Scaler;
      end loop;
      return Result;
   end IFFT;

end FFT;
