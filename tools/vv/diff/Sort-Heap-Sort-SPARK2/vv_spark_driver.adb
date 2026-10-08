pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Heap_Sort;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
procedure VV_Spark_Driver is
   N, V : Long_Long_Integer;
begin
   while not End_Of_File loop
      Get (N);
      declare
         A : Heap_Sort.Input_Array;
      begin
         for I in A'Range loop
            Get (V); A (I) := Integer (V);
         end loop;
         declare
            R : constant Heap_Sort.Input_Array := Heap_Sort.Sort (A);
         begin
            for X of R loop
               Put (X'Image);
            end loop;
         end;
         New_Line;
      end;
   end loop;
end VV_Spark_Driver;
