with Ada.Text_IO; use Ada.Text_IO;
with Chandy_Lamport; use Chandy_Lamport;

procedure Main is
   N : Node;
begin
   Put_Line("Chandy-Lamport Algorithm Simulator");
   Init_Node(N, 1, 100);
   Put_Line("Node 1 Initialized. Run 'make test' to execute the V&V test suite.");
end Main;
