-- celp.ads
-- Specification for Code-Excited Linear Prediction (CELP) and its variants.

package CELP is

   -- Strong typing for algorithm-specific data
   Frame_Size : constant Positive := 40;
   type Frame_Index is range 1 .. Frame_Size;
   type Signal_Frame is array (Frame_Index) of Float;
   
   LPC_Order : constant Positive := 10;
   type LPC_Coeffs is array (1 .. LPC_Order) of Float;

   -- CELP Variants mentioned in Wikipedia
   -- Note: 'Standard' renamed to 'Standard_CELP' to avoid conflict with Ada's root Standard package.
   type CELP_Variant is 
     (Standard_CELP, -- Basic Codebook (Gaussian noise)
      ACELP,         -- Algebraic CELP (Sparse, interleaved pulses)
      VSELP,         -- Vector Sum Excited Linear Prediction (Basis vectors)
      LD_CELP,       -- Low-Delay CELP (Backward-adaptive predictor, short vectors)
      PSI_CELP);     -- Pitch Synchronous Innovation CELP

   -- Custom Exceptions
   CELP_Configuration_Error : exception;
   CELP_Processing_Error    : exception;

   -- Encoded parameters transmitted/stored
   type Encoded_Parameters is record
      LPC         : LPC_Coeffs;
      Pitch_Delay : Integer range 0 .. 147; -- Typical pitch delay range
      Pitch_Gain  : Float;
      Fixed_Index : Integer range 1 .. 256; -- 8-bit fixed codebook index
      Fixed_Gain  : Float;
      Variant     : CELP_Variant;
   end record;

   -- Core Procedures
   -- Encodes a speech frame using the Analysis-by-Synthesis (AbS) loop
   procedure Encode (
      Input  : in  Signal_Frame; 
      Params : out Encoded_Parameters; 
      Variant: in  CELP_Variant := Standard_CELP
   );

   -- Decodes parameters back into a synthesized speech frame
   procedure Decode (
      Params : in  Encoded_Parameters; 
      Output : out Signal_Frame
   );

   -- Helper Functions exposed for testing and modularity
   function Compute_MSE (Frame_A, Frame_B : Signal_Frame) return Float;
   function Generate_Fixed_Codebook (Index : Integer; Variant : CELP_Variant) return Signal_Frame;
   function Apply_LPC_Synthesis (Excitation : Signal_Frame; LPC : LPC_Coeffs) return Signal_Frame;
   
end CELP;
