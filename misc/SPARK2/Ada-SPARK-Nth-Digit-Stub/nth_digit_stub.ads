pragma Ada_2022;

--  Digit at a zero-based position in the infinite string
--  "123456789101112..." (LeetCode 400), generalised from the old stub,
--  which covered positions 0 .. 9 only, to every Natural position.
package Nth_Digit_Stub with SPARK_Mode => On is
   subtype Position is Natural;
   subtype Digit is Natural range 0 .. 9;

   function Nth_Digit (P : Position) return Digit
     with Global => null,
          Post   => (if P <= 8 then Nth_Digit'Result = P + 1);
end Nth_Digit_Stub;
