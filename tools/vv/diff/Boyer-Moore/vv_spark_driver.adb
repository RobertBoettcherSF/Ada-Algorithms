pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Boyer_Moore;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values 0 .. 2) on stdin, maps values to 'a' .. 'c',
--  prints one result line per case. Text = first 16, Pattern = last 4; prints first match or 0.
procedure VV_SPARK_Driver is
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
            T : Text_Array;
            P : Pattern_Array;
         begin
            for I in T'Range loop T (I) := S (I); end loop;
            for I in P'Range loop P (I) := S (16 + I); end loop;
            Put (Integer (Search (T, P))'Image);
         end;
         New_Line;
      end;
   end loop;
end VV_SPARK_Driver;
