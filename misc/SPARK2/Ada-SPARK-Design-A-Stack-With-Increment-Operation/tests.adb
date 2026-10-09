with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Design_A_Stack_With_Increment_Operation; use Design_A_Stack_With_Increment_Operation;
procedure Tests is S : Stack := Empty; V : Value; begin
   Push (S, 1); Push (S, 2); Push (S, 3); Increment (S, 2, 5); Pop (S, V); Assert (V = 3); Pop (S, V); Assert (V = 7); Pop (S, V); Assert (V = 6);
   --  V&V sweep, agent A3: an increment that would take a value above
   --  Value'Last must be refused, not skipped silently for some elements
   --  (here 995 + 10 > 1000 while 5 + 10 fits).
   declare
      T : Stack := Empty;
      W : Value;
      Raised : Boolean := False;
   begin
      Push (T, 5); Push (T, 995);
      begin
         Increment (T, 2, 10);
      exception
         when Assertion_Error => Raised := True;
      end;
      Pop (T, W);
      Assert (Raised and then W = 995, "overflowing increment must be refused");
      Pop (T, W);
      Assert (W = 5, "refused increment must change nothing");
   end;
   Put_Line ("PASS Design_A_Stack_With_Increment_Operation");
end Tests;
