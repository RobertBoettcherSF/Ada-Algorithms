pragma SPARK_Mode (On);

package Three_Sum is
   subtype Index is Positive range 1 .. 32;
   subtype Length_Type is Natural range 0 .. 32;
   subtype Value is Integer range -1_000 .. 1_000;
   subtype Target is Integer range -3_000 .. 3_000;
   type Values is array (Index) of Value;

   function Has_Triple_Sum (Data : Values; Length : Length_Type; Goal : Target)
     return Boolean
     with Global => null;
end Three_Sum;
