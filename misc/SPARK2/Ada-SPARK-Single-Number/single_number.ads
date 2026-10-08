pragma Ada_2022;

package Single_Number with SPARK_Mode => On is
   Length : constant := 5;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -20 .. 20;
   type Input_Array is array (Index) of Value;

   function Find (Input : Input_Array) return Value
     with Global => null;
end Single_Number;
