pragma Ada_2022;

package Roman_To_Int with SPARK_Mode => On is
   Length : constant := 7;
   subtype Index is Positive range 1 .. Length;
   type Roman_Text is array (Index) of Character;

   function To_Integer (Input : Roman_Text) return Integer
     with Global => null;
end Roman_To_Int;
