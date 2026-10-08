pragma SPARK_Mode (On);

package Three_Sum_Closest is
   subtype Index is Positive range 1 .. 32;
   subtype Length_Type is Natural range 0 .. 32;
   --  a triple needs at least three values
   subtype Triple_Length is Length_Type range 3 .. Length_Type'Last;
   subtype Value is Integer range -1_000 .. 1_000;
   subtype Sum_Value is Integer range -3_000 .. 3_000;
   subtype Target_Value is Integer range -3_000 .. 3_000;
   type Values is array (Index) of Value;

   function Closest (Data : Values; Length : Triple_Length; Target : Target_Value)
     return Sum_Value with Global => null;
end Three_Sum_Closest;
