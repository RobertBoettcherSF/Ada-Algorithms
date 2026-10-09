pragma SPARK_Mode (On);

--  Letter combinations of a phone number on the standard keypad:
--  2 = abc, 3 = def, 4 = ghi, 5 = jkl, 6 = mno, 7 = pqrs, 8 = tuv, 9 = wxyz.
--  Count (Number) is the number of letter strings the digits spell, and
--  Combination (Number, K) is the K-th of them (K from 0) in dictionary
--  order, built by mixed-radix decoding of K.
--
--  Why at most 15 digits: a digit has at most 4 letters, so a count is at
--  most 4 ** 15 = 2 ** 30 <= Natural'Last; sixteen digits 7 or 9 spell
--  4 ** 16 = 2 ** 32 strings, which does not fit.
package Letter_Combinations_Of_A_Phone_Number is
   Max_Digits : constant := 15;

   subtype Phone_Digit is Character range '2' .. '9';

   subtype Digit_String is String
   with Dynamic_Predicate =>
     Digit_String'First = 1
     and then Digit_String'Last in 0 .. Max_Digits
     and then (for all C of Digit_String => C in Phone_Digit);

   subtype Letter_Count is Positive range 3 .. 4;

   --  The keypad.
   function Letters (D : Phone_Digit) return Letter_Count is
     (if D = '7' or else D = '9' then 4 else 3);

   function First_Letter (D : Phone_Digit) return Character is
     (case D is
        when '2' => 'a', when '3' => 'd', when '4' => 'g', when '5' => 'j',
        when '6' => 'm', when '7' => 'p', when '8' => 't', when '9' => 'w');

   --  Letter J (from 0) of digit D.
   function Letter (D : Phone_Digit; J : Natural) return Character is
     (Character'Val (Character'Pos (First_Letter (D)) + J))
   with Pre => J < Letters (D);

   --  Ghost proof aid for the overflow bound: 4 ** N, N <= 15. The proof
   --  checks every entry against the recurrence (Post of Pow4); the tests
   --  regenerate it. The code does not use it.
   function Pow4_Table (N : Natural) return Long_Long_Integer is
     (case N is
        when 0 => 1, when 1 => 4, when 2 => 16, when 3 => 64, when 4 => 256,
        when 5 => 1_024, when 6 => 4_096, when 7 => 16_384, when 8 => 65_536,
        when 9 => 262_144, when 10 => 1_048_576, when 11 => 4_194_304,
        when 12 => 16_777_216, when 13 => 67_108_864, when 14 => 268_435_456,
        when 15 => 1_073_741_824, when others => 0)
   with Ghost;

   function Pow4 (N : Natural) return Long_Long_Integer
   with
     Ghost,
     Pre                => N <= Max_Digits,
     Post               => Pow4'Result = Pow4_Table (N) and then Pow4'Result in 1 .. 2 ** 30,
     Subprogram_Variant => (Decreases => N);

   --  The number of letter strings spelt by Number (I .. Number'Last).
   function Suffix_Count (Number : Digit_String; I : Positive) return Long_Long_Integer
   with
     Ghost,
     Pre                => I <= Number'Last + 1,
     Post               => Suffix_Count'Result in 1 .. Pow4 (Number'Last + 1 - I),
     Subprogram_Variant => (Increases => I);

   --  R (I .. Number'Last) spells Number (I .. Number'Last).
   function Spells_From (Number : Digit_String; R : String; I : Positive) return Boolean is
     (R'First = 1 and then R'Last = Number'Last
      and then (for all P in I .. Number'Last =>
                  R (P) in First_Letter (Number (P)) .. Letter (Number (P), Letters (Number (P)) - 1)))
   with Ghost;

   --  The dictionary-order rank of R (I .. Number'Last) among the strings
   --  spelt by Number (I .. Number'Last): letter P counts
   --  (its index on the key) * (number of strings spelt by the digits after P).
   function Rank (Number : Digit_String; R : String; I : Positive) return Long_Long_Integer
   with
     Ghost,
     Pre                => I <= Number'Last + 1 and then Spells_From (Number, R, I),
     Post               => Rank'Result in 0 .. Suffix_Count (Number, I) - 1,
     Subprogram_Variant => (Increases => I);

   function Count (Number : Digit_String) return Positive
   with
     Global => null,
     Post   => Long_Long_Integer (Count'Result) = Suffix_Count (Number, 1);

   function Combination (Number : Digit_String; K : Natural) return String
   with
     Global => null,
     Pre    => Long_Long_Integer (K) < Suffix_Count (Number, 1),
     Post   => Spells_From (Number, Combination'Result, 1)
               and then Rank (Number, Combination'Result, 1) = Long_Long_Integer (K);

private
   function Pow4 (N : Natural) return Long_Long_Integer is
     (if N = 0 then 1 else 4 * Pow4 (N - 1));

   function Suffix_Count (Number : Digit_String; I : Positive) return Long_Long_Integer is
     (if I > Number'Last then 1
      else Long_Long_Integer (Letters (Number (I))) * Suffix_Count (Number, I + 1));

   function Rank (Number : Digit_String; R : String; I : Positive) return Long_Long_Integer is
     (if I > Number'Last then 0
      else Long_Long_Integer (Character'Pos (R (I)) - Character'Pos (First_Letter (Number (I))))
             * Suffix_Count (Number, I + 1)
           + Rank (Number, R, I + 1));
end Letter_Combinations_Of_A_Phone_Number;
