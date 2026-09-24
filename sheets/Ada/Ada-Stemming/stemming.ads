--  Stemming — Ada 2023 educational package for Wikipedia "Stemming"
--  (linguistic morphology / information retrieval). Primary algorithm:
--  Martin Porter's English suffix-stripping stemmer (Program 14(3), 1980).
--  Secondary helper: a tiny length-guarded suffix stripper for comparison.
--  Stems need not be real words (e.g. argue → argu). Related history:
--  Lovins 1968; Paice–Husk; Snowball / Porter2 (not implemented here).

pragma Ada_2022;

package Stemming
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity
   ---------------------------------------------------------------------------

   --  Educational bound on working word length (Porter vocabularies are short).
   Max_Word_Length : constant Positive := 256;

   subtype Word_Length is Natural range 0 .. Max_Word_Length;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised if a working buffer would exceed Max_Word_Length.

   ---------------------------------------------------------------------------
   -- Character / measure helpers (Porter definitions)
   ---------------------------------------------------------------------------

   function To_Lower (C : Character) return Character
     with Global => null;
   --  Map A–Z to a–z; leave other characters unchanged.

   function To_Lower (S : String) return String
     with Global => null;
   --  Apply To_Lower to every character. Result length = S'Length.
   --  Raises Invalid_Argument if S'Length > Max_Word_Length.

   function Is_Vowel (C : Character) return Boolean
     with Global => null;
   --  True for a/e/i/o/u (case-insensitive). Y is *not* a vowel here;
   --  Porter treats Y contextually via Is_Consonant_At.

   function Is_Consonant_At (Word : String; Index : Positive) return Boolean
     with Pre => Index in Word'Range,
          Global => null;
   --  Porter consonant test at Index (1-based within Word'Range).
   --  A consonant is any letter other than A,E,I,O,U, and other than Y
   --  preceded by a consonant. Non-letters are treated as consonants.

   function Contains_Vowel (Stem : String) return Boolean
     with Global => null;
   --  True iff some letter in Stem is a Porter vowel (not-consonant).

   function Measure_M (Stem : String) return Natural
     with Global => null;
   --  Porter measure m of Stem: [C](VC)^m[V]. Counts VC groups after an
   --  optional leading consonant run. Examples: tree→0, trouble→1,
   --  troubles→2.

   function Ends_Double_Consonant (Stem : String) return Boolean
     with Global => null;
   --  *d : stem ends with two identical consonants.

   function Ends_CVC (Stem : String) return Boolean
     with Global => null;
   --  *o : stem ends consonant–vowel–consonant where the final consonant
   --  is not W, X, or Y.

   ---------------------------------------------------------------------------
   -- Stemmers
   ---------------------------------------------------------------------------

   function Porter_Stem (Word : String) return String
     with Global => null;
   --  Classic Porter English stemmer, steps 1a–5b, on a lowercased copy.
   --  Non-letter characters are preserved but rules assume English letters.
   --  Empty / very short inputs are returned lowercased unchanged.
   --  Raises Invalid_Argument if Word'Length > Max_Word_Length.

   function Simple_Stem (Word : String) return String
     with Global => null;
   --  Tiny educational suffix stripper: try -ing, -ed, -ly, -es, -s (longest
   --  first) with a minimum remaining length of 3. Lowercases first.
   --  Raises Invalid_Argument if Word'Length > Max_Word_Length.

   function Suffix_Strip (Word : String) return String
     with Global => null;
   --  Alias of Simple_Stem.

   function Stem_Word (Word : String) return String
     with Global => null;
   --  Alias of Porter_Stem (primary algorithm).

end Stemming;
