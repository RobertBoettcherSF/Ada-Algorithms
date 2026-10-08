with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body Adaptive_Additive is
   use Ada.Numerics;
   use Ada.Numerics.Elementary_Functions;

   -- Extracts the physical amplitude (modulus) of a complex wave
   function Modulus_Helper (C : Complex) return Float is
   begin
      return Sqrt (C.Re**2 + C.Im**2);
   end Modulus_Helper;

   -- Extracts the spatial frequency phase (argument) of a complex wave
   function Argument_Helper (C : Complex) return Float is
   begin
      if C.Re = 0.0 and C.Im = 0.0 then
         return 0.0;
      end if;
      return Arctan (Y => C.Im, X => C.Re);
   end Argument_Helper;

   -- Custom implementation of a Discrete Fourier Transform (DFT)
   -- Used instead of a bound external C-library to maintain pure Ada execution.
   function DFT (Input : Complex_Array; Inverse : Boolean := False) return Complex_Array is
      N : constant Natural := Input'Length;
      Result : Complex_Array (Input'Range);
      Angle_Factor, Theta : Float;
      Sum, Exp_Theta : Complex;
   begin
      if N = 0 then
         return Result;
      end if;

      Angle_Factor := (if Inverse then 2.0 * Pi / Float(N) else -2.0 * Pi / Float(N));

      for K in 0 .. N - 1 loop
         Sum := (0.0, 0.0);
         for J in 0 .. N - 1 loop
            Theta := Angle_Factor * Float(K * J);
            -- e^(i*theta) = cos(theta) + i*sin(theta)
            Exp_Theta := (Re => Cos (Theta), Im => Sin (Theta));
            Sum := Sum + Input (Input'First + J) * Exp_Theta;
         end loop;
         
         if Inverse then
            Result (Input'First + K) := Sum / Complex'(Re => Float(N), Im => 0.0);
         else
            Result (Input'First + K) := Sum;
         end if;
      end loop;
      
      return Result;
   end DFT;

   procedure AA_Algorithm
     (Input_Amplitude   : in Real_Array;
      Desired_Intensity : in Real_Array;
      Mixing_Ratio      : in Mixing_Ratio_Type;
      Max_Iterations    : in Positive;
      Tolerance         : in Float;
      Result_Phase      : out Real_Array;
      Converged         : out Boolean) 
   is
      N : constant Natural := Input_Amplitude'Length;
      Current_Wave, Transformed_Wave, Mixed_Wave : Complex_Array (Input_Amplitude'Range);
      Current_Phase : Real_Array (Input_Amplitude'Range) := (others => 0.0);
      Error_Sum, Current_Error, A_nf, I_nf, I_0, A_f, A_bar, Phi_nf : Float;
   begin
      -- Edge Case Validation: Validate identical bounds and valid lengths
      if N = 0 or else 
         Input_Amplitude'First /= Desired_Intensity'First or else 
         Input_Amplitude'Last /= Desired_Intensity'Last 
      then
         raise Invalid_Input_Error;
      end if;

      -- Edge Case Validation: Intensities physically cannot be negative
      for I in Desired_Intensity'Range loop
         if Desired_Intensity (I) < 0.0 then
            raise Invalid_Input_Error;
         end if;
      end loop;

      Converged := False;

      for Iter in 1 .. Max_Iterations loop
         -- Step 1 & 2: Combine amplitude and phase, apply Forward Transform
         for I in Input_Amplitude'Range loop
            Current_Wave (I) := (Re => Input_Amplitude (I) * Cos (Current_Phase (I)),
                                 Im => Input_Amplitude (I) * Sin (Current_Phase (I)));
         end loop;
         
         Transformed_Wave := DFT (Current_Wave, Inverse => False);

         -- Step 3: Compare transformed intensity to desired output and check convergence
         Error_Sum := 0.0;
         for I in Transformed_Wave'Range loop
            A_nf := Modulus_Helper (Transformed_Wave (I));
            I_nf := A_nf**2;
            I_0  := Desired_Intensity (I);
            Error_Sum := Error_Sum + (I_nf - I_0)**2;
         end loop;
         
         Current_Error := Sqrt (Error_Sum / Float (N));
         if Current_Error <= Tolerance then
            Converged := True;
            Result_Phase := Current_Phase;
            return;
         end if;

         -- Step 4: Mix amplitudes according to the ratio
         for I in Transformed_Wave'Range loop
            A_nf := Modulus_Helper (Transformed_Wave (I));
            I_0  := Desired_Intensity (I);
            A_f  := Sqrt (I_0);
            
            A_bar := Mixing_Ratio * A_f + (1.0 - Mixing_Ratio) * A_nf;
            Phi_nf := Argument_Helper (Transformed_Wave (I));
            
            Mixed_Wave (I) := (Re => A_bar * Cos (Phi_nf), Im => A_bar * Sin (Phi_nf));
         end loop;

         -- Step 5 & 6: Apply Inverse Transform and extract next phase loop
         Current_Wave := DFT (Mixed_Wave, Inverse => True);

         for I in Current_Wave'Range loop
            Current_Phase (I) := Argument_Helper (Current_Wave (I));
         end loop;
      end loop;

      Result_Phase := Current_Phase;
   end AA_Algorithm;

   procedure Gerchberg_Saxton
     (Input_Amplitude   : in Real_Array;
      Desired_Intensity : in Real_Array;
      Max_Iterations    : in Positive;
      Tolerance         : in Float;
      Result_Phase      : out Real_Array;
      Converged         : out Boolean) 
   is
   begin
      AA_Algorithm (Input_Amplitude, Desired_Intensity, 1.0, Max_Iterations, Tolerance, Result_Phase, Converged);
   end Gerchberg_Saxton;

   procedure Fixed_Amplitude
     (Input_Amplitude   : in Real_Array;
      Desired_Intensity : in Real_Array;
      Max_Iterations    : in Positive;
      Tolerance         : in Float;
      Result_Phase      : out Real_Array;
      Converged         : out Boolean) 
   is
   begin
      AA_Algorithm (Input_Amplitude, Desired_Intensity, 0.0, Max_Iterations, Tolerance, Result_Phase, Converged);
   end Fixed_Amplitude;

end Adaptive_Additive;
