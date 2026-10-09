pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Topological_Sort_Lite; use Topological_Sort_Lite;
--  Own checks (H127). Topo_Sort (Edges, N, Order, Ok, Left): Ok exactly
--  when the graph on 1 .. N has no cycle; then Order (1 .. N) is a
--  permutation of 1 .. N with every edge pointing forward. References:
--  every permutation (N <= 6: exhaustive over all graphs on 1 .. 3 and
--  2,000 random graphs on 4 .. 6 vertices, self-loops included) and, for
--  random graphs up to Capacity, a depth-first cycle search; the order is
--  checked by our own position table. Is_Valid_Order is compared with the
--  same check (it must reject repeated vertices and self-loops). Seed
--  20261009.
procedure Own_Checks is
   Fails : Natural := 0;
   Cases : Natural := 0;
   Seed  : Long_Long_Integer := 20261009;

   function Rand (N : Positive) return Natural is
   begin
      Seed := (Seed * 16807) mod 2_147_483_647;
      return Natural (Seed mod Long_Long_Integer (N));
   end Rand;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      Cases := Cases + 1;
      if not Cond then
         Fails := Fails + 1;
         if Fails <= 5 then
            Put_Line ("FAIL " & Name);
         end if;
      end if;
   end Check;

   --  Order (1 .. N) is a permutation of 1 .. N with all edges forward.
   function Good (G : Graph; O : Order_Array; N : Vertex) return Boolean is
      Pos : array (Vertex) of Natural := [others => 0];
   begin
      for I in 1 .. N loop
         if O (I) > N or else Pos (O (I)) /= 0 then
            return False;
         end if;
         Pos (O (I)) := I;
      end loop;
      for U in 1 .. N loop
         for V in 1 .. N loop
            if G (U, V) and then Pos (U) >= Pos (V) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Good;

   --  Depth-first search: a cycle among 1 .. N?
   function Cyclic (G : Graph; N : Vertex) return Boolean is
      Color : array (Vertex) of Natural := [others => 0];   --  0 new, 1 on path, 2 done
      Found : Boolean := False;
      procedure Visit (U : Vertex) is
      begin
         Color (U) := 1;
         for V in 1 .. N loop
            if G (U, V) then
               if Color (V) = 1 then
                  Found := True;
               elsif Color (V) = 0 then
                  Visit (V);
               end if;
            end if;
         end loop;
         Color (U) := 2;
      end Visit;
   begin
      for U in 1 .. N loop
         if Color (U) = 0 then
            Visit (U);
         end if;
      end loop;
      return Found;
   end Cyclic;

   --  Is there a permutation with all edges forward (all N! orders)?
   function Some_Order (G : Graph; N : Vertex) return Boolean is
      P    : Order_Array := [others => 1];
      Used : array (Vertex) of Boolean := [others => False];
      function Try (K : Positive) return Boolean is
      begin
         if K > N then
            return Good (G, P, N);
         end if;
         for V in 1 .. N loop
            if not Used (V) then
               Used (V) := True;
               P (K) := V;
               if Try (K + 1) then
                  Used (V) := False;
                  return True;
               end if;
               Used (V) := False;
            end if;
         end loop;
         return False;
      end Try;
   begin
      return Try (1);
   end Some_Order;

   procedure Run (G : Graph; N : Vertex; Small : Boolean; Tag : String) is
      O    : Order_Array;
      Ok   : Boolean;
      Left : Vertex_Set;
      Want : constant Boolean := (if Small then Some_Order (G, N) else not Cyclic (G, N));
   begin
      Topo_Sort (G, N, O, Ok, Left);
      Check (Ok = Want, "Ok" & Tag);
      if Ok then
         Check (Good (G, O, N), "order" & Tag);
         Check (Is_Valid_Order (G, O, N), "Is_Valid_Order accepts the result" & Tag);
      end if;
      --  a random order: Is_Valid_Order must agree with Good
      for I in 1 .. N loop
         O (I) := 1 + Rand (N);
      end loop;
      Check (Is_Valid_Order (G, O, N) = Good (G, O, N), "Is_Valid_Order random order" & Tag);
   end Run;

   G : Graph;
begin
   for N in 1 .. 3 loop
      for M in 0 .. 2 ** (N * N) - 1 loop
         G := [others => [others => False]];
         for U in 1 .. N loop
            for V in 1 .. N loop
               G (U, V) := (M / 2 ** ((U - 1) * N + V - 1)) mod 2 = 1;
            end loop;
         end loop;
         Run (G, N, True, " exhaustive N =" & N'Image & " M =" & M'Image);
      end loop;
   end loop;
   for T in 1 .. 2_000 loop
      declare
         N : constant Vertex := 4 + Rand (3);
         P : constant Natural := Rand (40);
      begin
         G := [others => [others => False]];
         for U in 1 .. N loop
            for V in 1 .. N loop
               G (U, V) := Rand (100) < P and then (U < V or else Rand (8) = 0);
            end loop;
         end loop;
         Run (G, N, True, " small random" & T'Image);
      end;
   end loop;
   for T in 1 .. 300 loop
      declare
         N : constant Vertex := 1 + Rand (Capacity);
         P : constant Natural := Rand (10);
         Back : constant Boolean := Rand (2) = 0;
      begin
         G := [others => [others => False]];
         for U in 1 .. N loop
            for V in 1 .. N loop
               --  edges along a hidden random-ish rank, plus rare back edges
               G (U, V) := Rand (100) < P and then ((U * 7) mod N < (V * 7) mod N
                                                     or else (Back and then Rand (500) = 0));
            end loop;
         end loop;
         Run (G, N, False, " large random" & T'Image & " N =" & N'Image);
      end;
   end loop;
   if Fails = 0 then
      Put_Line ("PASS Topological_Sort_Lite own checks:" & Cases'Image & " checks (seed 20261009)");
   else
      Put_Line ("FAILED" & Fails'Image & " of" & Cases'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
