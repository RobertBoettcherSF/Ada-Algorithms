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
   Hello5 : constant Char_Array (5 .. 9) := ['h', 'e', 'l', 'l', 'o'];
   Hello_Top : constant Char_Array (Positive'Last - 4 .. Positive'Last) :=
     ['h', 'e', 'l', 'l', 'o'];
   Empty_At_9 : constant Char_Array (9 .. 8) := [others => ' '];
begin
   Check (H1 /= H2, "hello and world differ");
   --  Values from the plain-Ada twin (same table, same algorithm)
   Check (H1 = 185, "hello -> 185");
   Check (H2 = 209, "world -> 209");
   Check (Hash ("a") = 113, "a -> 113");
   Check (Hash (Empty) = 0, "empty input -> 0");
   --  First-relative: the same characters at any origin give the same value
   --  (origins 1, 5 and storage ending at Positive'Last).
   Check (Hash (Hello5) = 185, "hello at origin 5 -> 185");
   Check (Hash (Hello_Top) = 185, "hello ending at Positive'Last -> 185");
   Check (Hash (Empty_At_9) = 0, "empty at origin 9 -> 0");
   if Failures = 0 then
      Put_Line ("PASS Pearson_Hashing");
   else
      Put_Line ("FAIL" & Failures'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
