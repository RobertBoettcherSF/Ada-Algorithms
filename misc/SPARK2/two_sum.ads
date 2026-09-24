pragma Ada_2022;

package Two_Sum with SPARK_Mode => On is
   Length : constant := 6;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -10 .. 10;
   subtype Target_Value is Integer range -20 .. 20;
   type Input_Array is array (Index) of Value;

   function Has_Pair (Input : Input_Array; Target : Target_Value) return Boolean
     with Global => null;
end Two_Sum;
