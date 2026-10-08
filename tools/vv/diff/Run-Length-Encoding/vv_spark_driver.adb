pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Run_Length_Encoding; use Run_Length_Encoding;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
--  Case = up to 32 bits; prints the number of runs (Ada: length of Encode_Binary).
procedure VV_SPARK_Driver is

   N : Long_Long_Integer;
   V : array (1 .. 64) of Long_Long_Integer;
begin
   while not End_Of_File loop
      Get (N);
      for I in 1 .. Integer (N) loop
         Get (V (I));
      end loop;
      declare
         C : Char_Array (1 .. Integer (N));
      begin
         for I in C'Range loop C (I) := (if V (I) = 1 then 'b' else 'a'); end loop;
         Put (Number_Of_Runs (C)'Image);
      end;
      New_Line;
   end loop;
end VV_SPARK_Driver;
