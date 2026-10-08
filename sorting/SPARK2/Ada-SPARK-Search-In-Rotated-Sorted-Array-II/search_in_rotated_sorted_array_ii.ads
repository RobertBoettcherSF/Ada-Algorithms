pragma Ada_2022;

package Search_In_Rotated_Sorted_Array_II with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 100;
   type Data_Array is array (Index) of Value;

   function Contains (Data : Data_Array; Target : Value) return Boolean
     with Global => null;
end Search_In_Rotated_Sorted_Array_II;
