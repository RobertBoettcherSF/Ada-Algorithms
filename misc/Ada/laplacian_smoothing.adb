--  Laplacian_Smoothing body — Jacobi umbrella / Laplacian vertex
--  smoothing with optional Dirichlet pinning (educational).

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Laplacian_Smoothing
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Point (A, B : Point; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Near_Point;

   function Dist2 (A, B : Point) return Real is
      DX : constant Real := A.X - B.X;
      DY : constant Real := A.Y - B.Y;
   begin
      return DX * DX + DY * DY;
   end Dist2;

   function Dist (A, B : Point) return Real is
   begin
      return Real (Math.Sqrt (Long_Float (Dist2 (A, B))));
   end Dist;

   function Lerp (A, B : Point; T : Real) return Point is
   begin
      return
        (X => (1.0 - T) * A.X + T * B.X,
         Y => (1.0 - T) * A.Y + T * B.Y);
   end Lerp;

   ---------------------------------------------------------------------------
   -- Adjacency construction
   ---------------------------------------------------------------------------

   function Empty_Adjacency return Adjacency is
   begin
      return (Neighbors => [others => 1], Count => 0);
   end Empty_Adjacency;

   function Has_Neighbor (Adj : Adjacency; V : Vertex_Index) return Boolean is
   begin
      for K in 1 .. Adj.Count loop
         if Adj.Neighbors (K) = V then
            return True;
         end if;
      end loop;
      return False;
   end Has_Neighbor;

   procedure Add_Neighbor (Adj : in out Adjacency; V : Vertex_Index) is
   begin
      if Has_Neighbor (Adj, V) then
         return;
      end if;
      if Adj.Count = Max_Degree then
         raise Invalid_Argument;
      end if;
      Adj.Count := Adj.Count + 1;
      Adj.Neighbors (Adj.Count) := V;
   end Add_Neighbor;

   function Build_Adjacency
     (Num_Vertices : Vertex_Count;
      Edges        : Edge_Array) return Adjacency_Array
   is
      Result : Adjacency_Array (1 .. Num_Vertices);
   begin
      if Num_Vertices = 0 then
         raise Invalid_Argument;
      end if;

      for I in Result'Range loop
         Result (I) := Empty_Adjacency;
      end loop;

      for E of Edges loop
         if Natural (E.A) > Natural (Num_Vertices)
           or else Natural (E.B) > Natural (Num_Vertices)
           or else E.A = E.B
         then
            raise Invalid_Argument;
         end if;
         Add_Neighbor (Result (E.A), E.B);
         Add_Neighbor (Result (E.B), E.A);
      end loop;

      return Result;
   end Build_Adjacency;

   function All_Free (First, Last : Vertex_Index) return Fixed_Flags is
      Result : constant Fixed_Flags (First .. Last) := [others => False];
   begin
      return Result;
   end All_Free;

   function Neighbor_Average
     (Vertices : Point_Array;
      Adj      : Adjacency) return Point
   is
      SX, SY : Real := 0.0;
      N      : Vertex_Index;
      Inv    : Real;
   begin
      if Adj.Count = 0 then
         raise Invalid_Argument;
      end if;

      for K in 1 .. Adj.Count loop
         N := Adj.Neighbors (K);
         if N not in Vertices'Range then
            raise Invalid_Argument;
         end if;
         SX := SX + Vertices (N).X;
         SY := SY + Vertices (N).Y;
      end loop;

      Inv := 1.0 / Real (Adj.Count);
      return (X => SX * Inv, Y => SY * Inv);
   end Neighbor_Average;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   procedure Validate_Mesh
     (Vertices : Point_Array;
      Adj      : Adjacency_Array;
      Lambda   : Real;
      Fixed    : Fixed_Flags)
   is
   begin
      if Vertices'Length = 0
        or else Vertices'Length > Max_Vertices
        or else Adj'Length /= Vertices'Length
        or else Fixed'Length /= Vertices'Length
        or else Adj'First /= Vertices'First
        or else Adj'Last /= Vertices'Last
        or else Fixed'First /= Vertices'First
        or else Fixed'Last /= Vertices'Last
        or else Lambda <= 0.0
        or else Lambda > 1.0
      then
         raise Invalid_Argument;
      end if;
   end Validate_Mesh;

   ---------------------------------------------------------------------------
   -- Smoothing
   ---------------------------------------------------------------------------

   function Smooth_Once
     (Vertices : Point_Array;
      Adj      : Adjacency_Array;
      Lambda   : Real;
      Fixed    : Fixed_Flags) return Point_Array
   is
      Result : Point_Array (Vertices'Range);
      Avg    : Point;
   begin
      Validate_Mesh (Vertices, Adj, Lambda, Fixed);

      for I in Vertices'Range loop
         if Fixed (I) or else Adj (I).Count = 0 then
            Result (I) := Vertices (I);
         else
            Avg := Neighbor_Average (Vertices, Adj (I));
            Result (I) := Lerp (Vertices (I), Avg, Lambda);
         end if;
      end loop;

      return Result;
   end Smooth_Once;

   function Smooth_Once
     (Vertices : Point_Array;
      Adj      : Adjacency_Array;
      Lambda   : Real) return Point_Array
   is
   begin
      if Vertices'Length = 0 then
         raise Invalid_Argument;
      end if;
      return Smooth_Once
        (Vertices, Adj, Lambda, All_Free (Vertices'First, Vertices'Last));
   end Smooth_Once;

   function Smooth
     (Vertices   : Point_Array;
      Adj        : Adjacency_Array;
      Lambda     : Real;
      Iterations : Positive;
      Fixed      : Fixed_Flags) return Point_Array
   is
      Current : Point_Array := Vertices;
   begin
      if Iterations > Max_Iters then
         raise Invalid_Argument;
      end if;
      Validate_Mesh (Vertices, Adj, Lambda, Fixed);

      for Step in 1 .. Iterations loop
         Current := Smooth_Once (Current, Adj, Lambda, Fixed);
      end loop;

      return Current;
   end Smooth;

   function Smooth
     (Vertices   : Point_Array;
      Adj        : Adjacency_Array;
      Lambda     : Real;
      Iterations : Positive) return Point_Array
   is
   begin
      if Vertices'Length = 0 then
         raise Invalid_Argument;
      end if;
      return Smooth
        (Vertices, Adj, Lambda, Iterations,
         All_Free (Vertices'First, Vertices'Last));
   end Smooth;

   function Mean_Edge_Length
     (Vertices : Point_Array;
      Adj      : Adjacency_Array) return Real
   is
      Sum   : Real := 0.0;
      Count : Natural := 0;
      J     : Vertex_Index;
   begin
      if Vertices'Length = 0
        or else Adj'Length /= Vertices'Length
        or else Adj'First /= Vertices'First
        or else Adj'Last /= Vertices'Last
      then
         raise Invalid_Argument;
      end if;

      for I in Vertices'Range loop
         for K in 1 .. Adj (I).Count loop
            J := Adj (I).Neighbors (K);
            if J not in Vertices'Range then
               raise Invalid_Argument;
            end if;
            --  Count each undirected edge once (I < J).
            if J > I then
               Sum := Sum + Dist (Vertices (I), Vertices (J));
               Count := Count + 1;
            end if;
         end loop;
      end loop;

      if Count = 0 then
         raise Invalid_Argument;
      end if;

      return Sum / Real (Count);
   end Mean_Edge_Length;

end Laplacian_Smoothing;
