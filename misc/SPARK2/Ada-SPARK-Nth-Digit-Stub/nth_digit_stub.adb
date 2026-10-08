pragma Ada_2022;

package body Nth_Digit_Stub with SPARK_Mode => On is
   subtype Width is Positive range 1 .. 10;
   subtype Big is Long_Long_Integer;

   --  Cum (W): how many digits the numbers of 1 .. W digits use together.
   --  Cum (10) exceeds Natural'Last, so every position falls in 1 .. 10.
   Cum : constant array (0 .. 10) of Big :=
     [0, 9, 189, 2_889, 38_889, 488_889, 5_888_889, 68_888_889,
      788_888_889, 8_888_888_889, 98_888_888_889];
   --  First number with W digits (10 ** (W - 1)).
   First_Of : constant array (Width) of Big :=
     [1, 10, 100, 1_000, 10_000, 100_000, 1_000_000, 10_000_000,
      100_000_000, 1_000_000_000];
   --  Pow10 (K) = 10 ** K.
   Pow10 : constant array (0 .. 9) of Big :=
     [1, 10, 100, 1_000, 10_000, 100_000, 1_000_000, 10_000_000,
      100_000_000, 1_000_000_000];

   function Nth_Digit (P : Position) return Digit is
      N      : constant Big := Big (P) + 1;   --  one-based position
      W      : Width := 1;
      Offset : Big;
      Number : Big;
      Place  : Natural;
   begin
      while N > Cum (W) loop
         pragma Loop_Invariant (N > Cum (W));
         pragma Loop_Invariant (W <= 9);
         pragma Loop_Variant (Increases => W);
         W := W + 1;
      end loop;
      pragma Assert (N > Cum (W - 1));
      Offset := N - Cum (W - 1) - 1;            --  0 .. W * 9 * 10 ** (W-1) - 1
      Number := First_Of (W) + Offset / Big (W);
      Place  := W - 1 - Natural (Offset mod Big (W));
      return Digit ((Number / Pow10 (Place)) mod 10);
   end Nth_Digit;
end Nth_Digit_Stub;
