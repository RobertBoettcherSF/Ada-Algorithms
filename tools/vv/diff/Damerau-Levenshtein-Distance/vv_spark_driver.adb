pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Damerau_Levenshtein_Distance;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values 0 .. 2) on stdin, maps values to 'a' .. 'c',
--  prints one result line per case. A = first half, B = second half.
procedure VV_SPARK_Driver is
   use Damerau_Levenshtein_Distance;
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
            A : Char_Array (1 .. N / 2);
            B : Char_Array (1 .. N - N / 2);
         begin
            for I in A'Range loop A (I) := S (I); end loop;
            for I in B'Range loop B (I) := S (N / 2 + I); end loop;
            Put (Distance (A, B)'Image);
         end;
         New_Line;
      end;
   end loop;
end VV_SPARK_Driver;
