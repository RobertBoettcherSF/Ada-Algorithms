pragma Ada_2022;

package Write_String_Lines with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Text is array (Index) of Character;

   subtype Width_Type is Natural range 0 .. 100;
   type Width_Table is array (Character range 'a' .. 'z') of Width_Type;
   subtype Line_Count_Type is Positive range 1 .. 32;

   procedure Lines_For
     (Widths      : Width_Table;
      Input       : Text;
      Length      : Length_Type;
      Lines       : out Line_Count_Type;
      Last_Width  : out Width_Type)
     with Global => null;
end Write_String_Lines;
