pragma Ada_2022;

package Reverse_Vowels_Of_A_String with SPARK_Mode => On is
   Length : constant := 6;
   subtype Index is Positive range 1 .. Length;
   type Text_Array is array (Index) of Character;

   function Is_Vowel (Value : Character) return Boolean
     with Global => null;

   function Reverse_Vowels (Input : Text_Array) return Text_Array
     with Pre =>
       Is_Vowel (Input (2)) and then Is_Vowel (Input (5))
       and then not Is_Vowel (Input (1))
       and then not Is_Vowel (Input (3))
       and then not Is_Vowel (Input (4))
       and then not Is_Vowel (Input (6)),
          Global => null;
end Reverse_Vowels_Of_A_String;
