with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Design_A_Stack_With_Increment_Operation; use Design_A_Stack_With_Increment_Operation;
with Own_Checks;
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
   --  Hand-worked (V&V sweep, agent A3; tests/SOURCES.txt).
   declare
      T : Stack := Empty;
      W : Value;
   begin
      Increment (T, 5, 10);              --  empty: nothing to change
      Assert (Size (T) = 0);
      for K in 1 .. 8 loop
         Push (T, K);
      end loop;
      Increment (T, 0, 10);              --  Bottom 0: nothing
      Increment (T, 8, 1);               --  all: 2 .. 9
      Increment (T, 3, 10);              --  bottom 3: 12 13 14 5 .. 9
      Increment (T, 8, 0);               --  By 0: nothing
      for K in reverse 4 .. 8 loop
         Pop (T, W);
         Assert (W = K + 1, "upper elements got only the +1");
      end loop;
      for K in reverse 1 .. 3 loop
         Pop (T, W);
         Assert (W = K + 11, "bottom three got +1 and +10");
      end loop;
      Assert (Size (T) = 0);
      Push (T, 990); Push (T, 1000);
      Increment (T, 1, 10);              --  990 + 10 = 1000 fits exactly
      Pop (T, W); Assert (W = 1000);
      Pop (T, W); Assert (W = 1000);
      Push (T, 0); Push (T, 1000);
      Increment (T, 1, 10);              --  only the bottom 0 is touched
      Pop (T, W); Assert (W = 1000);
      Pop (T, W); Assert (W = 10);
   end;
   Own_Checks;
   Put_Line ("PASS Design_A_Stack_With_Increment_Operation");
end Tests;
