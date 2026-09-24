pragma Ada_2022;
package Shift_2D_Grid with SPARK_Mode => On is
   Side : constant := 4;
   subtype Index is Positive range 1 .. Side;
   subtype Pixel is Integer range 0 .. 99;
   type Matrix is array (Index, Index) of Pixel;
   procedure Shift (Input : in Matrix; Output : out Matrix);
end Shift_2D_Grid;
