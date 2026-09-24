pragma Ada_2022;

package Word_Search_II_Lite with SPARK_Mode => On is
   Board_Size : constant := 4;
   subtype Row is Positive range 1 .. Board_Size;
   subtype Column is Positive range 1 .. Board_Size;
   subtype Letter is Character range 'a' .. 'd';
   type Board is array (Row, Column) of Letter;
   type Pattern is array (Positive range 1 .. 3) of Letter;
   type Pattern_List is array (Positive range 1 .. 3) of Pattern;
   function Appears_Horizontally (B : Board; W : Pattern) return Boolean with Global => null;
   function Count_Found (B : Board; Words : Pattern_List) return Natural with Global => null;
end Word_Search_II_Lite;
