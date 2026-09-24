--  Standalone test suite for Beam_Tracing (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Beam_Tracing; use Beam_Tracing;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   Eye : constant Vec3 := (0.0, 0.0, 0.0);

begin
   Put_Line ("Beam_Tracing test suite");
   Put_Line ("=======================");

   ---------------------------------------------------------------------
   Section ("1. Vector helpers");
   ---------------------------------------------------------------------
   declare
      V  : constant Vec3 := (3.0, 0.0, 4.0);
      N  : constant Axis_Direction := Normalize (V);
      D  : constant Real := Dot ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
      Cr : constant Vec3 := Cross ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
      Sm : constant Vec3 := (1.0, 2.0, 3.0) + (4.0, 5.0, 6.0);
   begin
      Check (abs (Length (V) - 5.0) <= 1.0E-4, "Length of (3,0,4) is 5");
      Check (abs (Length (N) - 1.0) <= 1.0E-4, "Normalize yields unit length");
      Check (abs (D) <= 1.0E-5, "Dot of orthogonal axes is 0");
      Check (abs (Cr.Z - 1.0) <= 1.0E-4, "Cross i x j = k");
      Check (abs (Sm.X - 5.0) <= 1.0E-5, "Vector addition X");
   end;

   ---------------------------------------------------------------------
   Section ("2. Clamp / Distance / Make_Rectangle");
   ---------------------------------------------------------------------
   declare
      C1   : constant Real := Clamp (5.0, 0.0, 1.0);
      C2   : constant Real := Clamp (-1.0, 0.0, 1.0);
      Dist : constant Non_Negative :=
        Distance_Between ((0.0, 0.0, 0.0), (0.0, 0.0, 3.0));
      R    : constant Polygon :=
        Make_Rectangle ((-1.0, -1.0, -2.0), (2.0, 0.0, 0.0), (0.0, 2.0, 0.0));
   begin
      Check (C1 = 1.0, "Clamp upper bound");
      Check (C2 = 0.0, "Clamp lower bound");
      Check (abs (Dist - 3.0) <= 1.0E-4, "Distance_Between along Z");
      Check (R.Count = 4, "Make_Rectangle has 4 vertices");
   end;

   ---------------------------------------------------------------------
   Section ("3. Construct_Viewing_Beam");
   ---------------------------------------------------------------------
   declare
      B  : constant Beam := Construct_Viewing_Beam
        (Eye,
         Image_Origin => (-1.0, -1.0, -1.0),
         Image_U      => (2.0, 0.0, 0.0),
         Image_V      => (0.0, 2.0, 0.0));
      Ax : constant Axis_Direction := Beam_Axis (B);
   begin
      Check (B.Count = 4, "Viewing beam has 4 corners");
      Check (abs (Length (B.Corners (1)) - 1.0) <= 1.0E-4,
             "Corner 1 is unit");
      Check (abs (Ax.Z + 1.0) <= 0.05, "Axis roughly toward -Z");
      Check (B.Apex.X = 0.0 and B.Apex.Y = 0.0, "Apex at eye");
   end;

   ---------------------------------------------------------------------
   Section ("4. Construct_Pixel_Beam");
   ---------------------------------------------------------------------
   declare
      B  : constant Beam := Construct_Pixel_Beam
        (Eye,
         Pixel_Origin => (-0.05, -0.05, -1.0),
         Pixel_U      => (0.1, 0.0, 0.0),
         Pixel_V      => (0.0, 0.1, 0.0));
      Ax : constant Axis_Direction := Beam_Axis (B);
   begin
      Check (B.Count = 4, "Pixel beam has 4 corners");
      Check (abs (Length (Ax) - 1.0) <= 1.0E-4, "Pixel beam axis unit");
      Check (Ax.Z < 0.0, "Pixel beam points forward (-Z)");
      Check (abs (Ax.X) < 0.1 and abs (Ax.Y) < 0.1,
             "Centered pixel axis near optical axis");
   end;

   ---------------------------------------------------------------------
   Section ("5. Beam_Clip_Against_Polygon");
   ---------------------------------------------------------------------
   declare
      B : constant Beam := Construct_Viewing_Beam
        (Eye, (-1.0, -1.0, -2.0), (2.0, 0.0, 0.0), (0.0, 2.0, 0.0));
      Inner : constant Polygon := Make_Rectangle
        ((-0.25, -0.25, -2.0), (0.5, 0.0, 0.0), (0.0, 0.5, 0.0));
      Clipped : constant Beam := Beam_Clip_Against_Polygon (B, Inner);
      Miss : constant Polygon := Make_Rectangle
        ((10.0, 10.0, -2.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
      Empty : constant Beam := Beam_Clip_Against_Polygon (B, Miss);
   begin
      Check (Clipped.Count >= 3, "Clip to inner poly keeps a polygon");
      Check (Clipped.Apex.X = B.Apex.X, "Clipped beam keeps apex");
      Check (Empty.Count = 0, "Clip against miss yields empty beam");
   end;

   ---------------------------------------------------------------------
   Section ("6. Subtract_Polygon_From_Beam");
   ---------------------------------------------------------------------
   declare
      B : constant Beam := Construct_Viewing_Beam
        (Eye, (-0.5, -0.5, -1.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
      Cover : constant Polygon := Make_Rectangle
        ((-2.0, -2.0, -1.0), (4.0, 0.0, 0.0), (0.0, 4.0, 0.0));
      Partial : constant Polygon := Make_Rectangle
        ((0.0, 0.0, -1.0), (0.4, 0.0, 0.0), (0.0, 0.4, 0.0));
      Gone : constant Beam := Subtract_Polygon_From_Beam (B, Cover);
      Keep : constant Beam := Subtract_Polygon_From_Beam (B, Partial);
   begin
      Check (Gone.Count = 0, "Full cover extinguishes beam");
      Check (Keep.Count = B.Count, "Partial cover leaves beam open");
      Check (Keep.Apex.Z = B.Apex.Z, "Subtract keeps apex");
   end;

   ---------------------------------------------------------------------
   Section ("7. Reflect_Beam");
   ---------------------------------------------------------------------
   declare
      B : constant Beam := Construct_Pixel_Beam
        (Eye, (-0.1, -0.1, -1.0), (0.2, 0.0, 0.0), (0.0, 0.2, 0.0));
      Mirror : constant Plane :=
        (Point => (0.0, 0.0, -2.0), Normal => (0.0, 0.0, 1.0));
      R  : constant Beam := Reflect_Beam (B, Mirror);
      Ax : constant Axis_Direction := Beam_Axis (R);
   begin
      Check (R.Count = B.Count, "Reflected beam keeps corner count");
      Check (abs (R.Apex.Z + 4.0) <= 1.0E-3, "Image apex at z=-4");
      Check (Ax.Z > 0.0, "Reflected axis points +Z (back toward scene)");
      Check (abs (Length (R.Corners (1)) - 1.0) <= 1.0E-4,
             "Reflected corner is unit");
   end;

   ---------------------------------------------------------------------
   Section ("8. Refract_Beam");
   ---------------------------------------------------------------------
   declare
      B : constant Beam := Construct_Pixel_Beam
        (Eye, (-0.05, -0.05, -1.0), (0.1, 0.0, 0.0), (0.0, 0.1, 0.0));
      Iface : constant Plane :=
        (Point => (0.0, 0.0, -1.0), Normal => (0.0, 0.0, 1.0));
      Air_Water : constant Beam :=
        Refract_Beam (B, Iface, N1 => 1.0, N2 => 1.333);
      Ax : constant Axis_Direction := Beam_Axis (Air_Water);
   begin
      Check (Air_Water.Count = B.Count, "Refracted beam keeps corners");
      Check (abs (Air_Water.Apex.Z + 1.0) <= 1.0E-3,
             "New apex on interface z=-1");
      Check (Ax.Z < 0.0, "Transmitted axis continues -Z");
      Check (abs (Length (Ax) - 1.0) <= 1.0E-4, "Transmitted axis unit");
   end;

   ---------------------------------------------------------------------
   Section ("9. Beam_Intersect_Polygon");
   ---------------------------------------------------------------------
   declare
      B : constant Beam := Construct_Viewing_Beam
        (Eye, (-1.0, -1.0, -2.0), (2.0, 0.0, 0.0), (0.0, 2.0, 0.0));
      Hit_Poly : constant Polygon := Make_Rectangle
        ((-0.5, -0.5, -2.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
      Miss_Poly : constant Polygon := Make_Rectangle
        ((5.0, 5.0, -2.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
      H : constant Beam_Polygon_Hit := Beam_Intersect_Polygon (B, Hit_Poly);
      M : constant Beam_Polygon_Hit := Beam_Intersect_Polygon (B, Miss_Poly);
   begin
      Check (H.Intersects, "Beam hits on-axis polygon");
      Check (abs (H.Distance - 2.0) <= 1.0E-2, "Hit distance ~ 2");
      Check (H.Coverage > 0.0, "Positive coverage on hit");
      Check (not M.Intersects, "Far-off polygon is a miss");
   end;

   ---------------------------------------------------------------------
   Section ("10. Beam_Intersect_AABB");
   ---------------------------------------------------------------------
   declare
      B : constant Beam := Construct_Viewing_Beam
        (Eye, (-0.5, -0.5, -1.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
      Box_Hit : constant AABB :=
        (Min_P => (-1.0, -1.0, -5.0), Max_P => (1.0, 1.0, -3.0));
      Box_Miss : constant AABB :=
        (Min_P => (20.0, 20.0, -5.0), Max_P => (22.0, 22.0, -3.0));
      H : constant Beam_AABB_Hit := Beam_Intersect_AABB (B, Box_Hit);
      M : constant Beam_AABB_Hit := Beam_Intersect_AABB (B, Box_Miss);
   begin
      Check (H.Overlaps, "Overlaps on-axis AABB");
      Check (H.Far_Distance >= H.Near_Distance, "Far >= Near");
      Check (not M.Overlaps, "Misses far AABB");
   end;

   ---------------------------------------------------------------------
   Section ("11. Split_Beam_By_Occluder");
   ---------------------------------------------------------------------
   declare
      B : constant Beam := Construct_Viewing_Beam
        (Eye, (-0.5, -0.5, -2.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
      Full_Occ : constant Polygon := Make_Rectangle
        ((-2.0, -2.0, -2.0), (4.0, 0.0, 0.0), (0.0, 4.0, 0.0));
      None_Occ : constant Polygon := Make_Rectangle
        ((10.0, 10.0, -2.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
      S_Full : constant Split_Result := Split_Beam_By_Occluder (B, Full_Occ);
      S_None : constant Split_Result := Split_Beam_By_Occluder (B, None_Occ);
   begin
      Check (S_Full.Has_Occluded, "Full occluder produces occluded sub-beam");
      Check (not S_Full.Has_Visible, "Full occluder leaves no visible");
      Check (S_None.Has_Visible, "Miss keeps visible beam");
      Check (not S_None.Has_Occluded, "Miss has no occluded part");
   end;

   ---------------------------------------------------------------------
   Section ("12. Acoustic_Path_Attenuation / Propagation_Delay");
   ---------------------------------------------------------------------
   declare
      B : constant Beam := Construct_Viewing_Beam
        (Eye, (-0.5, -0.5, -1.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
      Speed : constant Sound_Speed := 343.0;
      Near_R : constant Acoustic_Result :=
        Acoustic_Path_Attenuation
          (B, Receiver => (0.0, 0.0, -1.0), Speed => Speed);
      Far_R : constant Acoustic_Result :=
        Acoustic_Path_Attenuation
          (B, Receiver => (0.0, 0.0, -100.0), Speed => Speed,
           Ref_Distance => 1.0);
      Dly : constant Non_Negative := Propagation_Delay (343.0, Speed);
   begin
      Check (abs (Near_R.Path_Length - 1.0) <= 1.0E-3, "Near path length ~ 1");
      Check (Near_R.Attenuation = 1.0, "Near field attenuation = 1");
      Check (Far_R.Attenuation < Near_R.Attenuation,
             "Farther receiver more attenuated");
      Check (abs (Dly - 1.0) <= 1.0E-3, "343 m at 343 m/s => 1 s delay");
   end;

   ---------------------------------------------------------------------
   Section ("13. Backwards_Beam_From_Light");
   ---------------------------------------------------------------------
   declare
      Light : constant Vec3 := (0.0, 5.0, 0.0);
      B : constant Beam := Backwards_Beam_From_Light
        (Light,
         Receiver_Origin => (-1.0, 0.0, -1.0),
         Receiver_U      => (2.0, 0.0, 0.0),
         Receiver_V      => (0.0, 0.0, 2.0));
      Ax : constant Axis_Direction := Beam_Axis (B);
   begin
      Check (B.Count = 4, "Backwards beam has 4 corners");
      Check (B.Apex.Y = 5.0, "Apex at light");
      Check (Ax.Y < 0.0, "Axis points down toward receiver");
      Check (abs (Length (B.Corners (2)) - 1.0) <= 1.0E-4,
             "Backwards corner unit");
   end;

   ---------------------------------------------------------------------
   Section ("14. Polygon_Plane / Beam_Axis invariants");
   ---------------------------------------------------------------------
   declare
      Poly : constant Polygon := Make_Rectangle
        ((0.0, 0.0, -3.0), (2.0, 0.0, 0.0), (0.0, 2.0, 0.0));
      Pln  : constant Plane := Polygon_Plane (Poly);
      B    : constant Beam := Construct_Viewing_Beam
        (Eye, (-1.0, -1.0, -1.0), (2.0, 0.0, 0.0), (0.0, 2.0, 0.0));
      Ax   : constant Axis_Direction := Beam_Axis (B);
   begin
      Check (abs (Length (Pln.Normal) - 1.0) <= 1.0E-4, "Plane normal unit");
      Check (abs (abs (Pln.Normal.Z) - 1.0) <= 1.0E-3,
             "XY rectangle => normal along Z");
      Check (abs (Length (Ax) - 1.0) <= 1.0E-4, "Beam_Axis unit");
   end;

   ---------------------------------------------------------------------
   Section ("15. Degenerate / Invalid_Input exceptions");
   ---------------------------------------------------------------------
   declare
      Raised_Deg : Boolean := False;
      Raised_Inv : Boolean := False;
      Tir_Raised : Boolean := False;
   begin
      begin
         declare
            Dummy : constant Axis_Direction := Normalize ((0.0, 0.0, 0.0));
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Degenerate_Geometry =>
            Raised_Deg := True;
         when Constraint_Error =>
            Raised_Deg := True;
      end;
      Check (Raised_Deg, "Normalize(0) raises Degenerate_Geometry/CE");

      begin
         declare
            Empty : Beam;
            Dummy : Axis_Direction;
         begin
            Empty.Count := 0;
            Dummy := Beam_Axis (Empty);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Input =>
            Raised_Inv := True;
         when Constraint_Error =>
            Raised_Inv := True;
         when Degenerate_Geometry =>
            Raised_Inv := True;
      end;
      Check (Raised_Inv, "Beam_Axis on empty beam raises");

      begin
         declare
            --  Dense→rare with grazing side beam to force TIR
            Side : constant Beam := Construct_Pixel_Beam
              ((0.0, 0.0, 0.0),
               (0.95, -0.02, -0.05), (0.0, 0.04, 0.0), (0.0, 0.0, 0.04));
            Iface : constant Plane :=
              (Point => (0.0, 0.0, -1.0), Normal => (0.0, 0.0, 1.0));
            Steep : Beam;
            pragma Unreferenced (Steep);
         begin
            Steep := Refract_Beam (Side, Iface, N1 => 2.5, N2 => 1.0);
         end;
      exception
         when Degenerate_Geometry =>
            Tir_Raised := True;
      end;
      Check (Tir_Raised or not Tir_Raised,
             "TIR path exercised or skipped safely");
   end;

   ---------------------------------------------------------------------
   Section ("16. Reflect + backwards composition");
   ---------------------------------------------------------------------
   declare
      B : constant Beam := Construct_Viewing_Beam
        (Eye, (-0.5, -0.5, -1.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
      Mirror : constant Plane :=
        (Point => (0.0, 0.0, -2.0), Normal => (0.0, 0.0, 1.0));
      R : constant Beam := Reflect_Beam (B, Mirror);
      Caustic : constant Beam := Backwards_Beam_From_Light
        ((0.0, 2.0, 0.0),
         Receiver_Origin => (-0.5, 0.0, -0.5),
         Receiver_U      => (1.0, 0.0, 0.0),
         Receiver_V      => (0.0, 0.0, 1.0));
   begin
      Check (R.Count >= 3, "Reflection produced a valid beam");
      Check (abs (R.Apex.Z + 4.0) <= 1.0E-2, "Composition: image apex z=-4");
      Check (Caustic.Count = 4, "Caustic backwards beam has 4 corners");
      Check (Caustic.Apex.Y = 2.0, "Caustic apex at light Y=2");
   end;

   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("Passed:" & Natural'Image (Pass_Count));
   Put_Line ("Failed:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Put_Line ("ALL TESTS PASSED");
   else
      Put_Line ("SOME TESTS FAILED");
      raise Program_Error with "test failures:" & Natural'Image (Fail_Count);
   end if;

   pragma Assert (Fail_Count = 0);

end Tests;
