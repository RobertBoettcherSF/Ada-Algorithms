--  Christofides_Algorithm body — Prim MST, subset-DP matching,
--  Hierholzer Euler tour, shortcutting, and exact (N−1)! oracle.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Christofides_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Internal matrix shape check
   ---------------------------------------------------------------------------

   procedure Require_Valid_Matrix (Distances : Cost_Matrix; N : out Natural) is
   begin
      if Distances'First (1) /= 1
        or else Distances'First (2) /= 1
        or else Distances'Last (1) /= Distances'Last (2)
        or else Distances'Last (1) < 1
      then
         raise Invalid_Argument;
      end if;
      N := Natural (Distances'Last (1));
      if N = 0 or else N > Max_Vertices then
         raise Invalid_Argument;
      end if;
   end Require_Valid_Matrix;

   procedure Require_Tour_Matrix (Distances : Cost_Matrix; N : out Natural) is
   begin
      Require_Valid_Matrix (Distances, N);
      if N < 2 then
         raise Invalid_Argument;
      end if;
   end Require_Tour_Matrix;

   function In_Matrix
     (Distances : Cost_Matrix; V : Vertex_Id) return Boolean
   is
   begin
      return V in Distances'Range (1) and then V in Distances'Range (2);
   end In_Matrix;

   ---------------------------------------------------------------------------
   -- Matrix builders / queries
   ---------------------------------------------------------------------------

   procedure Put_Distance
     (Distances : in out Cost_Matrix;
      From, To  : Vertex_Id;
      Value     : Integer)
   is
   begin
      if Value < 0 then
         raise Invalid_Argument;
      end if;
      if not In_Matrix (Distances, From)
        or else not In_Matrix (Distances, To)
      then
         raise Invalid_Argument;
      end if;
      Distances (From, To) := Cost_Value (Value);
   end Put_Distance;

   procedure Put_Symmetric
     (Distances : in out Cost_Matrix;
      A, B      : Vertex_Id;
      Value     : Integer)
   is
   begin
      Put_Distance (Distances, A, B, Value);
      if A /= B then
         Put_Distance (Distances, B, A, Value);
      end if;
   end Put_Symmetric;

   function Matrix_Order (Distances : Cost_Matrix) return Natural is
      N : Natural;
   begin
      Require_Valid_Matrix (Distances, N);
      return N;
   end Matrix_Order;

   function Distance
     (Distances : Cost_Matrix; From, To : Vertex_Id) return Cost_Value
   is
      N : Natural;
   begin
      Require_Valid_Matrix (Distances, N);
      pragma Unreferenced (N);
      if not In_Matrix (Distances, From)
        or else not In_Matrix (Distances, To)
      then
         raise Invalid_Argument;
      end if;
      return Distances (From, To);
   end Distance;

   function Rounded_Euclidean
     (X1, Y1, X2, Y2 : Integer) return Cost_Value
   is
      use Ada.Numerics.Elementary_Functions;
      DX : constant Float := Float (X2) - Float (X1);
      DY : constant Float := Float (Y2) - Float (Y1);
      R  : constant Float := Sqrt (DX * DX + DY * DY);
   begin
      if R < 0.0 then
         return 0;
      end if;
      if R >= Float (Natural'Last) then
         raise Invalid_Argument;
      end if;
      return Cost_Value (Float'Rounding (R));
   end Rounded_Euclidean;

   function Undirected_Weight
     (Distances : Cost_Matrix; A, B : Vertex_Id) return Cost_Value
   is
      N    : Natural;
      Cab  : Cost_Value;
      Cba  : Cost_Value;
   begin
      Require_Valid_Matrix (Distances, N);
      pragma Unreferenced (N);
      if not In_Matrix (Distances, A)
        or else not In_Matrix (Distances, B)
      then
         raise Invalid_Argument;
      end if;
      Cab := Distances (A, B);
      Cba := Distances (B, A);
      if Cab <= Cba then
         return Cab;
      else
         return Cba;
      end if;
   end Undirected_Weight;

   ---------------------------------------------------------------------------
   -- Tour cost / validity
   ---------------------------------------------------------------------------

   function Closed_Tour_Cost
     (Distances : Cost_Matrix;
      Cities    : City_Seq;
      N         : Natural) return Cost_Value
   is
      Order : Natural;
      Total : Cost_Value := 0;
      A, B  : Vertex_Id;
   begin
      Require_Valid_Matrix (Distances, Order);
      if N < 2 or else N /= Order then
         raise Invalid_Argument;
      end if;
      for I in 1 .. N loop
         A := Cities (I);
         if Natural (A) > N then
            raise Invalid_Argument;
         end if;
         if I < N then
            B := Cities (I + 1);
         else
            B := Cities (1);
         end if;
         if Natural (B) > N then
            raise Invalid_Argument;
         end if;
         Total := Total + Distances (A, B);
      end loop;
      return Total;
   end Closed_Tour_Cost;

   function Is_Valid_Tour (T : Tour) return Boolean is
      Seen : array (1 .. Max_Vertices) of Boolean := [others => False];
      V    : Vertex_Id;
   begin
      if T.N < 2 or else T.N > Max_Vertices then
         return False;
      end if;
      for I in 1 .. T.N loop
         V := T.Cities (I);
         if Natural (V) > T.N then
            return False;
         end if;
         if Seen (Natural (V)) then
            return False;
         end if;
         Seen (Natural (V)) := True;
      end loop;
      for C in 1 .. T.N loop
         if not Seen (C) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Tour;

   function Tour_Cost
     (Distances : Cost_Matrix; T : Tour) return Cost_Value
   is
   begin
      return Closed_Tour_Cost (Distances, T.Cities, T.N);
   end Tour_Cost;

   ---------------------------------------------------------------------------
   -- Prim MST (dense) — shared by MST_Cost / Odd_Vertices / Approximate
   ---------------------------------------------------------------------------

   --  Parent(V) = MST parent of V (Parent(Root) = 0). Root = 1.
   type Parent_Array is array (1 .. Max_Vertices) of Natural;
   type Degree_Array is array (1 .. Max_Vertices) of Natural;

   procedure Compute_MST
     (Distances : Cost_Matrix;
      N         : Natural;
      Parent    : out Parent_Array;
      Total     : out Cost_Value)
   is
      In_Tree : array (1 .. Max_Vertices) of Boolean := [others => False];
      Key     : array (1 .. Max_Vertices) of Cost_Value :=
        [others => Cost_Value'Last];
      U       : Natural;
      W       : Cost_Value;
   begin
      Parent := [others => 0];
      Total  := 0;
      Key (1) := 0;

      for Step in 1 .. N loop
         U := 0;
         for V in 1 .. N loop
            if not In_Tree (V) then
               if U = 0 or else Key (V) < Key (U) then
                  U := V;
               end if;
            end if;
         end loop;

         if U = 0 then
            raise Invalid_Argument;
         end if;

         In_Tree (U) := True;
         if Parent (U) /= 0 then
            Total := Total + Key (U);
         end if;

         for V in 1 .. N loop
            if not In_Tree (V) and then U /= V then
               W := Undirected_Weight
                 (Distances, Vertex_Id (U), Vertex_Id (V));
               if W < Key (V)
                 or else (W = Key (V) and then Parent (V) = 0)
                 or else (W = Key (V) and then U < Parent (V))
               then
                  Key (V)    := W;
                  Parent (V) := U;
               end if;
            end if;
         end loop;
      end loop;
   end Compute_MST;

   procedure Degrees_From_Parent
     (Parent : Parent_Array;
      N      : Natural;
      Deg    : out Degree_Array)
   is
      P : Natural;
   begin
      Deg := [others => 0];
      for V in 2 .. N loop
         P := Parent (V);
         if P = 0 or else P > N then
            raise Invalid_Argument;
         end if;
         Deg (V) := Deg (V) + 1;
         Deg (P) := Deg (P) + 1;
      end loop;
   end Degrees_From_Parent;

   function MST_Cost (Distances : Cost_Matrix) return Cost_Value is
      N      : Natural;
      Parent : Parent_Array;
      Total  : Cost_Value;
   begin
      Require_Tour_Matrix (Distances, N);
      Compute_MST (Distances, N, Parent, Total);
      return Total;
   end MST_Cost;

   function Odd_Vertices (Distances : Cost_Matrix) return Vertex_List is
      N      : Natural;
      Parent : Parent_Array;
      Total  : Cost_Value;
      Deg    : Degree_Array;
      Result : Vertex_List;
   begin
      Require_Tour_Matrix (Distances, N);
      Compute_MST (Distances, N, Parent, Total);
      pragma Unreferenced (Total);
      Degrees_From_Parent (Parent, N, Deg);
      Result.Count := 0;
      for V in 1 .. N loop
         if Deg (V) mod 2 = 1 then
            Result.Count := Result.Count + 1;
            Result.Vertices (Result.Count) := Vertex_Id (V);
         end if;
      end loop;
      return Result;
   end Odd_Vertices;

   ---------------------------------------------------------------------------
   -- Minimum-weight perfect matching (subset DP on odd set)
   ---------------------------------------------------------------------------

   function Pop_Count (Mask, K : Natural) return Natural is
      C : Natural := 0;
   begin
      for B in 0 .. K - 1 loop
         if (Mask / (2**B)) mod 2 = 1 then
            C := C + 1;
         end if;
      end loop;
      return C;
   end Pop_Count;

   function Lowest_Set_Bit (Mask, K : Natural) return Natural is
   begin
      for B in 0 .. K - 1 loop
         if (Mask / (2**B)) mod 2 = 1 then
            return B;
         end if;
      end loop;
      return K;
   end Lowest_Set_Bit;

   function Matching_Cost
     (Distances : Cost_Matrix; Odds : Vertex_List) return Cost_Value
   is
      N      : Natural;
      K      : Natural;
      States : Natural;
      I_Bit  : Natural;
      Best   : Cost_Value;
      Cand   : Cost_Value;
      W      : Cost_Value;
      Vi, Vj : Vertex_Id;
      --  Classic subset DP: dp(S) = MWPM cost on bit-subset S of Odds.
      type DP_Array is array (Natural range <>) of Cost_Value;
      Inf : constant Cost_Value := Cost_Value'Last / 4;
   begin
      Require_Tour_Matrix (Distances, N);
      K := Odds.Count;
      if K mod 2 = 1 then
         raise Invalid_Argument;
      end if;
      if K > Max_Matching_Odd then
         raise Invalid_Argument;
      end if;
      for I in 1 .. K loop
         if Natural (Odds.Vertices (I)) > N then
            raise Invalid_Argument;
         end if;
      end loop;
      if K = 0 then
         return 0;
      end if;

      States := 2**K;
      declare
         DP : DP_Array (0 .. States - 1) := [others => Inf];
      begin
         DP (0) := 0;
         for Mask in 1 .. States - 1 loop
            if Pop_Count (Mask, K) mod 2 = 0 then
               I_Bit := Lowest_Set_Bit (Mask, K);
               Best  := Inf;
               for J_Bit in I_Bit + 1 .. K - 1 loop
                  if (Mask / (2**J_Bit)) mod 2 = 1 then
                     Vi := Odds.Vertices (I_Bit + 1);
                     Vj := Odds.Vertices (J_Bit + 1);
                     W  := Undirected_Weight (Distances, Vi, Vj);
                     Cand := DP (Mask - 2**I_Bit - 2**J_Bit) + W;
                     if Cand < Best then
                        Best := Cand;
                     end if;
                  end if;
               end loop;
               DP (Mask) := Best;
            end if;
         end loop;
         Best := DP (States - 1);
         if Best >= Inf then
            raise Invalid_Argument;
         end if;
         return Best;
      end;
   end Matching_Cost;

   ---------------------------------------------------------------------------
   -- Multigraph adjacency for Euler tour (MST edges + matching edges)
   ---------------------------------------------------------------------------

   Max_Multi_Degree : constant Positive := Max_Vertices + Max_Matching_Odd;
   --  Each vertex degree in H ≤ (N−1) + (matching incident ≤ 1 in tree
   --  sense, but MST degree ≤ N−1 and matching adds 1) so ≤ N is enough;
   --  leave headroom for duplicate MST/matching edges.

   type Neighbour_Bucket is
     array (1 .. Max_Multi_Degree) of Natural;
   type Adj_Lists is
     array (1 .. Max_Vertices) of Neighbour_Bucket;
   type Adj_Count is array (1 .. Max_Vertices) of Natural;

   procedure Adj_Add
     (Adj : in out Adj_Lists;
      Cnt : in out Adj_Count;
      U, V : Natural)
   is
   begin
      if Cnt (U) >= Max_Multi_Degree or else Cnt (V) >= Max_Multi_Degree then
         raise Invalid_Argument;
      end if;
      Cnt (U) := Cnt (U) + 1;
      Adj (U)(Cnt (U)) := V;
      Cnt (V) := Cnt (V) + 1;
      Adj (V)(Cnt (V)) := U;
   end Adj_Add;

   procedure Adj_Remove_One
     (Adj : in out Adj_Lists;
      Cnt : in out Adj_Count;
      U   : Natural;
      V   : Natural)
   is
      Found : Natural := 0;
   begin
      for I in 1 .. Cnt (U) loop
         if Adj (U)(I) = V then
            Found := I;
            exit;
         end if;
      end loop;
      if Found = 0 then
         raise Invalid_Argument;
      end if;
      Adj (U)(Found) := Adj (U)(Cnt (U));
      Cnt (U) := Cnt (U) - 1;
   end Adj_Remove_One;

   --  Recover matching edges by classic DP + backtrack on first set bit.
   procedure Matching_Edges
     (Distances : Cost_Matrix;
      Odds      : Vertex_List;
      Adj       : in out Adj_Lists;
      Cnt       : in out Adj_Count)
   is
      K      : constant Natural := Odds.Count;
      States : Natural;
      Mask   : Natural;
      I_Bit  : Natural;
      Best_J : Natural;
      Best   : Cost_Value;
      Cand   : Cost_Value;
      W      : Cost_Value;
      Inf    : constant Cost_Value := Cost_Value'Last / 4;
      type DP_Array is array (Natural range <>) of Cost_Value;
   begin
      if K = 0 then
         return;
      end if;
      States := 2**K;
      declare
         DP : DP_Array (0 .. States - 1) := [others => Inf];
      begin
         DP (0) := 0;
         for Mask in 1 .. States - 1 loop
            if Pop_Count (Mask, K) mod 2 = 0 then
               I_Bit := Lowest_Set_Bit (Mask, K);
               Best  := Inf;
               for J_Bit in I_Bit + 1 .. K - 1 loop
                  if (Mask / (2**J_Bit)) mod 2 = 1 then
                     W := Undirected_Weight
                       (Distances,
                        Odds.Vertices (I_Bit + 1),
                        Odds.Vertices (J_Bit + 1));
                     Cand := DP (Mask - 2**I_Bit - 2**J_Bit) + W;
                     if Cand < Best then
                        Best := Cand;
                     end if;
                  end if;
               end loop;
               DP (Mask) := Best;
            end if;
         end loop;

         Mask := States - 1;
         while Mask /= 0 loop
            I_Bit := Lowest_Set_Bit (Mask, K);
            Best_J := K;
            for J_Bit in I_Bit + 1 .. K - 1 loop
               if (Mask / (2**J_Bit)) mod 2 = 1 then
                  W := Undirected_Weight
                    (Distances,
                     Odds.Vertices (I_Bit + 1),
                     Odds.Vertices (J_Bit + 1));
                  Cand := DP (Mask - 2**I_Bit - 2**J_Bit) + W;
                  if Cand = DP (Mask) then
                     Best_J := J_Bit;
                     exit;
                  end if;
               end if;
            end loop;
            if Best_J >= K then
               raise Invalid_Argument;
            end if;
            Adj_Add
              (Adj, Cnt,
               Natural (Odds.Vertices (I_Bit + 1)),
               Natural (Odds.Vertices (Best_J + 1)));
            Mask := Mask - 2**I_Bit - 2**Best_J;
         end loop;
      end;
   end Matching_Edges;

   ---------------------------------------------------------------------------
   -- Hierholzer Eulerian circuit + shortcutting
   ---------------------------------------------------------------------------

   function Approximate_Tour (Distances : Cost_Matrix) return Tour is
      N      : Natural;
      Parent : Parent_Array;
      MST_W  : Cost_Value;
      Deg    : Degree_Array;
      Odds   : Vertex_List;
      Adj    : Adj_Lists := [others => [others => 0]];
      Cnt    : Adj_Count := [others => 0];
      --  Euler circuit vertices (open walk length ≤ 2N).
      Max_Euler : constant Positive := 2 * Max_Vertices + 2;
      type Euler_Seq is array (1 .. Max_Euler) of Natural;
      Circuit : Euler_Seq := [others => 0];
      Circ_Len : Natural := 0;
      Stack   : array (1 .. Max_Euler) of Natural := [others => 0];
      Sp      : Natural := 0;
      U, V    : Natural;
      Visited : array (1 .. Max_Vertices) of Boolean := [others => False];
      Result  : Tour;
      Seen_Count : Natural;
      Start_Pos  : Natural;
      Rotated    : City_Seq := [others => Vertex_Id'First];
   begin
      Require_Tour_Matrix (Distances, N);
      Compute_MST (Distances, N, Parent, MST_W);
      pragma Unreferenced (MST_W);
      Degrees_From_Parent (Parent, N, Deg);

      Odds.Count := 0;
      for V in 1 .. N loop
         if Deg (V) mod 2 = 1 then
            Odds.Count := Odds.Count + 1;
            Odds.Vertices (Odds.Count) := Vertex_Id (V);
         end if;
      end loop;
      if Odds.Count mod 2 = 1 or else Odds.Count > Max_Matching_Odd then
         raise Invalid_Argument;
      end if;

      --  Insert MST edges into multigraph.
      for V in 2 .. N loop
         Adj_Add (Adj, Cnt, V, Parent (V));
      end loop;

      --  Insert matching edges.
      Matching_Edges (Distances, Odds, Adj, Cnt);

      --  Hierholzer from vertex 1.
      Sp := 1;
      Stack (1) := 1;
      while Sp > 0 loop
         U := Stack (Sp);
         if Cnt (U) > 0 then
            V := Adj (U)(Cnt (U));
            --  Remove undirected edge U—V (one copy).
            Adj_Remove_One (Adj => Adj, Cnt => Cnt, U => U, V => V);
            Adj_Remove_One (Adj => Adj, Cnt => Cnt, U => V, V => U);
            Sp := Sp + 1;
            if Sp > Max_Euler then
               raise Invalid_Argument;
            end if;
            Stack (Sp) := V;
         else
            Circ_Len := Circ_Len + 1;
            if Circ_Len > Max_Euler then
               raise Invalid_Argument;
            end if;
            Circuit (Circ_Len) := U;
            Sp := Sp - 1;
         end if;
      end loop;

      --  Circuit is in reverse Hierholzer order; reverse for forward walk.
      declare
         L, R : Natural;
         Tmp  : Natural;
      begin
         L := 1;
         R := Circ_Len;
         while L < R loop
            Tmp := Circuit (L);
            Circuit (L) := Circuit (R);
            Circuit (R) := Tmp;
            L := L + 1;
            R := R - 1;
         end loop;
      end;

      --  Shortcut: keep first occurrence of each vertex.
      Result.N := 0;
      Seen_Count := 0;
      for I in 1 .. Circ_Len loop
         U := Circuit (I);
         if U >= 1 and then U <= N and then not Visited (U) then
            Visited (U) := True;
            Seen_Count := Seen_Count + 1;
            Result.N := Result.N + 1;
            Result.Cities (Result.N) := Vertex_Id (U);
         end if;
      end loop;
      if Seen_Count /= N or else Result.N /= N then
         raise Invalid_Argument;
      end if;

      --  Rotate so the tour starts at vertex 1 (stable educational output).
      Start_Pos := 1;
      for I in 1 .. Result.N loop
         if Result.Cities (I) = 1 then
            Start_Pos := I;
            exit;
         end if;
      end loop;
      for I in 1 .. Result.N loop
         Rotated (I) :=
           Result.Cities (((Start_Pos + I - 2) mod Result.N) + 1);
      end loop;
      Result.Cities := Rotated;
      Result.Cost := Closed_Tour_Cost (Distances, Result.Cities, Result.N);
      return Result;
   end Approximate_Tour;

   ---------------------------------------------------------------------------
   -- Exact brute-force oracle (N ≤ Max_Exact_Vertices)
   ---------------------------------------------------------------------------

   function Exact_Tour (Distances : Cost_Matrix) return Tour is
      N      : Natural;
      Cities : City_Seq := [others => Vertex_Id'First];
      Used   : array (1 .. Max_Vertices) of Boolean := [others => False];
      Best   : Tour;
      Best_Set : Boolean := False;
      Cand_Cost : Cost_Value;

      procedure Recurse (Pos : Natural) is
      begin
         if Pos > N then
            Cand_Cost := Closed_Tour_Cost (Distances, Cities, N);
            if not Best_Set or else Cand_Cost < Best.Cost then
               Best.N := N;
               Best.Cities := Cities;
               Best.Cost := Cand_Cost;
               Best_Set := True;
            end if;
            return;
         end if;
         for V in 1 .. N loop
            if not Used (V) then
               Used (V) := True;
               Cities (Pos) := Vertex_Id (V);
               Recurse (Pos + 1);
               Used (V) := False;
            end if;
         end loop;
      end Recurse;
   begin
      Require_Tour_Matrix (Distances, N);
      if N > Max_Exact_Vertices then
         raise Invalid_Argument;
      end if;

      --  Fix start at 1; permute the rest (covers every directed cycle).
      Cities (1) := 1;
      Used (1) := True;
      Recurse (2);

      if not Best_Set then
         raise Invalid_Argument;
      end if;
      return Best;
   end Exact_Tour;

end Christofides_Algorithm;
