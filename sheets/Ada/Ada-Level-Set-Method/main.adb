-- main.adb
-- A simple entry point demonstrating usage of the Level Set Method.
with Ada.Text_IO; use Ada.Text_IO;
with Level_Set_Method; use Level_Set_Method;

procedure Main is
   Grid : Grid_2D (1 .. 15, 1 .. 15);
begin
   Put_Line ("Initializing Interface (Circle at 8,8 R=4.0)");
   Initialize_Circle (Grid, 8.0, 8.0, 4.0);
   
   Put_Line ("Value at Center (8,8): " & Real'Image(Grid(8,8)));
   Put_Line ("Value at Edge (12,8): " & Real'Image(Grid(12,8)));
   
   Put_Line ("Expanding Level Set (F = 1.0, dt = 1.0)");
   Update_Basic (Grid, dt => 1.0, F => 1.0);
   
   Put_Line ("Value at Edge (12,8) after step: " & Real'Image(Grid(12,8)));
   
   Put_Line ("Simulation Step Complete.");
end Main;
