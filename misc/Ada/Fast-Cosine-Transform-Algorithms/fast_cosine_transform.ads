-- fast_cosine_transform.ads
-- Specification for the Fast Cosine Transform (FCT) library.
-- Supports standard Discrete Cosine Transform (DCT) variants.

package Fast_Cosine_Transform is

   -- Use high-precision floating point for trigonometric stability
   type Real is new Long_Float;
   type Real_Array is array (Integer range <>) of Real;

   -- DCT variants as per standard definitions
   type Transform_Variant is 
     (DCT_I,   -- Often used for solving partial differential equations
      DCT_II,  -- The standard "Fast Cosine Transform" (used in JPEG/MPEG)
      DCT_III, -- The standard Inverse DCT
      DCT_IV); -- Used in Modified Discrete Cosine Transform (MDCT)

   Invalid_Argument_Error : exception;

   -- Primary dispatch procedure
   -- Automatically uses O(N log N) Fast algorithm for DCT-II if N is a power of 2, 
   -- otherwise falls back to the robust O(N^2) naive calculation.
   procedure Transform 
     (Input   : in out Real_Array;
      Variant : Transform_Variant := DCT_II);

   -- Explicit variant subprograms for direct access
   procedure Transform_DCT_I   (Input : in out Real_Array);
   procedure Transform_DCT_II  (Input : in out Real_Array);
   procedure Transform_DCT_III (Input : in out Real_Array);
   procedure Transform_DCT_IV  (Input : in out Real_Array);

end Fast_Cosine_Transform;
