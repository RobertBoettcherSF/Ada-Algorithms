pragma Ada_2022;

package Is_Palindrome with SPARK_Mode => On is
   Length : constant := 7;
   subtype Index is Positive range 1 .. Length;
   type Text_Array is array (Index) of Character;

   function Check (Input : Text_Array) return Boolean
     with Global => null;
end Is_Palindrome;
