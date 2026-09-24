pragma Ada_2022;
package Word_Search with SPARK_Mode => On is
   Size : constant := 8;
   subtype Index is Positive range 1 .. Size;
   subtype Used_Length is Natural range 0 .. Size;
   type Board is array (Index, Index) of Character;
   type Word is array (Index) of Character;

   function Exists (B : Board; W : Word; Used : Used_Length) return Boolean
     with Global => null;
end Word_Search;
