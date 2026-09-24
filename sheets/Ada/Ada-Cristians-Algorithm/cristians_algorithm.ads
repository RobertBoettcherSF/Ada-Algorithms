-- cristians_algorithm.ads
-- Specification for Cristian's Clock Synchronization Algorithm

package Cristians_Algorithm is

   -- Strong typing: Distinct types for absolute time and time differences
   type Timestamp is new Long_Float;
   type Time_Delta is new Long_Float;

   -- Represents a single synchronization request/response cycle
   type Sync_Sample is record
      T_Send   : Timestamp;  -- Client time when request was sent (T0)
      T_Server : Timestamp;  -- Server time reported in response
      T_Recv   : Timestamp;  -- Client time when response was received (T1)
   end record;

   -- Array for the multiple-request variant of the algorithm
   type Sample_Array is array (Positive range <>) of Sync_Sample;

   -- Exceptions for error handling and invalid data
   Invalid_Time_Error     : exception; -- Raised if T_Recv < T_Send (Negative RTT)
   Invalid_Delay_Error    : exception; -- Raised if Min_Delay > RTT
   Outlier_Error          : exception; -- Raised if RTT exceeds max threshold
   No_Valid_Samples_Error : exception; -- Raised if sample array is empty

   -- Variant 1: Basic Cristian's Algorithm
   -- Calculates the synchronized time: T_Server + (RTT / 2)
   function Synchronize_Basic (Sample : Sync_Sample) return Timestamp;

   -- Variant 2: Threshold-based Cristian's Algorithm
   -- Discards the sample if the Round Trip Time (RTT) exceeds a given threshold
   function Synchronize_With_Threshold 
     (Sample : Sync_Sample; 
      Max_RTT : Time_Delta) return Timestamp;

   -- Variant 3: Multiple Request Algorithm
   -- Takes multiple samples, selects the one with the shortest RTT to minimize network variance
   function Synchronize_Multiple (Samples : Sample_Array) return Timestamp;

   -- Helper: Calculates the Round Trip Time (RTT) for a sample
   function Calculate_RTT (Sample : Sync_Sample) return Time_Delta;

   -- Helper: Calculates the accuracy/error bound of the synchronization: ±(RTT - Min_Delay) / 2
   function Calculate_Error_Bound 
     (Sample    : Sync_Sample; 
      Min_Delay : Time_Delta) return Time_Delta;

end Cristians_Algorithm;
