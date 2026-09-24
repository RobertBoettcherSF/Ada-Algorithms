--  Sukhotin — Ada 2023 educational package for Sukhotin's algorithm
--  (B. V. Sukhotin): unsupervised classification of alphabetic characters
--  as vowels or consonants from co-occurrence structure. Listed on
--  Wikipedia "List of algorithms" / "Outline of natural language
--  processing"; the dedicated Wikipedia page historically redirected.
--  Classic idea: vowels tend to alternate with consonants. Build a
--  symmetric adjacency matrix of consecutive letters, score each letter
--  by row sum, iteratively promote the remaining letter with maximum
--  positive score to vowel, then subtract twice its co-occurrence from
--  every other letter's score. Stop when no remaining score is > 0;
--  leftover letters are consonants.

pragma Ada_2022;

package Sukhotin
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Fixed English-style alphabet: lowercase a .. z.
   Max_Symbols : constant Positive := 26;

   subtype Letter_Index is Natural range 0 .. Max_Symbols - 1;
   --  0 = 'a', 1 = 'b', …, 25 = 'z'.

   subtype Letter_Char is Character range 'a' .. 'z';

   type Count_Value is range 0 .. Integer'Last;
   type Score_Value is range Integer'First .. Integer'Last;

   type Adjacency_Matrix is
     array (Letter_Index, Letter_Index) of Count_Value;

   type Score_Vector is array (Letter_Index) of Score_Value;

   type Bool_Array is array (Letter_Index) of Boolean;

   type Classification is record
      Is_Vowel    : Bool_Array   := [others => False];
      Final_Score : Score_Vector := [others => 0];
      Vowel_Count : Natural      := 0;
   end record;
   --  Is_Vowel (I) is True iff letter Index_To_Char (I) was selected as a
   --  vowel. Final_Score holds residual scores after the last update
   --  (selected vowels keep the score they had when chosen; consonants
   --  end with score ≤ 0).

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Alphabet helpers
   ---------------------------------------------------------------------------

   function Is_Alphabetic (C : Character) return Boolean
     with Global => null;
   --  True for 'A'..'Z' and 'a'..'z'.

   function To_Lower_Letter (C : Character) return Letter_Char
     with Pre => Is_Alphabetic (C),
          Global => null;
   --  Map A–Z / a–z to 'a'..'z'. Raises Invalid_Argument if not alphabetic.

   function Char_To_Index (C : Letter_Char) return Letter_Index
     with Global => null,
          Post => Char_To_Index'Result =
            Character'Pos (C) - Character'Pos ('a');

   function Index_To_Char (I : Letter_Index) return Letter_Char
     with Global => null,
          Post => Index_To_Char'Result =
            Character'Val (Character'Pos ('a') + I);

   ---------------------------------------------------------------------------
   -- Adjacency / co-occurrence
   ---------------------------------------------------------------------------

   function Empty_Adjacency return Adjacency_Matrix
     with Global => null;
   --  All-zero symmetric matrix (diagonal stays zero).

   function Build_Adjacency (Text : String) return Adjacency_Matrix
     with Global => null;
   --  Normalize Text to lowercase a–z only. Within each maximal run of
   --  letters (word-like span; non-letters break adjacency), for every
   --  consecutive pair of distinct letters (X, Y) increment both
   --  A[X,Y] and A[Y,X] by 1 so the matrix stays symmetric. Same-letter
   --  neighbours (e.g. "ll") do not increment the diagonal (kept 0).

   function Is_Symmetric (A : Adjacency_Matrix) return Boolean
     with Global => null;
   --  True iff A(I,J) = A(J,I) for all I, J and diagonal is zero.

   function Adjacency_Get
     (A : Adjacency_Matrix; I, J : Letter_Index) return Count_Value
     with Global => null;

   function Adjacency_Get
     (A : Adjacency_Matrix; X, Y : Letter_Char) return Count_Value
     with Global => null;

   ---------------------------------------------------------------------------
   -- Scores
   ---------------------------------------------------------------------------

   function Initial_Scores (A : Adjacency_Matrix) return Score_Vector
     with Global => null;
   --  S[I] = sum_J A[I,J] (row sums). Classic Sukhotin initial scores.

   function Near
     (Left, Right : Score_Value;
      Tol         : Natural := 0) return Boolean
     with Global => null;
   --  |Left - Right| <= Tol (integer closeness helper).

   ---------------------------------------------------------------------------
   -- Core algorithm
   ---------------------------------------------------------------------------

   function Run_Sukhotin (A : Adjacency_Matrix) return Classification
     with Global => null;
   --  Classic iterative selection:
   --    1. S := Initial_Scores (A); all letters unmarked (consonants).
   --    2. While some unmarked letter has S > 0:
   --         pick unmarked V with maximum S (ties → lowest index);
   --         mark V as vowel;
   --         for each unmarked K ≠ V: S[K] := S[K] - 2 * A[V,K].
   --    3. Unmarked letters are consonants.
   --  Deterministic given A.

   function Classify_Text (Text : String) return Classification
     with Global => null;
   --  Build_Adjacency (Text) then Run_Sukhotin.

   function Is_Vowel
     (C : Classification; Letter : Character) return Boolean
     with Global => null;
   --  True if Letter (case-insensitive) was classified as a vowel.
   --  Non-alphabetic → False. Raises nothing.

   function Is_Consonant
     (C : Classification; Letter : Character) return Boolean
     with Global => null;
   --  True if Letter is alphabetic, appears in the alphabet, and was not
   --  selected as a vowel. (Letters never seen still count as consonants
   --  under the classic "never selected" rule.)

   function Vowel_Set (C : Classification) return String
     with Global => null;
   --  Sorted lowercase string of selected vowels, e.g. "aeiou".

   function Consonant_Set (C : Classification) return String
     with Global => null;
   --  Sorted lowercase string of letters not selected as vowels.

   function Score_Of
     (C : Classification; Letter : Character) return Score_Value
     with Global => null;
   --  Residual / selection-time score for Letter; 0 if non-alphabetic.

   function Score_Vector_Of (C : Classification) return Score_Vector
     with Global => null;
   --  Copy of Final_Score.

   function Vowel_Count (C : Classification) return Natural
     with Global => null,
          Post => Vowel_Count'Result = C.Vowel_Count;

end Sukhotin;
