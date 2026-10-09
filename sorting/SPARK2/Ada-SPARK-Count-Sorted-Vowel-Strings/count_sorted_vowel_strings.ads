pragma Ada_2022;
--  Scaffold for the failing test: the new API, still answering from the
--  old table (n <= 16, From ignored).
package Count_Sorted_Vowel_Strings with SPARK_Mode => On is
   type Vowel is (A, E, I, O, U);
   subtype Length is Natural range 0 .. 473;
   function Number_Of_Strings (N : Length; From : Vowel := A) return Natural with Global => null;
end Count_Sorted_Vowel_Strings;
