with Ada.Containers.Vectors;
with Ada.Containers.Doubly_Linked_Lists;

package SPIHT is
   -- Strong typing for coefficients and coordinates
   type Coefficient is new Integer;
   
   type Coordinate_2D is record
      R, C : Positive;
   end record;
   
   type Coordinate_3D is record
      R, C, D : Positive;
   end record;

   -- 2D and 3D Image Matrices
   type Matrix_2D is array (Positive range <>, Positive range <>) of Coefficient;
   type Matrix_3D is array (Positive range <>, Positive range <>, Positive range <>) of Coefficient;

   -- Bit representation for the output stream
   type Bit is new Integer range 0 .. 1;
   package Bit_Vectors is new Ada.Containers.Vectors (Index_Type => Positive, Element_Type => Bit);
   subtype Bit_Stream is Bit_Vectors.Vector;

   -- Set types used in LIS (List of Insignificant Sets)
   type Set_Type is (Type_A, Type_B);
   
   type LIS_Node_2D is record
      Coord : Coordinate_2D;
      Set   : Set_Type;
   end record;

   type LIS_Node_3D is record
      Coord : Coordinate_3D;
      Set   : Set_Type;
   end record;

   -- Target constraints for encoding variants (Lossless vs Rate-Constrained Lossy)
   type Encoding_Variant is (Lossless, Lossy_Target_Bits);

   -- Exceptions for edge cases
   Invalid_Size_Error : exception;
   Empty_Input_Error  : exception;

   -- =========================================================================
   -- 2D SPIHT Variant
   -- =========================================================================
   procedure Encode_2D 
     (Image       : in Matrix_2D; 
      Target_Bits : in Natural; 
      Variant     : in Encoding_Variant;
      Stream      : out Bit_Stream);

   -- Helper functions exposed for unit testing
   function Max_Magnitude_2D (Image : Matrix_2D) return Natural;
   function Max_Magnitude_3D (Volume : Matrix_3D) return Natural;
   function Is_Power_Of_Two (N : Positive) return Boolean;

   -- =========================================================================
   -- 3D SPIHT Variant (For Volumetric Data / Video as mentioned on Wikipedia)
   -- =========================================================================
   procedure Encode_3D 
     (Volume      : in Matrix_3D; 
      Target_Bits : in Natural; 
      Variant     : in Encoding_Variant;
      Stream      : out Bit_Stream);

end SPIHT;
