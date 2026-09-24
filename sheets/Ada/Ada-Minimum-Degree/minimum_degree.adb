--  Minimum_Degree body — classical elimination ordering on an explicit
--  undirected boolean adjacency graph (educational; n ≤ 32).

pragma Ada_2022;

package body Minimum_Degree
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Construction / queries
   -------------------------------------------------------------------------

   function Empty_Graph (N : Vertex_Count) return Graph is
   begin
      return (N => N, Adj => [others => [others => False]]);
   end Empty_Graph;

   procedure Clear (G : in out Graph) is
   begin
      for I in 1 .. G.N loop
         for J in 1 .. G.N loop
            G.Adj (I, J) := False;
         end loop;
      end loop;
   end Clear;

   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id) is
   begin
      if U not in 1 .. G.N or else V not in 1 .. G.N then
         raise Invalid_Argument with "Add_Edge: vertex out of range";
      end if;
      if U = V then
         return;
      end if;
      G.Adj (U, V) := True;
      G.Adj (V, U) := True;
   end Add_Edge;

   function Has_Edge (G : Graph; U, V : Vertex_Id) return Boolean is
   begin
      if U not in 1 .. G.N or else V not in 1 .. G.N then
         return False;
      end if;
      return G.Adj (U, V);
   end Has_Edge;

   function Degree (G : Graph; V : Vertex_Id) return Natural is
      D : Natural := 0;
   begin
      for W in 1 .. G.N loop
         if G.Adj (V, W) then
            D := D + 1;
         end if;
      end loop;
      return D;
   end Degree;

   function Edge_Count (G : Graph) return Natural is
      C : Natural := 0;
   begin
      for I in 1 .. G.N loop
         for J in I + 1 .. G.N loop
            if G.Adj (I, J) then
               C := C + 1;
            end if;
         end loop;
      end loop;
      return C;
   end Edge_Count;

   function Is_Symmetric_Pattern (G : Graph) return Boolean is
   begin
      for I in 1 .. G.N loop
         if G.Adj (I, I) then
            return False;
         end if;
         for J in I + 1 .. G.N loop
            if G.Adj (I, J) /= G.Adj (J, I) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Symmetric_Pattern;

   -------------------------------------------------------------------------
   -- Textbook builders
   -------------------------------------------------------------------------

   function Path_Graph (N : Vertex_Count) return Graph is
      G : Graph := Empty_Graph (N);
   begin
      for I in 1 .. N - 1 loop
         Add_Edge (G, I, I + 1);
      end loop;
      return G;
   end Path_Graph;

   function Cycle_Graph (N : Vertex_Count) return Graph is
      G : Graph := Path_Graph (N);
   begin
      Add_Edge (G, 1, N);
      return G;
   end Cycle_Graph;

   function Star_Graph (N : Vertex_Count) return Graph is
      G : Graph := Empty_Graph (N);
   begin
      for Leaf in 2 .. N loop
         Add_Edge (G, 1, Leaf);
      end loop;
      return G;
   end Star_Graph;

   function Clique_Graph (N : Vertex_Count) return Graph is
      G : Graph := Empty_Graph (N);
   begin
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            Add_Edge (G, I, J);
         end loop;
      end loop;
      return G;
   end Clique_Graph;

   function Band_Graph (N : Vertex_Count; Bandwidth : Natural) return Graph is
      G : Graph := Empty_Graph (N);
   begin
      if Bandwidth = 0 then
         return G;
      end if;
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            if Natural (J - I) <= Bandwidth then
               Add_Edge (G, I, J);
            end if;
         end loop;
      end loop;
      return G;
   end Band_Graph;

   -------------------------------------------------------------------------
   -- Ordering helpers
   -------------------------------------------------------------------------

   function Natural_Order (G : Graph) return Order is
      Ord : Order (1 .. G.N);
   begin
      for I in 1 .. G.N loop
         Ord (I) := I;
      end loop;
      return Ord;
   end Natural_Order;

   function Reverse_Natural_Order (G : Graph) return Order is
      Ord : Order (1 .. G.N);
   begin
      for I in 1 .. G.N loop
         Ord (I) := G.N - I + 1;
      end loop;
      return Ord;
   end Reverse_Natural_Order;

   function Is_Valid_Order (G : Graph; Ord : Order) return Boolean is
      Seen : array (1 .. Max_Vertices) of Boolean := [others => False];
   begin
      if Ord'Length /= G.N then
         return False;
      end if;
      if G.N = 0 then
         return True;
      end if;
      for K in Ord'Range loop
         if Ord (K) not in 1 .. G.N then
            return False;
         end if;
         if Seen (Ord (K)) then
            return False;
         end if;
         Seen (Ord (K)) := True;
      end loop;
      for V in 1 .. G.N loop
         if not Seen (V) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Order;

   -------------------------------------------------------------------------
   -- Elimination simulation (shared by MD order and fill counters)
   -------------------------------------------------------------------------

   type Remaining_Flags is array (Vertex_Id range <>) of Boolean;

   --  Current degree of V among Remaining vertices in Working adjacency.
   function Current_Degree
     (Working   : Bool_Matrix;
      Remaining : Remaining_Flags;
      V         : Vertex_Id;
      N         : Vertex_Count) return Natural
   is
      D : Natural := 0;
   begin
      for W in 1 .. N loop
         if Remaining (W) and then Working (V, W) then
            D := D + 1;
         end if;
      end loop;
      return D;
   end Current_Degree;

   --  Simulate elimination of Ord: return fill count; optionally mutate
   --  Working in place through the full elimination (caller owns copy).
   function Simulate_Fill
     (G   : Graph;
      Ord : Order) return Natural
   is
      N         : constant Vertex_Count := G.N;
      Working   : Bool_Matrix (1 .. N, 1 .. N);
      Remaining : array (1 .. N) of Boolean := [others => True];
      Fill      : Natural := 0;
   begin
      if not Is_Valid_Order (G, Ord) then
         raise Invalid_Argument with "Simulate_Fill: invalid order";
      end if;
      for I in 1 .. N loop
         for J in 1 .. N loop
            Working (I, J) := G.Adj (I, J);
         end loop;
      end loop;

      for Step in Ord'Range loop
         declare
            V : constant Vertex_Id := Ord (Step);
         begin
            if not Remaining (V) then
               raise Invalid_Argument with "Simulate_Fill: duplicate elim";
            end if;
            --  Clique the remaining neighbors of V (add missing edges).
            for U in 1 .. N loop
               if Remaining (U) and then Working (V, U) then
                  for W in U + 1 .. N loop
                     if Remaining (W) and then Working (V, W) then
                        if not Working (U, W) then
                           Working (U, W) := True;
                           Working (W, U) := True;
                           Fill := Fill + 1;
                        end if;
                     end if;
                  end loop;
               end if;
            end loop;
            Remaining (V) := False;
         end;
      end loop;
      return Fill;
   end Simulate_Fill;

   function Minimum_Degree_Order (G : Graph) return Order is
      N         : constant Vertex_Count := G.N;
      Ord       : Order (1 .. N);
      Working   : Bool_Matrix (1 .. N, 1 .. N);
      Remaining : Remaining_Flags (1 .. N) := [others => True];
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            Working (I, J) := G.Adj (I, J);
         end loop;
      end loop;

      for Step in 1 .. N loop
         declare
            Best_V : Vertex_Id := 1;
            Best_D : Natural := Natural'Last;
            Found  : Boolean := False;
         begin
            for V in 1 .. N loop
               if Remaining (V) then
                  declare
                     D : constant Natural :=
                       Current_Degree (Working, Remaining, V, N);
                  begin
                     if not Found or else D < Best_D
                       or else (D = Best_D and then V < Best_V)
                     then
                        Best_V := V;
                        Best_D := D;
                        Found  := True;
                     end if;
                  end;
               end if;
            end loop;
            if not Found then
               raise Invalid_Argument with "MD: no remaining vertex";
            end if;

            Ord (Step) := Best_V;

            --  Add fill among remaining neighbors of Best_V.
            for U in 1 .. N loop
               if Remaining (U) and then Working (Best_V, U) then
                  for W in U + 1 .. N loop
                     if Remaining (W) and then Working (Best_V, W) then
                        if not Working (U, W) then
                           Working (U, W) := True;
                           Working (W, U) := True;
                        end if;
                     end if;
                  end loop;
               end if;
            end loop;

            Remaining (Best_V) := False;
         end;
      end loop;
      return Ord;
   end Minimum_Degree_Order;

   function Fill_In_Count (G : Graph; Ord : Order) return Natural is
   begin
      return Simulate_Fill (G, Ord);
   end Fill_In_Count;

   function Filled_Edge_Count (G : Graph; Ord : Order) return Natural is
   begin
      return Edge_Count (G) + Fill_In_Count (G, Ord);
   end Filled_Edge_Count;

   function Symbolic_Cholesky_Nnz (G : Graph; Ord : Order) return Natural is
   begin
      --  Diagonal N plus one lower entry per undirected filled edge.
      return Natural (G.N) + Filled_Edge_Count (G, Ord);
   end Symbolic_Cholesky_Nnz;

   function Natural_Fill (G : Graph) return Natural is
   begin
      return Fill_In_Count (G, Natural_Order (G));
   end Natural_Fill;

   function MD_Fill (G : Graph) return Natural is
   begin
      return Fill_In_Count (G, Minimum_Degree_Order (G));
   end MD_Fill;

   function Fill_Reduction (G : Graph) return Integer is
   begin
      return Integer (Natural_Fill (G)) - Integer (MD_Fill (G));
   end Fill_Reduction;

   -------------------------------------------------------------------------
   -- Taxonomy
   -------------------------------------------------------------------------

   function Method_Name (M : Method_Kind) return String is
   begin
      case M is
         when Classical_Minimum_Degree =>
            return "Classical Minimum Degree";
         when Multiple_Minimum_Degree =>
            return "Multiple Minimum Degree (MMD)";
         when Approximate_Minimum_Degree =>
            return "Approximate Minimum Degree (AMD)";
         when Nested_Dissection =>
            return "Nested Dissection";
      end case;
   end Method_Name;

   function Implemented (M : Method_Kind) return Boolean is
   begin
      return M = Classical_Minimum_Degree;
   end Implemented;

   function Forthcoming (M : Method_Kind) return Boolean is
   begin
      return not Implemented (M);
   end Forthcoming;

end Minimum_Degree;
