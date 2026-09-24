pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Fruit_Into_Baskets; use Fruit_Into_Baskets;
procedure Tests is
begin
   Assert (Maximum ([1, 2, 1, 2, 3, 2, 2, 1]) = 4);
   Assert (Maximum ([1, 2, 3, 4, 1, 2, 3, 4]) = 2);
   Assert (Maximum ([1, 1, 1, 1, 1, 1, 1, 1]) = 8);
end Tests;
