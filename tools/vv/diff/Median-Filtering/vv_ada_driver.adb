pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Median_Filter;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
procedure VV_Ada_Driver is
   N, V : Long_Long_Integer;
begin
   while not End_Of_File loop
      Get (N);
      declare
         D : Median_Filter.Data_2D (1 .. 8, 1 .. 8);
      begin
         for R in 1 .. 8 loop
            for C in 1 .. 8 loop
               Get (V); D (R, C) := Integer (V);
            end loop;
         end loop;
         declare
            O : constant Median_Filter.Data_2D := Median_Filter.Process_2D (D, 3);
         begin
            for R in O'Range (1) loop
               for C in O'Range (2) loop
                  Put (O (R, C)'Image);
               end loop;
            end loop;
            New_Line;
         end;
      end;
   end loop;
end VV_Ada_Driver;
