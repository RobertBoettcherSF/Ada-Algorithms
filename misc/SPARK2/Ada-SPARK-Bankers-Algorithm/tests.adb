pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Bankers_Algorithm; use Bankers_Algorithm;
procedure Tests is
   S : State :=
     (Available => (3, 3, 2),
      Allocation => ((1, 0, 0), (0, 1, 0), (1, 1, 1), (0, 0, 1)),
      Maximum => ((3, 2, 2), (1, 2, 2), (2, 2, 2), (1, 1, 2)));
   Granted : Boolean;
   --  Safe only through an order (V&V sweep, agent A3): with 1 unit free,
   --  process 1 (needs 1) can finish and return its 1 unit, after which
   --  process 2 (needs 2) can finish. Not every need fits in Available at
   --  once, but the state is safe.
   Ordered : constant State :=
     (Available => (1, 0, 0),
      Allocation => ((1, 0, 0), (0, 0, 0), (0, 0, 0), (0, 0, 0)),
      Maximum => ((2, 0, 0), (2, 0, 0), (0, 0, 0), (0, 0, 0)));
begin
   if not Is_Safe (Ordered) then
      raise Program_Error with "safe state with a finishing order judged unsafe";
   end if;
   if not Is_Safe (S) then raise Program_Error; end if;
   Request (S, 2, 1, 1, Granted);
   if not Granted then raise Program_Error; end if;
   Put_Line ("Bankers: PASS");
end Tests;
