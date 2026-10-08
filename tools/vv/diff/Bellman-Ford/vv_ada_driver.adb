pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Bellman_Ford_Algorithm; use Bellman_Ford_Algorithm;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
--  Case = source value then 16 edges (U, V, W) with U, V = 1 + value mod 4, W in 0 .. 99; prints distances from the source (inf = unreachable).
procedure VV_Ada_Driver is
   N : Integer;
   V : array (1 .. 64) of Integer;
begin
   while not End_Of_File loop
      Get (N);
      for I in 1 .. N loop
         Get (V (I));
      end loop;
      declare
         G : Graph;
         D : Distance_Array (1 .. 4);
         P : Prev_Array (1 .. 4);
         S : Run_Status;
      begin
         Clear (G, 4);
         for E in 0 .. 15 loop
            Add_Edge (G, Vertex_Id (1 + V (2 + 3 * E) mod 4), Vertex_Id (1 + V (3 + 3 * E) mod 4), V (4 + 3 * E));
         end loop;
         Shortest_Paths (G, Vertex_Id (1 + V (1) mod 4), D, P, S);
         for X of D loop
            if X = Infinity then Put (" inf"); else Put (X'Image); end if;
         end loop;
      end;
      New_Line;
   end loop;
end VV_Ada_Driver;
