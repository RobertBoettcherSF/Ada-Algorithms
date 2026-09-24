pragma Ada_2022;

package Find_K_Closest with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -100 .. 100;
   type Input_Array is array (Index) of Value;

   function Closest_Index (Input : Input_Array; Target : Value) return Index
     with Global => null;
end Find_K_Closest;
