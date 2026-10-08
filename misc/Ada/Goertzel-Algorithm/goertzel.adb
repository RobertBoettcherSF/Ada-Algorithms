with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;

package body Goertzel is
   
   -- Instantiate math functions explicitly for our strongly-typed 'Real'
   package Real_Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Math;

   Pi : constant Real := Real(Ada.Numerics.Pi);

   -- Variant 1: Basic Goertzel Algorithm (Complex Output)
   function Basic_Goertzel (Data             : Real_Array; 
                            Target_Frequency : Real; 
                            Sample_Rate      : Real) return Complex is
      W      : Real;
      Cosine : Real;
      Sine   : Real;
      Coeff  : Real;
      Q0, Q1, Q2 : Real := 0.0;
      Result : Complex;
   begin
      if Data'Length = 0 or else Sample_Rate <= 0.0 then
         raise Goertzel_Error with "Invalid array length or sample rate";
      end if;

      -- Calculate normalized frequency (omega)
      W := (2.0 * Pi * Target_Frequency) / Sample_Rate;
      Cosine := Cos (W);
      Sine   := Sin (W);
      Coeff  := 2.0 * Cosine;

      -- Recursive equation execution over the sample array
      for I in Data'Range loop
         Q0 := Data (I) + Coeff * Q1 - Q2;
         Q2 := Q1;
         Q1 := Q0;
      end loop;

      -- Final complex mathematical evaluation
      Result.Re := Q1 - Q2 * Cosine;
      Result.Im := Q2 * Sine;
      return Result;
   end Basic_Goertzel;

   -- Variant 2: Optimized Goertzel Algorithm (Magnitude Squared)
   function Optimized_Goertzel (Data             : Real_Array; 
                                Target_Frequency : Real; 
                                Sample_Rate      : Real) return Real is
      W      : Real;
      Coeff  : Real;
      Q0, Q1, Q2 : Real := 0.0;
   begin
      if Data'Length = 0 or else Sample_Rate <= 0.0 then
         raise Goertzel_Error with "Invalid array length or sample rate";
      end if;

      W := (2.0 * Pi * Target_Frequency) / Sample_Rate;
      Coeff := 2.0 * Cos (W);

      -- Same recursive filter as basic variant
      for I in Data'Range loop
         Q0 := Data (I) + Coeff * Q1 - Q2;
         Q2 := Q1;
         Q1 := Q0;
      end loop;

      -- Optimized power calculation bypassing complex domain
      return Q1 * Q1 + Q2 * Q2 - Q1 * Q2 * Coeff;
   end Optimized_Goertzel;

   -- Variant 3: Stateful / Streaming Initialization
   procedure Init_State (State            : in out Goertzel_State; 
                         Target_Frequency : Real; 
                         Sample_Rate      : Real) is
      W : Real;
   begin
      if Sample_Rate <= 0.0 then
         raise Goertzel_Error with "Invalid sample rate";
      end if;
      
      W := (2.0 * Pi * Target_Frequency) / Sample_Rate;
      State.Coeff   := 2.0 * Cos (W);
      State.S_Prev1 := 0.0;
      State.S_Prev2 := 0.0;
   end Init_State;

   -- Variant 3: Process a single streaming data point
   procedure Process_Sample (State  : in out Goertzel_State; 
                             Sample : Real) is
      S0 : Real;
   begin
      S0 := Sample + State.Coeff * State.S_Prev1 - State.S_Prev2;
      State.S_Prev2 := State.S_Prev1;
      State.S_Prev1 := S0;
   end Process_Sample;

   -- Variant 3: Retrieve Streaming Magnitude Squared
   function Get_Magnitude_Squared (State : Goertzel_State) return Real is
   begin
      return State.S_Prev1 * State.S_Prev1 + 
             State.S_Prev2 * State.S_Prev2 - 
             State.S_Prev1 * State.S_Prev2 * State.Coeff;
   end Get_Magnitude_Squared;

   -- Variant 3: Retrieve Streaming Complex Result
   function Get_Complex (State            : Goertzel_State; 
                         Target_Frequency : Real; 
                         Sample_Rate      : Real) return Complex is
      W      : Real;
      Cosine : Real;
      Sine   : Real;
      Result : Complex;
   begin
      W := (2.0 * Pi * Target_Frequency) / Sample_Rate;
      Cosine := Cos (W);
      Sine   := Sin (W);

      Result.Re := State.S_Prev1 - State.S_Prev2 * Cosine;
      Result.Im := State.S_Prev2 * Sine;
      return Result;
   end Get_Complex;

end Goertzel;
