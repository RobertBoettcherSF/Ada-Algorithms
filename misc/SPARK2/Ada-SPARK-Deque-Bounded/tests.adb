pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO;
with Deque_Bounded; use Deque_Bounded;
with Own_Checks;
procedure Tests is D : Deque; V : Integer;

   --  Hand-worked edge cases (V&V sweep, agent A3; tests/SOURCES.txt).
   procedure Check_Edges is
      E : Deque;
      X : Integer;
      Raised : Boolean;
   begin
      Initialize (E);
      Assert (Is_Empty (E) and then not Is_Full (E) and then Length (E) = 0);
      --  Push_Front only: 1 .. 8 come out of the back in push order.
      for K in 1 .. 8 loop
         Push_Front (E, K);
         Assert (Length (E) = K and then Is_Full (E) = (K = 8));
      end loop;
      Raised := False;
      begin
         Push_Back (E, 9);
      exception
         when Assertion_Error => Raised := True;
      end;
      Assert (Raised, "push on a full deque must be rejected");
      Raised := False;
      begin
         Push_Front (E, 9);
      exception
         when Assertion_Error => Raised := True;
      end;
      Assert (Raised, "push_front on a full deque must be rejected");
      for K in 1 .. 8 loop
         Pop_Back (E, X);
         Assert (X = K, "back order");
      end loop;
      Assert (Is_Empty (E));
      Raised := False;
      begin
         Pop_Front (E, X);
      exception
         when Assertion_Error => Raised := True;
      end;
      Assert (Raised, "pop_front on an empty deque must be rejected");
      Raised := False;
      begin
         Pop_Back (E, X);
      exception
         when Assertion_Error => Raised := True;
      end;
      Assert (Raised, "pop_back on an empty deque must be rejected");
      --  Push_Back only: front pops give push order (queue).
      for K in 1 .. 8 loop
         Push_Back (E, 10 * K);
      end loop;
      for K in 1 .. 8 loop
         Pop_Front (E, X);
         Assert (X = 10 * K, "front order");
      end loop;
      --  Wrap-around: interleave so the ends cross the array boundary.
      Initialize (E);
      Push_Front (E, 1); Push_Front (E, 2); Push_Back (E, 3);  --  2 1 3
      Pop_Back (E, X); Assert (X = 3);                          --  2 1
      Push_Back (E, 4); Push_Back (E, 5); Push_Front (E, 6);    --  6 2 1 4 5
      Pop_Front (E, X); Assert (X = 6);                         --  2 1 4 5
      Pop_Front (E, X); Assert (X = 2);                         --  1 4 5
      Pop_Back (E, X); Assert (X = 5);                          --  1 4
      Pop_Back (E, X); Assert (X = 4);                          --  1
      Pop_Front (E, X); Assert (X = 1 and then Is_Empty (E));
      --  A single element is both front and back.
      Push_Back (E, Integer'First);
      Pop_Front (E, X); Assert (X = Integer'First);
      Push_Front (E, Integer'Last);
      Pop_Back (E, X); Assert (X = Integer'Last and then Length (E) = 0);
      --  Initialize empties a non-empty deque.
      Push_Back (E, 1); Push_Back (E, 2); Initialize (E);
      Assert (Is_Empty (E) and then Length (E) = 0);
   end Check_Edges;
begin Initialize (D); Push_Back (D, 2); Push_Front (D, 1); Push_Back (D, 3); Pop_Front (D, V); Assert (V = 1); Pop_Back (D, V); Assert (V = 3);
   Check_Edges;
   Own_Checks;
   Put_Line ("PASS Deque_Bounded"); end Tests;
