package Fast_Folding is

   -- Strong typing for algorithm-specific data
   type Signal_Value is new Float;
   type Signal_Array is array (Positive range <>) of Signal_Value;

   type Profile_Array is array (Positive range <>) of Signal_Value;
   type Profile_Matrix is array (Positive range <>, Positive range <>) of Signal_Value;

   -- Custom Exceptions for Robust Error Handling
   Invalid_Period_Error   : exception;
   Invalid_Segments_Error : exception;

   -- Variant 1: Constant Period Fold (Non-drifting)
   -- A brute-force variant that assumes a static period with no phase drift.
   -- It iterates through the dataset and accumulates values into a fixed-period bin.
   procedure Constant_Period_Fold
     (Data   : in Signal_Array;
      Period : in Positive;
      Result : out Profile_Array);

   -- Variant 2: Fast Folding Algorithm (Dynamic Phase Drift)
   -- Implements logarithmic butterfly combinations to search for drifting periods.
   -- Efficiently sums segments with sequential shifts.
   -- Note: Num_Segments must be a power of 2.
   procedure Fast_Fold
     (Data         : in Signal_Array;
      Base_Period  : in Positive;
      Num_Segments : in Positive;
      Result       : out Profile_Matrix);

end Fast_Folding;
