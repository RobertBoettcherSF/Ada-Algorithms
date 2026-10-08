pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Sieve_Of_Eratosthenes; use Sieve_Of_Eratosthenes;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
--  Case = K in 1 .. 20 (SPARK Capacity); prints primality of K from the full sieve and from Is_Prime.
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
         F : Flags;
      begin
         Sieve (F); Put (F (Number (V (1)))'Image); Put (Is_Prime (Number (V (1)))'Image);
      end;
      New_Line;
   end loop;
end VV_SPARK_Driver;
