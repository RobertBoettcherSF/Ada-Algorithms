--  Package: BCJR
--  Description: Bahl-Cocke-Jelinek-Raviv (BCJR) algorithm for maximum a posteriori (MAP) decoding.
--  Implements Standard, Max-Log-MAP, and Log-MAP variants.

package BCJR is
   
   --  Strong typing for all algorithm-specific data domains.
   type Real is new Long_Float;
   type State_ID is new Natural;
   type Bit is range 0 .. 1;

   --  Represents the expected output bits of a trellis transition.
   type Output_Bits is record
      Systematic : Bit;
      Parity     : Bit;
   end record;

   --  Represents a single branch transition in the Trellis.
   type Branch_Info is record
      Next_State : State_ID;
      Output     : Output_Bits;
   end record;

   --  Each state has exactly 2 outgoing branches (for input bit 0 and 1).
   type Branch_Array is array (Bit) of Branch_Info;
   
   --  The Trellis Definition: an array mapping State_ID and Input_Bit to a Branch_Info.
   type Trellis_Def is array (State_ID range <>) of Branch_Array;

   --  Array type for sequences of Log-Likelihood Ratios (LLRs) or probabilities.
   type Metric_Array is array (Positive range <>) of Real;

   --  Algorithm variants defined in the literature.
   type Algorithm_Variant is 
     (Standard,    --  Probability domain (numerically prone to underflow, uses normalization)
      Max_Log_MAP, --  Log domain, uses max() approximation (slightly sub-optimal but fast)
      Log_MAP);    --  Log domain, uses Jacobian logarithm max*() (optimal)

   --  Decodes a block of soft-input LLRs and computes Extrinsic LLRs.
   --  Assumes Rate 1/2 encoding. Input LLR > 0 implies bit '1' is more likely (BPSK 1 -> +1.0).
   procedure Decode
     (Variant    : in  Algorithm_Variant;
      Trellis    : in  Trellis_Def;
      Sys_LLR    : in  Metric_Array;
      Parity_LLR : in  Metric_Array;
      Apriori    : in  Metric_Array;
      Ext_LLR    : out Metric_Array;
      Terminated : in  Boolean := True)
   with Pre => Sys_LLR'First = 1
               and then Parity_LLR'First = 1
               and then Apriori'First = 1
               and then Ext_LLR'First = 1
               and then Sys_LLR'Length = Parity_LLR'Length
               and then Sys_LLR'Length = Ext_LLR'Length
               and then Sys_LLR'Length = Apriori'Length
               and then Trellis'Length > 0;

end BCJR;
