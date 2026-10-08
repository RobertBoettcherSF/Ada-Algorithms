pragma SPARK_Mode (On);

package Four_Sum_II is
   subtype Index is Positive range 1 .. 8;
   subtype Length_Type is Natural range 0 .. 8;
   subtype Value is Integer range -1_000 .. 1_000;
   subtype Target is Integer range -4_000 .. 4_000;
   type Values is array (Index) of Value;

   function Has_Four_Sum (Data : Values; Length : Length_Type; Goal : Target)
     return Boolean with Global => null;
end Four_Sum_II;
