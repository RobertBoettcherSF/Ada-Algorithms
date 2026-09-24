--  Beam_Tracing body — Heckbert & Hanrahan style pyramidal beam algorithms.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Beam_Tracing
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Internal helpers
   -------------------------------------------------------------------------

   function Sqrt_Safe (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      else
         return Real (Sqrt (Float (X)));
      end if;
   end Sqrt_Safe;

   function Abs_R (X : Real) return Real is
   begin
      if X < 0.0 then
         return -X;
      else
         return X;
      end if;
   end Abs_R;

   procedure Ensure_Unit_Normal (N : in out Vec3) is
      L : constant Non_Negative := Length (N);
   begin
      if L = 0.0 then
         raise Degenerate_Geometry with "Zero plane normal";
      end if;
      N := (N.X / L, N.Y / L, N.Z / L);
   end Ensure_Unit_Normal;

   function Ray_Plane_T
     (Origin : Vec3; Dir : Axis_Direction; P : Plane) return Real
   is
      --  Origin + T*Dir on plane: Dot(N, Origin + T*Dir - Point) = 0
      Denom : constant Real := Dot (P.Normal, Dir);
   begin
      if Abs_R (Denom) < 1.0E-8 then
         return Real'First;  -- parallel sentinel
      end if;
      return Dot (P.Normal, P.Point - Origin) / Denom;
   end Ray_Plane_T;

   function Point_In_Convex_Polygon
     (Q : Vec3; Poly : Polygon; N : Plane_Normal) return Boolean
   is
      --  Same-side half-plane test in the polygon plane.
   begin
      if Poly.Count < 3 then
         return False;
      end if;
      for I in 1 .. Poly.Count loop
         declare
            A  : constant Vec3 := Poly.Vertices (I);
            B  : constant Vec3 :=
              Poly.Vertices (if I = Poly.Count then 1 else I + 1);
            E  : constant Vec3 := B - A;
            To : constant Vec3 := Q - A;
            C  : constant Vec3 := Cross (E, To);
         begin
            if Dot (C, N) < -1.0E-5 then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Point_In_Convex_Polygon;

   function Project_Beam_Onto_Plane
     (B : Beam; P : Plane) return Polygon
   is
      --  Intersect each corner ray with P; collect forward hits.
      Result : Polygon;
      T      : Real;
      Hit    : Vec3;
   begin
      Result.Count := 0;
      for I in 1 .. B.Count loop
         T := Ray_Plane_T (B.Apex, B.Corners (I), P);
         if T /= Real'First and then T > 1.0E-6 then
            Hit := B.Apex + (T * B.Corners (I));
            if Result.Count < Max_Vertices then
               Result.Count := Result.Count + 1;
               Result.Vertices (Result.Count) := Hit;
            end if;
         end if;
      end loop;
      return Result;
   end Project_Beam_Onto_Plane;

   function Beam_From_Apex_And_Polygon
     (Apex : Apex_Point; Poly : Polygon) return Beam
   is
      Result : Beam;
      D      : Vec3;
   begin
      Result.Apex  := Apex;
      Result.Count := 0;
      for I in 1 .. Poly.Count loop
         D := Poly.Vertices (I) - Apex;
         if Length (D) = 0.0 then
            raise Degenerate_Geometry with "Polygon vertex at apex";
         end if;
         if Result.Count < Max_Corners then
            Result.Count := Result.Count + 1;
            Result.Corners (Result.Count) := Normalize (D);
         end if;
      end loop;
      if Result.Count < 3 then
         raise Degenerate_Geometry with "Fewer than 3 beam corners";
      end if;
      return Result;
   end Beam_From_Apex_And_Polygon;

   --  Sutherland–Hodgman clip of Subject against convex Clip polygon
   --  (both coplanar; Clip oriented CCW w.r.t. N).
   function Clip_Polygon_SH
     (Subject, Clip : Polygon; N : Plane_Normal) return Polygon
   is
      function Inside (P, A, B : Vec3) return Boolean is
      begin
         return Dot (Cross (B - A, P - A), N) >= -1.0E-6;
      end Inside;

      function Intersect_Edge (P, Q, A, B : Vec3) return Vec3 is
         --  Line P→Q vs infinite line A→B in the plane.
         AB : constant Vec3 := B - A;
         PQ : constant Vec3 := Q - P;
         C1 : constant Vec3 := Cross (AB, P - A);
         C2 : constant Vec3 := Cross (AB, PQ);
         Denom : constant Real := Dot (C2, N);
         Numer : constant Real := Dot (C1, N);
         T     : Real;
      begin
         if Abs_R (Denom) < 1.0E-10 then
            return P;  -- parallel; return endpoint
         end if;
         T := -Numer / Denom;
         return P + (T * PQ);
      end Intersect_Edge;

      Output : Polygon := Subject;
      Input  : Polygon;
      A, B   : Vec3;
      S, E   : Vec3;
      Nin    : Boolean;
      Ein    : Boolean;
   begin
      if Subject.Count < 3 or else Clip.Count < 3 then
         return (Vertices => [others => (0.0, 0.0, 0.0)], Count => 0);
      end if;

      for C in 1 .. Clip.Count loop
         Input := Output;
         Output.Count := 0;
         A := Clip.Vertices (C);
         B := Clip.Vertices (if C = Clip.Count then 1 else C + 1);
         if Input.Count = 0 then
            exit;
         end if;
         S := Input.Vertices (Input.Count);
         for I in 1 .. Input.Count loop
            E := Input.Vertices (I);
            Nin := Inside (S, A, B);
            Ein := Inside (E, A, B);
            if Ein then
               if not Nin then
                  if Output.Count < Max_Vertices then
                     Output.Count := Output.Count + 1;
                     Output.Vertices (Output.Count) :=
                       Intersect_Edge (S, E, A, B);
                  end if;
               end if;
               if Output.Count < Max_Vertices then
                  Output.Count := Output.Count + 1;
                  Output.Vertices (Output.Count) := E;
               end if;
            elsif Nin then
               if Output.Count < Max_Vertices then
                  Output.Count := Output.Count + 1;
                  Output.Vertices (Output.Count) :=
                    Intersect_Edge (S, E, A, B);
               end if;
            end if;
            S := E;
         end loop;
      end loop;
      return Output;
   end Clip_Polygon_SH;

   function Refract_Dir
     (I : Axis_Direction; N : Plane_Normal; Eta : Real) return Axis_Direction
   is
      --  I points toward the surface; N faces the incident side.
      --  Eta = N1/N2. Returns unit transmitted direction or raises on TIR.
      Cos_I : Real := -Dot (N, I);
      N_Use : Plane_Normal := N;
      K     : Real;
      T     : Vec3;
   begin
      if Cos_I < 0.0 then
         --  Flip normal if incident from the other side.
         N_Use := (-1.0) * N;
         Cos_I := -Cos_I;
      end if;
      K := 1.0 - Eta * Eta * (1.0 - Cos_I * Cos_I);
      if K < 0.0 then
         raise Degenerate_Geometry with "Total internal reflection";
      end if;
      T := (Eta * I) + (((Eta * Cos_I) - Sqrt_Safe (K)) * N_Use);
      if Length (T) = 0.0 then
         raise Degenerate_Geometry with "Zero refracted direction";
      end if;
      return Normalize (T);
   end Refract_Dir;

   -------------------------------------------------------------------------
   -- Vector helpers
   -------------------------------------------------------------------------

   function Length (V : Vec3) return Non_Negative is
      S : constant Real := V.X * V.X + V.Y * V.Y + V.Z * V.Z;
   begin
      return Non_Negative (Sqrt_Safe (S));
   end Length;

   function Normalize (V : Vec3) return Axis_Direction is
      L : constant Non_Negative := Length (V);
   begin
      if L = 0.0 then
         raise Degenerate_Geometry with "Normalize of zero vector";
      end if;
      return (V.X / L, V.Y / L, V.Z / L);
   end Normalize;

   function Dot (A, B : Vec3) return Real is
   begin
      return A.X * B.X + A.Y * B.Y + A.Z * B.Z;
   end Dot;

   function Cross (A, B : Vec3) return Vec3 is
   begin
      return
        (A.Y * B.Z - A.Z * B.Y,
         A.Z * B.X - A.X * B.Z,
         A.X * B.Y - A.Y * B.X);
   end Cross;

   function "-" (A, B : Vec3) return Vec3 is
   begin
      return (A.X - B.X, A.Y - B.Y, A.Z - B.Z);
   end "-";

   function "+" (A, B : Vec3) return Vec3 is
   begin
      return (A.X + B.X, A.Y + B.Y, A.Z + B.Z);
   end "+";

   function "*" (S : Real; V : Vec3) return Vec3 is
   begin
      return (S * V.X, S * V.Y, S * V.Z);
   end "*";

   function Clamp (X, Lo, Hi : Real) return Real is
   begin
      if X < Lo then
         return Lo;
      elsif X > Hi then
         return Hi;
      else
         return X;
      end if;
   end Clamp;

   function Distance_Between (A, B : Vec3) return Non_Negative is
   begin
      return Length (A - B);
   end Distance_Between;

   function Beam_Axis (B : Beam) return Axis_Direction is
      Sum : Vec3 := (0.0, 0.0, 0.0);
   begin
      if B.Count < 3 then
         raise Invalid_Input with "Beam needs >= 3 corners";
      end if;
      for I in 1 .. B.Count loop
         Sum := Sum + B.Corners (I);
      end loop;
      if Length (Sum) = 0.0 then
         raise Degenerate_Geometry with "Beam corners cancel";
      end if;
      return Normalize (Sum);
   end Beam_Axis;

   function Make_Rectangle
     (Origin, U, V : Vec3) return Polygon
   is
      P : Polygon;
   begin
      P.Count := 4;
      P.Vertices (1) := Origin;
      P.Vertices (2) := Origin + U;
      P.Vertices (3) := Origin + U + V;
      P.Vertices (4) := Origin + V;
      return P;
   end Make_Rectangle;

   function Polygon_Plane (P : Polygon) return Plane is
      E1, E2, N : Vec3;
   begin
      if P.Count < 3 then
         raise Invalid_Input with "Polygon needs >= 3 vertices";
      end if;
      E1 := P.Vertices (2) - P.Vertices (1);
      E2 := P.Vertices (3) - P.Vertices (1);
      N  := Cross (E1, E2);
      if Length (N) = 0.0 then
         raise Degenerate_Geometry with "Degenerate polygon plane";
      end if;
      return (Point => P.Vertices (1), Normal => Normalize (N));
   end Polygon_Plane;

   -------------------------------------------------------------------------
   -- 1. Viewing beam
   -------------------------------------------------------------------------

   function Construct_Viewing_Beam
     (Eye          : Apex_Point;
      Image_Origin : Vec3;
      Image_U      : Vec3;
      Image_V      : Vec3) return Beam
   is
      Poly : constant Polygon := Make_Rectangle (Image_Origin, Image_U, Image_V);
   begin
      return Beam_From_Apex_And_Polygon (Eye, Poly);
   end Construct_Viewing_Beam;

   -------------------------------------------------------------------------
   -- 2. Pixel beam
   -------------------------------------------------------------------------

   function Construct_Pixel_Beam
     (Eye          : Apex_Point;
      Pixel_Origin : Vec3;
      Pixel_U      : Vec3;
      Pixel_V      : Vec3) return Beam
   is
      Poly : constant Polygon := Make_Rectangle (Pixel_Origin, Pixel_U, Pixel_V);
   begin
      return Beam_From_Apex_And_Polygon (Eye, Poly);
   end Construct_Pixel_Beam;

   -------------------------------------------------------------------------
   -- 3. Clip / subtract
   -------------------------------------------------------------------------

   function Beam_Clip_Against_Polygon
     (B : Beam; Poly : Polygon) return Beam
   is
      Pln      : constant Plane := Polygon_Plane (Poly);
      Projected : constant Polygon := Project_Beam_Onto_Plane (B, Pln);
      Clipped  : Polygon;
   begin
      if Projected.Count < 3 then
         --  No forward intersection → empty-ish beam (keep apex, zero count)
         declare
            Empty : Beam;
         begin
            Empty.Apex  := B.Apex;
            Empty.Count := 0;
            return Empty;
         end;
      end if;
      Clipped := Clip_Polygon_SH (Projected, Poly, Pln.Normal);
      if Clipped.Count < 3 then
         declare
            Empty : Beam;
         begin
            Empty.Apex  := B.Apex;
            Empty.Count := 0;
            return Empty;
         end;
      end if;
      return Beam_From_Apex_And_Polygon (B.Apex, Clipped);
   end Beam_Clip_Against_Polygon;

   function Subtract_Polygon_From_Beam
     (B : Beam; Poly : Polygon) return Beam
   is
      --  Educational visibility proxy: if the polygon fully covers the
      --  projected beam cross-section, the beam is extinguished (Count=0);
      --  otherwise the open beam is returned unchanged.
      Pln       : constant Plane := Polygon_Plane (Poly);
      Projected : constant Polygon := Project_Beam_Onto_Plane (B, Pln);
      All_Inside : Boolean := True;
   begin
      if Projected.Count < 3 then
         return B;
      end if;
      for I in 1 .. Projected.Count loop
         if not Point_In_Convex_Polygon
           (Projected.Vertices (I), Poly, Pln.Normal)
         then
            All_Inside := False;
            exit;
         end if;
      end loop;
      if All_Inside then
         declare
            Empty : Beam;
         begin
            Empty.Apex  := B.Apex;
            Empty.Count := 0;
            return Empty;
         end;
      else
         return B;
      end if;
   end Subtract_Polygon_From_Beam;

   -------------------------------------------------------------------------
   -- 4. Reflect
   -------------------------------------------------------------------------

   function Reflect_Beam
     (B : Beam; Mirror : Plane) return Beam
   is
      N        : Plane_Normal := Mirror.Normal;
      Image    : Apex_Point;
      --  Distance from apex to plane along normal
      Dist     : Real;
      Hit_Poly : Polygon;
      Result   : Beam;
      D        : Vec3;
   begin
      Ensure_Unit_Normal (N);
      Dist  := Dot (N, B.Apex - Mirror.Point);
      --  Image of apex across the plane
      Image := B.Apex - ((2.0 * Dist) * N);
      Hit_Poly := Project_Beam_Onto_Plane
        (B, (Point => Mirror.Point, Normal => N));
      if Hit_Poly.Count < 3 then
         raise Degenerate_Geometry with "Beam misses mirror plane";
      end if;
      --  New beam: image apex through the hit polygon (equivalent to
      --  reflecting each corner direction).
      Result.Apex  := Image;
      Result.Count := 0;
      for I in 1 .. Hit_Poly.Count loop
         D := Hit_Poly.Vertices (I) - Image;
         if Length (D) = 0.0 then
            raise Degenerate_Geometry with "Mirror hit at image apex";
         end if;
         if Result.Count < Max_Corners then
            Result.Count := Result.Count + 1;
            Result.Corners (Result.Count) := Normalize (D);
         end if;
      end loop;
      if Result.Count /= B.Count then
         --  Corner count should match projection; pad/trim already handled.
         null;
      end if;
      return Result;
   end Reflect_Beam;

   -------------------------------------------------------------------------
   -- 5. Refract
   -------------------------------------------------------------------------

   function Refract_Beam
     (B           : Beam;
      Interface_P : Plane;
      N1, N2      : Index_Of_Refraction) return Beam
   is
      N     : Plane_Normal := Interface_P.Normal;
      Axis  : constant Axis_Direction := Beam_Axis (B);
      T_Hit : Real;
      New_Apex : Apex_Point;
      Eta   : constant Real := Real (N1) / Real (N2);
      Result : Beam;
      RD    : Axis_Direction;
   begin
      Ensure_Unit_Normal (N);
      T_Hit := Ray_Plane_T (B.Apex, Axis, (Interface_P.Point, N));
      if T_Hit = Real'First or else T_Hit <= 0.0 then
         raise Degenerate_Geometry with "Beam axis misses interface";
      end if;
      New_Apex := B.Apex + (T_Hit * Axis);
      Result.Apex  := New_Apex;
      Result.Count := 0;
      for I in 1 .. B.Count loop
         RD := Refract_Dir (B.Corners (I), N, Eta);
         if Result.Count < Max_Corners then
            Result.Count := Result.Count + 1;
            Result.Corners (Result.Count) := RD;
         end if;
      end loop;
      return Result;
   end Refract_Beam;

   -------------------------------------------------------------------------
   -- 6. Intersections
   -------------------------------------------------------------------------

   function Beam_Intersect_Polygon
     (B : Beam; Poly : Polygon) return Beam_Polygon_Hit
   is
      Pln  : constant Plane := Polygon_Plane (Poly);
      Axis : constant Axis_Direction := Beam_Axis (B);
      T    : constant Real := Ray_Plane_T (B.Apex, Axis, Pln);
      Hit  : Vec3;
      Result : Beam_Polygon_Hit;
      Inside_Count : Natural := 0;
      Projected : Polygon;
   begin
      Result := (Intersects => False, Distance => 0.0,
                 Hit => (0.0, 0.0, 0.0), Coverage => 0.0);
      if T = Real'First or else T <= 0.0 then
         return Result;
      end if;
      Hit := B.Apex + (T * Axis);
      if not Point_In_Convex_Polygon (Hit, Poly, Pln.Normal) then
         --  Axis miss: still check if any projected corner lies inside
         Projected := Project_Beam_Onto_Plane (B, Pln);
         for I in 1 .. Projected.Count loop
            if Point_In_Convex_Polygon
              (Projected.Vertices (I), Poly, Pln.Normal)
            then
               Inside_Count := Inside_Count + 1;
            end if;
         end loop;
         if Inside_Count = 0 then
            return Result;
         end if;
         Result.Intersects := True;
         Result.Distance   := Non_Negative (T);
         Result.Hit        := Hit;
         Result.Coverage   := Unit_Interval
           (Clamp (Real (Inside_Count) / Real (B.Count), 0.0, 1.0));
         return Result;
      end if;
      --  Axis hit inside polygon: estimate coverage via corner projection
      Projected := Project_Beam_Onto_Plane (B, Pln);
      for I in 1 .. Projected.Count loop
         if Point_In_Convex_Polygon
           (Projected.Vertices (I), Poly, Pln.Normal)
         then
            Inside_Count := Inside_Count + 1;
         end if;
      end loop;
      Result.Intersects := True;
      Result.Distance   := Non_Negative (T);
      Result.Hit        := Hit;
      --  Axis-inside counts as coverage; corners refine the estimate.
      if Projected.Count > 0 then
         Result.Coverage := Unit_Interval
           (Clamp
              ((Real (Inside_Count) + 1.0) / (Real (Projected.Count) + 1.0),
               0.0, 1.0));
      else
         Result.Coverage := 1.0;
      end if;
      return Result;
   end Beam_Intersect_Polygon;

   function Beam_Intersect_AABB
     (B : Beam; Box : AABB) return Beam_AABB_Hit
   is
      --  Conservative: test the axis ray against the slab AABB; also accept
      --  if the apex is inside the box.
      Axis : constant Axis_Direction := Beam_Axis (B);
      Tmin : Real := 0.0;
      Tmax : Real := Real'Last;
      Result : Beam_AABB_Hit :=
        (Overlaps => False, Near_Distance => 0.0, Far_Distance => 0.0);

      procedure Slab (Orig, Dir, Bmin, Bmax : Real) is
         Inv : Real;
         T1, T2 : Real;
         Tnear, Tfar : Real;
      begin
         if Abs_R (Dir) < 1.0E-10 then
            if Orig < Bmin or else Orig > Bmax then
               Tmax := -1.0;  -- miss
            end if;
            return;
         end if;
         Inv := 1.0 / Dir;
         T1 := (Bmin - Orig) * Inv;
         T2 := (Bmax - Orig) * Inv;
         if T1 < T2 then
            Tnear := T1;
            Tfar  := T2;
         else
            Tnear := T2;
            Tfar  := T1;
         end if;
         if Tnear > Tmin then
            Tmin := Tnear;
         end if;
         if Tfar < Tmax then
            Tmax := Tfar;
         end if;
      end Slab;
   begin
      --  Apex inside?
      if B.Apex.X >= Box.Min_P.X and then B.Apex.X <= Box.Max_P.X
        and then B.Apex.Y >= Box.Min_P.Y and then B.Apex.Y <= Box.Max_P.Y
        and then B.Apex.Z >= Box.Min_P.Z and then B.Apex.Z <= Box.Max_P.Z
      then
         Result.Overlaps := True;
         Result.Near_Distance := 0.0;
         Result.Far_Distance  := 0.0;
         return Result;
      end if;

      Slab (B.Apex.X, Axis.X, Box.Min_P.X, Box.Max_P.X);
      Slab (B.Apex.Y, Axis.Y, Box.Min_P.Y, Box.Max_P.Y);
      Slab (B.Apex.Z, Axis.Z, Box.Min_P.Z, Box.Max_P.Z);

      if Tmax >= Tmin and then Tmax >= 0.0 then
         Result.Overlaps := True;
         if Tmin > 0.0 then
            Result.Near_Distance := Non_Negative (Tmin);
         else
            Result.Near_Distance := 0.0;
         end if;
         Result.Far_Distance := Non_Negative (Tmax);
      end if;
      return Result;
   end Beam_Intersect_AABB;

   -------------------------------------------------------------------------
   -- 7. Split by occluder
   -------------------------------------------------------------------------

   function Split_Beam_By_Occluder
     (B : Beam; Occluder : Polygon) return Split_Result
   is
      Hit  : constant Beam_Polygon_Hit := Beam_Intersect_Polygon (B, Occluder);
      Clip : Beam;
      Result : Split_Result;
   begin
      Result.Has_Visible  := False;
      Result.Has_Occluded := False;
      if not Hit.Intersects then
         Result.Visible     := B;
         Result.Has_Visible := True;
         return Result;
      end if;
      Clip := Beam_Clip_Against_Polygon (B, Occluder);
      if Clip.Count >= 3 then
         Result.Occluded     := Clip;
         Result.Has_Occluded := True;
      end if;
      if Hit.Coverage >= 1.0 - 1.0E-4 then
         --  Fully covered: no visible remainder
         Result.Has_Visible := False;
      else
         --  Partial: keep original as conservative visible remainder
         Result.Visible     := B;
         Result.Has_Visible := True;
      end if;
      return Result;
   end Split_Beam_By_Occluder;

   -------------------------------------------------------------------------
   -- 8. Acoustics
   -------------------------------------------------------------------------

   function Propagation_Delay
     (Path_Length : Non_Negative; Speed : Sound_Speed) return Non_Negative
   is
   begin
      return Non_Negative (Path_Length / Speed);
   end Propagation_Delay;

   function Acoustic_Path_Attenuation
     (B            : Beam;
      Receiver     : Vec3;
      Speed        : Sound_Speed;
      Ref_Distance : Positive_Real := 1.0) return Acoustic_Result
   is
      Path : constant Non_Negative := Distance_Between (B.Apex, Receiver);
      Att  : Unit_Interval;
      --  Inverse-distance geometric spreading, clamped to [0,1]
      Raw  : Real;
   begin
      if Path <= Ref_Distance then
         Att := 1.0;
      else
         Raw := Ref_Distance / Path;
         Att := Unit_Interval (Clamp (Raw, 0.0, 1.0));
      end if;
      return
        (Path_Length   => Path,
         Delay_Seconds => Propagation_Delay (Path, Speed),
         Attenuation   => Att);
   end Acoustic_Path_Attenuation;

   -------------------------------------------------------------------------
   -- 9. Backwards beam from light
   -------------------------------------------------------------------------

   function Backwards_Beam_From_Light
     (Light           : Apex_Point;
      Receiver_Origin : Vec3;
      Receiver_U      : Vec3;
      Receiver_V      : Vec3) return Beam
   is
   begin
      --  Same construction as a viewing beam, but apex is the light.
      return Construct_Viewing_Beam
        (Light, Receiver_Origin, Receiver_U, Receiver_V);
   end Backwards_Beam_From_Light;

end Beam_Tracing;
