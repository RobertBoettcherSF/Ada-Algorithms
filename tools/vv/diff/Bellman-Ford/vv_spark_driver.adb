pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Bellman_Ford_Algorithm; use Bellman_Ford_Algorithm;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
--  Case = source value then 16 edges (U, V, W) with U, V = 1 + value mod 4, W in 0 .. 99; prints distances from the source (inf = unreachable).
procedure VV_SPARK_Driver is
   N : Integer;
   V : array (1 .. 64) of Integer;
begin
   while not End_Of_File loop
      Get (N);
      for I in 1 .. N loop
         Get (V (I));
      end loop;
      declare
         E : Edge_Array;
         D : Distance_Array;
      begin
         for I in Edge_Index loop
            E (I) := (U => 1 + V (3 * I - 1) mod 4, V => 1 + V (3 * I) mod 4, Weight => V (3 * I + 1));
         end loop;
         Compute (E, 1 + V (1) mod 4, D);
         for X of D loop
            if X = Infinity then Put (" inf"); else Put (X'Image); end if;
         end loop;
      end;
      New_Line;
   end loop;
end VV_SPARK_Driver;
