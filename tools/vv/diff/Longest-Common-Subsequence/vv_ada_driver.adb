pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Longest_Common_Subsequence;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values 0 .. 2) on stdin, maps values to 'a' .. 'c',
--  prints one result line per case. A = first half, B = second half.
procedure VV_Ada_Driver is
   use Longest_Common_Subsequence;
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
            A : constant String := S (1 .. N / 2);
            B : constant String := S (N / 2 + 1 .. N);
         begin
            Put (Length (A, B)'Image);  Put (Length_Space_Optimized (A, B)'Image);
         end;
         New_Line;
      end;
   end loop;
end VV_Ada_Driver;
