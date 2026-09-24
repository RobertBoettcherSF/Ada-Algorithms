-- fractal_compression.ads
-- Specification for Fractal Compression algorithm and its variants.
with Ada.Containers.Vectors;

package Fractal_Compression is

   -- Strong typing for algorithm-specific data
   type Pixel is digits 5 range 0.0 .. 255.0;
   type Pixel_Grid is array (Positive range <>, Positive range <>) of Pixel;
   
   type Coordinate is record
      X : Positive;
      Y : Positive;
   end record;
   
   -- Supported partitioning variants mentioned in literature/Wikipedia
   type Partition_Variant is (
      Square_Fixed,   -- Standard fixed block size
      Quadtree,       -- Dynamic block sizing based on variance
      Rectangular,    -- R-b-T variant (Placeholder - requires non-square topology)
      Hexagonal,      -- (Placeholder - requires hex coordinate mapping)
      Triangular      -- (Placeholder - requires barycentric coordinate mapping)
   );

   -- 8 Standard Affine Geometric Transformations (Symmetries)
   type Symmetry_Type is (
      Identity, Rot_90, Rot_180, Rot_270,
      Flip_Horizontal, Flip_Vertical,
      Diag_Main, Diag_Anti
   );

   -- Mathematical transformation mapping a Domain block to a Range block
   type Affine_Transform is record
      Range_X      : Positive;
      Range_Y      : Positive;
      Block_Size   : Positive;
      Domain_X     : Positive;
      Domain_Y     : Positive;
      Symmetry     : Symmetry_Type;
      Contrast     : Float; -- Contractivity factor (s)
      Brightness   : Float; -- Offset (o)
   end record;

   package Transform_Vectors is new Ada.Containers.Vectors (
      Index_Type   => Positive,
      Element_Type => Affine_Transform
   );

   type Fractal_Code is new Transform_Vectors.Vector with null record;

   -- Exceptions
   Invalid_Image_Dimensions : exception;
   Invalid_Block_Size       : exception;
   Unsupported_Variant      : exception;

   -- Core Subprograms
   
   -- Encodes an image using a specific partition variant (Removed default values to satisfy GNAT conformance)
   function Encode (
      Image       : Pixel_Grid;
      Variant     : Partition_Variant;
      Range_Size  : Positive
   ) return Fractal_Code;

   -- Decodes a fractal code back into an image iteratively (Removed default values to satisfy GNAT conformance)
   function Decode (
      Code       : Fractal_Code;
      Width      : Positive;
      Height     : Positive;
      Iterations : Positive
   ) return Pixel_Grid;

   -- Helper Functions exposed for testing (V&V)
   function Apply_Symmetry (X, Y, Size : Positive; Sym : Symmetry_Type) return Coordinate;
   function Downsample (Domain : Pixel_Grid) return Pixel_Grid;
   procedure Least_Squares (Domain, Range_Block : Pixel_Grid; S, O : out Float);

end Fractal_Compression;
