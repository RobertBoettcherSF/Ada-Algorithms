pragma Ada_2022;

package Majority_Element with SPARK_Mode => On is
   Length : constant := 7;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -10 .. 10;
   type Input_Array is array (Index) of Value;

   function Find (Input : Input_Array) return Value
     with Global => null;
end Majority_Element;
