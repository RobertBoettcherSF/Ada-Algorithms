pragma Ada_2022;

package Permutation_In_String with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   type Text_Array is array (Index) of Character;
   function Contains_Permutation (Input : Text_Array) return Boolean with Global => null;
end Permutation_In_String;
