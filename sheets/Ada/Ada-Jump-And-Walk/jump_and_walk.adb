--  Jump_And_Walk body — point location via jump samples + Lawson walk.

pragma Ada_2022;

with Ada.Numerics.Discrete_Random;

package body Jump_And_Walk
  with SPARK_Mode => Off
is

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

   ---------------------------------------------------------------------------
   -- Orientation / point-in-triangle
   ---------------------------------------------------------------------------

   function Orient2D (A, B, C : Point) return Real is
   begin
      --  (Bx - Ax)*(Cy - Ay) - (By - Ay)*(Cx - Ax)
      return (B.X - A.X) * (C.Y - A.Y) - (B.Y - A.Y) * (C.X - A.X);
   end Orient2D;

   function CCW (A, B, C : Point) return Boolean is
   begin
      return Orient2D (A, B, C) > Epsilon;
   end CCW;

   function Point_In_Triangle
     (Q : Point; A, B, C : Point) return Boolean
   is
      --  Same half-plane for each oriented edge (closed triangle).
      --  Allow a small negative band so boundary points count as inside.
      O1 : constant Real := Orient2D (A, B, Q);
      O2 : constant Real := Orient2D (B, C, Q);
      O3 : constant Real := Orient2D (C, A, Q);
   begin
      return O1 >= -Epsilon
        and then O2 >= -Epsilon
        and then O3 >= -Epsilon;
   end Point_In_Triangle;

   function Point_In_Triangle
     (Q : Point; M : Mesh; T : Triangle_Index) return Boolean
   is
      Tri : constant Triangle := M.Tris (T);
   begin
      return Point_In_Triangle
        (Q,
         M.Points (Tri.A),
         M.Points (Tri.B),
         M.Points (Tri.C));
   end Point_In_Triangle;

   function Centroid (A, B, C : Point) return Point is
   begin
      return (X => (A.X + B.X + C.X) / 3.0,
              Y => (A.Y + B.Y + C.Y) / 3.0);
   end Centroid;

   function Centroid (M : Mesh; T : Triangle_Index) return Point is
      Tri : constant Triangle := M.Tris (T);
   begin
      return Centroid
        (M.Points (Tri.A), M.Points (Tri.B), M.Points (Tri.C));
   end Centroid;

   ---------------------------------------------------------------------------
   -- Mesh accessors / fan builder
   ---------------------------------------------------------------------------

   function Triangle_Count_Of (M : Mesh) return Triangle_Count is
   begin
      return M.Num_Triangles;
   end Triangle_Count_Of;

   function Get_Triangle
     (M : Mesh; Index : Triangle_Index) return Triangle
   is
   begin
      return M.Tris (Index);
   end Get_Triangle;

   function Get_Neighbors
     (M : Mesh; Index : Triangle_Index) return Adjacency
   is
   begin
      return M.Neighbors (Index);
   end Get_Neighbors;

   function Build_Convex_Fan (Points : Point_Array) return Mesh is
      N : constant Natural := Points'Length;
      M : Mesh;
      T : Triangle_Index;
   begin
      if N < 3 then
         raise Invalid_Argument;
      end if;
      if N > Max_Points then
         raise Invalid_Argument;
      end if;
      --  Fan of N-2 triangles; must fit Max_Triangles.
      if N - 2 > Max_Triangles then
         raise Capacity_Exceeded;
      end if;

      M.Num_Points := Point_Count (N);
      for I in 1 .. N loop
         M.Points (Point_Index (I)) :=
           Points (Points'First + Point_Index (I) - 1);
      end loop;

      --  Triangles (1, i, i+1) for i = 2 .. N-1  ⇒ indices 1 .. N-2.
      M.Num_Triangles := Triangle_Count (N - 2);
      for K in 1 .. M.Num_Triangles loop
         --  K corresponds to apex edge from vertex (K+1) to (K+2).
         T := Triangle_Index (K);
         M.Tris (T) :=
           (A => 1,
            B => Point_Index (K + 1),
            C => Point_Index (K + 2));

         --  N1 opposite A = across BC (outer polygon edge) → boundary.
         --  N2 opposite B = across CA = edge (1, C) → next fan triangle.
         --  N3 opposite C = across AB = edge (1, B) → prev fan triangle.
         M.Neighbors (T).N1 := -1;
         if K < M.Num_Triangles then
            M.Neighbors (T).N2 := Neighbor_Id (K + 1);
         else
            M.Neighbors (T).N2 := -1;
         end if;
         if K > 1 then
            M.Neighbors (T).N3 := Neighbor_Id (K - 1);
         else
            M.Neighbors (T).N3 := -1;
         end if;
      end loop;

      return M;
   end Build_Convex_Fan;

   ---------------------------------------------------------------------------
   -- Walk_From (Lawson / Green–Sibson)
   ---------------------------------------------------------------------------

   function Walk_From
     (Query : Point;
      M     : Mesh;
      Start : Triangle_Index) return Locate_Result
   is
      Curr  : Triangle_Index := Start;
      Steps : Natural := 0;
      Tri   : Triangle;
      Adj   : Adjacency;
      PA, PB, PC : Point;
      O_AB, O_BC, O_CA : Real;
      Next  : Neighbor_Id;
   begin
      loop
         if Point_In_Triangle (Query, M, Curr) then
            return Locate_Result (Curr);
         end if;

         Steps := Steps + 1;
         if Steps > Max_Triangles then
            --  Corrupted adjacency or numerical stall: give up.
            return 0;
         end if;

         Tri := M.Tris (Curr);
         Adj := M.Neighbors (Curr);
         PA  := M.Points (Tri.A);
         PB  := M.Points (Tri.B);
         PC  := M.Points (Tri.C);

         --  For a CCW triangle, Query is outside across the first edge
         --  for which Orient2D (edge_start, edge_end, Query) < 0.
         --  Edge AB opposite C → neighbor N3; BC opposite A → N1;
         --  CA opposite B → N2.
         O_AB := Orient2D (PA, PB, Query);
         O_BC := Orient2D (PB, PC, Query);
         O_CA := Orient2D (PC, PA, Query);

         Next := -1;
         if O_AB < -Epsilon then
            Next := Adj.N3;
         elsif O_BC < -Epsilon then
            Next := Adj.N1;
         elsif O_CA < -Epsilon then
            Next := Adj.N2;
         else
            --  All orientations non-negative but Point_In_Triangle failed
            --  (numerical edge case): treat as found.
            return Locate_Result (Curr);
         end if;

         if Next < 1 then
            --  Boundary exit ⇒ Query outside the mesh.
            return 0;
         end if;

         Curr := Triangle_Index (Next);
      end loop;
   end Walk_From;

   ---------------------------------------------------------------------------
   -- Jump-and-Walk
   ---------------------------------------------------------------------------

   function Jump_Start
     (Query        : Point;
      M            : Mesh;
      Seed         : Natural;
      Sample_Count : Positive) return Triangle_Index
   is
      subtype Tri_Range is Triangle_Index
        range 1 .. Triangle_Index (M.Num_Triangles);
      package Tri_RNG is new Ada.Numerics.Discrete_Random (Tri_Range);
      Gen : Tri_RNG.Generator;

      Budget : Positive;
      Best   : Triangle_Index := 1;
      Best_D : Real;
      Cand   : Triangle_Index;
      D      : Real;
      Effective_Seed : Integer;
   begin
      if M.Num_Triangles = 1 then
         return 1;
      end if;

      Budget := Sample_Count;
      if Budget > Positive (M.Num_Triangles) then
         Budget := Positive (M.Num_Triangles);
      end if;

      --  Map Seed to Discrete_Random's Reset seed; 0 → fixed classroom seed.
      if Seed = 0 then
         Effective_Seed := 42;
      else
         Effective_Seed := Integer (Seed mod Natural (Integer'Last));
      end if;
      Tri_RNG.Reset (Gen, Effective_Seed);

      Best   := Tri_RNG.Random (Gen);
      Best_D := Dist2 (Centroid (M, Best), Query);

      for I in 2 .. Budget loop
         Cand := Tri_RNG.Random (Gen);
         D    := Dist2 (Centroid (M, Cand), Query);
         if D < Best_D then
            Best_D := D;
            Best   := Cand;
         end if;
      end loop;

      return Best;
   end Jump_Start;

   function Locate_Jump_And_Walk
     (Query         : Point;
      M             : Mesh;
      Seed          : Natural := 0;
      Sample_Count  : Positive := Default_Sample_Count) return Locate_Result
   is
      Start : Triangle_Index;
   begin
      if M.Num_Triangles = 0 then
         raise Invalid_Argument;
      end if;

      Start := Jump_Start (Query, M, Seed, Sample_Count);
      return Walk_From (Query, M, Start);
   end Locate_Jump_And_Walk;

   function Locate
     (Query : Point;
      M     : Mesh;
      Seed  : Natural := 0) return Locate_Result
   is
   begin
      return Locate_Jump_And_Walk
        (Query, M, Seed, Default_Sample_Count);
   end Locate;

end Jump_And_Walk;
