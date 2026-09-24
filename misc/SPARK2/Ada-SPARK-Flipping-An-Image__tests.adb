pragma Ada_2022;
with Flipping_An_Image; use Flipping_An_Image;
procedure Tests is
   Picture : Image := ((1, 1, 0, 0), (1, 0, 0, 1), (0, 1, 1, 1), (1, 0, 1, 0));
begin
   Flip_And_Invert (Picture);
   pragma Assert (Picture = ((1, 1, 0, 0), (0, 1, 1, 0), (0, 0, 0, 1), (1, 0, 1, 0)));
end Tests;
