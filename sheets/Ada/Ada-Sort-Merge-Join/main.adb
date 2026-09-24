with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Sort_Merge_Join; use Sort_Merge_Join;

procedure Main is
   -- Helper to quickly generate test rows
   function R(K : Integer; D : String) return Row is
   begin
      return (Key => Join_Key(K), Data => To_Unbounded_String(D));
   end R;

   Left   : Relation := (1 => R(3, "Alice"), 2 => R(1, "Bob"), 3 => R(2, "Charlie"));
   Right  : Relation := (1 => R(2, "HR"), 2 => R(3, "Engineering"), 3 => R(4, "Sales"));
   Result : Joined_Relation;
begin
   Put_Line ("=== Sort-Merge Join Demonstration ===");
   Put_Line ("Executing Inner Join (Auto_Sort active)...");
   Result := Inner_Join (Left, Right, Auto_Sort => True);
   
   Put_Line ("Join completed. Records found: " & Natural'Image(Natural(Result.Length)));
   for I in 1 .. Natural(Result.Length) loop
      Put_Line ("Match Key: " & Join_Key'Image(Result.Element(I).Left_Row.Key) &
                " | Left Data: " & To_String(Result.Element(I).Left_Row.Data) &
                " | Right Data: " & To_String(Result.Element(I).Right_Row.Data));
   end loop;
end Main;
