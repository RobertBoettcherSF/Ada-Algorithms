with Target_Sum_Stub;
procedure Tests is
   A : constant Target_Sum_Stub.Values := (1, 1, 1, 1, 1);
   B : constant Target_Sum_Stub.Values := (1, 2, 3, 4, 5);
begin
   pragma Assert (Target_Sum_Stub.Exists (A, 5));
   pragma Assert (Target_Sum_Stub.Exists (B, 3));
   pragma Assert (not Target_Sum_Stub.Exists (A, 4));
end Tests;
