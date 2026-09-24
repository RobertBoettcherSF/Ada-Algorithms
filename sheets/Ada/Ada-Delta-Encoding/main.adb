with Ada.Text_IO; use Ada.Text_IO;
with Delta_Encoding; use Delta_Encoding;

procedure Main is
   Data : constant Integer_Array := (2, 4, 6, 9, 7);
   Encoded : Integer_Array (Data'Range);
begin
   Put_Line ("Delta Encoding Application");
   Put_Line ("Original values: 2, 4, 6, 9, 7");
   
   Encoded := Encode_Integer_Delta (Data);
   
   Put ("Encoded deltas:  ");
   for I in Encoded'Range loop
      Put (Integer'Image (Encoded (I)) & " ");
   end loop;
   New_Line;
end Main;
