with Partition_Around_Pivot;
procedure Tests is
   use type Partition_Around_Pivot.Value_Array;
   Input : constant Partition_Around_Pivot.Value_Array := [-1, 5, 0, 3, 2];
   Expected : constant Partition_Around_Pivot.Value_Array := [-1, 0, 2, 5, 3];
begin
   pragma Assert (Partition_Around_Pivot.Partition (Input, 2) = Expected);
end Tests;
