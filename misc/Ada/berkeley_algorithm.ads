-- berkeley_algorithm.ads
-- Specification for the Berkeley Algorithm for clock synchronization.
-- Implements both Standard and Fault-Tolerant variants.

package Berkeley_Algorithm is

   -- Strong typing for algorithm-specific data to prevent unit mixing
   type Time_Value is new Long_Long_Integer;
   type Time_Offset is new Long_Long_Integer;
   type Node_ID is new Positive;

   -- Record representing a slave node's clock reading and latency
   type Slave_Record is record
      ID              : Node_ID;
      Reported_Time   : Time_Value;
      Round_Trip_Time : Time_Value;
   end record;

   -- Unconstrained array of slaves
   type Slave_Array is array (Positive range <>) of Slave_Record;

   -- Record representing the calculated adjustment for a specific node
   type Offset_Record is record
      ID     : Node_ID;
      Offset : Time_Offset;
   end record;

   type Offset_Array is array (Positive range <>) of Offset_Record;

   -- Exception raised when invalid data (e.g., negative RTT) is provided
   Invalid_Data_Error : exception;

   -- =========================================================================
   -- Variant 1: Standard Berkeley Algorithm
   -- =========================================================================
   -- Computes the average time across the Master and ALL Slaves.
   -- Assumes all clock readings are trustworthy.
   procedure Calculate_Offsets
     (Master_Time : in  Time_Value;
      Slaves      : in  Slave_Array;
      Master_Adj  : out Time_Offset;
      Slave_Adjs  : out Offset_Array);

   -- =========================================================================
   -- Variant 2: Fault-Tolerant Berkeley Algorithm
   -- =========================================================================
   -- Computes the average time using only clocks that are within a specific
   -- tolerance compared to the Master's time. Ignores outliers (faulty clocks).
   procedure Calculate_Fault_Tolerant_Offsets
     (Master_Time   : in  Time_Value;
      Slaves        : in  Slave_Array;
      Max_Tolerance : in  Time_Value;
      Master_Adj    : out Time_Offset;
      Slave_Adjs    : out Offset_Array);

end Berkeley_Algorithm;
