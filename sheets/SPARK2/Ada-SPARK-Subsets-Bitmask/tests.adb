pragma Ada_2022;
with Subsets_Bitmask;
procedure Tests is
   M : Subsets_Bitmask.Mask := 0;
begin
   pragma Assert (not Subsets_Bitmask.Has_Item (M, 5));
   M := Subsets_Bitmask.Add_Item (M, 5);
   pragma Assert (Subsets_Bitmask.Has_Item (M, 5));
   pragma Assert (not Subsets_Bitmask.Has_Item (M, 4));
end Tests;
