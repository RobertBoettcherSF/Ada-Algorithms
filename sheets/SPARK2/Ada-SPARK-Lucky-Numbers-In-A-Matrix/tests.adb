pragma Ada_2022;
with Lucky_Numbers; use Lucky_Numbers;
procedure Tests is
   Input : Matrix := ((3, 7, 8, 9), (9, 11, 13, 10), (15, 16, 17, 18), (14, 20, 21, 22));
   Value : Pixel;
   Found : Boolean;
begin
   Find (Input, Value, Found);
   pragma Assert (Found and Value = 15);
end Tests;
