--  Nearest_Neighbor_Algorithm body — matrix validation, NN construction,
--  all-starts Best_Tour, and exact (N−1)! enumeration for N ≤ 10.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Nearest_Neighbor_Algorithm
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

   function Tour_From
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
         Found := False;
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
                  Found := True;
                  Best_C := Cand_C;
                  Best_V := Vertex_Id (Cand);
               end if;
            end if;
         end loop;
         --  Complete graph ⇒ an unvisited city always exists for Step ≤ N.
         Result.Cities (Step) := Best_V;
         Visited (Natural (Best_V)) := True;
         Current := Best_V;
      end loop;

      Result.Cost := Closed_Tour_Cost (Distances, Result.Cities, N);
      return Result;
   end Tour_From;

   function Best_Tour (Distances : Cost_Matrix) return Tour is
      N     : Natural;
      Best  : Tour;
      Cand  : Tour;
      First : Boolean := True;
   begin
      Require_Valid_Matrix (Distances, N);
      for S in 1 .. N loop
         Cand := Tour_From (Distances, Vertex_Id (S));
         if First
           or else Cand.Cost < Best.Cost
           or else (Cand.Cost = Best.Cost
                    and then Cand.Cities (1) < Best.Cities (1))
         then
            Best := Cand;
            First := False;
         end if;
      end loop;
      return Best;
   end Best_Tour;

   ---------------------------------------------------------------------------
   -- Exact brute-force oracle (N ≤ Max_Exact_Vertices)
   ---------------------------------------------------------------------------

   function Exact_Tour (Distances : Cost_Matrix) return Tour is
      N      : Natural;
      Best   : Tour;
      Perm   : City_Seq := [others => Vertex_Id'First];
      Used   : array (1 .. Max_Exact_Vertices) of Boolean :=
        [others => False];
      First  : Boolean := True;

      procedure Consider is
         C : Cost_Value;
      begin
         C := Closed_Tour_Cost (Distances, Perm, N);
         if First or else C < Best.Cost then
            Best.N := N;
            Best.Cities := Perm;
            Best.Cost := C;
            First := False;
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
      if N > Max_Exact_Vertices then
         raise Invalid_Argument;
      end if;

      if N = 1 then
         Best.N := 1;
         Best.Cities (1) := 1;
         Best.Cost := Distances (1, 1);
         return Best;
      end if;

      --  Fix start at city 1; permute the remaining positions.
      --  Every directed Hamiltonian cycle has a unique rotation with
      --  Cities(1) = 1, so this enumerates all directed cycles once.
      Perm (1) := 1;
      Used (1) := True;
      Recurse (2);
      return Best;
   end Exact_Tour;

end Nearest_Neighbor_Algorithm;
