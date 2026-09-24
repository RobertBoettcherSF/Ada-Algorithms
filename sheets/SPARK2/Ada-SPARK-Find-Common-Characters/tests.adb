with Find_Common_Characters;
procedure Tests is
   Left  : constant Find_Common_Characters.Character_Array := [0, 1, 2, 3];
   Right : constant Find_Common_Characters.Character_Array := [4, 2, 5, 6];
   Other : constant Find_Common_Characters.Character_Array := [4, 5, 6, 7];
begin
   pragma Assert (Find_Common_Characters.Has_Common (Left, Right));
   pragma Assert (not Find_Common_Characters.Has_Common (Left, Other));
end Tests;
