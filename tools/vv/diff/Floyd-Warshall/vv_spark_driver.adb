pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Floyd_Warshall; use Floyd_Warshall;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
--  Case = 4x4 weights 0 .. 79, value >= 50 means no edge, diagonal ignored; prints all-pairs distances (inf = unreachable).
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
         D : Distance_Matrix;
      begin
         for I in Node loop
            for J in Node loop
               D (I, J) := (if I = J then 0 elsif V (4 * (I - 1) + J) < 50 then V (4 * (I - 1) + J) else Infinity);
            end loop;
         end loop;
         Compute (D);
         for X of D loop
            if X = Infinity then Put (" inf"); else Put (X'Image); end if;
         end loop;
      end;
      New_Line;
   end loop;
end VV_SPARK_Driver;
