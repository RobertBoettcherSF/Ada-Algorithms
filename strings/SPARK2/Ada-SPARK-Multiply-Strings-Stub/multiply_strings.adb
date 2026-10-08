pragma SPARK_Mode (On);

package body Multiply_Strings is
   function Multiply (Left, Right : String) return String is
      L1 : constant Positive := Left'Length;
      L2 : constant Positive := Right'Length;
      subtype Pos is Positive range 1 .. L1 + L2;
      --  Acc (P): sum of digit products landing on position P, most
      --  significant position first; each row adds at most 81 per slot.
      Acc        : array (Pos) of Natural := (others => 0);
      Digits_Out : String (Pos) := (others => '0');
      Carry      : Natural := 0;
      T          : Natural;
      First      : Pos;
      D1, D2     : Natural range 0 .. 9;
   begin
      for I in 1 .. L1 loop
         pragma Loop_Invariant (for all P in Pos => Acc (P) <= 81 * (I - 1));
         D1 := Character'Pos (Left (Left'First + I - 1)) - Character'Pos ('0');
         for J in reverse 1 .. L2 loop
            pragma Loop_Invariant
              (for all P in Pos =>
                 Acc (P) <= 81 * (I - 1) + (if P > I + J then 81 else 0));
            D2 := Character'Pos (Right (Right'First + J - 1))
                  - Character'Pos ('0');
            Acc (I + J) := Acc (I + J) + D1 * D2;
         end loop;
      end loop;
      pragma Assert (for all P in Pos => Acc (P) <= 81 * L1);
      for P in reverse Pos loop
         pragma Loop_Invariant (Carry <= 9 * L1);
         pragma Loop_Invariant (for all Q in Pos => Digits_Out (Q) in '0' .. '9');
         T := Acc (P) + Carry;
         Digits_Out (P) := Character'Val (Character'Pos ('0') + T mod 10);
         Carry := T / 10;
      end loop;
      --  Carry is 0 here: the product of an L1- and an L2-digit number has
      --  at most L1 + L2 digits.
      First := 1;
      while First < Pos'Last and then Digits_Out (First) = '0' loop
         pragma Loop_Invariant (First < Pos'Last);
         pragma Loop_Variant (Increases => First);
         First := First + 1;
      end loop;
      return Digits_Out (First .. Pos'Last);
   end Multiply;
end Multiply_Strings;
