pragma SPARK_Mode (On);

package Trapping_Rain_Water_II_Lite is
   subtype Index is Positive range 1 .. 32;
   subtype Length_Type is Natural range 0 .. 32;
   subtype Height is Natural range 0 .. 1_000;
   type Heights is array (Index) of Height;

   function Trapped (Data : Heights; Length : Length_Type) return Natural
     with Global => null;
end Trapping_Rain_Water_II_Lite;
