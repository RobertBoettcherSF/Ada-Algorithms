--  seam_carving.ads
--  Specification for the Seam Carving algorithm.
--  Implements variants: Backward Energy, Forward Energy, Horizontal/Vertical Seams, Removal/Insertion.

package Seam_Carving is

   --  Basic Pixel definition using integers to prevent overflow during calculations
   type Pixel is record
      R, G, B : Integer;
   end record;

   --  2D array representing an Image. First index is X (Width), second is Y (Height).
   type Image is array (Positive range <>, Positive range <>) of Pixel;

   --  A seam is a list of coordinates. 
   --  For Vertical seams: index is Y, value is X.
   --  For Horizontal seams: index is X, value is Y.
   type Seam is array (Positive range <>) of Positive;

   --  Algorithm variants mentioned in Wikipedia
   type Energy_Function_Type is (Backward_Energy, Forward_Energy);
   type Seam_Direction is (Vertical, Horizontal);

   --  Exceptions
   Image_Too_Small : exception;

   --  Finds the optimal seam with minimum energy cost.
   function Find_Seam (Img : Image; 
                       Dir : Seam_Direction; 
                       Energy_Type : Energy_Function_Type) return Seam;

   --  Removes a given seam from the image, reducing dimension by 1.
   function Remove_Seam (Img : Image; 
                         S : Seam; 
                         Dir : Seam_Direction) return Image;

   --  Inserts a seam (by averaging with neighbors), increasing dimension by 1.
   function Insert_Seam (Img : Image; 
                         S : Seam; 
                         Dir : Seam_Direction) return Image;

end Seam_Carving;
