--  Own checks for Newell-Newell-Sancha depth sorting.
--  The plane reference is the cross product of two edges, not Newell's sum.
--  The five ordering tests are reimplemented from the geometric definitions
--  (Newell, Newell, Sancha, Proc. ACM 1972) and applied to the vertices,
--  not to the cached plane or bounds.
--  Seed is fixed, printed, and overridable with AA_SEED.

with Ada.Environment_Variables;
with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Text_IO;
with Newells_Algorithm;

procedure Own_Checks (Fail_Count : out Natural) is
   use Newells_Algorithm;
   package Txt renames Ada.Text_IO;
   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   Eps : constant Real := 1.0e-5;
   Checks : Natural := 0;
   Fails  : Natural := 0;

   type U32 is mod 2**32;
   Seed : U32 := 20261008;

   procedure Note (OK : Boolean; Label : String) is
   begin
      Checks := Checks + 1;
      if not OK then
         Fails := Fails + 1;
         Txt.Put_Line ("  FAIL -- " & Label);
      end if;
   end Note;

   function Next_U return U32 is
   begin
      Seed := Seed * 1664525 + 1013904223;
      return Seed;
   end Next_U;

   function Unit return Real is
   begin
      return Real (Next_U) / 4294967296.0;
   end Unit;

   function R (Lo, Hi : Real) return Real is
   begin
      return Lo + (Hi - Lo) * Unit;
   end R;

   function Cross_Normal (V : Vertex_Array) return Plane_3D is
      A : constant Point_3D := V (V'First);
      B : constant Point_3D := V (V'First + 1);
      C : constant Point_3D := V (V'First + 2);
      Nx : constant Real := (B.Y - A.Y) * (C.Z - A.Z) - (B.Z - A.Z) * (C.Y - A.Y);
      Ny : constant Real := (B.Z - A.Z) * (C.X - A.X) - (B.X - A.X) * (C.Z - A.Z);
      Nz : constant Real := (B.X - A.X) * (C.Y - A.Y) - (B.Y - A.Y) * (C.X - A.X);
      Len : constant Real := Math.Sqrt (Nx * Nx + Ny * Ny + Nz * Nz);
   begin
      if Len <= 1.0e-12 then
         raise Degenerate_Polygon_Error;
      end if;
      return (A => Nx / Len, B => Ny / Len, C => Nz / Len,
              D => -((Nx / Len) * A.X + (Ny / Len) * A.Y + (Nz / Len) * A.Z));
   end Cross_Normal;

   function Dist (Pl : Plane_3D; P : Point_3D) return Real is
   begin
      return Pl.A * P.X + Pl.B * P.Y + Pl.C * P.Z + Pl.D;
   end Dist;

   function Z_Min (P : Polygon) return Real is
      M : Real := P.Vertices (1).Z;
   begin
      for I in 2 .. P.Num_Vertices loop
         if P.Vertices (I).Z < M then
            M := P.Vertices (I).Z;
         end if;
      end loop;
      return M;
   end Z_Min;

   function Z_Max (P : Polygon) return Real is
      M : Real := P.Vertices (1).Z;
   begin
      for I in 2 .. P.Num_Vertices loop
         if P.Vertices (I).Z > M then
            M := P.Vertices (I).Z;
         end if;
      end loop;
      return M;
   end Z_Max;

   function Box_Disjoint (P, Q : Polygon) return Boolean is
      PminX : Real := P.Vertices (1).X;
      PmaxX : Real := P.Vertices (1).X;
      PminY : Real := P.Vertices (1).Y;
      PmaxY : Real := P.Vertices (1).Y;
      QminX : Real := Q.Vertices (1).X;
      QmaxX : Real := Q.Vertices (1).X;
      QminY : Real := Q.Vertices (1).Y;
      QmaxY : Real := Q.Vertices (1).Y;
   begin
      for I in 2 .. P.Num_Vertices loop
         if P.Vertices (I).X < PminX then PminX := P.Vertices (I).X; end if;
         if P.Vertices (I).X > PmaxX then PmaxX := P.Vertices (I).X; end if;
         if P.Vertices (I).Y < PminY then PminY := P.Vertices (I).Y; end if;
         if P.Vertices (I).Y > PmaxY then PmaxY := P.Vertices (I).Y; end if;
      end loop;
      for I in 2 .. Q.Num_Vertices loop
         if Q.Vertices (I).X < QminX then QminX := Q.Vertices (I).X; end if;
         if Q.Vertices (I).X > QmaxX then QmaxX := Q.Vertices (I).X; end if;
         if Q.Vertices (I).Y < QminY then QminY := Q.Vertices (I).Y; end if;
         if Q.Vertices (I).Y > QmaxY then QmaxY := Q.Vertices (I).Y; end if;
      end loop;
      return PmaxX < QminX - Eps or else PminX > QmaxX + Eps
        or else PmaxY < QminY - Eps or else PminY > QmaxY + Eps;
   end Box_Disjoint;

   function Orient (O, A, B : Point_3D) return Real is
   begin
      return (A.X - O.X) * (B.Y - O.Y) - (A.Y - O.Y) * (B.X - O.X);
   end Orient;

   function Seg_Hit (A1, A2, B1, B2 : Point_3D) return Boolean is
      D1 : constant Real := Orient (B1, B2, A1);
      D2 : constant Real := Orient (B1, B2, A2);
      D3 : constant Real := Orient (A1, A2, B1);
      D4 : constant Real := Orient (A1, A2, B2);
      function On (A, B, P : Point_3D) return Boolean is
      begin
         return P.X <= Real'Max (A.X, B.X) + Eps
           and then P.X >= Real'Min (A.X, B.X) - Eps
           and then P.Y <= Real'Max (A.Y, B.Y) + Eps
           and then P.Y >= Real'Min (A.Y, B.Y) - Eps;
      end On;
   begin
      if ((D1 > Eps and then D2 < -Eps) or else (D1 < -Eps and then D2 > Eps))
        and then ((D3 > Eps and then D4 < -Eps) or else (D3 < -Eps and then D4 > Eps))
      then
         return True;
      end if;
      if abs (D1) <= Eps and then On (B1, B2, A1) then return True; end if;
      if abs (D2) <= Eps and then On (B1, B2, A2) then return True; end if;
      if abs (D3) <= Eps and then On (A1, A2, B1) then return True; end if;
      if abs (D4) <= Eps and then On (A1, A2, B2) then return True; end if;
      return False;
   end Seg_Hit;

   --  Even-odd ray cast to +X. Different threshold and winding from the body.
   function Inside (Pt : Point_3D; Poly : Polygon) return Boolean is
      Hits : Natural := 0;
      J : Positive := Poly.Num_Vertices;
   begin
      for I in 1 .. Poly.Num_Vertices loop
         declare
            Vi : constant Point_3D := Poly.Vertices (I);
            Vj : constant Point_3D := Poly.Vertices (J);
         begin
            if (Vi.Y > Pt.Y) /= (Vj.Y > Pt.Y) then
               declare
                  Xint : constant Real :=
                    (Vj.X - Vi.X) * (Pt.Y - Vi.Y) / (Vj.Y - Vi.Y) + Vi.X;
               begin
                  if Pt.X < Xint then
                     Hits := Hits + 1;
                  end if;
               end;
            end if;
         end;
         J := I;
      end loop;
      return Hits mod 2 = 1;
   end Inside;

   function Proj_Disjoint (P, Q : Polygon) return Boolean is
   begin
      for I in 1 .. P.Num_Vertices loop
         declare
            A1 : constant Point_3D := P.Vertices (I);
            A2 : constant Point_3D := P.Vertices (if I = P.Num_Vertices then 1 else I + 1);
         begin
            for J in 1 .. Q.Num_Vertices loop
               declare
                  B1 : constant Point_3D := Q.Vertices (J);
                  B2 : constant Point_3D := Q.Vertices (if J = Q.Num_Vertices then 1 else J + 1);
               begin
                  if Seg_Hit (A1, A2, B1, B2) then
                     return False;
                  end if;
               end;
            end loop;
         end;
      end loop;
      if Inside (P.Vertices (1), Q) or else Inside (Q.Vertices (1), P) then
         return False;
      end if;
      return True;
   end Proj_Disjoint;

   function All_Far (Pts : Polygon; Pl : Plane_3D) return Boolean is
      Viewer : constant Point_3D := (0.0, 0.0, 1.0e8);
      Vs : constant Real := Dist (Pl, Viewer);
   begin
      if abs (Vs) < 1.0e-3 then
         return False;
      end if;
      for I in 1 .. Pts.Num_Vertices loop
         if Dist (Pl, Pts.Vertices (I)) * Vs > Eps then
            return False;
         end if;
      end loop;
      return True;
   end All_Far;

   function All_Near (Pts : Polygon; Pl : Plane_3D) return Boolean is
      Viewer : constant Point_3D := (0.0, 0.0, 1.0e8);
      Vs : constant Real := Dist (Pl, Viewer);
   begin
      if abs (Vs) < 1.0e-3 then
         return False;
      end if;
      for I in 1 .. Pts.Num_Vertices loop
         if Dist (Pl, Pts.Vertices (I)) * Vs < -Eps then
            return False;
         end if;
      end loop;
      return True;
   end All_Near;

   function Own_Before (P, Q : Polygon) return Boolean is
      Qp : Plane_3D;
      Pp : Plane_3D;
   begin
      if Z_Max (P) < Z_Min (Q) - Eps then
         return True;
      end if;
      if Box_Disjoint (P, Q) then
         return True;
      end if;
      Qp := Cross_Normal (P.Vertices);
      Pp := Cross_Normal (Q.Vertices);
      --  Cross_Normal reads the polygon's own vertex array, which starts at 1.
      if All_Far (P, Pp) then
         return True;
      end if;
      if All_Near (Q, Qp) then
         return True;
      end if;
      if Proj_Disjoint (P, Q) then
         return True;
      end if;
      return False;
   exception
      when Degenerate_Polygon_Error =>
         return False;
   end Own_Before;

   function Slab (Id : Polygon_Id; Z, X0, Y0, W : Real) return Polygon is
      V : constant Vertex_Array (1 .. 4) :=
        [(X0, Y0, Z), (X0 + W, Y0, Z), (X0 + W, Y0 + W, Z), (X0, Y0 + W, Z)];
   begin
      return Make_Polygon (Id, V);
   end Slab;

   procedure Read_Seed is
      Default : constant U32 := 20261008;
   begin
      Seed := Default;
      if Ada.Environment_Variables.Exists ("AA_SEED") then
         declare
            Raw : constant String := Ada.Environment_Variables.Value ("AA_SEED");
            Acc : U32 := 0;
         begin
            for Ch of Raw loop
               if Ch in '0' .. '9' then
                  Acc := Acc * 10 + U32 (Character'Pos (Ch) - Character'Pos ('0'));
               end if;
            end loop;
            if Raw'Length > 0 then
               Seed := Acc;
            end if;
         end;
      end if;
      Txt.Put_Line ("own checks seed:" & U32'Image (Seed)
        & " (default 20261008; set AA_SEED to override)");
   end Read_Seed;

begin
   Fail_Count := 0;
   Read_Seed;

   --  Triangle plane matches the edge cross product, vertices sit on it,
   --  and an index origin other than 1 does not change the polygon.
   for Trial in 1 .. 40 loop
      declare
         Shift : constant Integer := Integer (Next_U mod 7);
         V : Vertex_Array (Shift + 1 .. Shift + 3);
         Pl : Plane_3D;
         Ref : Plane_3D;
         Poly : Polygon (3);
         Dotn : Real;
      begin
         V (Shift + 1) := (R (-4.0, 4.0), R (-4.0, 4.0), R (-4.0, 4.0));
         V (Shift + 2) := (R (-4.0, 4.0), R (-4.0, 4.0), R (-4.0, 4.0));
         V (Shift + 3) := (R (-4.0, 4.0), R (-4.0, 4.0), R (-4.0, 4.0));
         begin
            Ref := Cross_Normal (V);
            Pl := Compute_Plane (V);
            Dotn := abs (Pl.A * Ref.A + Pl.B * Ref.B + Pl.C * Ref.C);
            Note (Dotn > 1.0 - 1.0e-8, "plane parallel to edge cross product");
            for I in V'Range loop
               Note (abs (Dist (Pl, V (I))) < 1.0e-6, "vertex on Newell plane");
               Note (abs (Dist (Ref, V (I))) < 1.0e-6, "vertex on cross-product plane");
            end loop;
            Poly := Make_Polygon (Polygon_Id (Trial), V);
            Note (Poly.Vertices (1).X = V (V'First).X
              and then Poly.Vertices (3).Z = V (V'Last).Z,
              "index origin copied in order");
            Note (abs (Poly.Z_Bounds.Min_Z - Real'Min (V (V'First).Z,
                    Real'Min (V (V'First + 1).Z, V (V'Last).Z))) < 1.0e-12,
              "Z min is the smallest vertex Z");
            Note (abs (Poly.XY_Bounds.Max_X - Real'Max (V (V'First).X,
                    Real'Max (V (V'First + 1).X, V (V'Last).X))) < 1.0e-12,
              "X max is the largest vertex X");
         exception
            when Degenerate_Polygon_Error =>
               null;
         end;
      end;
   end loop;

   --  Constructed ordering cases, compared with the package predicates.
   declare
      Far  : constant Polygon := Slab (1, -8.0, 0.0, 0.0, 2.0);
      Near : constant Polygon := Slab (2, -1.0, 0.0, 0.0, 2.0);
      Side : constant Polygon := Slab (3, -1.0, 10.0, 0.0, 2.0);
   begin
      Note (Test_1_Z_Disjoint (Far, Near) and then not Test_1_Z_Disjoint (Near, Far),
        "far slab is strictly behind the near slab");
      Note (Own_Before (Far, Near) and then not Own_Before (Near, Far),
        "own Z test agrees on the two slabs");
      Note (Test_2_XY_Box_Disjoint (Near, Side),
        "side-by-side slabs have disjoint boxes");
      Note (Box_Disjoint (Near, Side) and then not Box_Disjoint (Far, Near),
        "own boxes agree");
      Note (Test_5_2D_Polygons_Disjoint (Near, Side)
        and then not Test_5_2D_Polygons_Disjoint (Far, Near),
        "projections disjoint only for the separated pair");
   end;

   --  Constant-Z slabs shuffled, then strict-sorted back to front.
   declare
      List : Polygon_List;
      Order : constant array (1 .. 6) of Real := [-9.0, -2.0, -6.0, -4.0, -7.5, -0.5];
      Seen : array (1 .. 6) of Boolean := [others => False];
   begin
      for K in Order'Range loop
         List.Append (Slab (Polygon_Id (K), Order (K),
           R (-1.0, 1.0), R (-1.0, 1.0), 1.5));
      end loop;
      Sort_Polygons_Strict (List);
      Note (Natural (List.Length) = 6, "strict sort keeps six slabs");
      for I in 1 .. Natural (List.Length) loop
         Seen (Positive (List (I).Id)) := True;
         if I > 1 then
            Note (Z_Min (List (I)) + Eps >= Z_Min (List (I - 1)),
              "constant-Z slabs come out farther first");
            Note (Own_Before (List (I - 1), List (I)),
              "earlier slab can be drawn before the later one");
         end if;
      end loop;
      for K in Seen'Range loop
         Note (Seen (K), "slab id survived the sort");
      end loop;
   end;

   --  A quad that straddles a facing square cannot be ordered either way.
   declare
      List : Polygon_List;
      Raised : Boolean := False;
      Face : constant Polygon := Slab (1, 0.0, 0.0, 0.0, 2.0);
      Pierce : constant Vertex_Array (1 .. 4) :=
        [(0.4, -0.5, -1.0), (0.4, 2.5, -1.0), (1.6, 2.5, 1.0), (1.6, -0.5, 1.0)];
      Q : constant Polygon := Make_Polygon (2, Pierce);
      Splits : Natural := 99;
   begin
      Note (not Own_Before (Face, Q) and then not Own_Before (Q, Face),
        "piercing pair is unordered by the five tests");
      List.Append (Face);
      List.Append (Q);
      begin
         Sort_Polygons_Strict (List);
      exception
         when Cyclic_Overlap_Error =>
            Raised := True;
      end;
      Note (Raised, "strict sort raises Cyclic_Overlap_Error on a piercing pair");

      List.Clear;
      List.Append (Face);
      List.Append (Q);
      Sort_Polygons_Adaptive (List, Max_Splits => 8, Splits_Performed => Splits);
      Note (Splits <= 8, "adaptive split count stays inside the budget");
      if Splits < 8 then
         for I in 1 .. Natural (List.Length) - 1 loop
            for J in I + 1 .. Natural (List.Length) loop
               Note (Own_Before (List (I), List (J)),
                 "resolved adaptive order draws earlier before later");
            end loop;
         end loop;
      end if;
   end;

   --  Signed distance is the plane formula, including the Y term.
   for Trial in 1 .. 20 loop
      declare
         Pl : constant Plane_3D :=
           (A => R (-2.0, 2.0), B => R (-2.0, 2.0), C => R (-2.0, 2.0), D => R (-2.0, 2.0));
         Pt : constant Point_3D := (R (-3.0, 3.0), R (-3.0, 3.0), R (-3.0, 3.0));
         Mine : constant Real := Pl.A * Pt.X + Pl.B * Pt.Y + Pl.C * Pt.Z + Pl.D;
      begin
         Note (Distance_To_Plane (Pl, Pt) = Mine, "distance is A x + B y + C z + D");
      end;
   end loop;

   --  Test 1 is strict: a gap of exactly the same 1.0e-7 literal is not disjoint.
   declare
      P : constant Polygon := Slab (1, 0.0, 0.0, 0.0, 1.0);
      Q : constant Polygon := Slab (2, 1.0e-7, 0.0, 0.0, 1.0);
      Touch : constant Polygon := Slab (3, 0.0, 1.0, 0.0, 1.0);
   begin
      Note (not Test_1_Z_Disjoint (P, Q),
        "Z gap equal to 1.0e-7 is not strict separation");
      Note (Test_1_Z_Disjoint (P, Slab (4, 1.0, 0.0, 0.0, 1.0)),
        "a unit Z gap is strict separation");
      --  P occupies x in [0,1], Touch occupies x in [1,2]: boxes meet, they are not disjoint.
      Note (not Test_2_XY_Box_Disjoint (Touch, P),
        "boxes that meet at an edge are not disjoint");
      Note (Test_2_XY_Box_Disjoint (P, Slab (5, 0.0, 3.0, 0.0, 1.0)),
        "a gap of 2 in X is disjoint");
      --  Gap of exactly the 1.0e-7 literal is not strict separation.
      declare
         Left  : constant Polygon := Slab (6, 0.0, 0.0, 0.0, 1.0);
         Right : constant Polygon := Slab (7, 0.0, 1.0 + 1.0e-7, 0.0, 1.0);
         Below : constant Polygon := Slab (8, 0.0, 0.0, 0.0, 1.0);
         Above : constant Polygon := Slab (9, 0.0, 0.0, 1.0, 1.0);
      begin
         Note (not Test_2_XY_Box_Disjoint (Right, Left),
           "an X gap of exactly 1.0e-7 is not disjoint");
         Note (not Test_2_XY_Box_Disjoint (Below, Above),
           "boxes that meet on Y are not disjoint");
      end;
   end;

   --  Test 5 against an independent crossing test and an interior point.
   declare
      Cross_A : constant Polygon := Make_Polygon (1,
        [(0.0, 0.0, 0.0), (4.0, 0.0, 0.0), (2.0, 3.0, 0.0)]);
      Cross_B : constant Polygon := Make_Polygon (2,
        [(0.0, 1.0, 0.0), (4.0, 1.0, 0.0), (2.0, -1.0, 0.0)]);
      Outer : constant Polygon := Slab (3, 0.0, 0.0, 0.0, 6.0);
      Inner : constant Polygon := Make_Polygon (4,
        [(2.0, 2.0, 0.0), (3.0, 2.0, 0.0), (2.5, 3.0, 0.0)]);
      Apart : constant Polygon := Slab (5, 0.0, 20.0, 20.0, 1.0);
   begin
      Note (not Proj_Disjoint (Cross_A, Cross_B), "own test sees the crossing pair");
      Note (not Test_5_2D_Polygons_Disjoint (Cross_A, Cross_B),
        "crossing triangles are not projection-disjoint");
      Note (not Proj_Disjoint (Outer, Inner) and then not Test_5_2D_Polygons_Disjoint (Outer, Inner),
        "a triangle inside a square is not projection-disjoint");
      Note (Proj_Disjoint (Outer, Apart) and then Test_5_2D_Polygons_Disjoint (Outer, Apart),
        "separated squares are projection-disjoint");
   end;

   --  Adaptive sort of non-overlapping slabs must not split and must keep order.
   declare
      List : Polygon_List;
      Splits : Natural := 99;
      Zs : constant array (1 .. 4) of Real := [-3.0, -1.0, -4.0, -2.0];
   begin
      for K in Zs'Range loop
         List.Append (Slab (Polygon_Id (K), Zs (K), 0.0, 0.0, 1.0));
      end loop;
      Sort_Polygons_Adaptive (List, Max_Splits => 4, Splits_Performed => Splits);
      Note (Splits = 0, "no split when the five tests already order the slabs");
      Note (Natural (List.Length) = 4, "adaptive sort keeps four slabs");
      for I in 2 .. Natural (List.Length) loop
         Note (Own_Before (List (I - 1), List (I)),
           "adaptive order draws the farther slab first");
      end loop;
   end;

   declare
      List : Polygon_List;
      Face : constant Polygon := Slab (1, 0.0, 0.0, 0.0, 2.0);
      Pierce : constant Vertex_Array (1 .. 4) :=
        [(0.4, -0.5, -1.0), (0.4, 2.5, -1.0), (1.6, 2.5, 1.0), (1.6, -0.5, 1.0)];
      Q : constant Polygon := Make_Polygon (2, Pierce);
      Splits : Natural := 0;
      function Has (List : Polygon_List; X : Polygon_Id) return Boolean is
      begin
         for I in 1 .. Natural (List.Length) loop
            if List (I).Id = X then
               return True;
            end if;
         end loop;
         return False;
      end Has;
   begin
      List.Append (Face);
      List.Append (Q);
      Sort_Polygons_Adaptive (List, Max_Splits => 1, Splits_Performed => Splits);
      Note (Splits = 1, "the piercing pair takes one split when the budget is 1");
      Note ((Has (List, 1) and then Has (List, 21) and then Has (List, 22))
        or else (Has (List, 2) and then Has (List, 11) and then Has (List, 12)),
        "the split ids are 10 * parent + 1 and 10 * parent + 2");
   end;

   --  A split of the piercing quad must introduce the midpoint of its first edge.
   declare
      List : Polygon_List;
      Face : constant Polygon := Slab (1, 0.0, 0.0, 0.0, 2.0);
      Pierce : constant Vertex_Array (1 .. 4) :=
        [(0.4, -0.5, -1.0), (0.4, 2.5, -1.0), (1.6, 2.5, 1.0), (1.6, -0.5, 1.0)];
      Q : constant Polygon := Make_Polygon (2, Pierce);
      Splits : Natural := 0;
      Mid : constant Point_3D :=
        ((Pierce (1).X + Pierce (2).X) / 2.0,
         (Pierce (1).Y + Pierce (2).Y) / 2.0,
         (Pierce (1).Z + Pierce (2).Z) / 2.0);
      Seen : Boolean := False;
   begin
      List.Append (Face);
      List.Append (Q);
      Sort_Polygons_Adaptive (List, Max_Splits => 8, Splits_Performed => Splits);
      if Splits > 0 then
         for I in 1 .. Natural (List.Length) loop
            for V in 1 .. List (I).Num_Vertices loop
               if abs (List (I).Vertices (V).X - Mid.X) < 1.0e-12
                 and then abs (List (I).Vertices (V).Y - Mid.Y) < 1.0e-12
                 and then abs (List (I).Vertices (V).Z - Mid.Z) < 1.0e-12
               then
                  Seen := True;
               end if;
            end loop;
         end loop;
         Note (Seen, "a split inserts the midpoint of the first edge");
      end if;
   end;

   --  One polygon strictly inside another: only the point-in-polygon test can see it.
   --  The sample is a triangle whose first vertex the broken ray-cast formula misses.
   declare
      Outer : constant Polygon := Make_Polygon (1,
        [(-1.7452972448023694, 2.0464336332577915, 0.0),
         (0.9469519734026530, -1.9959492691004757, 0.0),
         (3.2779700477459210, 3.8622838083012248, 0.0)]);
      Inner : constant Polygon := Make_Polygon (2,
        [(0.0549899410400703, 1.5269093302176635, 0.0),
         (0.1549899410400703, 1.6269093302176635, 0.0),
         (0.1549899410400703, 1.4269093302176635, 0.0)]);
   begin
      Note (Inside (Inner.Vertices (1), Outer), "own ray cast sees the inner vertex");
      Note (not Test_5_2D_Polygons_Disjoint (Outer, Inner),
        "a polygon inside another is not projection-disjoint");
   end;

   for Trial in 1 .. 15 loop
      declare
         V : Vertex_Array (1 .. 3);
         Area : Real;
         Cx, Cy : Real;
         Inner_V : Vertex_Array (1 .. 3);
         Outer_P, Inner_P : Polygon (3);
      begin
         V (1) := (R (-4.0, 4.0), R (-4.0, 4.0), 0.0);
         V (2) := (R (-4.0, 4.0), R (-4.0, 4.0), 0.0);
         V (3) := (R (-4.0, 4.0), R (-4.0, 4.0), 0.0);
         Area := (V (2).X - V (1).X) * (V (3).Y - V (1).Y)
           - (V (2).Y - V (1).Y) * (V (3).X - V (1).X);
         if abs (Area) > 0.5 then
            Cx := (V (1).X + V (2).X + V (3).X) / 3.0;
            Cy := (V (1).Y + V (2).Y + V (3).Y) / 3.0;
            for I in 1 .. 3 loop
               Inner_V (I) := (0.7 * Cx + 0.3 * V (I).X, 0.7 * Cy + 0.3 * V (I).Y, 0.0);
            end loop;
            Outer_P := Make_Polygon (1, V);
            Inner_P := Make_Polygon (2, Inner_V);
            if Inside (Inner_P.Vertices (1), Outer_P) then
               Note (not Test_5_2D_Polygons_Disjoint (Outer_P, Inner_P),
                 "shrunk triangle is inside its parent");
            end if;
         end if;
      exception
         when Degenerate_Polygon_Error =>
            null;
      end;
   end loop;

   --  Random triangles: the package predicates must match the independent ones.
   for Trial in 1 .. 30 loop
      declare
         function Tri (Id : Polygon_Id) return Polygon is
            V : Vertex_Array (1 .. 3);
         begin
            V (1) := (R (-5.0, 5.0), R (-5.0, 5.0), R (-5.0, 5.0));
            V (2) := (R (-5.0, 5.0), R (-5.0, 5.0), R (-5.0, 5.0));
            V (3) := (R (-5.0, 5.0), R (-5.0, 5.0), R (-5.0, 5.0));
            return Make_Polygon (Id, V);
         end Tri;
         P : Polygon (3);
         Q : Polygon (3);
      begin
         P := Tri (1);
         Q := Tri (2);
         Note (Test_1_Z_Disjoint (P, Q) = (Z_Max (P) < Z_Min (Q) - 1.0e-7),
           "Z test matches the vertex extents");
         Note (Test_2_XY_Box_Disjoint (P, Q) = Box_Disjoint (P, Q),
           "box test matches an independent min/max");
         Note (Test_5_2D_Polygons_Disjoint (P, Q) = Proj_Disjoint (P, Q),
           "projection test matches an independent crossing test");
         Note (Test_3_P_Behind_Plane_Of_Q (P, Q) = All_Far (P, Cross_Normal (Q.Vertices)),
           "behind-plane test matches the edge cross product");
      exception
         when Degenerate_Polygon_Error =>
            null;
      end;
   end loop;

   --  Fan of triangle cross products, not Newell's edge sum.
   --  Concave, first-three collinear, and a slightly non-planar quad.
   declare
      function Fan (V : Vertex_Array) return Plane_3D is
         O  : constant Point_3D := V (V'First);
         Nx : Real := 0.0;
         Ny : Real := 0.0;
         Nz : Real := 0.0;
      begin
         for I in V'First + 1 .. V'Last - 1 loop
            declare
               A  : constant Point_3D := V (I);
               B  : constant Point_3D := V (I + 1);
               Ax : constant Real := A.X - O.X;
               Ay : constant Real := A.Y - O.Y;
               Az : constant Real := A.Z - O.Z;
               Bx : constant Real := B.X - O.X;
               By : constant Real := B.Y - O.Y;
               Bz : constant Real := B.Z - O.Z;
            begin
               Nx := Nx + Ay * Bz - Az * By;
               Ny := Ny + Az * Bx - Ax * Bz;
               Nz := Nz + Ax * By - Ay * Bx;
            end;
         end loop;
         declare
            Len : constant Real := Math.Sqrt (Nx * Nx + Ny * Ny + Nz * Nz);
         begin
            if Len <= 1.0e-12 then
               raise Degenerate_Polygon_Error;
            end if;
            return (A => Nx / Len, B => Ny / Len, C => Nz / Len,
                    D => -((Nx / Len) * O.X + (Ny / Len) * O.Y + (Nz / Len) * O.Z));
         end;
      end Fan;

      procedure Plane_Agrees (V : Vertex_Array; Label : String) is
         Got : constant Plane_3D := Compute_Plane (V);
         Ref : constant Plane_3D := Fan (V);
         Dot : constant Real := abs (Got.A * Ref.A + Got.B * Ref.B + Got.C * Ref.C);
      begin
         Note (Dot > 1.0 - 1.0e-8, Label);
      end Plane_Agrees;
   begin
      Plane_Agrees
        ([(0.0, 0.0, 0.0), (3.0, 0.0, 0.0), (1.0, 1.0, 0.0), (3.0, 2.0, 0.0)],
         "concave quad normal matches the fan");
      Plane_Agrees
        ([(0.0, 0.0, 0.0), (1.0, 0.0, 0.0), (2.0, 0.0, 0.0), (1.0, 1.0, 1.0)],
         "first three collinear; fan of the rest still matches");
      Plane_Agrees
        ([(0.0, 0.0, 0.0), (1.0, 0.0, 0.02), (1.0, 1.0, -0.01), (0.0, 1.0, 0.03)],
         "slightly non-planar quad matches the fan");
   end;

   --  Painter's order against an independent z-buffer.
   --  Larger Z is nearer. Painting back-to-front, the last polygon that
   --  covers a pixel must be the one the z-buffer says is nearest, and its
   --  depth must be the depth of the original surface (a split has to cut
   --  the real polygons, not replace them with a different shape).
   declare
      function Fan_Of (V : Vertex_Array) return Plane_3D is
         O  : constant Point_3D := V (V'First);
         Nx : Real := 0.0;
         Ny : Real := 0.0;
         Nz : Real := 0.0;
      begin
         for I in V'First + 1 .. V'Last - 1 loop
            declare
               A : constant Point_3D := V (I);
               B : constant Point_3D := V (I + 1);
               Ax : constant Real := A.X - O.X;
               Ay : constant Real := A.Y - O.Y;
               Az : constant Real := A.Z - O.Z;
               Bx : constant Real := B.X - O.X;
               By : constant Real := B.Y - O.Y;
               Bz : constant Real := B.Z - O.Z;
            begin
               Nx := Nx + Ay * Bz - Az * By;
               Ny := Ny + Az * Bx - Ax * Bz;
               Nz := Nz + Ax * By - Ay * Bx;
            end;
         end loop;
         declare
            Len : constant Real := Math.Sqrt (Nx * Nx + Ny * Ny + Nz * Nz);
         begin
            if Len <= 1.0e-12 then
               raise Degenerate_Polygon_Error;
            end if;
            return (A => Nx / Len, B => Ny / Len, C => Nz / Len,
                    D => -((Nx / Len) * O.X + (Ny / Len) * O.Y + (Nz / Len) * O.Z));
         end;
      end Fan_Of;

      function Covers (Poly : Polygon; X, Y : Real) return Boolean is
         Pt : constant Point_3D := (X, Y, 0.0);
      begin
         return Inside (Pt, Poly);
      end Covers;

      function Depth_Of (Poly : Polygon; X, Y : Real) return Real is
         Pl : constant Plane_3D := Fan_Of (Poly.Vertices);
      begin
         return -(Pl.A * X + Pl.B * Y + Pl.D) / Pl.C;
      end Depth_Of;

      procedure Z_Buffer_Agrees
        (Original : Polygon_List; Painted : Polygon_List; Label : String)
      is
         Min_X : Real := Original (1).Vertices (1).X;
         Max_X : Real := Min_X;
         Min_Y : Real := Original (1).Vertices (1).Y;
         Max_Y : Real := Min_Y;
         Covered : Natural := 0;
         Bad : Natural := 0;
         N : constant := 12;
      begin
         for I in 1 .. Natural (Original.Length) loop
            for V in 1 .. Original (I).Num_Vertices loop
               Min_X := Real'Min (Min_X, Original (I).Vertices (V).X);
               Max_X := Real'Max (Max_X, Original (I).Vertices (V).X);
               Min_Y := Real'Min (Min_Y, Original (I).Vertices (V).Y);
               Max_Y := Real'Max (Max_Y, Original (I).Vertices (V).Y);
            end loop;
         end loop;
         if Max_X - Min_X < 1.0e-6 then
            Max_X := Min_X + 1.0;
         end if;
         if Max_Y - Min_Y < 1.0e-6 then
            Max_Y := Min_Y + 1.0;
         end if;
         for Iy in 0 .. N - 1 loop
            for Ix in 0 .. N - 1 loop
               declare
                  X : constant Real :=
                    Min_X + (Max_X - Min_X) * (Real (Ix) + 0.5) / Real (N);
                  Y : constant Real :=
                    Min_Y + (Max_Y - Min_Y) * (Real (Iy) + 0.5) / Real (N);
                  True_Z : Real := -1.0e30;
                  Hit : Boolean := False;
                  Paint_Z : Real := -1.0e30;
                  Paint_Hit : Boolean := False;
               begin
                  for I in 1 .. Natural (Original.Length) loop
                     if Covers (Original (I), X, Y) then
                        declare
                           Z : constant Real := Depth_Of (Original (I), X, Y);
                        begin
                           if Z > True_Z then
                              True_Z := Z;
                              Hit := True;
                           end if;
                        end;
                     end if;
                  end loop;
                  if Hit then
                     Covered := Covered + 1;
                     for I in 1 .. Natural (Painted.Length) loop
                        if Covers (Painted (I), X, Y) then
                           Paint_Z := Depth_Of (Painted (I), X, Y);
                           Paint_Hit := True;
                        end if;
                     end loop;
                     if not Paint_Hit or else abs (Paint_Z - True_Z) > 1.0e-3 then
                        Bad := Bad + 1;
                     end if;
                  end if;
               end;
            end loop;
         end loop;
         Note (Covered > 0, Label & " (grid sees the polygons)");
         Note (Bad = 0, Label);
      end Z_Buffer_Agrees;
   begin
      --  Separated constant-Z slabs: strict order is a correct painter.
      for Trial in 1 .. 4 loop
         declare
            Orig : Polygon_List;
            Sorted : Polygon_List;
            Zs : constant array (1 .. 3) of Real :=
              [R (-3.0, -2.0), R (-1.0, 0.0), R (1.0, 2.0)];
         begin
            for K in Zs'Range loop
               Orig.Append (Slab (Polygon_Id (K), Zs (K),
                 R (-0.5, 0.5), R (-0.5, 0.5), 1.2));
            end loop;
            Sorted := Orig;
            Sort_Polygons_Strict (Sorted);
            Z_Buffer_Agrees (Orig, Sorted, "strict slabs match the z-buffer");
         end;
      end loop;

      --  Interlocking triangles. Neither whole triangle is a correct last
      --  painter on the overlap, so the adaptive split has to cut them.
      declare
         Orig : Polygon_List;
         Sorted : Polygon_List;
         Splits : Natural := 0;
         A : constant Polygon := Make_Polygon (1,
           [(0.0, 0.0, 0.0), (2.0, 0.0, 0.0), (1.0, 2.0, 1.0)]);
         B : constant Polygon := Make_Polygon (2,
           [(0.2, 0.4, 1.0), (1.8, 0.4, 1.0), (1.0, 1.2, 0.0)]);
         Raised : Boolean := False;
      begin
         Orig.Append (A);
         Orig.Append (B);
         Sorted := Orig;
         begin
            Sort_Polygons_Strict (Sorted);
         exception
            when Cyclic_Overlap_Error =>
               Raised := True;
         end;
         Note (Raised, "interlocking triangles are a strict-sort cycle");
         Sorted := Orig;
         Sort_Polygons_Adaptive
           (Sorted, Max_Splits => 8, Splits_Performed => Splits);
         Note (Splits >= 1, "adaptive split cuts the interlock");
         Note (Splits <= 8, "interlock stays inside the split budget");
         Z_Buffer_Agrees
           (Orig, Sorted, "adaptive order matches the z-buffer on the interlock");
      end;
   end;

   Txt.Put_Line ("own checks:" & Natural'Image (Checks)
     & "  failed:" & Natural'Image (Fails));
   Fail_Count := Fails;
end Own_Checks;
