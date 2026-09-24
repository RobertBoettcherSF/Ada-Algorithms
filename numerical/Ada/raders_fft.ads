with Ada.Numerics;
with Ada.Numerics.Generic_Complex_Types;

package Raders_FFT is
   -- Use a custom Real type to ensure precision and strong typing
   type Real is new Long_Float;
   package Complex_Types is new Ada.Numerics.Generic_Complex_Types (Real);
   use Complex_Types;

   type Complex_Array is array (Natural range <>) of Complex;

   -- Exceptions for error handling
   Non_Prime_Length_Error : exception;
   Invalid_Input_Error : exception;

   -- Variant 1: Rader's Algorithm using direct N-1 cyclic convolution
   procedure Rader_DFT_Direct (Input : in Complex_Array; Output : out Complex_Array);

   -- Variant 2: Rader's Algorithm using O(N log N) Fast Convolution (Zero-padded FFT)
   procedure Rader_DFT_Fast (Input : in Complex_Array; Output : out Complex_Array);

   -- Helper mathematical subprograms (exposed for verification and validation)
   function Is_Prime (N : Natural) return Boolean;
   function Primitive_Root (N : Natural) return Natural;
   function Mod_Inverse (A, M : Natural) return Natural;
   function Mod_Exp (Base, Exp, M : Natural) return Natural;
   function Next_Power_Of_2 (N : Natural) return Natural;
   
end Raders_FFT;
