pragma Ada_2022;
package Flipping_An_Image with SPARK_Mode => On is
   Side : constant := 4;
   subtype Index is Positive range 1 .. Side;
   subtype Bit is Integer range 0 .. 1;
   type Image is array (Index, Index) of Bit;
   procedure Flip_And_Invert (Picture : in out Image);
end Flipping_An_Image;
