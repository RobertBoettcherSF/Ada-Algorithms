with Ada.Text_IO; use Ada.Text_IO;
with Spectral_Layout; use Spectral_Layout;

procedure Main is
   G : constant Adjacency_Matrix (1 .. 4, 1 .. 4) :=
     (1 => (0.0, 1.0, 0.0, 1.0),
      2 => (1.0, 0.0, 1.0, 0.0),
      3 => (0.0, 1.0, 0.0, 1.0),
      4 => (1.0, 0.0, 1.0, 0.0));
   
   Coords : Layout_Array (1 .. 4);
begin
   Put_Line ("--- Spectral Layout Algorithm Runner ---");
   Put_Line ("Generating coordinates for a 4-node cycle graph using Unnormalized Laplacian...");
   
   Layout_Unnormalized_Laplacian (G, Coords);
   
   for I in 1 .. 4 loop
      Put_Line ("Node " & Integer'Image(I) & 
                ": X=" & Float'Image (Coords(Node_Id(I)).X) & 
                ", Y=" & Float'Image (Coords(Node_Id(I)).Y));
   end loop;
end Main;
