pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Hamming_Distance;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values 0 .. 2) on stdin, maps values to 'a' .. 'c',
--  prints one result line per case. Two 3-bit vectors.
procedure VV_Ada_Driver is
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
            B1, B2 : Bit_Array (1 .. 3);
         begin
            for I in 1 .. 3 loop B1 (I) := S (I) = 'b'; B2 (I) := S (3 + I) = 'b'; end loop;
            Put (Distance (B1, B2)'Image);
         end;
         New_Line;
      end;
   end loop;
end VV_Ada_Driver;
