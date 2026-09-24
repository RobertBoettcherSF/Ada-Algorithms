pragma Ada_2022;

package Stream_Of_Characters_Lite with SPARK_Mode => On is
   Max_Length : constant := 4;
   subtype Length_Range is Natural range 0 .. Max_Length;
   subtype Position is Positive range 1 .. Max_Length;
   subtype Word_Index is Positive range 1 .. 4;
   subtype Letter is Character range 'a' .. 'd';
   type Word_Chars is array (Position) of Letter;
   type Word is record
      Len : Length_Range := 0;
      Chars : Word_Chars := (others => 'a');
   end record;
   type Word_Array is array (Word_Index) of Word;
   type Stream is record
      Used : Length_Range := 0;
      Chars : Word_Chars := (others => 'a');
   end record;
   procedure Push (S : in out Stream; C : in Letter);
   function Matches_Suffix (S : Stream; W : Word) return Boolean with Global => null;
   function Query (S : Stream; Words : Word_Array) return Boolean with Global => null;
end Stream_Of_Characters_Lite;
