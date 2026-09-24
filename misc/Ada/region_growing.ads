with Ada.Containers.Doubly_Linked_Lists;

package Region_Growing is

   -- Strong typing for algorithm-specific data
   type Pixel_Value is new Integer;
   type Image is array (Positive range <>, Positive range <>) of Pixel_Value;
   type Mask is array (Positive range <>, Positive range <>) of Boolean;
   type Region_Map is array (Positive range <>, Positive range <>) of Natural;

   type Point is record
      X : Positive;
      Y : Positive;
   end record;

   type Point_Array is array (Positive range <>) of Point;

   type Connectivity_Type is (Four_Connected, Eight_Connected);

   -- Exceptions for error handling
   Invalid_Seed_Error : exception;

   -- Variant 1: Seeded Region Growing (Local Threshold)
   -- Grows a region by checking if a neighbor's pixel value is within Threshold 
   -- of the adjacent already-accepted pixel value.
   function Seeded_Local (
      Input_Image  : Image;
      Seeds        : Point_Array;
      Threshold    : Natural;
      Connectivity : Connectivity_Type := Four_Connected
   ) return Mask;

   -- Variant 2: Seeded Region Growing (Average Threshold)
   -- Grows a region by comparing a neighbor's pixel value to the running average
   -- of the entire region grown so far.
   function Seeded_Average (
      Input_Image  : Image;
      Seeds        : Point_Array;
      Threshold    : Natural;
      Connectivity : Connectivity_Type := Four_Connected
   ) return Mask;

   -- Variant 3: Unseeded Region Growing
   -- Automatically iterates over the entire image, treating unassigned pixels as
   -- new seeds. Segments the whole image into distinct regions.
   function Unseeded (
      Input_Image  : Image;
      Threshold    : Natural;
      Connectivity : Connectivity_Type := Four_Connected
   ) return Region_Map;

end Region_Growing;
