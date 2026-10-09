with Ada.Text_IO; use Ada.Text_IO;
with Fast_Pow; use Fast_Pow;

procedure Tests is
   --  Left-to-right square-and-multiply over the 31 bits of a Natural
   --  exponent: one squaring step per bit, so exactly 31 steps for every
   --  call. A loop of E multiplications or a table cannot match it.
   procedure Check (B, E : Natural; M : Positive; Want : Natural) is
      R : constant Pow_Result := Power_Mod (B, E, M);
   begin
      if R.Value /= Want or else R.Steps /= 31 then
         raise Program_Error with B'Image & " **" & E'Image & " mod" & M'Image & ": got"
           & R.Value'Image & ", steps" & R.Steps'Image & " (expected" & Want'Image & ", 31 steps)";
      end if;
   end Check;
   P31 : constant := 2_147_483_647;    --  2 ** 31 - 1, prime
   P   : constant := 1_000_000_007;    --  prime
begin
   --  The old table's answers (exact, since they are below the modulus).
   Check (2, 10, P31, 1_024);
   Check (5, 12, P31, 244_140_625);
   Check (0, 4, P31, 0);
   Check (0, 0, P31, 1);
   --  By hand: 2 ** 10 = 1024 -> 24 mod 1000.
   Check (2, 10, 1_000, 24);
   --  10 ** 10 = 10_000_000_000 = 9 * 1_000_000_007 + 999_999_937.
   Check (10, 10, P, 999_999_937);
   --  Fermat: a ** (p - 1) = 1 mod p for a prime p not dividing a.
   Check (3, P - 1, P, 1);
   Check (123_456_789, P31 - 1, P31, 1);
   --  (p - 1) ** odd = -1 = p - 1 mod p; the largest operands.
   Check (P31 - 1, Natural'Last, P31, P31 - 1);
   --  Modulus 1: everything is 0, even 0 ** 0.
   Check (0, 0, 1, 0);
   Check (Natural'Last, Natural'Last, 1, 0);
   --  The base is reduced first: 1_000_000_008 = 1 mod p.
   Check (1_000_000_008, Natural'Last, P, 1);
   Put_Line ("fast pow checks passed");
end Tests;
