pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Long_Long_Integer_Text_IO; use Ada.Long_Long_Integer_Text_IO;
with Quantum_Sort;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
procedure VV_Ada_Driver is
   N, V : Long_Long_Integer;
begin
   while not End_Of_File loop
      Get (N);
      declare
         A : Quantum_Sort.Element_Array (1 .. Quantum_Sort.Index_Type'Base (N));
      begin
         for I in A'Range loop
            Get (V); A (I) := Quantum_Sort.Element_Value (V);
         end loop;
         Quantum_Sort.Sort_Comparison (A);
         for X of A loop
            Put (X'Image);
         end loop;
         New_Line;
      end;
   end loop;
end VV_Ada_Driver;
