package body Gerchberg_Saxton is

   Two_Pi : constant Real := 2.0 * Ada.Numerics.Pi;
   J      : constant Complex := (0.0, 1.0);

   -----------------------------------------------------------------------------
   -- Discrete Fourier Transform (1D)
   -----------------------------------------------------------------------------
   function DFT (Input : Complex_Array) return Complex_Array is
      N      : constant Real := Real (Input'Length);
      Output : Complex_Array (Input'Range);
      Angle  : Real;
      Sum    : Complex;
   begin
      if Input'Length = 0 then
         raise Invalid_Input_Error;
      end if;

      for K in Output'Range loop
         Sum := (0.0, 0.0);
         for T in Input'Range loop
            -- 1-based indexing correction for proper mathematical bounds (0 to N-1)
            Angle := -Two_Pi * Real (K - Output'First) * Real (T - Input'First) / N;
            Sum := Sum + Input (T) * Complex_Math.Exp (J * Angle);
         end loop;
         Output (K) := Sum;
      end loop;
      return Output;
   end DFT;

   -----------------------------------------------------------------------------
   -- Inverse Discrete Fourier Transform (1D)
   -----------------------------------------------------------------------------
   function IDFT (Input : Complex_Array) return Complex_Array is
      N      : constant Real := Real (Input'Length);
      Output : Complex_Array (Input'Range);
      Angle  : Real;
      Sum    : Complex;
   begin
      if Input'Length = 0 then
         raise Invalid_Input_Error;
      end if;

      for K in Output'Range loop
         Sum := (0.0, 0.0);
         for T in Input'Range loop
            Angle := Two_Pi * Real (K - Output'First) * Real (T - Input'First) / N;
            Sum := Sum + Input (T) * Complex_Math.Exp (J * Angle);
         end loop;
         Output (K) := Sum / Complex'(N, 0.0);
      end loop;
      return Output;
   end IDFT;

   -----------------------------------------------------------------------------
   -- Variant 1: Standard Gerchberg-Saxton Algorithm
   -----------------------------------------------------------------------------
   function Standard_GS (Source_Amp, Target_Amp : Real_Array;
                         Max_Iter               : Natural) return Real_Array is
      
      Phase        : Real_Array (Source_Amp'Range) := (others => 0.0); -- Initial guess
      Field_Space  : Complex_Array (Source_Amp'Range);
      Field_Freq   : Complex_Array (Source_Amp'Range);
   begin
      if Source_Amp'Length = 0 or Target_Amp'Length = 0 then
         raise Invalid_Input_Error;
      end if;
      if Source_Amp'Length /= Target_Amp'Length then
         raise Dimension_Mismatch_Error;
      end if;

      if Max_Iter = 0 then
         return Phase;
      end if;

      for Iter in 1 .. Max_Iter loop
         -- Step 1: Multiply Source Amplitude by current phase guess
         for I in Phase'Range loop
            Field_Space (I) := Complex'(Source_Amp (I), 0.0) * Complex_Math.Exp (J * Phase (I));
         end loop;

         -- Step 2: Forward Transform to frequency domain
         Field_Freq := DFT (Field_Space);

         -- Step 3: Replace Amplitude with Target Amplitude, keep phase
         for I in Field_Freq'Range loop
            declare
               -- Argument is in Complex_Types, which is visible directly
               Current_Phase : Real := Argument (Field_Freq (I));
            begin
               Field_Freq (I) := Complex'(Target_Amp (I), 0.0) * Complex_Math.Exp (J * Current_Phase);
            end;
         end loop;

         -- Step 4: Inverse Transform back to spatial domain
         Field_Space := IDFT (Field_Freq);

         -- Step 5: Extract new phase for next iteration
         for I in Field_Space'Range loop
            Phase (I) := Argument (Field_Space (I));
         end loop;
      end loop;

      return Phase;
   end Standard_GS;

   -----------------------------------------------------------------------------
   -- Variant 2: Hybrid Input-Output GS Variant (HIO)
   -----------------------------------------------------------------------------
   function Hybrid_Input_Output_GS (Source_Amp, Target_Amp : Real_Array;
                                    Max_Iter               : Natural;
                                    Beta                   : Real) return Real_Array is
      
      Phase        : Real_Array (Source_Amp'Range) := (others => 0.0);
      Prev_Space   : Complex_Array (Source_Amp'Range);
      Field_Space  : Complex_Array (Source_Amp'Range);
      Field_Freq   : Complex_Array (Source_Amp'Range);
   begin
      if Source_Amp'Length = 0 or Target_Amp'Length = 0 then
         raise Invalid_Input_Error;
      end if;
      if Source_Amp'Length /= Target_Amp'Length then
         raise Dimension_Mismatch_Error;
      end if;

      -- Initialize Prev_Space for the first iteration
      for I in Source_Amp'Range loop
         Prev_Space (I) := Complex'(Source_Amp (I), 0.0);
      end loop;

      for Iter in 1 .. Max_Iter loop
         -- Apply Source Amplitude constraints
         for I in Phase'Range loop
            Field_Space (I) := Complex'(Source_Amp (I), 0.0) * Complex_Math.Exp (J * Phase (I));
         end loop;

         Field_Freq := DFT (Field_Space);

         -- Enforce Target Amplitude
         for I in Field_Freq'Range loop
            declare
               Current_Phase : Real := Argument (Field_Freq (I));
            begin
               Field_Freq (I) := Complex'(Target_Amp (I), 0.0) * Complex_Math.Exp (J * Current_Phase);
            end;
         end loop;

         Field_Space := IDFT (Field_Freq);

         -- Relaxation/HIO update step
         for I in Field_Space'Range loop
            -- Combine previous input with new output using feedback Beta
            Field_Space (I) := Prev_Space (I) - Complex'(Beta, 0.0) * Field_Space (I);
            Phase (I) := Argument (Field_Space (I));
            Prev_Space (I) := Field_Space (I); -- Save for next cycle
         end loop;
      end loop;

      return Phase;
   end Hybrid_Input_Output_GS;

end Gerchberg_Saxton;
