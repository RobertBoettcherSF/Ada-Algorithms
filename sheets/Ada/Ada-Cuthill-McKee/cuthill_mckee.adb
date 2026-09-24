--  Cuthill_Mckee body — CM / RCM bandwidth-reducing orderings on an
--  explicit undirected boolean adjacency graph (educational; n ≤ 32).

pragma Ada_2022;

package body Cuthill_Mckee
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

   function Band_Graph
     (N : Vertex_Count; Half_Bandwidth : Natural) return Graph
   is
      G : Graph := Empty_Graph (N);
   begin
      if Half_Bandwidth = 0 then
         return G;
      end if;
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            if Natural (J - I) <= Half_Bandwidth then
               Add_Edge (G, I, J);
            end if;
         end loop;
      end loop;
      return G;
   end Band_Graph;

   function Grid_Graph (Rows, Cols : Positive) return Graph is
      N : constant Vertex_Count := Rows * Cols;
      G : Graph := Empty_Graph (N);

      function Id (R, C : Positive) return Vertex_Id is
         (Vertex_Id ((R - 1) * Cols + C));
   begin
      for R in 1 .. Rows loop
         for C in 1 .. Cols loop
            if C < Cols then
               Add_Edge (G, Id (R, C), Id (R, C + 1));
            end if;
            if R < Rows then
               Add_Edge (G, Id (R, C), Id (R + 1, C));
            end if;
         end loop;
      end loop;
      return G;
   end Grid_Graph;

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

   function Reverse_Order (Ord : Order) return Order is
      Rev : Order (Ord'Range);
   begin
      if Ord'Length = 0 then
         return Rev;
      end if;
      for K in 0 .. Ord'Length - 1 loop
         Rev (Ord'First + K) := Ord (Ord'Last - K);
      end loop;
      return Rev;
   end Reverse_Order;

   -------------------------------------------------------------------------
   -- Bandwidth / profile
   -------------------------------------------------------------------------

   function Bandwidth (G : Graph) return Natural is
      BW : Natural := 0;
   begin
      for I in 1 .. G.N loop
         for J in I + 1 .. G.N loop
            if G.Adj (I, J) then
               declare
                  D : constant Natural := Natural (J - I);
               begin
                  if D > BW then
                     BW := D;
                  end if;
               end;
            end if;
         end loop;
      end loop;
      return BW;
   end Bandwidth;

   function Bandwidth (G : Graph; Ord : Order) return Natural is
      New_Label : array (1 .. Max_Vertices) of Natural := [others => 0];
      BW        : Natural := 0;
      Pos       : Natural := 0;
   begin
      for K in Ord'Range loop
         Pos := Pos + 1;
         New_Label (Ord (K)) := Pos;
      end loop;
      for I in 1 .. G.N loop
         for J in I + 1 .. G.N loop
            if G.Adj (I, J) then
               declare
                  D : constant Natural :=
                    abs (Integer (New_Label (I)) - Integer (New_Label (J)));
               begin
                  if D > BW then
                     BW := D;
                  end if;
               end;
            end if;
         end loop;
      end loop;
      return BW;
   end Bandwidth;

   function Profile (G : Graph) return Natural is
      P : Natural := 0;
   begin
      for I in 1 .. G.N loop
         declare
            Lo : Vertex_Id := I;
         begin
            for J in 1 .. I loop
               if G.Adj (I, J) or else J = I then
                  Lo := J;
                  exit;
               end if;
            end loop;
            P := P + Natural (I - Lo);
         end;
      end loop;
      return P;
   end Profile;

   function Profile (G : Graph; Ord : Order) return Natural is
      New_Label : array (1 .. Max_Vertices) of Natural := [others => 0];
      --  Work adjacency in new labels 1 .. N
      Work      : Bool_Matrix (1 .. G.N, 1 .. G.N) :=
        [others => [others => False]];
      P         : Natural := 0;
      Pos       : Natural := 0;
   begin
      for K in Ord'Range loop
         Pos := Pos + 1;
         New_Label (Ord (K)) := Pos;
      end loop;
      for I in 1 .. G.N loop
         for J in I + 1 .. G.N loop
            if G.Adj (I, J) then
               declare
                  A : constant Vertex_Id := Vertex_Id (New_Label (I));
                  B : constant Vertex_Id := Vertex_Id (New_Label (J));
               begin
                  Work (A, B) := True;
                  Work (B, A) := True;
               end;
            end if;
         end loop;
      end loop;
      for I in 1 .. G.N loop
         declare
            Lo : Vertex_Id := I;
         begin
            for J in 1 .. I loop
               if Work (I, J) or else J = I then
                  Lo := J;
                  exit;
               end if;
            end loop;
            P := P + Natural (I - Lo);
         end;
      end loop;
      return P;
   end Profile;

   -------------------------------------------------------------------------
   -- BFS helpers for pseudo-peripheral and CM
   -------------------------------------------------------------------------

   type Dist_Array is array (Vertex_Id range <>) of Integer;
   --  Distance from root; -1 = unvisited / unreachable.

   procedure BFS_Distances
     (G     : Graph;
      Root  : Vertex_Id;
      Dist  : out Dist_Array;
      Ecc   : out Natural)
   is
      Queue : array (1 .. Max_Vertices) of Vertex_Id;
      Head  : Natural := 1;
      Tail  : Natural := 0;
   begin
      for V in Dist'Range loop
         Dist (V) := -1;
      end loop;
      Ecc := 0;
      if Root not in 1 .. G.N then
         return;
      end if;
      Dist (Root) := 0;
      Tail := Tail + 1;
      Queue (Tail) := Root;
      while Head <= Tail loop
         declare
            U : constant Vertex_Id := Queue (Head);
         begin
            Head := Head + 1;
            for W in 1 .. G.N loop
               if G.Adj (U, W) and then Dist (W) < 0 then
                  Dist (W) := Dist (U) + 1;
                  if Natural (Dist (W)) > Ecc then
                     Ecc := Natural (Dist (W));
                  end if;
                  Tail := Tail + 1;
                  Queue (Tail) := W;
               end if;
            end loop;
         end;
      end loop;
   end BFS_Distances;

   function Min_Degree_Vertex (G : Graph) return Vertex_Id is
      Best : Vertex_Id := 1;
      BD   : Natural := Degree (G, 1);
   begin
      for V in 2 .. G.N loop
         declare
            D : constant Natural := Degree (G, V);
         begin
            if D < BD then
               BD := D;
               Best := V;
            end if;
         end;
      end loop;
      return Best;
   end Min_Degree_Vertex;

   function Pseudo_Peripheral_Vertex
     (G     : Graph;
      Start : Vertex_Id := 1) return Vertex_Id
   is
      Dist  : Dist_Array (1 .. G.N);
      Ecc   : Natural;
      Cur   : Vertex_Id := Start;
      Max_It : constant := 4;
   begin
      if G.N = 1 then
         return 1;
      end if;

      --  Prefer a low-degree seed when Start is the default-ish choice.
      if Start = 1 then
         Cur := Min_Degree_Vertex (G);
      end if;

      for Iter in 1 .. Max_It loop
         BFS_Distances (G, Cur, Dist, Ecc);
         declare
            Cand     : Vertex_Id := Cur;
            Cand_Deg : Natural := Natural'Last;
            Found    : Boolean := False;
         begin
            for V in 1 .. G.N loop
               if Dist (V) = Integer (Ecc) then
                  declare
                     D : constant Natural := Degree (G, V);
                  begin
                     if not Found or else D < Cand_Deg
                       or else (D = Cand_Deg and then V < Cand)
                     then
                        Cand := V;
                        Cand_Deg := D;
                        Found := True;
                     end if;
                  end;
               end if;
            end loop;
            if not Found or else Cand = Cur then
               return Cur;
            end if;
            --  Accept only if eccentricity grows (classic George–Liu).
            declare
               Dist2 : Dist_Array (1 .. G.N);
               Ecc2  : Natural;
            begin
               BFS_Distances (G, Cand, Dist2, Ecc2);
               if Ecc2 > Ecc then
                  Cur := Cand;
               else
                  return Cand;
               end if;
            end;
         end;
      end loop;
      return Cur;
   end Pseudo_Peripheral_Vertex;

   -------------------------------------------------------------------------
   -- Cuthill–McKee core
   -------------------------------------------------------------------------

   --  Sort Neighbors (1 .. Count) by ascending Degree, tie → lowest id.
   procedure Sort_By_Degree
     (G         : Graph;
      Neighbors : in out Order;
      Count     : Natural)
   is
   begin
      for I in 1 .. Count loop
         for J in I + 1 .. Count loop
            declare
               U : constant Vertex_Id := Neighbors (I);
               V : constant Vertex_Id := Neighbors (J);
               DU : constant Natural := Degree (G, U);
               DV : constant Natural := Degree (G, V);
            begin
               if DV < DU or else (DV = DU and then V < U) then
                  Neighbors (I) := V;
                  Neighbors (J) := U;
               end if;
            end;
         end loop;
      end loop;
   end Sort_By_Degree;

   function Cuthill_Mckee_Order
     (G     : Graph;
      Start : Natural := 0) return Order
   is
      Ord     : Order (1 .. G.N);
      Numbered : array (1 .. Max_Vertices) of Boolean := [others => False];
      Count   : Natural := 0;
      Scan    : Natural := 0;  --  index into Ord being processed
   begin
      if G.N = 0 then
         return Ord;
      end if;

      --  Process components one by one.
      while Count < G.N loop
         declare
            Root : Vertex_Id;
         begin
            if Count = 0 and then Start in 1 .. G.N then
               Root := Vertex_Id (Start);
            else
               --  Pick an unnumbered seed: min-degree among remaining,
               --  then refine with pseudo-peripheral within the residual
               --  component (approximate: run from that seed on full G
               --  but only consider unnumbered vertices via a local BFS).
               declare
                  Seed     : Vertex_Id := 1;
                  Seed_Deg : Natural := Natural'Last;
                  Found    : Boolean := False;
               begin
                  for V in 1 .. G.N loop
                     if not Numbered (V) then
                        declare
                           D : constant Natural := Degree (G, V);
                        begin
                           if not Found or else D < Seed_Deg then
                              Seed := V;
                              Seed_Deg := D;
                              Found := True;
                           end if;
                        end;
                     end if;
                  end loop;
                  --  Farthest unnumbered from Seed (one iteration).
                  declare
                     Queue : array (1 .. Max_Vertices) of Vertex_Id;
                     Dist  : array (1 .. Max_Vertices) of Integer :=
                       [others => -1];
                     Head  : Natural := 1;
                     Tail  : Natural := 0;
                     Ecc   : Natural := 0;
                     Far   : Vertex_Id := Seed;
                     Far_D : Natural := Natural'Last;
                  begin
                     Dist (Seed) := 0;
                     Tail := 1;
                     Queue (1) := Seed;
                     while Head <= Tail loop
                        declare
                           U : constant Vertex_Id := Queue (Head);
                        begin
                           Head := Head + 1;
                           for W in 1 .. G.N loop
                              if G.Adj (U, W) and then not Numbered (W)
                                and then Dist (W) < 0
                              then
                                 Dist (W) := Dist (U) + 1;
                                 if Natural (Dist (W)) > Ecc then
                                    Ecc := Natural (Dist (W));
                                 end if;
                                 Tail := Tail + 1;
                                 Queue (Tail) := W;
                              end if;
                           end loop;
                        end;
                     end loop;
                     for V in 1 .. G.N loop
                        if Dist (V) = Integer (Ecc) then
                           declare
                              D : constant Natural := Degree (G, V);
                           begin
                              if D < Far_D
                                or else (D = Far_D and then V < Far)
                              then
                                 Far := V;
                                 Far_D := D;
                              end if;
                           end;
                        end if;
                     end loop;
                     Root := Far;
                  end;
               end;
            end if;

            if Numbered (Root) then
               --  Defensive: find any unnumbered vertex.
               for V in 1 .. G.N loop
                  if not Numbered (V) then
                     Root := V;
                     exit;
                  end if;
               end loop;
            end if;

            Count := Count + 1;
            Ord (Count) := Root;
            Numbered (Root) := True;
            Scan := Count;

            --  Classic CM: for each numbered vertex in order, append its
            --  unnumbered neighbors sorted by ascending degree.
            while Scan <= Count loop
               declare
                  U         : constant Vertex_Id := Ord (Scan);
                  Neighbors : Order (1 .. G.N);
                  NCount    : Natural := 0;
               begin
                  for W in 1 .. G.N loop
                     if G.Adj (U, W) and then not Numbered (W) then
                        NCount := NCount + 1;
                        Neighbors (NCount) := W;
                     end if;
                  end loop;
                  Sort_By_Degree (G, Neighbors, NCount);
                  for K in 1 .. NCount loop
                     if not Numbered (Neighbors (K)) then
                        Count := Count + 1;
                        Ord (Count) := Neighbors (K);
                        Numbered (Neighbors (K)) := True;
                     end if;
                  end loop;
                  Scan := Scan + 1;
               end;
            end loop;
         end;
      end loop;

      return Ord;
   end Cuthill_Mckee_Order;

   function Reverse_Cuthill_Mckee_Order
     (G     : Graph;
      Start : Natural := 0) return Order
   is
   begin
      return Reverse_Order (Cuthill_Mckee_Order (G, Start));
   end Reverse_Cuthill_Mckee_Order;

   -------------------------------------------------------------------------
   -- Taxonomy
   -------------------------------------------------------------------------

   function Method_Name (M : Method_Kind) return String is
   begin
      case M is
         when Classical_CM =>
            return "Cuthill-McKee";
         when Classical_RCM =>
            return "Reverse Cuthill-McKee";
         when Sloan =>
            return "Sloan";
         when Nested_Dissection =>
            return "Nested Dissection";
      end case;
   end Method_Name;

   function Implemented (M : Method_Kind) return Boolean is
   begin
      return M = Classical_CM or else M = Classical_RCM;
   end Implemented;

   function Forthcoming (M : Method_Kind) return Boolean is
   begin
      return not Implemented (M);
   end Forthcoming;

end Cuthill_Mckee;
