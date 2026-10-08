pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Hamming_Distance;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values 0 .. 2) on stdin, maps values to 'a' .. 'c',
--  prints one result line per case. Two 3-bit vectors.
procedure VV_SPARK_Driver is
   use Hamming_Distance;
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
            V1, V2 : Vector;
         begin
            for I in Index loop V1 (I) := (if S (I) = 'b' then 1 else 0); V2 (I) := (if S (3 + I) = 'b' then 1 else 0); end loop;
            Put (Distance (V1, V2)'Image);
         end;
         New_Line;
      end;
   end loop;
end VV_SPARK_Driver;
