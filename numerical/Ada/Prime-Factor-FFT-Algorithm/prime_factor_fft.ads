with Ada.Numerics.Complex_Types;
use Ada.Numerics.Complex_Types;

package Prime_Factor_FFT is
   -- Use unconstrained arrays for flexible sizes
   type Complex_Array is array (Natural range <>) of Complex;
   
   -- Exception for invalid PFA setups (e.g., factors not coprime or bad lengths)
   Invalid_Factors : exception;

   -- 1. Naive DFT Variant (Used as inner DFT for the PFA)
   -- Computes the standard O(N^2) Discrete Fourier Transform.
   function DFT_Naive (Input : Complex_Array; Inverse : Boolean := False) return Complex_Array;

   -- 2. Prime-Factor Algorithm (PFA) - Out-of-place variant
   -- Computes FFT using Good-Thomas mapping.
   -- Requires N1 and N2 to be coprime and Input'Length to equal N1 * N2.
   function PFA_Transform (Input : Complex_Array; N1, N2 : Positive; Inverse : Boolean := False) return Complex_Array;

   -- 3. Prime-Factor Algorithm (PFA) - In-place variant
   -- Evaluates the Good-Thomas algorithm modifying the array directly.
   procedure PFA_Transform_In_Place (Data : in out Complex_Array; N1, N2 : Positive; Inverse : Boolean := False);

private
   -- Helper mathematical functions for the Good-Thomas index mappings
   procedure Extended_GCD(A, B : Integer; G, X, Y : out Integer);
   function Mod_Inverse(A, M : Integer) return Integer;
end Prime_Factor_FFT;
