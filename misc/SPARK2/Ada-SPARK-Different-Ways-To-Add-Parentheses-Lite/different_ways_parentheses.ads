pragma Ada_2022;
with Ada.Numerics.Big_Numbers.Big_Integers;
use Ada.Numerics.Big_Numbers.Big_Integers;

--  Different ways to put parentheses into an expression of operands and
--  binary operators.
--
--  Number_Of_Ways (N): how many ways there are to fully parenthesize N
--  operands. The last operator applied splits the operands into a left
--  part of K and a right part of N - K (K in 1 .. N - 1), so
--  W (1) = 1 and W (N) = sum over K of W (K) * W (N - K).
--  Limit: N <= 20. W (20) = 1_767_263_190 fits Natural, W (21) =
--  6_564_120_420 does not (both proved in Facts).
--
--  All_Results (Values, Ops): the value of every parenthesization of an
--  expression of up to 9 operands in -99 .. 99 with +, - and *. That gives
--  at most W (9) = 1_430 results, and every value is at most 99 ** 9 =
--  913_517_247_483_640_899 < 2 ** 63 in absolute value (each operator at
--  most multiplies the bounds of its two parts), so Long_Long_Integer
--  holds every intermediate value; 99 ** 10 would not fit (the limit).
package Different_Ways_Parentheses with SPARK_Mode => On is
   Max_Operands : constant := 20;
   subtype Operand_Count is Positive range 1 .. Max_Operands;

   --  W (N) for N <= 20, a ghost table of values (an expression function,
   --  nothing runs at elaboration). Facts states that it satisfies the
   --  recurrence above, which fixes every entry; Lemma_Facts proves it and
   --  the tests regenerate the values.
   function Ways (N : Positive) return Big_Integer
   with Ghost, Pre => N <= Max_Operands;

   --  Sum over K in 1 .. S of W (K) * W (N - K). One expression function
   --  (no separate declaration): GNAT 14.2.0 leaks on every -gnata
   --  evaluation of a recursive Big_Integer expression function that has a
   --  separate declaration (tools/vv/h187_gnat14_leak, handover H189).
   function Partial (N : Positive; S : Natural) return Big_Integer is
     (if S = 0 then To_Big_Integer (0) else Partial (N, S - 1) + Ways (S) * Ways (N - S))
   with
     Ghost,
     Pre                => N in 2 .. Max_Operands + 1 and then S <= N - 1,
     Subprogram_Variant => (Decreases => S);

   Max_Expression : constant := 9;
   Max_Results    : constant := 1_430;   --  W (9)
   subtype Expression_Length is Positive range 1 .. Max_Expression;

   function Facts return Boolean is
     (Ways (1) = 1
      and then (for all N in 2 .. Max_Operands => Ways (N) = Partial (N, N - 1))
      and then (for all N in 1 .. Max_Operands => Ways (N) >= 1 and then Ways (N) <= Ways (Max_Operands))
      and then (for all N in 1 .. Max_Expression => Ways (N) <= Max_Results)
      and then Ways (Max_Operands) = 1_767_263_190
      --  W (21) would not fit Natural.
      and then Partial (Max_Operands + 1, Max_Operands) > To_Big_Integer (Natural'Last))
   with Ghost;

   procedure Lemma_Facts
   with Ghost, Global => null, Post => Facts;

   --  The split dynamic program (in Big_Integer; the result fits Natural).
   function Number_Of_Ways (Operands : Operand_Count) return Positive
   with Global => null, Post => To_Big_Integer (Number_Of_Ways'Result) = Ways (Operands);

   subtype Operand is Integer range -99 .. 99;
   type Operator is (Plus, Minus, Times);
   type Operand_List is array (Positive range <>) of Operand;
   type Operator_List is array (Positive range <>) of Operator;
   type Value_List is array (Positive range <>) of Long_Long_Integer;

   --  99 ** L.
   function Bound (L : Expression_Length) return Long_Long_Integer;

   --  Every value of every parenthesization, ordered by the position of the
   --  last operator applied (left to right), then by the left part's
   --  results, then by the right part's results. Values and Ops may start
   --  at any index (each independently); the K-th operator stands between
   --  the K-th and the (K + 1)-th operand.
   function All_Results (Values : Operand_List; Ops : Operator_List) return Value_List
   with
     Global => null,
     Pre    => Values'Length in 1 .. Max_Expression
               and then Ops'Length = Values'Length - 1,
     Post   => To_Big_Integer (All_Results'Result'Length) = Ways (Values'Length)
               and then (for all V of All_Results'Result =>
                           V in -Bound (Values'Length) .. Bound (Values'Length));

private
   function Ways_Value (N : Operand_Count) return Positive is
     (case N is
        when 1 => 1,
        when 2 => 1,
        when 3 => 2,
        when 4 => 5,
        when 5 => 14,
        when 6 => 42,
        when 7 => 132,
        when 8 => 429,
        when 9 => 1_430,
        when 10 => 4_862,
        when 11 => 16_796,
        when 12 => 58_786,
        when 13 => 208_012,
        when 14 => 742_900,
        when 15 => 2_674_440,
        when 16 => 9_694_845,
        when 17 => 35_357_670,
        when 18 => 129_644_790,
        when 19 => 477_638_700,
        when 20 => 1_767_263_190)
   with Ghost;

   function Ways (N : Positive) return Big_Integer is (To_Big_Integer (Ways_Value (N)));

   function Bound (L : Expression_Length) return Long_Long_Integer is
     (case L is
        when 1 => 99,
        when 2 => 9_801,
        when 3 => 970_299,
        when 4 => 96_059_601,
        when 5 => 9_509_900_499,
        when 6 => 941_480_149_401,
        when 7 => 93_206_534_790_699,
        when 8 => 9_227_446_944_279_201,
        when 9 => 913_517_247_483_640_899);
end Different_Ways_Parentheses;
