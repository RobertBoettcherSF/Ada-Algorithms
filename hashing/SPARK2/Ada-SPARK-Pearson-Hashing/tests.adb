pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Pearson_Hashing;
use Pearson_Hashing;
procedure Tests is
   Failures : Natural := 0;

   procedure Check (Ok : Boolean; Name : String) is
   begin
      if Ok then
         Put_Line ("PASS " & Name);
      else
         Put_Line ("FAIL " & Name);
         Failures := Failures + 1;
      end if;
   end Check;

   H1 : constant Hash_Value := Hash ("hello");
   H2 : constant Hash_Value := Hash ("world");
   Empty : constant Char_Array (1 .. 0) := [others => ' '];
begin
   Check (H1 /= H2, "hello and world differ");
   --  Values from the plain-Ada twin (same table, same algorithm)
   Check (H1 = 185, "hello -> 185");
   Check (H2 = 209, "world -> 209");
   Check (Hash ("a") = 113, "a -> 113");
   Check (Hash (Empty) = 0, "empty input -> 0");
   if Failures = 0 then
      Put_Line ("PASS Pearson_Hashing");
   else
      Put_Line ("FAIL" & Failures'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
