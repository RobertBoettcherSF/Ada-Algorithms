pragma Ada_2022;

package Move_Zeroes with SPARK_Mode => On is
   Length : constant := 5;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 20;
   subtype Position is Positive range 1 .. Length + 1;
   type Input_Array is array (Index) of Value;

   function Move (Input : Input_Array) return Input_Array
     with Global => null;
end Move_Zeroes;
