pragma SPARK_Mode (On);

package Container_With_Most_Water is
   subtype Index is Positive range 1 .. 32;
   subtype Length_Type is Natural range 0 .. 32;
   subtype Height is Natural range 0 .. 1_000;
   subtype Area is Natural range 0 .. 31_000;
   type Heights is array (Index) of Height;

   function Max_Area (Data : Heights; Length : Length_Type) return Area
     with Global => null;
end Container_With_Most_Water;
