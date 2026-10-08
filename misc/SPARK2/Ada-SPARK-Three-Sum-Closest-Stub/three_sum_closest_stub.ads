pragma Ada_2022;

package Three_Sum_Closest_Stub with SPARK_Mode => On is
   Length : constant := 5;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -5 .. 5;
   subtype Sum_Value is Integer range -15 .. 15;
   subtype Target_Value is Integer range -15 .. 15;
   type Input_Array is array (Index) of Value;

   function Closest (Input : Input_Array; Target : Target_Value) return Sum_Value
     with Global => null;
end Three_Sum_Closest_Stub;
