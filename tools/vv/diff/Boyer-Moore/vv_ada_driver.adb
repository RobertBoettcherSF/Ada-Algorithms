pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Boyer_Moore;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values 0 .. 2) on stdin, maps values to 'a' .. 'c',
--  prints one result line per case. Text = first 16, Pattern = last 4; prints first match or 0.
procedure VV_Ada_Driver is
   use Boyer_Moore;
   N, V : Integer;
begin
   while not End_Of_File loop
      Get (N);
      declare
         S : String (1 .. N);
      begin
         for I in S'Range loop
            Get (V); S (I) := Character'Val (Character'Pos ('a') + V);
         end loop;
         declare
            M : constant Match_Index_Array := Search (S (17 .. 20), S (1 .. 16));
         begin
            Put (Integer'(if M'Length = 0 then 0 else M (M'First))'Image);
         end;
         New_Line;
      end;
   end loop;
end VV_Ada_Driver;
