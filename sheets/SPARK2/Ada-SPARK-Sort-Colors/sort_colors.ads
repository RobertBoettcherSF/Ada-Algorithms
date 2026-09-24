pragma SPARK_Mode (On);

package Sort_Colors is
   subtype Index is Positive range 1 .. 32;
   subtype Length_Type is Natural range 0 .. 32;
   subtype Color is Natural range 0 .. 2;
   type Colors is array (Index) of Color;

   procedure Sort (Data : in out Colors; Length : Length_Type)
     with Global => null;
end Sort_Colors;
