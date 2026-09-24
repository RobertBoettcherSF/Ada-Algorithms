pragma SPARK_Mode (On);

package Trapping_Rain_Water is
   subtype Index is Positive range 1 .. 32;
   subtype Length_Type is Natural range 0 .. 32;
   subtype Height is Natural range 0 .. 1_000;
   subtype Water is Natural range 0 .. 32_000;
   type Heights is array (Index) of Height;

   function Trapped (Data : Heights; Length : Length_Type) return Water
     with Global => null;
end Trapping_Rain_Water;
