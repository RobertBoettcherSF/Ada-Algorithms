pragma Ada_2022;

package Delete_Operation_For_Two_Strings with SPARK_Mode => On is
   Max_Length : constant := 16;
   subtype Length is Natural range 0 .. Max_Length;
   subtype Index is Positive range 1 .. Max_Length;
   type Text is array (Index) of Character;

   function Min_Deletions
     (Left, Right : Text; NL, NR : Length) return Integer
     with Global => null;
end Delete_Operation_For_Two_Strings;
