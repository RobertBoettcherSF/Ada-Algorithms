pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Bankers_Algorithm; use Bankers_Algorithm;
with Own_Checks;
procedure Tests is
   S : State :=
     (Available => [3, 3, 2],
      Allocation => [[1, 0, 0], [0, 1, 0], [1, 1, 1], [0, 0, 1]],
      Maximum => [[3, 2, 2], [1, 2, 2], [2, 2, 2], [1, 1, 2]]);
   Granted : Boolean;
   --  Safe only through an order (V&V sweep, agent A3): with 1 unit free,
   --  process 1 (needs 1) can finish and return its 1 unit, after which
   --  process 2 (needs 2) can finish. Not every need fits in Available at
   --  once, but the state is safe.
   Ordered : constant State :=
     (Available => [1, 0, 0],
      Allocation => [[1, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]],
      Maximum => [[2, 0, 0], [2, 0, 0], [0, 0, 0], [0, 0, 0]]);

   procedure Check (Ok : Boolean; Label : String) is
   begin
      if not Ok then
         raise Program_Error with Label;
      end if;
   end Check;

   --  Hand-worked cases (V&V sweep, agent A3; tests/SOURCES.txt).
   procedure Check_Edges is
      --  Nobody can finish: both need 1 more unit and none is free.
      Deadlock : constant State :=
        (Available => [0, 0, 0],
         Allocation => [[1, 0, 0], [1, 0, 0], [0, 0, 0], [0, 0, 0]],
         Maximum => [[2, 0, 0], [2, 0, 0], [0, 0, 0], [0, 0, 0]]);
      --  Order across resources: 1, then 2, then 3.
      Mixed : constant State :=
        (Available => [0, 1, 0],
         Allocation => [[0, 0, 1], [1, 0, 0], [0, 0, 0], [0, 0, 0]],
         Maximum => [[0, 1, 1], [1, 1, 1], [1, 1, 1], [0, 0, 0]]);
      --  Only the order 4, 3, 2, 1 works; a scan 1 .. 4 needs four passes.
      Chain : constant State :=
        (Available => [1, 0, 0],
         Allocation => [[0, 0, 0], [1, 0, 0], [0, 0, 1], [0, 1, 0]],
         Maximum => [[2, 0, 0], [1, 0, 1], [0, 1, 1], [1, 1, 0]]);
      --  Chain with process 1 needing one unit more than ever comes free.
      Chain_Short : State := Chain;
      T : State;
      G : Boolean;
   begin
      Check (Is_Safe (S), "classic state is safe");
      Check (Is_Safe (Ordered), "ordered state is safe");
      Check (not Is_Safe (Deadlock), "deadlock is unsafe");
      Check (Is_Safe (Mixed), "mixed-resource order is safe");
      Check (Is_Safe (Chain), "4-3-2-1 chain is safe");
      Chain_Short.Maximum (1, 1) := 3;
      Check (not Is_Safe (Chain_Short), "chain short by one unit is unsafe");
      Check (Need (Chain, 1, 1) = 2 and then Need (Chain, 4, 2) = 0,
             "need = maximum - allocation");

      --  A request that leaves process 1 unable to finish is refused and
      --  changes nothing.
      T := Ordered;
      Request (T, 2, 1, 1, G);
      Check (not G and then T = Ordered, "unsafe request refused, state kept");
      --  Giving process 1 its last unit is safe (it finishes, frees 2).
      Request (T, 1, 1, 1, G);
      Check (G and then T.Available (1) = 0 and then T.Allocation (1, 1) = 2,
             "safe request granted");
      Check (T.Allocation (2, 1) = 0 and then T.Maximum = Ordered.Maximum,
             "grant changes only the requested entries");
      --  More than is free, or more than the process still needs.
      T := S;
      Request (T, 1, 3, 3, G);
      Check (not G and then T = S, "request above Available refused");
      Request (T, 2, 1, 2, G);
      Check (not G and then T = S, "request above Need refused");
      --  A zero request on a safe state is granted and changes nothing.
      Request (T, 3, 2, 0, G);
      Check (G and then T = S, "zero request granted unchanged");
      --  A zero request on an unsafe state is refused.
      T := Deadlock;
      Request (T, 1, 1, 0, G);
      Check (not G and then T = Deadlock, "zero request on unsafe state refused");
   end Check_Edges;
begin
   if not Is_Safe (Ordered) then
      raise Program_Error with "safe state with a finishing order judged unsafe";
   end if;
   if not Is_Safe (S) then raise Program_Error; end if;
   Request (S, 2, 1, 1, Granted);
   if not Granted then raise Program_Error; end if;
   Check_Edges;
   Own_Checks;
   Put_Line ("Bankers: PASS");
end Tests;
