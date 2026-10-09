pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Clone_Graph; use Clone_Graph;
procedure Tests is
   --  Undirected square 1 - 2 - 3 - 4 - 1 (each edge listed both ways),
   --  labels 10, 20, 30, 40, and node 5 -> 1 that nothing reaches.
   G : Graph;
   R : Clone_Result;

   procedure Check (Cond : Boolean; What : String) is
   begin
      if not Cond then
         raise Program_Error with What;
      end if;
   end Check;
begin
   G (1) := (10, [2, 4, 0, 0]);
   G (2) := (20, [1, 3, 0, 0]);
   G (3) := (30, [2, 0, 4, 0]);   --  empty slot kept in place
   G (4) := (40, [3, 1, 0, 0]);
   G (5) := (50, [1, 0, 0, 0]);

   --  From node 3: copies in breadth-first order 3, 2, 4, 1.
   R := Clone (G, 3);
   Check (R.Size = 4, "copy size");
   Check (R.Map (3) = 1 and then R.Map (2) = 2 and then R.Map (4) = 3
          and then R.Map (1) = 4 and then R.Map (5) = 0, "copy ids");
   Check (R.Copy (1) = (30, [2, 0, 3, 0]), "copy of node 3");
   Check (R.Copy (2) = (20, [4, 1, 0, 0]), "copy of node 2");
   Check (R.Copy (3) = (40, [1, 4, 0, 0]), "copy of node 4");
   Check (R.Copy (4) = (10, [2, 3, 0, 0]), "copy of node 1");
   Check (R.Copy (5) = (0, [0, 0, 0, 0]), "unused copy node");

   --  From node 5: five nodes, 5 first, then 1.
   R := Clone (G, 5);
   Check (R.Size = 5 and then R.Map (5) = 1 and then R.Map (1) = 2, "from 5");

   --  A node with only a self-loop (twice).
   G (7) := (-7, [7, 0, 7, 0]);
   R := Clone (G, 7);
   Check (R.Size = 1 and then R.Copy (1) = (-7, [1, 0, 1, 0]), "self-loop");
   Put_Line ("Clone_Graph: PASS");
end Tests;
