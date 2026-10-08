pragma Ada_2022;

package Top_K_Frequent_Stub with SPARK_Mode => On is
   Length : constant := 8;
   Result_Length : constant := 3;
   subtype Index is Positive range 1 .. Length;
   subtype Result_Index is Positive range 1 .. Result_Length;
   subtype Value is Integer range -10 .. 10;
   type Input_Array is array (Index) of Value;
   type Result_Array is array (Result_Index) of Value;
   function Top_K (Input : Input_Array; K : Result_Index) return Result_Array with Global => null;
end Top_K_Frequent_Stub;
