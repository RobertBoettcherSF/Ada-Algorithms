pragma SPARK_Mode (On);

package Three_Sum_Closest is
   subtype Index is Positive range 1 .. 32;
   subtype Length_Type is Natural range 0 .. 32;
   subtype Value is Integer range -1_000 .. 1_000;
   subtype Sum_Value is Integer range -3_000 .. 3_000;
   subtype Target_Value is Integer range -3_000 .. 3_000;
   type Values is array (Index) of Value;

   function Closest (Data : Values; Length : Length_Type; Target : Target_Value)
     return Sum_Value with Global => null;
end Three_Sum_Closest;
