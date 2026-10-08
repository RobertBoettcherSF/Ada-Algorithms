with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Basic_Calculator_II; use Basic_Calculator_II;
procedure Tests is
   --  operands whose product does not fit the result range must be rejected by the operand
   --  type, not answered with a clamped value (1000 * 2 is not 1000)
   procedure Check_Rejected (L, R : Integer; Op : Operator; Label : String) is
      V : Integer;
   begin
      V := Evaluate (L, R, Op);
      Assert (False, Label & ": accepted, returned" & Integer'Image (V));
   exception
      when Constraint_Error => null;
   end Check_Rejected;
   Checked : Natural := 0;
begin
   Assert (Evaluate (7, 3, Plus) = 10); Assert (Evaluate (7, 3, Times) = 21); Assert (Evaluate (7, 3, Divide) = 2);
   Assert (Evaluate (-7, 2, Divide) = -3);   --  integer division truncates toward zero
   --  own property: the exact integer result for every pair of operands in -31 .. 31
   for L in -31 .. 31 loop
      for R in -31 .. 31 loop
         Assert (Evaluate (L, R, Plus) = L + R);
         Assert (Evaluate (L, R, Minus) = L - R);
         Assert (Evaluate (L, R, Times) = L * R);
         if R /= 0 then
            Assert (Evaluate (L, R, Divide) = L / R);
         end if;
         Checked := Checked + 1;
      end loop;
   end loop;
   Check_Rejected (1000, 2, Times, "1000 * 2");
   Check_Rejected (40, 40, Times, "40 * 40");
   Check_Rejected (-1000, -1000, Minus, "-1000 - (-1000) with out-of-range operands");
   Put_Line ("PASS Basic_Calculator_II (" & Natural'Image (Checked) & " operand pairs)");
end Tests;
