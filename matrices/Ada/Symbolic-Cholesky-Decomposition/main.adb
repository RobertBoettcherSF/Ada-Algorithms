-- main.adb
with Ada.Text_IO; use Ada.Text_IO;
with Symbolic_Cholesky; use Symbolic_Cholesky;

procedure Main is
   -- Sparse pattern defined by an adjacency matrix
   A : constant Matrix (1 .. 4, 1 .. 4) :=
     (1 => (True,  True,  False, True),
      2 => (True,  True,  True,  False),
      3 => (False, True,  True,  True),
      4 => (True,  False, True,  True));
      
   L : Matrix (1 .. 4, 1 .. 4);
   Tree : Tree_Array (1 .. 4);
begin
   Put_Line ("Executing Symbolic Cholesky Decomposition...");
   
   -- Process elimination game to find fill-in structural map
   L := Elimination_Game (A);
   
   -- Generate optimum calculation tree
   Tree := Compute_Elimination_Tree (L);
   
   Put_Line ("Elimination Tree output:");
   for I in Tree'Range loop
      Put_Line ("Node" & Integer'Image(I) & " parent ->" & Integer'Image(Tree(I)));
   end loop;
end Main;
