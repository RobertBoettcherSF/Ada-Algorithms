pragma Ada_2022;
with Find_The_Original_Array_Of_Prefix_XOR;
procedure Tests is
   use Find_The_Original_Array_Of_Prefix_XOR;
   Result : constant Original_Array := Recover ([5, 7, 0, 3]);
begin
   pragma Assert (Result = [5, 2, 7, 3]);
end Tests;
