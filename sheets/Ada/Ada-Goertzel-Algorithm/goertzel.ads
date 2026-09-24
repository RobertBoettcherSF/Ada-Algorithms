package Goertzel is
   
   -- Custom types for strong typing
   type Real is new Long_Float;
   type Real_Array is array (Positive range <>) of Real;

   -- Represents a complex number for the DFT output
   type Complex is record
      Re : Real;
      Im : Real;
   end record;

   -- Custom exception for invalid inputs
   Goertzel_Error : exception;

   -- =========================================================================
   -- Variant 1: Basic Goertzel Algorithm (Complex Output)
   -- =========================================================================
   -- Evaluates the full complex DFT at a specific target frequency.
   -- Provides both Real and Imaginary components, useful when phase information 
   -- is required.
   function Basic_Goertzel (Data             : Real_Array; 
                            Target_Frequency : Real; 
                            Sample_Rate      : Real) return Complex;

   -- =========================================================================
   -- Variant 2: Optimized Goertzel Algorithm (Magnitude Squared / Power)
   -- =========================================================================
   -- Efficiently calculates the power (magnitude squared) of the target frequency.
   -- Avoids complex arithmetic at the end step. Often used in DTMF tone detection.
   function Optimized_Goertzel (Data             : Real_Array; 
                                Target_Frequency : Real; 
                                Sample_Rate      : Real) return Real;

   -- =========================================================================
   -- Variant 3: Stateful / Pre-computed Goertzel (Streaming Data)
   -- =========================================================================
   -- Maintains internal state to process data sample-by-sample (streaming)
   -- or in blocks, instead of requiring all data at once.
   type Goertzel_State is record
      S_Prev1 : Real := 0.0;
      S_Prev2 : Real := 0.0;
      Coeff   : Real := 0.0;
   end record;

   -- Initializes the state and precomputes the cosine coefficient
   procedure Init_State (State            : in out Goertzel_State; 
                         Target_Frequency : Real; 
                         Sample_Rate      : Real);

   -- Processes a single sample and updates the state
   procedure Process_Sample (State  : in out Goertzel_State; 
                             Sample : Real);

   -- Extracts the optimized magnitude squared from the current state
   function Get_Magnitude_Squared (State : Goertzel_State) return Real;

   -- Extracts the full complex result from the current state 
   function Get_Complex (State            : Goertzel_State; 
                         Target_Frequency : Real; 
                         Sample_Rate      : Real) return Complex;

end Goertzel;
