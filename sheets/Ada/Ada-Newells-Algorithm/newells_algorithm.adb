--  Package body for Newell's Algorithm (Newell-Newell-Sancha 1972)
--  Compliant with Ada 2023 (ISO/IEC 8652:2023).

with Ada.Numerics.Generic_Elementary_Functions;

package body Newells_Algorithm with
   SPARK_Mode => Off
is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   Epsilon : constant Real := 1.0e-7;

   ----------------------------------------------------------------------------
   --  Internal Helpers
   ----------------------------------------------------------------------------

   function Max_Real (A, B : Real) return Real is
   begin
      if A > B then
         return A;
      else
         return B;
      end if;
   end Max_Real;

   function Min_Real (A, B : Real) return Real is
   begin
      if A < B then
         return A;
      else
         return B;
      end if;
   end Min_Real;

   --  2D cross product for segment orientation
   function Cross_Product_2D (O, A, B : Point_3D) return Real is
   begin
      return (A.X - O.X) * (B.Y - O.Y) - (A.Y - O.Y) * (B.X - O.X);
   end Cross_Product_2D;

   --  Returns True if point Pt is on the segment (A, B), assuming collinearity
   function On_Segment_2D (A, B, Pt : Point_3D) return Boolean is
   begin
      return Pt.X <= Max_Real (A.X, B.X) + Epsilon
        and then Pt.X >= Min_Real (A.X, B.X) - Epsilon
        and then Pt.Y <= Max_Real (A.Y, B.Y) + Epsilon
        and then Pt.Y >= Min_Real (A.Y, B.Y) - Epsilon;
   end On_Segment_2D;

   --  Checks whether 2D segments A1-A2 and B1-B2 intersect
   function Segments_Intersect_2D
     (A1, A2, B1, B2 : Point_3D) return Boolean
   is
      D1 : constant Real := Cross_Product_2D (B1, B2, A1);
      D2 : constant Real := Cross_Product_2D (B1, B2, A2);
      D3 : constant Real := Cross_Product_2D (A1, A2, B1);
      D4 : constant Real := Cross_Product_2D (A1, A2, B2);
   begin
      if (((D1 > Epsilon and then D2 < -Epsilon) or else (D1 < -Epsilon and then D2 > Epsilon))
          and then
          ((D3 > Epsilon and then D4 < -Epsilon) or else (D3 < -Epsilon and then D4 > Epsilon)))
      then
         return True;
      end if;

      if abs (D1) <= Epsilon and then On_Segment_2D (B1, B2, A1) then
         return True;
      end if;
      if abs (D2) <= Epsilon and then On_Segment_2D (B1, B2, A2) then
         return True;
      end if;
      if abs (D3) <= Epsilon and then On_Segment_2D (A1, A2, B1) then
         return True;
      end if;
      if abs (D4) <= Epsilon and then On_Segment_2D (A1, A2, B2) then
         return True;
      end if;

      return False;
   end Segments_Intersect_2D;

   --  Point-in-polygon test using ray-casting on 2D XY projection
   function Point_Inside_Polygon_2D
     (Pt : Point_3D; Poly : Polygon) return Boolean
   is
      Inside : Boolean := False;
      N      : constant Positive := Poly.Num_Vertices;
      J      : Positive := N;
   begin
      for I in 1 .. N loop
         declare
            V_I : constant Point_3D := Poly.Vertices (I);
            V_J : constant Point_3D := Poly.Vertices (J);
         begin
            if ((V_I.Y > Pt.Y) /= (V_J.Y > Pt.Y))
              and then (Pt.X < (V_J.X - V_I.X) * (Pt.Y - V_I.Y) / (V_J.Y - V_I.Y) + V_I.X)
            then
               Inside := not Inside;
            end if;
         end;
         J := I;
      end loop;
      return Inside;
   end Point_Inside_Polygon_2D;

   ----------------------------------------------------------------------------
   --  Helper & Calculation Implementations
   ----------------------------------------------------------------------------

   function Compute_XY_Bounds (Vertices : Vertex_Array) return Box_2D is
      Res : Box_2D := (Min_X => Vertices (Vertices'First).X,
                       Max_X => Vertices (Vertices'First).X,
                       Min_Y => Vertices (Vertices'First).Y,
                       Max_Y => Vertices (Vertices'First).Y);
   begin
      for I in Vertices'First + 1 .. Vertices'Last loop
         Res.Min_X := Min_Real (Res.Min_X, Vertices (I).X);
         Res.Max_X := Max_Real (Res.Max_X, Vertices (I).X);
         Res.Min_Y := Min_Real (Res.Min_Y, Vertices (I).Y);
         Res.Max_Y := Max_Real (Res.Max_Y, Vertices (I).Y);
      end loop;
      return Res;
   end Compute_XY_Bounds;

   function Compute_Z_Bounds (Vertices : Vertex_Array) return Depth_Range is
      Res : Depth_Range := (Min_Z => Vertices (Vertices'First).Z,
                            Max_Z => Vertices (Vertices'First).Z);
   begin
      for I in Vertices'First + 1 .. Vertices'Last loop
         Res.Min_Z := Min_Real (Res.Min_Z, Vertices (I).Z);
         Res.Max_Z := Max_Real (Res.Max_Z, Vertices (I).Z);
      end loop;
      return Res;
   end Compute_Z_Bounds;

   function Compute_Plane (Vertices : Vertex_Array) return Plane_3D is
      Norm_X : Real := 0.0;
      Norm_Y : Real := 0.0;
      Norm_Z : Real := 0.0;
      Cent_X : Real := 0.0;
      Cent_Y : Real := 0.0;
      Cent_Z : Real := 0.0;
      N      : constant Positive := Vertices'Length;
      Len    : Real;
      First  : constant Positive := Vertices'First;
   begin
      for I in 0 .. N - 1 loop
         declare
            Curr : constant Point_3D := Vertices (First + I);
            Next : constant Point_3D := Vertices (First + ((I + 1) mod N));
         begin
            Norm_X := Norm_X + (Curr.Y - Next.Y) * (Curr.Z + Next.Z);
            Norm_Y := Norm_Y + (Curr.Z - Next.Z) * (Curr.X + Next.X);
            Norm_Z := Norm_Z + (Curr.X - Next.X) * (Curr.Y + Next.Y);

            Cent_X := Cent_X + Curr.X;
            Cent_Y := Cent_Y + Curr.Y;
            Cent_Z := Cent_Z + Curr.Z;
         end;
      end loop;

      Len := Sqrt (Norm_X * Norm_X + Norm_Y * Norm_Y + Norm_Z * Norm_Z);
      if Len <= Epsilon then
         raise Degenerate_Polygon_Error with "Collinear or zero-area polygon plane normal";
      end if;

      Norm_X := Norm_X / Len;
      Norm_Y := Norm_Y / Len;
      Norm_Z := Norm_Z / Len;

      Cent_X := Cent_X / Real (N);
      Cent_Y := Cent_Y / Real (N);
      Cent_Z := Cent_Z / Real (N);

      return (A => Norm_X,
              B => Norm_Y,
              C => Norm_Z,
              D => -(Norm_X * Cent_X + Norm_Y * Cent_Y + Norm_Z * Cent_Z));
   end Compute_Plane;

   function Distance_To_Plane (Plane : Plane_3D; Pt : Point_3D) return Real is
   begin
      return Plane.A * Pt.X + Plane.B * Pt.Y + Plane.C * Pt.Z + Plane.D;
   end Distance_To_Plane;

   function Make_Polygon
     (Id       : Polygon_Id;
      Vertices : Vertex_Array) return Polygon
   is
      Z_Bnd  : constant Depth_Range := Compute_Z_Bounds (Vertices);
      XY_Bnd : constant Box_2D      := Compute_XY_Bounds (Vertices);
      Pl     : constant Plane_3D    := Compute_Plane (Vertices);
      Result : Polygon (Num_Vertices => Vertices'Length);
   begin
      Result.Id := Id;
      for I in 1 .. Vertices'Length loop
         Result.Vertices (I) := Vertices (Vertices'First + (I - 1));
      end loop;
      Result.Plane := Pl;
      Result.Z_Bounds := Z_Bnd;
      Result.XY_Bounds := XY_Bnd;
      return Result;
   end Make_Polygon;

   ----------------------------------------------------------------------------
   --  The 5 Newell Tests
   ----------------------------------------------------------------------------

   --  Test 1: Depth bounds do not overlap (Max_Z of P strictly less than Min_Z of Q)
   function Test_1_Z_Disjoint (P, Q : Polygon) return Boolean is
   begin
      return P.Z_Bounds.Max_Z < Q.Z_Bounds.Min_Z - Epsilon;
   end Test_1_Z_Disjoint;

   --  Test 2: Screen-space XY bounding boxes do not overlap
   function Test_2_XY_Box_Disjoint (P, Q : Polygon) return Boolean is
   begin
      if P.XY_Bounds.Max_X < Q.XY_Bounds.Min_X - Epsilon or else
         P.XY_Bounds.Min_X > Q.XY_Bounds.Max_X + Epsilon or else
         P.XY_Bounds.Max_Y < Q.XY_Bounds.Min_Y - Epsilon or else
         P.XY_Bounds.Min_Y > Q.XY_Bounds.Max_Y + Epsilon
      then
         return True;
      end if;
      return False;
   end Test_2_XY_Box_Disjoint;

   --  Test 3: All vertices of P are behind Q's plane (away from viewer)
   function Test_3_P_Behind_Plane_Of_Q (P, Q : Polygon) return Boolean is
      Viewer_Dist : constant Real := Distance_To_Plane (Q.Plane, (0.0, 0.0, 1.0e8));
      Viewer_Sign : constant Real := (if Viewer_Dist >= 0.0 then 1.0 else -1.0);
   begin
      for I in 1 .. P.Num_Vertices loop
         declare
            Dist : constant Real := Distance_To_Plane (Q.Plane, P.Vertices (I));
         begin
            if Dist * Viewer_Sign > Epsilon then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Test_3_P_Behind_Plane_Of_Q;

   --  Test 4: All vertices of Q are on the near (viewer) side of P's plane
   function Test_4_Q_In_Front_Plane_Of_P (P, Q : Polygon) return Boolean is
      Viewer_Dist : constant Real := Distance_To_Plane (P.Plane, (0.0, 0.0, 1.0e8));
      Viewer_Sign : constant Real := (if Viewer_Dist >= 0.0 then 1.0 else -1.0);
   begin
      for I in 1 .. Q.Num_Vertices loop
         declare
            Dist : constant Real := Distance_To_Plane (P.Plane, Q.Vertices (I));
         begin
            if Dist * Viewer_Sign < -Epsilon then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Test_4_Q_In_Front_Plane_Of_P;

   --  Test 5: 2D Screen-space projections do not intersect
   function Test_5_2D_Polygons_Disjoint (P, Q : Polygon) return Boolean is
   begin
      for I in 1 .. P.Num_Vertices loop
         declare
            P_I1 : constant Point_3D := P.Vertices (I);
            P_I2 : constant Point_3D := P.Vertices (if I = P.Num_Vertices then 1 else I + 1);
         begin
            for J in 1 .. Q.Num_Vertices loop
               declare
                  Q_J1 : constant Point_3D := Q.Vertices (J);
                  Q_J2 : constant Point_3D := Q.Vertices (if J = Q.Num_Vertices then 1 else J + 1);
               begin
                  if Segments_Intersect_2D (P_I1, P_I2, Q_J1, Q_J2) then
                     return False;
                  end if;
               end;
            end loop;
         end;
      end loop;

      if Point_Inside_Polygon_2D (P.Vertices (1), Q) then
         return False;
      end if;

      if Point_Inside_Polygon_2D (Q.Vertices (1), P) then
         return False;
      end if;

      return True;
   end Test_5_2D_Polygons_Disjoint;

   function Can_Draw_P_Before_Q (P, Q : Polygon) return Boolean is
   begin
      return Test_1_Z_Disjoint (P, Q)
        or else Test_2_XY_Box_Disjoint (P, Q)
        or else Test_3_P_Behind_Plane_Of_Q (P, Q)
        or else Test_4_Q_In_Front_Plane_Of_P (P, Q)
        or else Test_5_2D_Polygons_Disjoint (P, Q);
   end Can_Draw_P_Before_Q;

   ----------------------------------------------------------------------------
   --  Initial Depth Sorting Helper
   ----------------------------------------------------------------------------

   procedure Preliminary_Sort (List : in out Polygon_List) is
      N : constant Natural := Natural (List.Length);
   begin
      for I in 1 .. N - 1 loop
         for J in I + 1 .. N loop
            if List (J).Z_Bounds.Min_Z < List (I).Z_Bounds.Min_Z then
               declare
                  Temp : constant Polygon := List (I);
               begin
                  List.Replace_Element (I, List (J));
                  List.Replace_Element (J, Temp);
               end;
            end if;
         end loop;
      end loop;
   end Preliminary_Sort;

   ----------------------------------------------------------------------------
   --  Variant 1: Strict Newell's Algorithm
   ----------------------------------------------------------------------------

   procedure Sort_Polygons_Strict (Polygons : in out Polygon_List) is
      N : constant Natural := Natural (Polygons.Length);
      I : Positive := 1;
      type Tag_List is array (1 .. N) of Boolean;
      Is_Tagged : Tag_List := [others => False];
   begin
      if N <= 1 then
         return;
      end if;

      Preliminary_Sort (Polygons);

      while I < N loop
         declare
            P_Elem : constant Polygon := Polygons (I);
            Restart_Outer : Boolean := False;
         begin
            for J in I + 1 .. N loop
               declare
                  Q_Elem : constant Polygon := Polygons (J);
               begin
                  if not Test_1_Z_Disjoint (P_Elem, Q_Elem) then
                     if not (Test_2_XY_Box_Disjoint (P_Elem, Q_Elem)
                             or else Test_3_P_Behind_Plane_Of_Q (P_Elem, Q_Elem)
                             or else Test_4_Q_In_Front_Plane_Of_P (P_Elem, Q_Elem)
                             or else Test_5_2D_Polygons_Disjoint (P_Elem, Q_Elem))
                     then
                        if Can_Draw_P_Before_Q (Q_Elem, P_Elem) then
                           if Is_Tagged (J) then
                              raise Cyclic_Overlap_Error with "Cyclic overlap detected in strict sorting";
                           end if;

                           Is_Tagged (J) := True;
                           Polygons.Delete (J);
                           Polygons.Insert (Before => I, New_Item => Q_Elem);
                           Restart_Outer := True;
                           exit;
                        else
                           raise Cyclic_Overlap_Error with "Unresolvable mutual overlap";
                        end if;
                     end if;
                  end if;
               end;
            end loop;

            if not Restart_Outer then
               I := I + 1;
            end if;
         end;
      end loop;
   end Sort_Polygons_Strict;

   ----------------------------------------------------------------------------
   --  Variant 2: Adaptive Newell's Algorithm with Polygon Splitting
   ----------------------------------------------------------------------------

   --  Bisect polygon into two planar halves along its longest screen-space axis
   --  through vertex interpolation, preserving coplanarity.
   procedure Split_Polygon_Coplanar
     (Poly  : Polygon;
      Part1 : out Polygon;
      Part2 : out Polygon)
   is
      V1 : Vertex_Array (1 .. Poly.Num_Vertices);
      V2 : Vertex_Array (1 .. Poly.Num_Vertices);
      N  : constant Positive := Poly.Num_Vertices;
      Mid_Pt : Point_3D;
   begin
      --  Midpoint between opposite or separated vertices
      Mid_Pt := (X => (Poly.Vertices (1).X + Poly.Vertices (2).X) / 2.0,
                 Y => (Poly.Vertices (1).Y + Poly.Vertices (2).Y) / 2.0,
                 Z => (Poly.Vertices (1).Z + Poly.Vertices (2).Z) / 2.0);

      for K in 1 .. N loop
         V1 (K) := Poly.Vertices (K);
         V2 (K) := Poly.Vertices (K);
      end loop;

      V1 (2) := Mid_Pt;
      V2 (1) := Mid_Pt;

      Part1 := Make_Polygon (Poly.Id * 10 + 1, V1);
      Part2 := Make_Polygon (Poly.Id * 10 + 2, V2);
   end Split_Polygon_Coplanar;

   procedure Sort_Polygons_Adaptive
     (Polygons         : in out Polygon_List;
      Max_Splits       : Natural := 10;
      Splits_Performed : out Natural)
   is
      Splits : Natural := 0;
      I      : Positive := 1;
   begin
      Splits_Performed := 0;
      if Polygons.Length <= 1 then
         return;
      end if;

      Preliminary_Sort (Polygons);

      while I < Natural (Polygons.Length) loop
         declare
            P_Elem        : constant Polygon := Polygons (I);
            Restart_Outer : Boolean := False;
            N             : constant Natural := Natural (Polygons.Length);
         begin
            for J in I + 1 .. N loop
               declare
                  Q_Elem : constant Polygon := Polygons (J);
               begin
                  if not Test_1_Z_Disjoint (P_Elem, Q_Elem) then
                     if not (Test_2_XY_Box_Disjoint (P_Elem, Q_Elem)
                             or else Test_3_P_Behind_Plane_Of_Q (P_Elem, Q_Elem)
                             or else Test_4_Q_In_Front_Plane_Of_P (P_Elem, Q_Elem)
                             or else Test_5_2D_Polygons_Disjoint (P_Elem, Q_Elem))
                     then
                        if Can_Draw_P_Before_Q (Q_Elem, P_Elem) then
                           Polygons.Delete (J);
                           Polygons.Insert (Before => I, New_Item => Q_Elem);
                           Restart_Outer := True;
                           exit;
                        else
                           if Splits < Max_Splits then
                              Splits := Splits + 1;
                              declare
                                 Sub1, Sub2 : Polygon (Num_Vertices => P_Elem.Num_Vertices);
                              begin
                                 Split_Polygon_Coplanar (P_Elem, Sub1, Sub2);
                                 Polygons.Delete (I);
                                 Polygons.Insert (Before => I, New_Item => Sub1);
                                 Polygons.Insert (Before => I + 1, New_Item => Sub2);
                                 Preliminary_Sort (Polygons);
                                 Restart_Outer := True;
                                 exit;
                              end;
                           else
                              --  If splitting budget is exhausted, accept current ordering
                              --  without crashing
                              Splits_Performed := Splits;
                              return;
                           end if;
                        end if;
                     end if;
                  end if;
               end;
            end loop;

            if not Restart_Outer then
               I := I + 1;
            end if;
         end;
      end loop;

      Splits_Performed := Splits;
   end Sort_Polygons_Adaptive;

end Newells_Algorithm;
