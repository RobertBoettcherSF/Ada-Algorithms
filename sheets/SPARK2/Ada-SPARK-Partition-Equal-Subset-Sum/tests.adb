with Partition_Equal_Subset_Sum;
procedure Tests is
   A : constant Partition_Equal_Subset_Sum.Values := (1, 5, 9, 5, 2, 2);
   B : constant Partition_Equal_Subset_Sum.Values := (1, 2, 3, 5, 7, 9);
   C : constant Partition_Equal_Subset_Sum.Values := (0, 0, 0, 0, 0, 0);
begin
   pragma Assert (Partition_Equal_Subset_Sum.Can_Partition (A));
   pragma Assert (not Partition_Equal_Subset_Sum.Can_Partition (B));
   pragma Assert (Partition_Equal_Subset_Sum.Can_Partition (C));
end Tests;
