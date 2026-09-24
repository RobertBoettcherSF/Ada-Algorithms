pragma Ada_2022;

package Valid_Word_Abbreviation with SPARK_Mode => On is
   Word_Length : constant := 6;
   Abbreviation_Length : constant := 5;
   subtype Word_Index is Positive range 1 .. Word_Length;
   subtype Abbreviation_Index is Positive range 1 .. Abbreviation_Length;
   type Text_Array is array (Word_Index) of Character;
   type Abbreviation_Array is array (Abbreviation_Index) of Character;

   function Is_Valid
     (Word : Text_Array; Abbreviation : Abbreviation_Array) return Boolean
     with Global => null;
end Valid_Word_Abbreviation;
