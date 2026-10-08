pragma Ada_2022;

package Find_The_Smallest_Divisor with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Positive range 1 .. 1_000;
   subtype Divisor is Positive range 1 .. 1_000;
   --  every rounded-up quotient is at least 1, so a limit below Length can never be met;
   --  such limits are rejected by the type (with Divisor'Last every quotient is exactly 1)
   subtype Threshold is Positive range Length .. 8_000;
   type Value_Array is array (Index) of Value;

   function Quotient (V : Value; D : Divisor) return Positive is ((V + D - 1) / D);

   function Quotient_Sum (Values : Value_Array; D : Divisor) return Positive is
     (Quotient (Values (1), D) + Quotient (Values (2), D) + Quotient (Values (3), D)
      + Quotient (Values (4), D) + Quotient (Values (5), D) + Quotient (Values (6), D)
      + Quotient (Values (7), D) + Quotient (Values (8), D))
   with Ghost;

   function Smallest_Divisor
     (Values : Value_Array; Limit : Threshold) return Divisor
     with Global => null,
          Post   => Quotient_Sum (Values, Smallest_Divisor'Result) <= Limit
                    and then (Smallest_Divisor'Result = 1
                              or else Quotient_Sum (Values, Smallest_Divisor'Result - 1) > Limit);
end Find_The_Smallest_Divisor;
