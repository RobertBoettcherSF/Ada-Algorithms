pragma Ada_2022;

package Word_Break with SPARK_Mode => On is
   Word_Length : constant := 8;
   subtype Index is Positive range 1 .. Word_Length;
   type Word is array (Index) of Character;

   function Is_Breakable (Input : Word) return Boolean
     with Global => null;
end Word_Break;
