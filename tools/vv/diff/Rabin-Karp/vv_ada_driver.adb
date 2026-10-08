pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Rabin_Karp;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values 0 .. 2) on stdin, maps values to 'a' .. 'c',
--  prints one result line per case. Pattern = first 1 + N mod 4 chars, Text = the rest; prints whether found.
procedure VV_Ada_Driver is
   use Rabin_Karp;
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
            L : constant Positive := 1 + N mod 4;   --  pattern length 1 .. 4
         begin
            Put (Boolean'(Search (S (1 .. L), S (L + 1 .. N))'Length > 0)'Image);
         end;
         New_Line;
      end;
   end loop;
end VV_Ada_Driver;
