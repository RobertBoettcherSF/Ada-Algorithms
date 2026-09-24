pragma Ada_2022;

package Peak_Index_In_Mountain_Array with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -1000 .. 1000;
   type Mountain_Array is array (Index) of Value;

   function Peak_Index (Input : Mountain_Array) return Index
     with Global => null;
end Peak_Index_In_Mountain_Array;
