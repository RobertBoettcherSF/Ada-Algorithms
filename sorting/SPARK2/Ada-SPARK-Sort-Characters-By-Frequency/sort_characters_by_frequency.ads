pragma Ada_2022;

package Sort_Characters_By_Frequency with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   type Char_Array is array (Index) of Character;

   function Sort_By_Frequency (Input : Char_Array) return Char_Array
     with Global => null;
end Sort_Characters_By_Frequency;
