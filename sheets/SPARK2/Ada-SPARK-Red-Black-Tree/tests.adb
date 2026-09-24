pragma Ada_2022;
with Red_Black_Tree;
use Red_Black_Tree;
procedure Tests is
   R : Node_Index := 0;
begin
   pragma Assert (Is_Red (Red));
   pragma Assert (not Is_Red (Black));
   Rotate_Left (R);
   pragma Assert (R = 1);
end Tests;
