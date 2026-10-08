pragma Ada_2022;

package Valid_Anagram with SPARK_Mode => On is
   Length : constant := 6;
   subtype Index is Positive range 1 .. Length;
   subtype Letter is Character range 'a' .. 'f';
   type Text_Array is array (Index) of Letter;

   function Is_Anagram (Left : Text_Array; Right : Text_Array) return Boolean
     with Global => null;
end Valid_Anagram;
