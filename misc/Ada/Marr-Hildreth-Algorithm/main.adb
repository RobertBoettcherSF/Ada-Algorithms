-- main.adb
-- Demonstration application executing Marr-Hildreth edge detection.

with Ada.Text_IO; use Ada.Text_IO;
with Marr_Hildreth; use Marr_Hildreth;

procedure Main is
   Img    : Image_Grid (1 .. 10, 1 .. 10) := (others => (others => 0.0));
   Edges  : Edge_Grid (1 .. 10, 1 .. 10);
   Params : Parameters;
begin
   Put_Line ("=== Marr-Hildreth Edge Detector Demonstration ===");

   -- Create a vertical step edge down the middle
   for I in 1 .. 10 loop
      for J in 6 .. 10 loop
         Img (I, J) := 255.0;
      end loop;
   end loop;

   Params.Kernel_Dim := 3;
   Params.Sigma := 1.0;
   Params.Threshold := 0.01;

   Detect_Edges_LoG (Img, Edges, Params);

   Put_Line ("Edge Map Result (1 = Edge, . = Background):");
   for I in Edges'Range (1) loop
      for J in Edges'Range (2) loop
         if Edges (I, J) = Edge then
            Put ("1 ");
         else
            Put (". ");
         end if;
      end loop;
      New_Line;
   end loop;
end Main;
