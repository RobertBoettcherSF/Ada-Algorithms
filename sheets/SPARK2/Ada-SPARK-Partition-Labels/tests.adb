with Partition_Labels;
procedure Tests is
begin
   pragma Assert (Partition_Labels.Length_Of (0, 0) = 1);
   pragma Assert (Partition_Labels.Length_Of (3, 7) = 5);
   pragma Assert (Partition_Labels.Length_Of (10, 32) = 23);
end Tests;
