pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO;
with Stack_Bounded; use Stack_Bounded;
with Own_Checks;
procedure Tests is S : Stack; V : Integer;

   --  Hand-worked edge cases (V&V sweep, agent A3); expected values in
   --  tests/SOURCES.txt.
   procedure Check_Edges is
      T : Stack;
      X : Integer;
      Raised : Boolean;
   begin
      Initialize (T);
      Assert (Is_Empty (T) and then not Is_Full (T) and then Depth (T) = 0);
      --  Fill to Capacity: depth counts up, Top is the latest value.
      for K in 1 .. 8 loop
         Push (T, K * 10);
         Assert (Depth (T) = K, "depth after push");
         Assert (Top (T) = K * 10, "top after push");
         Assert (not Is_Empty (T), "not empty after push");
         Assert (Is_Full (T) = (K = 8), "full only at 8");
      end loop;
      --  Top does not remove anything.
      Assert (Top (T) = 80 and then Top (T) = 80 and then Depth (T) = 8);
      --  A push on a full stack violates Push's precondition.
      Raised := False;
      begin
         Push (T, 99);
      exception
         when Assertion_Error => Raised := True;
      end;
      Assert (Raised, "push on a full stack must be rejected");
      Assert (Depth (T) = 8 and then Top (T) = 80);
      --  Pop returns 80, 70, ..., 10 (last in, first out).
      for K in reverse 1 .. 8 loop
         Pop (T, X);
         Assert (X = K * 10, "LIFO order");
         Assert (Depth (T) = K - 1, "depth after pop");
         Assert (not Is_Full (T), "not full after pop");
         if K > 1 then
            Assert (Top (T) = (K - 1) * 10, "top after pop");
         end if;
      end loop;
      Assert (Is_Empty (T) and then Depth (T) = 0);
      --  Pop and Top on an empty stack violate their preconditions.
      Raised := False;
      begin
         Pop (T, X);
      exception
         when Assertion_Error => Raised := True;
      end;
      Assert (Raised, "pop on an empty stack must be rejected");
      Raised := False;
      begin
         X := Top (T);
      exception
         when Assertion_Error => Raised := True;
      end;
      Assert (Raised, "top on an empty stack must be rejected");
      --  A slot freed by Pop is reused by the next Push.
      Push (T, 1); Push (T, 2); Pop (T, X); Assert (X = 2);
      Push (T, 3); Assert (Top (T) = 3 and then Depth (T) = 2);
      Pop (T, X); Assert (X = 3); Pop (T, X); Assert (X = 1);
      --  Extreme values are stored unchanged.
      Push (T, Integer'First); Push (T, Integer'Last); Push (T, 0);
      Pop (T, X); Assert (X = 0);
      Pop (T, X); Assert (X = Integer'Last);
      Pop (T, X); Assert (X = Integer'First);
      --  Initialize empties a non-empty stack.
      Push (T, 5); Push (T, 6); Initialize (T);
      Assert (Is_Empty (T) and then Depth (T) = 0 and then not Is_Full (T));
      Push (T, 7); Assert (Top (T) = 7 and then Depth (T) = 1);
   end Check_Edges;
begin Initialize (S); Push (S, 10); Push (S, 20); Assert (Top (S) = 20); Pop (S, V); Assert (V = 20); Pop (S, V); Assert (V = 10);
   Check_Edges;
   Own_Checks;
   Put_Line ("PASS Stack_Bounded"); end Tests;
