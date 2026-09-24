pragma Ada_2022;
package Path_With_Minimum_Effort with SPARK_Mode => On is
   Side : constant := 4;
   Cells : constant := Side * Side;
   subtype Cell is Positive range 1 .. Cells;
   subtype Height is Natural range 0 .. 100;
   subtype Effort is Natural range 0 .. 100;
   type Height_Array is array (Cell) of Height;
   procedure Compute (Heights : in Height_Array; Result : out Effort);
end Path_With_Minimum_Effort;
