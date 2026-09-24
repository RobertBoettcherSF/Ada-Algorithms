--  Quasitriangulation body — educational classroom implementation.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Quasitriangulation
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Elementary_Functions;

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

   function Distance (A, B : Point) return Real is
      D2 : constant Real := Dist2 (A, B);
   begin
      if D2 <= 0.0 then
         return 0.0;
      end if;
      return Real (Math.Sqrt (Float (D2)));
   end Distance;

   function Midpoint (S : Segment) return Point is
   begin
      return (X => 0.5 * (S.A.X + S.B.X), Y => 0.5 * (S.A.Y + S.B.Y));
   end Midpoint;

   function Segment_Length (S : Segment) return Real is
   begin
      return Distance (S.A, S.B);
   end Segment_Length;

   function Is_Point_Site (S : Segment; Tol : Real := Epsilon) return Boolean is
   begin
      return Near_Point (S.A, S.B, Tol);
   end Is_Point_Site;

   function Orient2D (A, B, C : Point) return Real is
   begin
      return (B.X - A.X) * (C.Y - A.Y) - (B.Y - A.Y) * (C.X - A.X);
   end Orient2D;

   function CCW (A, B, C : Point) return Boolean is
   begin
      return Orient2D (A, B, C) > Epsilon;
   end CCW;

   ---------------------------------------------------------------------------
   -- Segment intersection (educational)
   ---------------------------------------------------------------------------

   function On_Segment (P, A, B : Point) return Boolean is
      --  P collinear with AB and within the axis-aligned box of AB.
      Cross : constant Real := Orient2D (A, B, P);
      Dot   : Real;
   begin
      if abs (Cross) > Epsilon then
         return False;
      end if;
      Dot := (P.X - A.X) * (B.X - A.X) + (P.Y - A.Y) * (B.Y - A.Y);
      if Dot < -Epsilon then
         return False;
      end if;
      return Dot <= Dist2 (A, B) + Epsilon;
   end On_Segment;

   function Endpoints_Touch (S, T : Segment) return Boolean is
   begin
      return Near_Point (S.A, T.A)
        or else Near_Point (S.A, T.B)
        or else Near_Point (S.B, T.A)
        or else Near_Point (S.B, T.B);
   end Endpoints_Touch;

   function Classify_Intersection (S, T : Segment) return Intersection_Kind is
      O1 : constant Real := Orient2D (S.A, S.B, T.A);
      O2 : constant Real := Orient2D (S.A, S.B, T.B);
      O3 : constant Real := Orient2D (T.A, T.B, S.A);
      O4 : constant Real := Orient2D (T.A, T.B, S.B);
      S1, S2, S3, S4 : Integer;
   begin
      --  Sign helpers with epsilon band treated as zero.
      if abs (O1) <= Epsilon then
         S1 := 0;
      elsif O1 > 0.0 then
         S1 := 1;
      else
         S1 := -1;
      end if;
      if abs (O2) <= Epsilon then
         S2 := 0;
      elsif O2 > 0.0 then
         S2 := 1;
      else
         S2 := -1;
      end if;
      if abs (O3) <= Epsilon then
         S3 := 0;
      elsif O3 > 0.0 then
         S3 := 1;
      else
         S3 := -1;
      end if;
      if abs (O4) <= Epsilon then
         S4 := 0;
      elsif O4 > 0.0 then
         S4 := 1;
      else
         S4 := -1;
      end if;

      --  Proper crossing: endpoints of each on opposite sides of the other.
      if S1 * S2 < 0 and then S3 * S4 < 0 then
         return Proper_Cross;
      end if;

      --  Collinear overlap: all orientations ~0 and projections overlap.
      if S1 = 0 and then S2 = 0 and then S3 = 0 and then S4 = 0 then
         if On_Segment (T.A, S.A, S.B)
           or else On_Segment (T.B, S.A, S.B)
           or else On_Segment (S.A, T.A, T.B)
           or else On_Segment (S.B, T.A, T.B)
         then
            --  Distinguish pure endpoint touch from positive-length overlap.
            if Endpoints_Touch (S, T)
              and then not
                (On_Segment (T.A, S.A, S.B)
                   and then not Near_Point (T.A, S.A)
                   and then not Near_Point (T.A, S.B))
              and then not
                (On_Segment (T.B, S.A, S.B)
                   and then not Near_Point (T.B, S.A)
                   and then not Near_Point (T.B, S.B))
              and then not
                (On_Segment (S.A, T.A, T.B)
                   and then not Near_Point (S.A, T.A)
                   and then not Near_Point (S.A, T.B))
              and then not
                (On_Segment (S.B, T.A, T.B)
                   and then not Near_Point (S.B, T.A)
                   and then not Near_Point (S.B, T.B))
            then
               return Endpoint_Touch;
            end if;
            --  If any interior-ish point of one lies on the other → overlap.
            if (On_Segment (T.A, S.A, S.B)
                  and then not Near_Point (T.A, S.A)
                  and then not Near_Point (T.A, S.B))
              or else (On_Segment (T.B, S.A, S.B)
                  and then not Near_Point (T.B, S.A)
                  and then not Near_Point (T.B, S.B))
              or else (On_Segment (S.A, T.A, T.B)
                  and then not Near_Point (S.A, T.A)
                  and then not Near_Point (S.A, T.B))
              or else (On_Segment (S.B, T.A, T.B)
                  and then not Near_Point (S.B, T.A)
                  and then not Near_Point (S.B, T.B))
            then
               return Collinear_Overlap;
            end if;
            if Endpoints_Touch (S, T) then
               return Endpoint_Touch;
            end if;
            return None;
         end if;
         return None;
      end if;

      --  Endpoint / grazing touch (one orientation zero, point on segment).
      if S1 = 0 and then On_Segment (T.A, S.A, S.B) then
         return Endpoint_Touch;
      end if;
      if S2 = 0 and then On_Segment (T.B, S.A, S.B) then
         return Endpoint_Touch;
      end if;
      if S3 = 0 and then On_Segment (S.A, T.A, T.B) then
         return Endpoint_Touch;
      end if;
      if S4 = 0 and then On_Segment (S.B, T.A, T.B) then
         return Endpoint_Touch;
      end if;

      return None;
   end Classify_Intersection;

   function Segments_Properly_Cross (S, T : Segment) return Boolean is
   begin
      return Classify_Intersection (S, T) = Proper_Cross;
   end Segments_Properly_Cross;

   function Has_Proper_Crossing (Segs : Segment_Array) return Boolean is
   begin
      for I in Segs'Range loop
         for J in Segs'Range loop
            if J > I then
               if Segments_Properly_Cross (Segs (I), Segs (J)) then
                  return True;
               end if;
            end if;
         end loop;
      end loop;
      return False;
   end Has_Proper_Crossing;

   function All_Point_Sites
     (Segs : Segment_Array; Tol : Real := Epsilon) return Boolean
   is
   begin
      for S of Segs loop
         if not Is_Point_Site (S, Tol) then
            return False;
         end if;
      end loop;
      return Segs'Length > 0;
   end All_Point_Sites;

   function Is_Classical_Point_Setting
     (M : Quasi_Mesh; Tol : Real := Epsilon) return Boolean
   is
   begin
      if M.Seg_N = 0 then
         return False;
      end if;
      return All_Point_Sites (M.Segs (1 .. M.Seg_N), Tol);
   end Is_Classical_Point_Setting;

   function Is_Quasi_Setting
     (M : Quasi_Mesh; Tol : Real := Epsilon) return Boolean
   is
   begin
      if M.Seg_N = 0 then
         return False;
      end if;
      for I in 1 .. M.Seg_N loop
         if not Is_Point_Site (M.Segs (I), Tol) then
            return True;
         end if;
      end loop;
      return False;
   end Is_Quasi_Setting;

   ---------------------------------------------------------------------------
   -- Edge bookkeeping
   ---------------------------------------------------------------------------

   function Ordered_Edge (A, B : Segment_Index) return Edge is
   begin
      if A < B then
         return (P => A, Q => B);
      else
         return (P => B, Q => A);
      end if;
   end Ordered_Edge;

   function Edge_Equal (E1, E2 : Edge) return Boolean is
   begin
      return E1.P = E2.P and then E1.Q = E2.Q;
   end Edge_Equal;

   procedure Add_Edge_Unique (M : in out Quasi_Mesh; A, B : Segment_Index) is
      E : constant Edge := Ordered_Edge (A, B);
   begin
      if A = B then
         return;
      end if;
      for I in 1 .. M.Edge_N loop
         if Edge_Equal (M.Edges (I), E) then
            return;
         end if;
      end loop;
      if M.Edge_N = Max_Edges then
         raise Capacity_Exceeded;
      end if;
      M.Edge_N := M.Edge_N + 1;
      M.Edges (M.Edge_N) := E;
   end Add_Edge_Unique;

   procedure Rebuild_Edges_From_Faces (M : in out Quasi_Mesh) is
   begin
      M.Edge_N := 0;
      for I in 1 .. M.Face_N loop
         declare
            F : constant Simplex := M.Faces (I);
         begin
            Add_Edge_Unique (M, F.U, F.V);
            Add_Edge_Unique (M, F.V, F.W);
            Add_Edge_Unique (M, F.W, F.U);
         end;
      end loop;
   end Rebuild_Edges_From_Faces;

   ---------------------------------------------------------------------------
   -- Tiny midpoint triangulation (fan from lowest-left midpoint)
   ---------------------------------------------------------------------------

   function Lex_Less (P, Q : Point) return Boolean is
   begin
      if P.Y < Q.Y - Epsilon then
         return True;
      elsif abs (P.Y - Q.Y) <= Epsilon and then P.X < Q.X - Epsilon then
         return True;
      else
         return False;
      end if;
   end Lex_Less;

   function Build_From_Segments (Segs : Segment_Array) return Quasi_Mesh is
      N : constant Natural := Segs'Length;
      M : Quasi_Mesh;
      Mids : array (1 .. Max_Segments) of Point := [others => (0.0, 0.0)];
      --  Sorted order of segment indices by midpoint (Y then X).
      Order : array (1 .. Max_Segments) of Segment_Index := [others => 1];
      Origin : Segment_Index;
      Origin_Pt : Point;
   begin
      if N < 3 or else N > Max_Segments then
         raise Invalid_Argument;
      end if;

      --  Copy sites; reject point-sites / degeneracies for the quasi builder.
      M.Seg_N := Segment_Count (N);
      for I in 0 .. N - 1 loop
         declare
            S : constant Segment := Segs (Segs'First + I);
         begin
            if Is_Point_Site (S) then
               raise Invalid_Argument;
            end if;
            M.Segs (I + 1) := S;
            Mids (I + 1) := Midpoint (S);
            Order (I + 1) := Segment_Index (I + 1);
         end;
      end loop;

      if Has_Proper_Crossing (M.Segs (1 .. M.Seg_N)) then
         raise Invalid_Argument;
      end if;

      --  Also reject collinear overlaps (educational policy: sites must be
      --  combinatorially independent enough to act as distinct vertices).
      for I in 1 .. M.Seg_N loop
         for J in I + 1 .. M.Seg_N loop
            if Classify_Intersection (M.Segs (I), M.Segs (J)) =
              Collinear_Overlap
            then
               raise Invalid_Argument;
            end if;
         end loop;
      end loop;

      --  Insertion sort Order by midpoint lex (Y, X).
      for I in 2 .. M.Seg_N loop
         declare
            Key : constant Segment_Index := Order (I);
            Key_Pt : constant Point := Mids (Key);
            J : Integer := Integer (I) - 1;
         begin
            while J >= 1 and then Lex_Less (Key_Pt, Mids (Order (J))) loop
               Order (J + 1) := Order (J);
               J := J - 1;
            end loop;
            Order (J + 1) := Key;
         end;
      end loop;

      Origin := Order (1);
      Origin_Pt := Mids (Origin);

      --  Sort the remaining midpoints angularly around Origin (CCW by Orient2D
      --  then by distance). Educational polar sort.
      for I in 2 .. M.Seg_N loop
         for J in I + 1 .. M.Seg_N loop
            declare
               PI : constant Point := Mids (Order (I));
               PJ : constant Point := Mids (Order (J));
               Cross : constant Real := Orient2D (Origin_Pt, PI, PJ);
               Swap_Needed : Boolean := False;
            begin
               if Cross < -Epsilon then
                  Swap_Needed := True;
               elsif abs (Cross) <= Epsilon
                 and then Dist2 (Origin_Pt, PJ) < Dist2 (Origin_Pt, PI)
               then
                  Swap_Needed := True;
               end if;
               if Swap_Needed then
                  declare
                     Tmp : constant Segment_Index := Order (I);
                  begin
                     Order (I) := Order (J);
                     Order (J) := Tmp;
                  end;
               end if;
            end;
         end loop;
      end loop;

      --  Fan triangulation: faces (Origin, Order(K), Order(K+1)) for K=2..N-1
      --  when the triple is non-collinear (strict CCW or CW).
      M.Face_N := 0;
      for K in 2 .. Integer (M.Seg_N) - 1 loop
         declare
            U : constant Segment_Index := Origin;
            V : constant Segment_Index := Order (K);
            W : constant Segment_Index := Order (K + 1);
            O : constant Real :=
              Orient2D (Mids (U), Mids (V), Mids (W));
         begin
            if abs (O) > Epsilon then
               if M.Face_N = Max_Faces then
                  raise Capacity_Exceeded;
               end if;
               M.Face_N := M.Face_N + 1;
               if O > 0.0 then
                  M.Faces (M.Face_N) := (U => U, V => V, W => W);
               else
                  M.Faces (M.Face_N) := (U => U, V => W, W => V);
               end if;
            end if;
         end;
      end loop;

      if M.Face_N = 0 then
         --  All midpoints collinear — cannot form a topological triangle.
         raise Invalid_Argument;
      end if;

      Rebuild_Edges_From_Faces (M);
      return M;
   end Build_From_Segments;

   function From_Point_Sites (Pts : Point_Array) return Quasi_Mesh is
      N : constant Natural := Pts'Length;
      Segs : Segment_Array (1 .. Max_Segments);
      M : Quasi_Mesh;
      Mids : array (1 .. Max_Segments) of Point := [others => (0.0, 0.0)];
      Order : array (1 .. Max_Segments) of Segment_Index := [others => 1];
      Origin : Segment_Index;
      Origin_Pt : Point;
   begin
      if N < 3 or else N > Max_Segments then
         raise Invalid_Argument;
      end if;

      --  Near-duplicate points rejected.
      for I in Pts'Range loop
         for J in Pts'Range loop
            if J > I and then Near_Point (Pts (I), Pts (J)) then
               raise Invalid_Argument;
            end if;
         end loop;
      end loop;

      M.Seg_N := Segment_Count (N);
      for I in 0 .. N - 1 loop
         declare
            Pt : constant Point := Pts (Pts'First + I);
         begin
            Segs (I + 1) := (A => Pt, B => Pt);
            M.Segs (I + 1) := Segs (I + 1);
            Mids (I + 1) := Pt;
            Order (I + 1) := Segment_Index (I + 1);
         end;
      end loop;

      for I in 2 .. M.Seg_N loop
         declare
            Key : constant Segment_Index := Order (I);
            Key_Pt : constant Point := Mids (Key);
            J : Integer := Integer (I) - 1;
         begin
            while J >= 1 and then Lex_Less (Key_Pt, Mids (Order (J))) loop
               Order (J + 1) := Order (J);
               J := J - 1;
            end loop;
            Order (J + 1) := Key;
         end;
      end loop;

      Origin := Order (1);
      Origin_Pt := Mids (Origin);

      for I in 2 .. M.Seg_N loop
         for J in I + 1 .. M.Seg_N loop
            declare
               PI : constant Point := Mids (Order (I));
               PJ : constant Point := Mids (Order (J));
               Cross : constant Real := Orient2D (Origin_Pt, PI, PJ);
               Swap_Needed : Boolean := False;
            begin
               if Cross < -Epsilon then
                  Swap_Needed := True;
               elsif abs (Cross) <= Epsilon
                 and then Dist2 (Origin_Pt, PJ) < Dist2 (Origin_Pt, PI)
               then
                  Swap_Needed := True;
               end if;
               if Swap_Needed then
                  declare
                     Tmp : constant Segment_Index := Order (I);
                  begin
                     Order (I) := Order (J);
                     Order (J) := Tmp;
                  end;
               end if;
            end;
         end loop;
      end loop;

      M.Face_N := 0;
      for K in 2 .. Integer (M.Seg_N) - 1 loop
         declare
            U : constant Segment_Index := Origin;
            V : constant Segment_Index := Order (K);
            W : constant Segment_Index := Order (K + 1);
            O : constant Real :=
              Orient2D (Mids (U), Mids (V), Mids (W));
         begin
            if abs (O) > Epsilon then
               if M.Face_N = Max_Faces then
                  raise Capacity_Exceeded;
               end if;
               M.Face_N := M.Face_N + 1;
               if O > 0.0 then
                  M.Faces (M.Face_N) := (U => U, V => V, W => W);
               else
                  M.Faces (M.Face_N) := (U => U, V => W, W => V);
               end if;
            end if;
         end;
      end loop;

      if M.Face_N = 0 then
         raise Invalid_Argument;
      end if;

      Rebuild_Edges_From_Faces (M);
      return M;
   end From_Point_Sites;

   ---------------------------------------------------------------------------
   -- Accessors / queries
   ---------------------------------------------------------------------------

   function Segment_Count_Of (M : Quasi_Mesh) return Segment_Count is
   begin
      return M.Seg_N;
   end Segment_Count_Of;

   function Face_Count (M : Quasi_Mesh) return Face_Count_T is
   begin
      return M.Face_N;
   end Face_Count;

   function Edge_Count (M : Quasi_Mesh) return Edge_Count_T is
   begin
      return M.Edge_N;
   end Edge_Count;

   function Get_Segment
     (M : Quasi_Mesh; Index : Segment_Index) return Segment
   is
   begin
      return M.Segs (Index);
   end Get_Segment;

   function Get_Face
     (M : Quasi_Mesh; Index : Face_Index) return Simplex
   is
   begin
      return M.Faces (Index);
   end Get_Face;

   function Get_Edge
     (M : Quasi_Mesh; Index : Edge_Index) return Edge
   is
   begin
      return M.Edges (Index);
   end Get_Edge;

   function Faces_Reference_Valid_Sites (M : Quasi_Mesh) return Boolean is
   begin
      if M.Seg_N = 0 then
         return False;
      end if;
      for I in 1 .. M.Face_N loop
         declare
            F : constant Simplex := M.Faces (I);
         begin
            if F.U > M.Seg_N or else F.V > M.Seg_N or else F.W > M.Seg_N then
               return False;
            end if;
            if F.U = F.V or else F.V = F.W or else F.W = F.U then
               return False;
            end if;
         end;
      end loop;
      return M.Face_N >= 1;
   end Faces_Reference_Valid_Sites;

   function Euler_Characteristic (M : Quasi_Mesh) return Integer is
   begin
      return Integer (M.Seg_N) - Integer (M.Edge_N) + Integer (M.Face_N);
   end Euler_Characteristic;

   function Euler_Check (M : Quasi_Mesh) return Boolean is
   begin
      return Euler_Characteristic (M) = 1;
   end Euler_Check;

   function Is_Topological_Triangulation (M : Quasi_Mesh) return Boolean is
   begin
      if M.Seg_N < 3 or else M.Face_N < 1 then
         return False;
      end if;
      if not Faces_Reference_Valid_Sites (M) then
         return False;
      end if;
      if M.Edge_N < 3 then
         return False;
      end if;
      --  Every face side must appear in the edge table.
      for I in 1 .. M.Face_N loop
         declare
            F : constant Simplex := M.Faces (I);
            E1 : constant Edge := Ordered_Edge (F.U, F.V);
            E2 : constant Edge := Ordered_Edge (F.V, F.W);
            E3 : constant Edge := Ordered_Edge (F.W, F.U);
            Found1, Found2, Found3 : Boolean := False;
         begin
            for J in 1 .. M.Edge_N loop
               if Edge_Equal (M.Edges (J), E1) then
                  Found1 := True;
               end if;
               if Edge_Equal (M.Edges (J), E2) then
                  Found2 := True;
               end if;
               if Edge_Equal (M.Edges (J), E3) then
                  Found3 := True;
               end if;
            end loop;
            if not (Found1 and then Found2 and then Found3) then
               return False;
            end if;
         end;
      end loop;
      return Euler_Check (M);
   end Is_Topological_Triangulation;

   function Refine_Toward_Delaunay_Like (M : Quasi_Mesh) return Quasi_Mesh is
      R : Quasi_Mesh := M;
      --  Educational stub: optionally flip a face orientation so midpoints
      --  are CCW; no real Lawson flip / empty-circle optimization.
   begin
      if M.Seg_N = 0 or else M.Face_N = 0 then
         raise Invalid_Argument;
      end if;
      for I in 1 .. R.Face_N loop
         declare
            F : constant Simplex := R.Faces (I);
            Mu : constant Point := Midpoint (R.Segs (F.U));
            Mv : constant Point := Midpoint (R.Segs (F.V));
            Mw : constant Point := Midpoint (R.Segs (F.W));
         begin
            if Orient2D (Mu, Mv, Mw) < -Epsilon then
               --  Swap V/W to restore CCW proxy orientation.
               R.Faces (I) := (U => F.U, V => F.W, W => F.V);
            end if;
         end;
      end loop;
      Rebuild_Edges_From_Faces (R);
      return R;
   end Refine_Toward_Delaunay_Like;

end Quasitriangulation;
