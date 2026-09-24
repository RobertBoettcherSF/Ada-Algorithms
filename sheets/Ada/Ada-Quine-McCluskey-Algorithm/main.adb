with Ada.Text_IO; use Ada.Text_IO;
with Quine_McCluskey; use Quine_McCluskey;

procedure Main is
   -- Solving: f(A,B,C,D) = sum m(4,8,10,11,12,15) + sum d(9,14)
   Minterms   : Minterm_Array := (4, 8, 10, 11, 12, 15);
   Dont_Cares : Minterm_Array := (9, 14);
   Solution   : Implicant_List;
begin
   Put_Line ("Quine-McCluskey Logic Minimizer");
   Put_Line ("Solving: 4 variables, minterms(4,8,10,11,12,15) and don't cares(9,14)");
   
   Solution := Minimize_Exact (4, Minterms, Dont_Cares);
   
   Put_Line ("Minimal sum of products (Petrick's Exact Method):");
   for PI of Solution loop
      Put_Line ("  -> " & PI);
   end loop;
end Main;
