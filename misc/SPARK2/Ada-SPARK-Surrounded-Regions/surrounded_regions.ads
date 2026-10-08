pragma Ada_2022;
package Surrounded_Regions with SPARK_Mode => On is
   Size : constant := 8;
   subtype Index is Positive range 1 .. Size;
   subtype Cell is Integer range 0 .. 1;
   type Grid is array (Index, Index) of Cell;

   procedure Capture_Interior (G : in out Grid);
end Surrounded_Regions;
