--  Own checks (see tests/SOURCES.txt): Compute must return a spanning tree of
--  minimum total weight. Reference: brute force over every parent array.
with Ada.Text_IO;
with Prims_Algorithm; use Prims_Algorithm;

procedure Own_Checks is
   Seed : Long_Long_Integer := 20261008;
   function Next (Bound : Positive) return Natural is
   begin
      Seed := (Seed * 16807) mod 2147483647;
      return Natural (Seed mod Long_Long_Integer (Bound));
   end Next;

   --  Parent array P is a spanning tree rooted at Node'First when every other
   --  node uses an existing edge to its parent and reaches the root.
   function Is_Tree (G : Weight_Matrix; P : Parent_Array) return Boolean is
      V : Node;
   begin
      for N in Node range Node'First + 1 .. Node'Last loop
         if P (N) = N or else G (P (N), N) = Infinity then
            return False;
         end if;
         V := N;
         for Step in 1 .. Capacity loop
            exit when V = Node'First;
            V := P (V);
         end loop;
         if V /= Node'First then
            return False;
         end if;
      end loop;
      return True;
   end Is_Tree;

   function Total (G : Weight_Matrix; P : Parent_Array) return Natural is
      S : Natural := 0;
   begin
      for N in Node range Node'First + 1 .. Node'Last loop
         S := S + G (P (N), N);
      end loop;
      return S;
   end Total;

   Best_Seen : Natural;
   procedure Search (G : Weight_Matrix; P : in out Parent_Array; N : Node) is
   begin
      for Q in Node loop
         P (N) := Q;
         if N = Node'Last then
            if Is_Tree (G, P) then
               Best_Seen := Natural'Min (Best_Seen, Total (G, P));
            end if;
         else
            Search (G, P, N + 1);
         end if;
      end loop;
   end Search;

   G : Weight_Matrix;
   P, Q : Parent_Array;
   Runs : Natural := 0;
begin
   while Runs < 5000 loop
      for I in Node loop
         G (I, I) := 0;
         for J in Node range I + 1 .. Node'Last loop
            if Next (10) < 3 then
               G (I, J) := Infinity;
            else
               G (I, J) := 1 + Next (20);
            end if;
            G (J, I) := G (I, J);
         end loop;
      end loop;
      Best_Seen := Natural'Last;
      Q := [others => Node'First];
      Search (G, Q, Node'First + 1);
      if Best_Seen /= Natural'Last then   --  connected graphs only
         Runs := Runs + 1;
         Compute (G, P);
         if not Is_Tree (G, P) or else Total (G, P) /= Best_Seen then
            Ada.Text_IO.Put_Line ("FAIL own check: Compute is not a minimum spanning tree (weight"
                                  & Natural'Image (Total (G, P)) & ", minimum"
                                  & Natural'Image (Best_Seen) & ")");
            raise Program_Error;
         end if;
      end if;
   end loop;
   Ada.Text_IO.Put_Line ("PASS own checks: 5000 connected graphs (own brute-force minimum spanning tree)");
end Own_Checks;
