pragma Ada_2022;

package Map_Sum_Pairs with SPARK_Mode => On is
   Max_Length : constant := 8;
   subtype Length_Range is Natural range 0 .. Max_Length;
   subtype Position is Positive range 1 .. Max_Length;
   subtype Word_Index is Positive range 1 .. 8;
   subtype Letter is Character range 'a' .. 'd';
   type Word_Chars is array (Position) of Letter;
   type Word is record
      Len : Length_Range := 0;
      Chars : Word_Chars := (others => 'a');
   end record;
   type Word_Array is array (Word_Index) of Word;
   subtype Map_Index is Positive range 1 .. 8;
   type Map_Entry is record
      Key : Word;
      Value : Integer range -100 .. 100 := 0;
   end record;
   type Map is array (Map_Index) of Map_Entry;
   function Sum (M : Map; Prefix : Word) return Integer with Global => null;
end Map_Sum_Pairs;
