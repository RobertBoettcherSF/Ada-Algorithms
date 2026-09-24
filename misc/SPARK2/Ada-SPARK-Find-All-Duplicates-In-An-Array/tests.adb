with Find_All_Duplicates_In_An_Array;
procedure Tests is
   Input : constant Find_All_Duplicates_In_An_Array.Input_Array := [4, 3, 2, 7, 8, 2, 3, 1];
   Result : constant Find_All_Duplicates_In_An_Array.Output_Array := Find_All_Duplicates_In_An_Array.Duplicates (Input);
begin
   pragma Assert (Result (3) = 0);
   pragma Assert (Result (6) = 2);
   pragma Assert (Result (7) = 3);
end Tests;
