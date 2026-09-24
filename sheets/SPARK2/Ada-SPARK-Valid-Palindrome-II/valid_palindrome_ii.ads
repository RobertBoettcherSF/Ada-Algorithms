pragma Ada_2022;
package Valid_Palindrome_II with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   type Text is array (Index) of Character;
   function Is_Valid (Input : Text) return Boolean with Global => null;
end Valid_Palindrome_II;
