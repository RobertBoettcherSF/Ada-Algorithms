pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Connected_Component_Labeling; use Connected_Component_Labeling;
procedure Tests is
   Empty : constant Binary_Grid := [others => [others => False]];
   Out_G : Label_Grid;
   N     : Label_Id;

   --  Two diagonal cells: 4-connectivity keeps them separate.
   Diag : Binary_Grid := [others => [others => False]];

   --  Horizontal bar merges under 4-connectivity.
   Bar : Binary_Grid := [others => [others => False]];

   --  Checkerboard → two singleton components on 2x2.
   Checker : Binary_Grid := [others => [others => False]];
begin
   Label (Empty, Out_G, N);
   Assert (N = 0);
   Assert (Component_Count (Out_G) = 0);
   Put_Line ("PASS empty grid");

   Diag (1, 1) := True;
   Diag (2, 2) := True;
   Label (Diag, Out_G, N);
   Assert (N = 2);
   Assert (Out_G (1, 1) /= Out_G (2, 2));
   Assert (Component_Count (Out_G) = 2);
   Put_Line ("PASS diagonal separation (4-connected)");

   Bar (1, 1) := True;
   Bar (1, 2) := True;
   Label (Bar, Out_G, N);
   Assert (N = 1);
   Assert (Out_G (1, 1) = 1 and then Out_G (1, 2) = 1);
   Assert (Component_Count (Out_G) = 1);
   Put_Line ("PASS horizontal merge");

   Checker (1, 1) := True;
   Checker (1, 2) := False;
   Checker (2, 1) := False;
   Checker (2, 2) := True;
   Label (Checker, Out_G, N);
   Assert (N = 2);
   Assert (Component_Count (Out_G) = 2);
   Put_Line ("PASS checkerboard singletons");

   Put_Line ("All Connected_Component_Labeling tests passed.");
end Tests;
