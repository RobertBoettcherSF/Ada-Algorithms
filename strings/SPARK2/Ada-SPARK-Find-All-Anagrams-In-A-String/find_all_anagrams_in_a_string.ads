pragma Ada_2022;

package Find_All_Anagrams_In_A_String with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Count is Natural range 0 .. 7;
   type Text_Array is array (Index) of Character;
   function Count_Anagrams (Input : Text_Array) return Count with Global => null;
end Find_All_Anagrams_In_A_String;
