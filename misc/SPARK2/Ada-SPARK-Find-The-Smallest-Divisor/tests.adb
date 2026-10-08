with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Find_The_Smallest_Divisor; use Find_The_Smallest_Divisor;

procedure Tests is
   Values : constant Value_Array := [1, 2, 5, 9, 10, 11, 15, 20];

   --  sum of the rounded-up quotients, in plain Integer
   function Total (V : Value_Array; D : Positive) return Natural is
      S : Natural := 0;
   begin
      for I in Index loop
         S := S + (V (I) + D - 1) / D;
      end loop;
      return S;
   end Total;

   --  own property: the answer meets the limit and the next smaller divisor does not
   procedure Check (V : Value_Array; L : Integer) is
      D : constant Divisor := Smallest_Divisor (V, Threshold (L));
   begin
      Assert (Total (V, D) <= L, "answer misses the limit");
      Assert (D = 1 or else Total (V, D - 1) > L, "a smaller divisor meets the limit");
   end Check;

   --  a limit below the number of values can never be met (every quotient is at least 1);
   --  it must be rejected by the Threshold type, not answered with Divisor'Last
   procedure Check_Rejected (L : Integer) is
      D : Divisor;
   begin
      D := Smallest_Divisor (Values, Threshold (L));
      Assert (False, "limit" & Integer'Image (L) & " accepted, returned" & Integer'Image (D));
   exception
      when Constraint_Error => null;
   end Check_Rejected;

   Seed : Long_Long_Integer := 20261008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   V : Value_Array;
   Checked : Natural := 0;
begin
   Assert (Smallest_Divisor (Values, 8) = 20);
   Assert (Smallest_Divisor (Values, 20) = 5);
   for L in Length .. 80 loop
      Check (Values, L);
      Checked := Checked + 1;
   end loop;
   for Trial in 1 .. 3_000 loop
      for I in Index loop
         V (I) := Next (1, (if Trial mod 2 = 0 then 1_000 else 30));
      end loop;
      Check (V, Next (Length, (if Trial mod 3 = 0 then 8_000 else 60)));
      Checked := Checked + 1;
   end loop;
   Check_Rejected (7);
   Check_Rejected (1);
   Put_Line ("PASS Find_The_Smallest_Divisor (" & Natural'Image (Checked) & " cases)");
end Tests;
