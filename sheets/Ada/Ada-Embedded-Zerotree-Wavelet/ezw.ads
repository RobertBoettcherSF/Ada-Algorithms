-- ezw.ads
-- Specification for the Embedded Zerotree Wavelet (EZW) Algorithm
-- Covers Initialization, Dominant Pass, and Subordinate Pass variants.

package EZW is
   -- Strong typing for algorithm-specific data
   type Wavelet_Value is new Integer;
   type Threshold_Value is new Integer range 0 .. Integer'Last;
   
   -- Symbols emitted by the EZW encoder
   type Symbol is (POS, NEG, ZTR, IZ, SUB_1, SUB_0);
   type Symbol_Array is array (Positive range <>) of Symbol;

   -- Matrix representing flattened 2D Discrete Wavelet Transform (DWT) coefficients
   type Wavelet_Matrix is array (Positive range <>) of Wavelet_Value;
   
   -- State map tracking which coefficients have been found significant
   type Significance_Map is array (Positive range <>) of Boolean;

   -- Stream buffer for the encoded symbols
   type Encoded_Stream (Max_Size : Positive) is record
      Symbols : Symbol_Array (1 .. Max_Size);
      Count   : Natural := 0;
   end record;

   -- Exceptions
   Empty_Matrix_Error    : exception;
   Stream_Overflow_Error : exception;

   -- Variant/Phase 1: Initial Threshold Calculation
   -- Calculates the largest power of 2 that is <= the maximum absolute value in the matrix
   function Compute_Initial_Threshold (Matrix : Wavelet_Matrix) return Threshold_Value;

   -- Helper: Checks if a node and ALL its descendants form a Zerotree (strictly less than threshold)
   function Is_Zerotree_Root
     (Matrix    : Wavelet_Matrix;
      Index     : Positive;
      Threshold : Threshold_Value) return Boolean;

   -- Variant/Phase 2: Dominant Pass
   -- Scans coefficients and categorizes them into POS, NEG, ZTR, or IZ
   procedure Dominant_Pass
     (Matrix      : in out Wavelet_Matrix;
      Significant : in out Significance_Map;
      Threshold   : in     Threshold_Value;
      Stream      : in out Encoded_Stream);

   -- Variant/Phase 3: Subordinate Pass
   -- Refines the values of coefficients already deemed significant in previous passes
   procedure Subordinate_Pass
     (Original_Matrix : in     Wavelet_Matrix;
      Significant     : in     Significance_Map;
      Threshold       : in     Threshold_Value;
      Stream          : in out Encoded_Stream);

end EZW;
