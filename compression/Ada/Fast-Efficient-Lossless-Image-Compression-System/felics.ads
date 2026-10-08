-- felics.ads
-- Specification for the Fast Efficient Lossless Image Compression System (FELICS)
-- Implements pixel decorrelation, context delta calculation, range classification,
-- and encoding/decoding routines based on Howard and Vitter's algorithm.

package Felics is

   -- Types and Constants
   Max_Pixel_Value : constant := 255;
   type Pixel_Value is range 0 .. Max_Pixel_Value;
   
   type Pixel_Row is array (Positive range <>) of Pixel_Value;
   type Pixel_Matrix is array (Positive range <>, Positive range <>) of Pixel_Value;

   type Region_Type is (Inside_Range, Below_Range, Above_Range);

   type Context_Record is record
      Lower       : Pixel_Value;
      Higher      : Pixel_Value;
      Delta_Value : Pixel_Value;
   end record;

   type Encoded_Symbol is record
      Region : Region_Type;
      Code   : Natural;
      Bits   : Natural;
   end record;

   -- Exceptions
   Invalid_Image_Dimensions : exception;
   Decoding_Error           : exception;

   -- Subprograms / Variants / Helpers

   -- Calculates the nearest neighbors (Left and Above) with boundary handling
   procedure Get_Neighbors
     (Image  : in Pixel_Matrix;
      Row    : in Positive;
      Col    : in Positive;
      P1     : out Pixel_Value;
      P2     : out Pixel_Value);

   -- Computes the context delta (Delta = H - L) given two neighbor pixels
   function Compute_Context
     (P1, P2 : in Pixel_Value) return Context_Record;

   -- Encodes a single pixel given its context and actual value
   function Encode_Pixel
     (Pixel   : in Pixel_Value;
      Context : in Context_Record) return Encoded_Symbol;

   -- Decodes a single pixel given its context and encoded symbol
   function Decode_Symbol
     (Sym     : in Encoded_Symbol;
      Context : in Context_Record) return Pixel_Value;

   -- Full Image Lossless Compression Simulation (encodes matrix into a stream of symbols)
   type Encoded_Stream is array (Positive range <>) of Encoded_Symbol;
   
   function Compress_Image
     (Image : in Pixel_Matrix) return Encoded_Stream;

   -- Full Image Lossless Decompression Simulation
   function Decompress_Image
     (Stream : in Encoded_Stream;
      Rows   : in Positive;
      Cols   : in Positive) return Pixel_Matrix;

end Felics;
