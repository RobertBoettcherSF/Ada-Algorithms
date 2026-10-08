pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Package_Merge; use Package_Merge;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
--  First value picks the length limit L (feasible minimum .. 16), the rest
--  are the 2 .. 32 frequencies. Prints the weighted code length sum and
--  whether every length is in 1 .. L (twice: Ada runs two variants).
procedure VV_Ada_Driver is
   N, Seed, M, L : Integer;
   W : array (1 .. 64) of Integer;
   procedure Put_Cost (C : Code_Lengths) is
      S : Long_Long_Integer := 0; Ok : Boolean := True;
   begin
      for I in C'Range loop
         S := S + Long_Long_Integer (W (Integer (I))) * Long_Long_Integer (C (I));
         Ok := Ok and then C (I) in 1 .. L;
      end loop;
      Put (S'Image); Put (if Ok then " ok" else " BAD-LENGTH");
   end Put_Cost;
begin
   while not End_Of_File loop
      Get (N); Get (Seed); M := N - 1;
      for I in 1 .. M loop Get (W (I)); end loop;
      L := 1;
      while 2 ** L < M loop L := L + 1; end loop;
      L := Integer'Min (16, L + Seed mod 6);
         declare
            F : Symbol_Frequencies (1 .. Symbol_Index (M));
         begin
            for I in 1 .. M loop F (Symbol_Index (I)) := Weight_Type (W (I)); end loop;
            Put_Cost (Huffman_Via_Coin_Collector (F, L)); Put_Cost (Space_Efficient_Huffman (F, L));
         end;
      New_Line;
   end loop;
end VV_Ada_Driver;
