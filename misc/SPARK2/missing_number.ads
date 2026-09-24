pragma Ada_2022;

package Missing_Number with SPARK_Mode => On is
   Length : constant := 5;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 5;
   subtype Missing_Value is Integer range -10 .. 15;
   type Input_Array is array (Index) of Value;

   function Find (Input : Input_Array) return Missing_Value
     with Global => null;
end Missing_Number;
