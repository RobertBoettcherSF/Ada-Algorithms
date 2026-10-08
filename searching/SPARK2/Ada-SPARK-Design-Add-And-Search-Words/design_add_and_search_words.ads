pragma Ada_2022;

package Design_Add_And_Search_Words with SPARK_Mode => On is
   pragma Assertion_Policy (Pre => Check);
   Max_Words : constant := 8;
   Max_Length : constant := 8;
   subtype Length_Range is Natural range 0 .. Max_Length;
   subtype Position is Positive range 1 .. Max_Length;
   subtype Word_Index is Positive range 1 .. Max_Words;
   subtype Word_Count is Natural range 0 .. Max_Words;
   subtype Pattern_Char is Character range '.' .. 'd';
   type Word_Chars is array (Position) of Pattern_Char;
   type Word is record
      Len : Length_Range := 0;
      Chars : Word_Chars := [others => 'a'];
   end record;
   type Word_Array is array (Word_Index) of Word;
   type Dictionary is record
      Used : Word_Count := 0;
      Words : Word_Array := [others => (Len => 0, Chars => [others => 'a'])];
   end record;
   --  Every call stores W in the next free slot (duplicates included).
   procedure Add_Word (D : in out Dictionary; W : in Word)
     with Pre => D.Used < Max_Words;
   function Search (D : Dictionary; Pattern : Word) return Boolean with Global => null;
end Design_Add_And_Search_Words;
