pragma Ada_2022;

package Max_Consecutive_Ones_III with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Bit is Integer range 0 .. 1;
   subtype Result is Natural range 0 .. Length;
   type Input_Array is array (Index) of Bit;
   function Longest (Input : Input_Array) return Result with Global => null;
end Max_Consecutive_Ones_III;
