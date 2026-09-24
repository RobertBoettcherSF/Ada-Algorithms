pragma Ada_2022;
package Count_Sub_Islands with SPARK_Mode => On is
   Size : constant := 8;
   subtype Index is Positive range 1 .. Size;
   subtype Cell is Integer range 0 .. 1;
   type Grid is array (Index, Index) of Cell;
   type Count is mod 65;

   function Count_Sub (Base : Grid; Candidate : Grid) return Count
     with Global => null;
end Count_Sub_Islands;
