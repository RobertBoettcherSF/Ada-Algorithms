pragma Ada_2022;
package Image_Smoother with SPARK_Mode => On is
   Side : constant := 4;
   subtype Index is Positive range 1 .. Side;
   subtype Pixel is Integer range 0 .. 99;
   type Image is array (Index, Index) of Pixel;
   procedure Smooth (Input : in Image; Output : out Image);
end Image_Smoother;
