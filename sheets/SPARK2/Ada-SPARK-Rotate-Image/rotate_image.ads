pragma Ada_2022;

package Rotate_Image with SPARK_Mode => On is
   Side : constant := 3;
   subtype Index is Positive range 1 .. Side;
   subtype Pixel is Integer range 0 .. 99;
   type Image is array (Index, Index) of Pixel;

   procedure Rotate (Input : in out Image);
end Rotate_Image;
