with Search_Insert_Position;
procedure Tests is
   Data : constant Search_Insert_Position.Sorted_Array :=
     (1, 3, 5, 6, others => 100);
begin
   pragma Assert (Search_Insert_Position.Position (Data, 5) = 3);
   pragma Assert (Search_Insert_Position.Position (Data, 2) = 2);
   pragma Assert (Search_Insert_Position.Position (Data, 7) = 5);
end Tests;
