--  Spigot_Algorithm — Ada 2023 educational package for Wikipedia
--  "Spigot algorithm": emit decimal digits of a constant (e or π)
--  left-to-right with a bounded integer remainder array (no Float in
--  the core). Implements Sale-style e-spigot (factorial mixed radix)
--  and Rabinowitz–Wagon π spigot. Cap N ≤ Max_Digits_* so schoolbook
--  Integer arithmetic stays warning-free and testable.
--  Primary source:
--  https://en.wikipedia.org/wiki/Spigot_algorithm
--  Siblings (README): Ada-Binary-Splitting, Ada-Alpha-Max-Plus-Beta-Min;
--  upcoming Rounding, Newton multiplicative inverse, Toom–Cook.

pragma Ada_2022;

package Spigot_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Integer remainder arrays)
   ---------------------------------------------------------------------------

   --  Max digit counts: keep remainder arrays small for classroom Integer
   --  arithmetic. e needs ~N+5 terms; π needs ~(10/3)·N terms plus a
   --  small digit guard for the classic predigit/nines carry buffer.
   Max_Digits_E  : constant := 80;
   Max_Digits_Pi : constant := 50;

   --  Extra factorial-radix slots beyond N so truncated series does not
   --  corrupt early digits of e (worst case observed ≈ +3 for N ≤ 80).
   E_Term_Guard : constant := 5;

   --  Extra decimal steps for Rabinowitz–Wagon so a pending nines/carry
   --  resolves before we return the first N digits.
   Pi_Digit_Guard : constant := 2;

   subtype Digit_Value is Natural range 0 .. 9;

   type Digit_Array is array (Positive range <>) of Digit_Value;

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   --  True when S has length in 1 .. Max and every character is '0'..'9'.
   function Is_Digit_String
     (S : String; Max : Positive) return Boolean
     with Global => null;

   --  Number of remainder slots used by Digits_Of_E for request N
   --  (N + E_Term_Guard, or 0 when N = 0).
   function E_Term_Count (N : Natural) return Natural
     with Global => null;

   --  Remainder-array length for Rabinowitz–Wagon on Total_Digits steps:
   --  (10 · Total_Digits) / 3 + 1.
   function Pi_Term_Count (Total_Digits : Natural) return Natural
     with Global => null;

   ---------------------------------------------------------------------------
   -- e-spigot (Sale / factorial mixed radix)
   ---------------------------------------------------------------------------

   --  First N decimal digits of e = 2.71828… as characters, no radix point.
   --  Digits_Of_E (1) = "2", Digits_Of_E (5) = "27182".
   --  Raises Invalid_Argument if N = 0 or N > Max_Digits_E.
   function Digits_Of_E (N : Natural) return String
     with Global => null;

   --  Same digits as Digit_Value values in 1 .. N.
   function Digits_Of_E_Array (N : Natural) return Digit_Array
     with Global => null;

   ---------------------------------------------------------------------------
   -- π-spigot (Rabinowitz–Wagon)
   ---------------------------------------------------------------------------

   --  First N decimal digits of π = 3.14159… as characters, no radix point.
   --  Digits_Of_Pi (1) = "3", Digits_Of_Pi (5) = "31415".
   --  Raises Invalid_Argument if N = 0 or N > Max_Digits_Pi.
   function Digits_Of_Pi (N : Natural) return String
     with Global => null;

   function Digits_Of_Pi_Array (N : Natural) return Digit_Array
     with Global => null;

   ---------------------------------------------------------------------------
   -- Known prefixes (for tests / demos; not computed by the spigot)
   ---------------------------------------------------------------------------

   --  Return Known_E (1 .. N) / Known_Pi (1 .. N). Raises Invalid_Argument
   --  if N is out of the corresponding Max_Digits_* range (including 0).
   function Known_E_Prefix (N : Natural) return String
     with Global => null;

   function Known_Pi_Prefix (N : Natural) return String
     with Global => null;

   --  True iff Digit_Str equals the known prefix of the same length.
   function Matches_Known_E (Digit_Str : String) return Boolean
     with Global => null;

   function Matches_Known_Pi (Digit_Str : String) return Boolean
     with Global => null;

end Spigot_Algorithm;
