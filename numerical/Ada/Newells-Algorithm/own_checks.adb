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

   Txt.Put_Line ("own checks:" & Natural'Image (Checks)
     & "  failed:" & Natural'Image (Fails));
   Fail_Count := Fails;
end Own_Checks;
