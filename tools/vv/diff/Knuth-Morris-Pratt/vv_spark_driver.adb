pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with KMP;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values 0 .. 2) on stdin, maps values to 'a' .. 'c',
--  prints one result line per case. Prints the prefix (failure) table.
procedure VV_SPARK_Driver is
   use KMP;
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
            Pat : Char_Array (1 .. N);
            Pi  : Prefix_Table (1 .. N);
         begin
            for I in S'Range loop Pat (I) := S (I); end loop;
            Build_Prefix (Pat, Pi);
            for X of Pi loop Put (X'Image); end loop;
         end;
         New_Line;
      end;
   end loop;
end VV_SPARK_Driver;
