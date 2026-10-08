pragma Ada_2022;

package Sort_Characters_By_Frequency with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   type Char_Array is array (Index) of Character;

   function Hit (A : Char_Array; I : Index; C : Character) return Natural is (if A (I) = C then 1 else 0);
   --  occurrences of C in A, written out for the 8 positions (no loop, no recursion)
   function Frequency (A : Char_Array; C : Character) return Natural is
     (Hit (A, 1, C) + Hit (A, 2, C) + Hit (A, 3, C) + Hit (A, 4, C)
      + Hit (A, 5, C) + Hit (A, 6, C) + Hit (A, 7, C) + Hit (A, 8, C));

   --  sort key: higher frequency in Input first, ties by character code, so equal characters end up
   --  next to each other
   function Rank (Input : Char_Array; C : Character) return Natural is
     ((8 - Frequency (Input, C)) * 256 + Character'Pos (C))
     with Pre => Frequency (Input, C) <= 8;

   --  The characters of Input by decreasing frequency, equal characters grouped (ties: character order).
   function Sort_By_Frequency (Input : Char_Array) return Char_Array
     with Global => null,
          Post   => (for all I in 1 .. 7 =>
                       Rank (Input, Sort_By_Frequency'Result (I)) <= Rank (Input, Sort_By_Frequency'Result (I + 1)));
end Sort_Characters_By_Frequency;
