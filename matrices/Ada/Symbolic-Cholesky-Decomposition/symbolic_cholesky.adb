-- symbolic_cholesky.adb
-- Implementation of the Symbolic Cholesky algorithms.

package body Symbolic_Cholesky is

   function Elimination_Game (A : Matrix) return Matrix is
      N : constant Natural := A'Length(1);
      
      -- Initialize return matrix L to false everywhere initially.
      L : Matrix (A'Range(1), A'Range(2)) := (others => (others => False));
      
      -- The elimination graph G* that accrues fill-in edges.
      G_Star : Matrix (A'Range(1), A'Range(2));
   begin
      -- Validate input constraints
      if A'Length(1) /= A'Length(2) then
         raise Invalid_Matrix;
      end if;

      if N = 0 then
         return L; -- Edge case: Empty matrix
      end if;

      -- Initialize elimination graph with original structure A
      G_Star := A;
      
      -- Diagonal elements in L are always structurally non-zero
      for I in A'Range(1) loop
         L (I, I) := True;
      end loop;

      -- Iterate over each vertex (column elimination step)
      for I in A'First(1) .. A'Last(1) loop
         
         -- 1. Clique Formation: 
         -- For all neighbors of I (where J > I), they must become connected.
         for J in I + 1 .. A'Last(1) loop
            if G_Star (I, J) then
               for K in J + 1 .. A'Last(1) loop
                  if G_Star (I, K) then
                     -- Add fill-in edges to the elimination graph
                     G_Star (J, K) := True;
                     G_Star (K, J) := True;
                  end if;
               end loop;
            end if;
         end loop;

         -- 2. Extract L pattern:
         -- The non-zero pattern of L's column I below the diagonal is 
         -- exactly the neighbors of I in G* with index > I.
         for J in I + 1 .. A'Last(1) loop
            if G_Star (I, J) then
               L (J, I) := True; 
            end if;
         end loop;
         
      end loop;

      return L;
   end Elimination_Game;

   function Compute_Elimination_Tree (L : Matrix) return Tree_Array is
      Tree : Tree_Array (L'Range(2)) := (others => 0);
   begin
      if L'Length(1) /= L'Length(2) then
         raise Invalid_Matrix;
      end if;

      if L'Length(1) = 0 then
         return Tree;
      end if;

      -- For each column J, the parent is the row index I of the first 
      -- off-diagonal non-zero element in column J.
      for J in L'First(2) .. L'Last(2) loop
         for I in J + 1 .. L'Last(1) loop
            if L (I, J) then
               Tree (J) := I;
               exit; -- Found the smallest I > J, moving to next column
            end if;
         end loop;
      end loop;

      return Tree;
   end Compute_Elimination_Tree;

end Symbolic_Cholesky;
