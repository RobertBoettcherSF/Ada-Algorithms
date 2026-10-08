pragma SPARK_Mode (On);

--  Multiply two non-negative integers given as decimal digit strings and
--  return the product as a digit string (LeetCode 43). Generalised from
--  the old stub, which multiplied two Naturals up to 9_999, to digit
--  strings of any length up to Max_Len.
package Multiply_Strings is
   Max_Len : constant := 1_000;

   function Is_Number (S : String) return Boolean is
     (S'Length in 1 .. Max_Len
      and then (for all C of S => C in '0' .. '9'));

   function Multiply (Left, Right : String) return String
     with Global => null,
          Pre    => Is_Number (Left) and then Is_Number (Right)
                    and then Left'Last < Positive'Last
                    and then Right'Last < Positive'Last,
          Post   => Multiply'Result'Length in 1 .. Left'Length + Right'Length
                    and then (for all C of Multiply'Result => C in '0' .. '9')
                    and then (Multiply'Result'Length = 1
                              or else Multiply'Result
                                        (Multiply'Result'First) /= '0');
end Multiply_Strings;
