pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Linear_Search;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
--  First value = key (search) or rank seed (selection); the rest is the array.
procedure VV_SPARK_Driver is
   use Linear_Search;
   N, V, Key : Integer;
begin
   while not End_Of_File loop
      Get (N); Get (Key);
      declare
         A : Element_Array (1 .. N - 1);
      begin
         for I in A'Range loop
            Get (V); A (I) := V;
         end loop;
         Put (Integer (Find (A, Key))'Image); Put (Contains (A, Key)'Image);
         New_Line;
      end;
   end loop;
end VV_SPARK_Driver;
