--  Travelling_Salesman_Problem body — matrix validation, Held–Karp DP,
--  brute-force oracle, nearest-neighbour, 2-opt, and MST double-tree.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Travelling_Salesman_Problem
  with SPARK_Mode => Off
is

   Inf : constant Cost_Value := Cost_Value'Last / 4;

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
      N : Natural;
      W1, W2 : Cost_Value;
   begin
      Require_Valid_Matrix (Distances, N);
      pragma Unreferenced (N);
      if not In_Matrix (Distances, A)
        or else not In_Matrix (Distances, B)
      then
         raise Invalid_Argument;
      end if;
      W1 := Distances (A, B);
      W2 := Distances (B, A);
      if W1 <= W2 then
         return W1;
      else
         return W2;
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
      if N = 0 or else N /= Order then
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
      if T.N = 0 or else T.N > Max_Vertices then
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
   -- Nearest-neighbour construction
   ---------------------------------------------------------------------------

   function Nearest_Neighbor_From
     (Distances : Cost_Matrix; Start : Vertex_Id) return Tour
   is
      N       : Natural;
      Result  : Tour;
      Visited : array (1 .. Max_Vertices) of Boolean := [others => False];
      Current : Vertex_Id;
      Best_V  : Vertex_Id;
      Best_C  : Cost_Value;
      Cand_C  : Cost_Value;
      Found   : Boolean;
   begin
      Require_Valid_Matrix (Distances, N);
      if Natural (Start) > N then
         raise Invalid_Argument;
      end if;

      Result.N := N;
      Result.Cities (1) := Start;
      Visited (Natural (Start)) := True;
      Current := Start;

      for Step in 2 .. N loop
         Found  := False;
         Best_V := Vertex_Id'First;
         Best_C := Cost_Value'Last;
         for Cand in 1 .. N loop
            if not Visited (Cand) then
               Cand_C := Distances (Current, Vertex_Id (Cand));
               if (not Found)
                 or else Cand_C < Best_C
                 or else (Cand_C = Best_C
                          and then Vertex_Id (Cand) < Best_V)
               then
                  Found  := True;
                  Best_C := Cand_C;
                  Best_V := Vertex_Id (Cand);
               end if;
            end if;
         end loop;
         Result.Cities (Step) := Best_V;
         Visited (Natural (Best_V)) := True;
         Current := Best_V;
      end loop;

      Result.Cost := Closed_Tour_Cost (Distances, Result.Cities, N);
      return Result;
   end Nearest_Neighbor_From;

   function Best_Nearest_Neighbor (Distances : Cost_Matrix) return Tour is
      N     : Natural;
      Best  : Tour;
      Cand  : Tour;
      First : Boolean := True;
   begin
      Require_Valid_Matrix (Distances, N);
      for S in 1 .. N loop
         Cand := Nearest_Neighbor_From (Distances, Vertex_Id (S));
         if First
           or else Cand.Cost < Best.Cost
           or else (Cand.Cost = Best.Cost
                    and then Cand.Cities (1) < Best.Cities (1))
         then
            Best  := Cand;
            First := False;
         end if;
      end loop;
      return Best;
   end Best_Nearest_Neighbor;

   ---------------------------------------------------------------------------
   -- 2-opt local search
   ---------------------------------------------------------------------------

   function Improve_Two_Opt
     (Distances : Cost_Matrix; Seed : Tour) return Tour
   is
      N      : Natural;
      Result : Tour;
      Improved : Boolean;
      Best_Gain : Integer;
      Best_I, Best_J : Natural;
      --  2-opt on the path Cities(1)..Cities(N) with implicit return.
      --  Reversing the segment Cities(I+1 .. J) replaces edges
      --  (Cities(I),Cities(I+1)) and (Cities(J),Cities(J+1)) with
      --  (Cities(I),Cities(J)) and (Cities(I+1),Cities(J+1)), where
      --  Cities(N+1) means Cities(1). Delta may be computed with
      --  directed costs (asymmetric 2-opt).
      function Next_Idx (K : Natural) return Natural is
      begin
         if K = N then
            return 1;
         else
            return K + 1;
         end if;
      end Next_Idx;

      function Edge (A, B : Vertex_Id) return Cost_Value is
      begin
         return Distances (A, B);
      end Edge;

      procedure Apply_Reverse (I, J : Natural) is
         L, R : Natural;
         Tmp  : Vertex_Id;
      begin
         L := I + 1;
         R := J;
         while L < R loop
            Tmp := Result.Cities (L);
            Result.Cities (L) := Result.Cities (R);
            Result.Cities (R) := Tmp;
            L := L + 1;
            R := R - 1;
         end loop;
      end Apply_Reverse;

   begin
      Require_Valid_Matrix (Distances, N);
      if Seed.N /= N or else N = 0 then
         raise Invalid_Argument;
      end if;
      if not Is_Valid_Tour (Seed) then
         raise Invalid_Argument;
      end if;

      Result := Seed;
      Result.Cost := Closed_Tour_Cost (Distances, Result.Cities, N);

      if N < 4 then
         return Result;
      end if;

      loop
         Improved   := False;
         Best_Gain := 0;
         Best_I     := 0;
         Best_J     := 0;

         for I in 1 .. N - 2 loop
            for J in I + 2 .. N loop
               --  Skip the move that would reverse the whole tour when
               --  I = 1 and J = N (that only flips orientation of the
               --  closing pair in a degenerate way for directed costs).
               if not (I = 1 and then J = N) then
                  declare
                     A  : constant Vertex_Id := Result.Cities (I);
                     B  : constant Vertex_Id := Result.Cities (I + 1);
                     C  : constant Vertex_Id := Result.Cities (J);
                     D  : constant Vertex_Id := Result.Cities (Next_Idx (J));
                     Old_Cost : constant Cost_Value := Edge (A, B) + Edge (C, D);
                     New_Cost : constant Cost_Value := Edge (A, C) + Edge (B, D);
                     Gain     : Integer;
                  begin
                     if New_Cost < Old_Cost then
                        Gain := Integer (Old_Cost - New_Cost);
                        if Gain > Best_Gain then
                           Best_Gain := Gain;
                           Best_I     := I;
                           Best_J     := J;
                           Improved   := True;
                        end if;
                     end if;
                  end;
               end if;
            end loop;
         end loop;

         exit when not Improved;
         Apply_Reverse (Best_I, Best_J);
         Result.Cost := Closed_Tour_Cost (Distances, Result.Cities, N);
      end loop;

      return Result;
   end Improve_Two_Opt;

   ---------------------------------------------------------------------------
   -- Brute-force exact oracle (N ≤ Max_Brute_Force_Vertices)
   ---------------------------------------------------------------------------

   function Brute_Force_Tour (Distances : Cost_Matrix) return Tour is
      N      : Natural;
      Best   : Tour;
      Perm   : City_Seq := [others => Vertex_Id'First];
      Used   : array (1 .. Max_Brute_Force_Vertices) of Boolean :=
        [others => False];
      First  : Boolean := True;

      procedure Consider is
         C : Cost_Value;
      begin
         C := Closed_Tour_Cost (Distances, Perm, N);
         if First or else C < Best.Cost then
            Best.N      := N;
            Best.Cities := Perm;
            Best.Cost   := C;
            First       := False;
         end if;
      end Consider;

      procedure Recurse (Pos : Natural) is
      begin
         if Pos > N then
            Consider;
            return;
         end if;
         for C in 1 .. N loop
            if not Used (C) then
               Used (C) := True;
               Perm (Pos) := Vertex_Id (C);
               Recurse (Pos + 1);
               Used (C) := False;
            end if;
         end loop;
      end Recurse;

   begin
      Require_Valid_Matrix (Distances, N);
      if N > Max_Brute_Force_Vertices then
         raise Invalid_Argument;
      end if;

      if N = 1 then
         Best.N := 1;
         Best.Cities (1) := 1;
         Best.Cost := Distances (1, 1);
         return Best;
      end if;

      Perm (1) := 1;
      Used (1) := True;
      Recurse (2);
      return Best;
   end Brute_Force_Tour;

   ---------------------------------------------------------------------------
   -- Held–Karp bitmask DP (N ≤ Max_Held_Karp_Vertices)
   ---------------------------------------------------------------------------

   function Held_Karp_Tour (Distances : Cost_Matrix) return Tour is
      N : Natural;
   begin
      Require_Valid_Matrix (Distances, N);
      if N > Max_Held_Karp_Vertices then
         raise Invalid_Argument;
      end if;

      if N = 1 then
         declare
            Best : Tour;
         begin
            Best.N := 1;
            Best.Cities (1) := 1;
            Best.Cost := Distances (1, 1);
            return Best;
         end;
      end if;

      if N = 2 then
         declare
            Best : Tour;
         begin
            Best.N := 2;
            Best.Cities (1) := 1;
            Best.Cities (2) := 2;
            Best.Cost := Distances (1, 2) + Distances (2, 1);
            return Best;
         end;
      end if;

      declare
         --  Cities 1 .. N; bit (v-1) marks city v. Fix start = city 1.
         States : constant Natural := 2**N;
         --  Flat DP / pred: index = Mask * N + (J-1), J in 1 .. N.
         type Flat_Cost is array (Natural range <>) of Cost_Value;
         type Flat_Pred is array (Natural range <>) of Natural;
         --  Heap allocation avoids large stack frames for N = 16.
         type Cost_Acc is access Flat_Cost;
         type Pred_Acc is access Flat_Pred;
         DP   : constant Cost_Acc := new Flat_Cost'(0 .. States * N - 1 => Inf);
         Pred : constant Pred_Acc := new Flat_Pred'(0 .. States * N - 1 => 0);

         function Idx (Mask, J : Natural) return Natural is
         begin
            return Mask * N + (J - 1);
         end Idx;

         function Bit (V : Natural) return Natural is
         begin
            return 2**(V - 1);
         end Bit;

         function In_Mask (Mask, V : Natural) return Boolean is
         begin
            return (Mask / Bit (V)) mod 2 = 1;
         end In_Mask;

         Full       : constant Natural := States - 1;
         Start_Mask : constant Natural := Bit (1);
         Best_End   : Natural := 0;
         Best_Cost  : Cost_Value := Inf;
         Cand       : Cost_Value;
         Result     : Tour;
         J          : Natural;
         Cur_Mask   : Natural;
         Pos        : Natural;
         Prev       : Natural;
      begin
         DP (Idx (Start_Mask, 1)) := 0;

         for Mask in 0 .. Full loop
            if In_Mask (Mask, 1) then
               for J in 1 .. N loop
                  if In_Mask (Mask, J) and then DP (Idx (Mask, J)) < Inf then
                     for K in 1 .. N loop
                        if not In_Mask (Mask, K) then
                           Cand := DP (Idx (Mask, J))
                             + Distances (Vertex_Id (J), Vertex_Id (K));
                           declare
                              New_Mask : constant Natural := Mask + Bit (K);
                              Slot     : constant Natural := Idx (New_Mask, K);
                           begin
                              if Cand < DP (Slot) then
                                 DP (Slot) := Cand;
                                 Pred (Slot) := J;
                              end if;
                           end;
                        end if;
                     end loop;
                  end if;
               end loop;
            end if;
         end loop;

         for J in 2 .. N loop
            if DP (Idx (Full, J)) < Inf then
               Cand := DP (Idx (Full, J))
                 + Distances (Vertex_Id (J), Vertex_Id (1));
               if Cand < Best_Cost then
                  Best_Cost := Cand;
                  Best_End  := J;
               end if;
            end if;
         end loop;

         if Best_End = 0 or else Best_Cost >= Inf then
            raise Invalid_Argument;
         end if;

         --  Reconstruct path 1 ↝ … ↝ Best_End by walking predecessors,
         --  then store in reverse into Cities(1 .. N) with Cities(1)=1.
         Result.N := N;
         Result.Cost := Best_Cost;
         Result.Cities := [others => Vertex_Id'First];

         Cur_Mask := Full;
         J := Best_End;
         Pos := N;
         while Pos >= 2 loop
            Result.Cities (Pos) := Vertex_Id (J);
            Prev := Pred (Idx (Cur_Mask, J));
            if Prev = 0 and then Pos > 2 then
               raise Invalid_Argument;
            end if;
            Cur_Mask := Cur_Mask - Bit (J);
            J := Prev;
            Pos := Pos - 1;
         end loop;
         Result.Cities (1) := 1;

         return Result;
      end;
   end Held_Karp_Tour;

   function Exact_Tour (Distances : Cost_Matrix) return Tour is
   begin
      return Held_Karp_Tour (Distances);
   end Exact_Tour;

   ---------------------------------------------------------------------------
   -- Prim MST + double-tree 2-approximation
   ---------------------------------------------------------------------------

   type Parent_Array is array (1 .. Max_Vertices) of Natural;

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

   function Double_Tree_Tour (Distances : Cost_Matrix) return Tour is
      N      : Natural;
      Parent : Parent_Array;
      MST_W  : Cost_Value;
      --  Multigraph adjacency: each undirected tree edge appears twice.
      --  Degree of v in the doubled tree is 2 * deg_T(v) ≤ 2(N-1).
      Max_Deg : constant Positive := 2 * Max_Vertices;
      type Adj_Row is array (1 .. Max_Deg) of Natural;
      type Adj_Len is array (1 .. Max_Vertices) of Natural;
      type Adj_Mat is array (1 .. Max_Vertices) of Adj_Row;
      Adj   : Adj_Mat := [others => [others => 0]];
      Alen  : Adj_Len := [others => 0];

      procedure Add_Edge (U, V : Natural) is
      begin
         Alen (U) := Alen (U) + 1;
         Adj (U)(Alen (U)) := V;
         Alen (V) := Alen (V) + 1;
         Adj (V)(Alen (V)) := U;
      end Add_Edge;

      procedure Remove_Edge (U, V : Natural) is
         Found : Boolean;
      begin
         --  Remove one copy of undirected edge U–V from both sides.
         Found := False;
         for I in 1 .. Alen (U) loop
            if Adj (U)(I) = V then
               Adj (U)(I) := Adj (U)(Alen (U));
               Alen (U) := Alen (U) - 1;
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            raise Invalid_Argument;
         end if;
         Found := False;
         for I in 1 .. Alen (V) loop
            if Adj (V)(I) = U then
               Adj (V)(I) := Adj (V)(Alen (V));
               Alen (V) := Alen (V) - 1;
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            raise Invalid_Argument;
         end if;
      end Remove_Edge;

      --  Hierholzer: circuit of vertex ids (length = #edges + 1).
      Circuit : array (1 .. 2 * Max_Vertices + 2) of Natural :=
        [others => 0];
      Circ_Len : Natural := 0;
      Stack    : array (1 .. 2 * Max_Vertices + 2) of Natural :=
        [others => 0];
      Sp       : Natural := 0;
      U, V     : Natural;

      Seen   : array (1 .. Max_Vertices) of Boolean := [others => False];
      Result : Tour;
      Count  : Natural;
   begin
      Require_Valid_Matrix (Distances, N);
      if N < 2 then
         raise Invalid_Argument;
      end if;

      Compute_MST (Distances, N, Parent, MST_W);
      pragma Unreferenced (MST_W);

      --  Insert each MST edge twice (double-tree).
      for V in 2 .. N loop
         U := Parent (V);
         if U = 0 or else U > N then
            raise Invalid_Argument;
         end if;
         Add_Edge (U, V);
         Add_Edge (U, V);
      end loop;

      --  Hierholzer from vertex 1.
      Sp := 1;
      Stack (1) := 1;
      while Sp > 0 loop
         U := Stack (Sp);
         if Alen (U) > 0 then
            V := Adj (U)(Alen (U));
            Remove_Edge (U, V);
            Sp := Sp + 1;
            Stack (Sp) := V;
         else
            Circ_Len := Circ_Len + 1;
            Circuit (Circ_Len) := U;
            Sp := Sp - 1;
         end if;
      end loop;

      --  Shortcut: first occurrence of each vertex, starting at 1.
      --  Circuit is in reverse Hierholzer order; scan and keep uniques.
      Result.N := N;
      Result.Cities := [others => Vertex_Id'First];
      Count := 0;
      for I in reverse 1 .. Circ_Len loop
         U := Circuit (I);
         if U >= 1 and then U <= N and then not Seen (U) then
            Seen (U) := True;
            Count := Count + 1;
            Result.Cities (Count) := Vertex_Id (U);
         end if;
      end loop;

      if Count /= N then
         raise Invalid_Argument;
      end if;

      --  Rotate so Cities(1) = 1.
      declare
         Pos1 : Natural := 0;
         Rot  : City_Seq := [others => Vertex_Id'First];
      begin
         for I in 1 .. N loop
            if Result.Cities (I) = 1 then
               Pos1 := I;
               exit;
            end if;
         end loop;
         if Pos1 = 0 then
            raise Invalid_Argument;
         end if;
         for I in 1 .. N loop
            Rot (I) := Result.Cities (((Pos1 + I - 2) mod N) + 1);
         end loop;
         Result.Cities := Rot;
      end;

      Result.Cost := Closed_Tour_Cost (Distances, Result.Cities, N);
      return Result;
   end Double_Tree_Tour;

end Travelling_Salesman_Problem;
