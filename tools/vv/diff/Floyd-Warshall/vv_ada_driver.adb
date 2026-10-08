pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Floyd_Warshall_Algorithm; use Floyd_Warshall_Algorithm;
--  Differential-test driver (tools/vv/difftest.py): reads one case per
--  line (count, then values) on stdin, prints one result line per case.
--  Case = 4x4 weights 0 .. 79, value >= 50 means no edge, diagonal ignored; prints all-pairs distances (inf = unreachable).
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
         D : Dist_Matrix (1 .. 4, 1 .. 4);
         S : Run_Status;
      begin
         Clear (G, 4);
         for I in 1 .. 4 loop
            for J in 1 .. 4 loop
               if I /= J and then V (4 * (I - 1) + J) < 50 then
                  Add_Edge (G, Vertex_Id (I), Vertex_Id (J), V (4 * (I - 1) + J));
               end if;
            end loop;
         end loop;
         Floyd_Warshall (G, D, S);
         for X of D loop
            if X = Infinity then Put (" inf"); else Put (X'Image); end if;
         end loop;
      end;
      New_Line;
   end loop;
end VV_Ada_Driver;
