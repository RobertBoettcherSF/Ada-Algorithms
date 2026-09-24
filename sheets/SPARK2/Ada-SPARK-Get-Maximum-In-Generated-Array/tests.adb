with Get_Maximum_In_Generated_Array;
procedure Tests is
begin
   pragma Assert (Get_Maximum_In_Generated_Array.Maximum (0) = 0);
   pragma Assert (Get_Maximum_In_Generated_Array.Maximum (7) = 3);
   pragma Assert (Get_Maximum_In_Generated_Array.Maximum (16) = 5);
end Tests;
