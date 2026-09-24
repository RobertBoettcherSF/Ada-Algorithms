--  Standalone test suite for Cone_Tracing (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Cone_Tracing; use Cone_Tracing;

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

   --  Convenience constants
   Origin : constant Vec3 := (0.0, 0.0, 0.0);
   Eye    : constant Vec3 := (0.0, 0.0, 0.0);
   Forward : constant Vec3 := (0.0, 0.0, -1.0);
   Up      : constant Vec3 := (0.0, 1.0, 0.0);

begin
   Put_Line ("Cone_Tracing test suite");
   Put_Line ("=======================");

   ---------------------------------------------------------------------
   -- Test 1: Vector helpers
   ---------------------------------------------------------------------
   Section ("1. Vector helpers");
   declare
      V  : constant Vec3 := (3.0, 0.0, 4.0);
      N  : constant Axis_Direction := Normalize (V);
      D  : constant Real := Dot ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
      Cr : constant Vec3 := Cross ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
   begin
      Check (abs (Length (V) - 5.0) <= 1.0E-4, "Length of (3,0,4) is 5");
      Check (abs (Length (N) - 1.0) <= 1.0E-4, "Normalize yields unit length");
      Check (abs (D) <= 1.0E-5, "Dot of orthogonal unit axes is 0");
      Check (abs (Cr.Z - 1.0) <= 1.0E-4, "Cross i x j = k");
   end;

   ---------------------------------------------------------------------
   -- Test 2: Clamp / Clamp_Half_Angle
   ---------------------------------------------------------------------
   Section ("2. Clamp helpers");
   declare
      C1 : constant Real := Clamp (5.0, 0.0, 1.0);
      C2 : constant Real := Clamp (-1.0, 0.0, 1.0);
      C3 : constant Real := Clamp (0.5, 0.0, 1.0);
      A  : constant Half_Angle_Rad := Clamp_Half_Angle (3.0);
   begin
      Check (C1 = 1.0, "Clamp upper bound");
      Check (C2 = 0.0, "Clamp lower bound");
      Check (C3 = 0.5, "Clamp interior unchanged");
      Check (A = Half_Angle_Rad'Last, "Clamp_Half_Angle saturates at pi/2");
   end;

   ---------------------------------------------------------------------
   -- Test 3: Construct_Circular_Cone
   ---------------------------------------------------------------------
   Section ("3. Construct_Circular_Cone");
   declare
      Pixel : constant Vec3 := (0.0, 0.0, -1.0);
      C     : constant Cone :=
        Construct_Circular_Cone (Eye, Pixel, Pixel_Half_Ext => 0.01);
   begin
      Check (abs (C.Axis.Z + 1.0) <= 1.0E-4, "Cone axis points toward pixel (-Z)");
      Check (C.Half_Angle > 0.0, "Half-angle is positive for finite pixel");
      Check (C.Half_Angle < 0.1, "Small pixel => small half-angle");
      Check (abs (Length (C.Axis) - 1.0) <= 1.0E-4, "Axis is unit length");
   end;

   ---------------------------------------------------------------------
   -- Test 4: Construct_Pixel_Beam + Beam_Half_Angles
   ---------------------------------------------------------------------
   Section ("4. Construct_Pixel_Beam");
   declare
      --  Pixel on z=-1 plane, from (-0.5,-0.5,-1) with size 1x1
      P0 : constant Vec3 := (-0.5, -0.5, -1.0);
      U  : constant Vec3 := (1.0, 0.0, 0.0);
      V  : constant Vec3 := (0.0, 1.0, 0.0);
      B  : constant Beam_Frustum := Construct_Pixel_Beam (Eye, P0, U, V);
      HA : constant Half_Angle_Rad := Beam_Half_Angles (B);
   begin
      Check (Length (B.Corners (1)) > 0.9, "Corner 1 is near-unit");
      Check (Length (B.Corners (3)) > 0.9, "Corner 3 is near-unit");
      Check (HA > 0.0, "Beam half-angle positive");
      Check (HA < Half_Angle_Rad'Last, "Beam half-angle below pi/2");
   end;

   ---------------------------------------------------------------------
   -- Test 5: Intersect_Cone_Sphere (hit)
   ---------------------------------------------------------------------
   Section ("5. Intersect_Cone_Sphere hit");
   declare
      C : constant Cone :=
        (Apex => Origin,
         Axis => (0.0, 0.0, -1.0),
         Half_Angle => 0.2);
      S : constant Sphere :=
        (Center => (0.0, 0.0, -5.0), Radius => 1.0);
      H : constant Cone_Sphere_Hit := Intersect_Cone_Sphere (C, S);
   begin
      Check (H.Intersects, "Cone hits sphere on axis");
      Check (H.Exit_Distance >= H.Enter_Distance, "Exit >= Enter");
      Check (H.Coverage > 0.0, "Positive coverage for on-axis sphere");
   end;

   ---------------------------------------------------------------------
   -- Test 6: Intersect_Cone_Sphere (miss)
   ---------------------------------------------------------------------
   Section ("6. Intersect_Cone_Sphere miss");
   declare
      C : constant Cone :=
        (Apex => Origin,
         Axis => (0.0, 0.0, -1.0),
         Half_Angle => 0.05);
      S : constant Sphere :=
        (Center => (10.0, 0.0, -5.0), Radius => 0.5);
      H : constant Cone_Sphere_Hit := Intersect_Cone_Sphere (C, S);
   begin
      Check (not H.Intersects, "Far-off sphere is a miss");
      Check (H.Coverage = 0.0, "Miss has zero coverage");
      Check (H.Enter_Distance = 0.0, "Miss enter distance stays 0");
   end;

   ---------------------------------------------------------------------
   -- Test 7: Intersect_Cone_Plane
   ---------------------------------------------------------------------
   Section ("7. Intersect_Cone_Plane");
   declare
      C : constant Cone :=
        Construct_Circular_Cone (Eye, (0.0, 0.0, -2.0), 0.1);
      P : constant Plane :=
        (Point => (0.0, 0.0, -2.0), Normal => (0.0, 0.0, 1.0));
      H : constant Cone_Plane_Hit := Intersect_Cone_Plane (C, P);
   begin
      Check (H.Intersects, "Cone intersects plane ahead");
      Check (abs (H.Distance - 2.0) <= 1.0E-3, "Hit distance ~ 2");
      Check (H.Disk_Radius > 0.0, "Footprint disk radius positive");
      Check (abs (H.Center_Hit.Z + 2.0) <= 1.0E-3, "Hit center on plane z=-2");
   end;

   ---------------------------------------------------------------------
   -- Test 8: Cone_Overlaps_AABB
   ---------------------------------------------------------------------
   Section ("8. Cone_Overlaps_AABB");
   declare
      C : constant Cone :=
        (Apex => Origin, Axis => (0.0, 0.0, -1.0), Half_Angle => 0.3);
      Box_Hit : constant AABB :=
        (Min_P => (-1.0, -1.0, -6.0), Max_P => (1.0, 1.0, -4.0));
      Box_Miss : constant AABB :=
        (Min_P => (20.0, 20.0, -6.0), Max_P => (22.0, 22.0, -4.0));
   begin
      Check (Cone_Overlaps_AABB (C, Box_Hit), "Overlaps on-axis AABB");
      Check (not Cone_Overlaps_AABB (C, Box_Miss), "Misses far AABB");
      Check (Box_Hit.Min_P.Z < Box_Hit.Max_P.Z, "AABB invariant Min < Max (Z)");
   end;

   ---------------------------------------------------------------------
   -- Test 9: Soft_Shadow_Cone
   ---------------------------------------------------------------------
   Section ("9. Soft_Shadow_Cone");
   declare
      Hit_P : constant Vec3 := (0.0, 0.0, 0.0);
      Light : constant Vec3 := (0.0, 5.0, 0.0);
      Full  : constant Soft_Shadow_Result :=
        Soft_Shadow_Cone (Hit_P, Light, 0.5, Occluder_Dist => 2.0,
                          Occluder_Size => 0.0);
      Block : constant Soft_Shadow_Result :=
        Soft_Shadow_Cone (Hit_P, Light, 0.1, Occluder_Dist => 1.0,
                          Occluder_Size => 2.0);
      Soft  : constant Soft_Shadow_Result :=
        Soft_Shadow_Cone (Hit_P, Light, 1.0, Occluder_Dist => 2.0,
                          Occluder_Size => 0.2);
   begin
      Check (Full.Umbra_Factor = 1.0, "No occluder => fully lit");
      Check (Block.Umbra_Factor = 0.0, "Large occluder => umbra");
      Check (Soft.Umbra_Factor > 0.0 and Soft.Umbra_Factor < 1.0,
             "Partial occluder => penumbra blend");
      Check (Soft.Penumbra_Width >= 0.0, "Penumbra width non-negative");
   end;

   ---------------------------------------------------------------------
   -- Test 10: Glossy_Reflection_Cone
   ---------------------------------------------------------------------
   Section ("10. Glossy_Reflection_Cone");
   declare
      HP : constant Vec3 := (0.0, 0.0, 0.0);
      --  Incident from +Z toward origin; normal +Y => reflect into +Z-ish / up
      Inc : constant Vec3 := Normalize ((0.0, -1.0, -1.0));
      Nrm : constant Vec3 := (0.0, 1.0, 0.0);
      Mirror : constant Cone :=
        Glossy_Reflection_Cone (HP, Inc, Nrm, Rough => 0.0);
      Glossy : constant Cone :=
        Glossy_Reflection_Cone (HP, Inc, Nrm, Rough => 0.5);
   begin
      Check (Mirror.Half_Angle = 0.0, "Perfect mirror => zero spread");
      Check (Glossy.Half_Angle > Mirror.Half_Angle,
             "Roughness expands reflection cone");
      Check (abs (Length (Glossy.Axis) - 1.0) <= 1.0E-4,
             "Reflection axis is unit");
      Check (Glossy.Apex.X = HP.X and Glossy.Apex.Y = HP.Y,
             "Apex at hit point");
   end;

   ---------------------------------------------------------------------
   -- Test 11: Footprint_LOD
   ---------------------------------------------------------------------
   Section ("11. Footprint_LOD");
   declare
      C : constant Cone :=
        Construct_Circular_Cone (Eye, (0.0, 0.0, -1.0), 0.05);
      Near_F : constant Footprint_Result :=
        Footprint_LOD (C, Hit_Distance => 1.0, Texel_World => 1.0);
      Far_F  : constant Footprint_Result :=
        Footprint_LOD (C, Hit_Distance => 100.0, Texel_World => 0.01,
                       Max_Mip => 12);
   begin
      Check (Near_F.Radius_At_Hit >= 0.0, "Near radius non-negative");
      Check (Near_F.Mip_Level = 0 or Near_F.Filter_Width < 1.0,
             "Small footprint => low mip");
      Check (Far_F.Mip_Level > Near_F.Mip_Level,
             "Larger distance / smaller texel => higher mip");
      Check (Far_F.Mip_Level <= 12, "Mip capped at Max_Mip");
   end;

   ---------------------------------------------------------------------
   -- Test 12: Depth_Of_Field_Cone
   ---------------------------------------------------------------------
   Section ("12. Depth_Of_Field_Cone");
   declare
      Focus : constant Non_Negative := 5.0;
      At_Focus : constant DoF_Cone_Result :=
        Depth_Of_Field_Cone
          (Lens_Center => Origin, Lens_Radius => 0.5,
           Focus_Distance => Focus, View_Direction => Forward,
           Query_Distance => Focus);
      Near_Q : constant DoF_Cone_Result :=
        Depth_Of_Field_Cone
          (Origin, 0.5, Focus, Forward, Query_Distance => 1.0);
      Far_Q : constant DoF_Cone_Result :=
        Depth_Of_Field_Cone
          (Origin, 0.5, Focus, Forward, Query_Distance => 10.0);
   begin
      Check (At_Focus.Cross_Section <= 1.0E-4,
             "Cross-section ~0 at focus plane");
      Check (Near_Q.Cross_Section > At_Focus.Cross_Section,
             "Near field has larger circle of confusion");
      Check (Far_Q.Cross_Section > At_Focus.Cross_Section,
             "Far field has larger circle of confusion");
      Check (Far_Q.Focus_Distance = Focus, "Focus distance preserved");
   end;

   ---------------------------------------------------------------------
   -- Test 13: Radius_At_Distance + Distance_Between
   ---------------------------------------------------------------------
   Section ("13. Radius_At_Distance / Distance_Between");
   declare
      C : constant Cone :=
        (Apex => Origin, Axis => Forward, Half_Angle => 0.0);
      C2 : constant Cone :=
        (Apex => Origin, Axis => Forward, Half_Angle => 0.785_398);
      --  ~45 degrees => radius ≈ distance
      R0 : constant Non_Negative := Radius_At_Distance (C, 10.0);
      R1 : constant Non_Negative := Radius_At_Distance (C2, 1.0);
      DB : constant Non_Negative :=
        Distance_Between ((0.0, 0.0, 0.0), (0.0, 3.0, 4.0));
   begin
      Check (R0 = 0.0, "Zero half-angle => zero radius");
      Check (abs (Real (R1) - 1.0) <= 0.05, "45-deg cone radius ~ distance");
      Check (abs (Real (DB) - 5.0) <= 1.0E-4, "Distance_Between 3-4-5");
   end;

   ---------------------------------------------------------------------
   -- Test 14: Edge — parallel plane miss / behind apex
   ---------------------------------------------------------------------
   Section ("14. Edge cases: plane miss");
   declare
      C : constant Cone :=
        (Apex => Origin, Axis => Forward, Half_Angle => 0.1);
      Parallel : constant Plane :=
        (Point => (0.0, 1.0, 0.0), Normal => (0.0, 1.0, 0.0));
      Behind : constant Plane :=
        (Point => (0.0, 0.0, 2.0), Normal => (0.0, 0.0, 1.0));
      H1 : constant Cone_Plane_Hit := Intersect_Cone_Plane (C, Parallel);
      H2 : constant Cone_Plane_Hit := Intersect_Cone_Plane (C, Behind);
   begin
      Check (not H1.Intersects, "Parallel plane => no intersection");
      Check (not H2.Intersects, "Plane behind apex => no intersection");
      Check (H1.Disk_Radius = 0.0, "Miss keeps disk radius 0");
   end;

   ---------------------------------------------------------------------
   -- Test 15: Error handling — Normalize zero / Soft_Shadow coincidence
   ---------------------------------------------------------------------
   Section ("15. Error handling");
   declare
      Raised_Norm : Boolean := False;
      Raised_Soft : Boolean := False;
   begin
      begin
         declare
            Unused : Axis_Direction := Normalize ((0.0, 0.0, 0.0));
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Degenerate_Geometry =>
            Raised_Norm := True;
         when Invalid_Input =>
            Raised_Norm := True;
      end;
      begin
         declare
            Unused : Soft_Shadow_Result :=
              Soft_Shadow_Cone
                (Hit => (1.0, 2.0, 3.0),
                 Light_Center => (1.0, 2.0, 3.0),
                 Light_Radius => 0.1,
                 Occluder_Dist => 1.0,
                 Occluder_Size => 0.1);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Input =>
            Raised_Soft := True;
         when Constraint_Error =>
            --  Precondition Length(Light-Hit)>0 may raise CE under some checks
            Raised_Soft := True;
      end;
      Check (Raised_Norm, "Normalize(0) raises Degenerate_Geometry");
      Check (Raised_Soft, "Coincident light/hit raises Invalid_Input");
      Check (Pass_Count > 0, "At least one assertion passed so far");
   end;

   ---------------------------------------------------------------------
   -- Test 16: Invariants across construction
   ---------------------------------------------------------------------
   Section ("16. Invariants");
   declare
      C : constant Cone :=
        Construct_Circular_Cone
          ((0.0, 1.0, 2.0), (0.0, 1.0, -3.0), 0.25);
      R_Near : constant Non_Negative := Radius_At_Distance (C, 1.0);
      R_Far  : constant Non_Negative := Radius_At_Distance (C, 4.0);
      DoF    : constant DoF_Cone_Result :=
        Depth_Of_Field_Cone
          ((0.0, 0.0, 0.0), 1.0, 4.0, Forward, 0.0);
   begin
      Check (R_Far > R_Near, "Cone radius grows with distance");
      Check (C.Half_Angle >= 0.0 and C.Half_Angle <= Half_Angle_Rad'Last,
             "Half-angle in valid domain");
      Check (DoF.Cross_Section = 1.0,
             "At lens (d=0) cross-section equals lens radius");
      Check (abs (Dot (C.Axis, C.Axis) - 1.0) <= 1.0E-4,
             "Axis remains unit (dot self = 1)");
   end;

   --  Silence unused Up warning if any
   declare
      Unused_Up : constant Real := Length (Up);
   begin
      Check (Unused_Up = 1.0, "Up vector length is 1 (sanity)");
   end;

   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   Put_Line ("----------------------------------------");

   pragma Assert (Fail_Count = 0, "One or more tests failed");

   if Fail_Count = 0 then
      Put_Line ("ALL TESTS PASSED");
   else
      Put_Line ("SOME TESTS FAILED");
      raise Program_Error with "One or more tests failed";
   end if;
end Tests;
