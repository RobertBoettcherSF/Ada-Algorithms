pragma Ada_2022;

package Search_Insert_Position with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 100;
   subtype Insertion_Index is Positive range 1 .. Length + 1;
   type Sorted_Array is array (Index) of Value;

   function Position (Data : Sorted_Array; Target : Value) return Insertion_Index
     with Global => null;
end Search_Insert_Position;
