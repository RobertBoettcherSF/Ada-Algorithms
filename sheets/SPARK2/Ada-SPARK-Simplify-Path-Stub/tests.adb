with Ada.Assertions; use Ada.Assertions;
with Simplify_Path_Stub; use Simplify_Path_Stub;

procedure Tests is
   Path : constant Token_Array :=
     [Name, Name, Parent, Current, Name, Root, Name, Parent];
begin
   Assert (Simplified_Depth (Path) = 0);
   Assert (Simplified_Depth ([Name, Name, Parent, Current, Name, Name, Name, Name]) = 5);
end Tests;
