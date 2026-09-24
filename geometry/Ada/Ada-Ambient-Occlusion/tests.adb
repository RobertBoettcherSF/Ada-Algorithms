--  Standalone test suite for Ambient_Occlusion (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ambient_Occlusion; use Ambient_Occlusion;

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

   Origin : constant Vec3 := (0.0, 0.0, 0.0);
   Up     : constant Vec3 := (0.0, 1.0, 0.0);

begin
   Put_Line ("Ambient_Occlusion test suite");
   Put_Line ("============================");

   ---------------------------------------------------------------------
   Section ("1. Vector helpers");
   ---------------------------------------------------------------------
   declare
      V  : constant Vec3 := (3.0, 0.0, 4.0);
      N  : constant Direction3 := Normalize (V);
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
   Section ("2. Clamp / Clamp_Unit / Distance / Basis");
   ---------------------------------------------------------------------
   declare
      C1   : constant Real := Clamp (5.0, 0.0, 1.0);
      C2   : constant Real := Clamp (-1.0, 0.0, 1.0);
      U    : constant Unit_Interval := Clamp_Unit (1.5);
      Dist : constant Non_Negative :=
        Distance_Between ((0.0, 0.0, 0.0), (0.0, 0.0, 3.0));
      T, B : Direction3;
   begin
      Orthonormal_Basis (Up, T, B);
      Check (C1 = 1.0, "Clamp upper bound");
      Check (C2 = 0.0, "Clamp lower bound");
      Check (U = 1.0, "Clamp_Unit saturates at 1");
      Check (abs (Dist - 3.0) <= 1.0E-4, "Distance_Between along Z");
      Check (abs (Dot (T, Up)) <= 1.0E-4, "Tangent orthogonal to normal");
      Check (abs (Dot (B, Up)) <= 1.0E-4, "Bitangent orthogonal to normal");
   end;

   ---------------------------------------------------------------------
   Section ("3. Fixed hemisphere samples");
   ---------------------------------------------------------------------
   declare
      S : constant Direction_Array := Fixed_Hemisphere_Samples (8);
      All_Up : Boolean := True;
   begin
      Check (Length (S (1)) > 0.9, "Sample 1 near-unit");
      Check (Length (S (8)) > 0.9, "Sample 8 near-unit");
      for I in 1 .. 8 loop
         if S (I).Z < -1.0E-5 then
            All_Up := False;
         end if;
      end loop;
      Check (All_Up, "All samples in +Z hemisphere");
      Check (S (1).Z > 0.0, "First sample has positive Z");
   end;

   ---------------------------------------------------------------------
   Section ("4. Scene builders & Ray_Hit_Distance");
   ---------------------------------------------------------------------
   declare
      Scn : Scene := Empty_Scene;
      Hit, Miss : Non_Negative;
   begin
      Scn := Add_Sphere (Scn, (Center => (0.0, 0.0, -5.0), Radius => 1.0));
      Scn := Add_Plane
        (Scn, (Point => (0.0, -2.0, 0.0), Normal => (0.0, 1.0, 0.0)));
      Scn := Add_AABB
        (Scn, (Min_P => (4.0, -0.5, -0.5), Max_P => (5.0, 0.5, 0.5)));
      Hit := Ray_Hit_Distance
        (Origin, (0.0, 0.0, -1.0), Scn, Max_Dist => 20.0);
      Miss := Ray_Hit_Distance
        (Origin, (0.0, 1.0, 0.0), Scn, Max_Dist => 1.0);
      Check (Scn.Sphere_Count = 1, "One sphere in scene");
      Check (Scn.Plane_Count = 1, "One plane in scene");
      Check (Scn.Box_Count = 1, "One AABB in scene");
      Check (Hit > 0.0 and then Hit < 5.0, "Ray hits sphere ahead");
      Check (Miss = 0.0, "Short upward ray misses plane at y=-2");
   end;

   ---------------------------------------------------------------------
   Section ("5. Hemisphere_AO open vs occluded");
   ---------------------------------------------------------------------
   declare
      Open_Scn : constant Scene := Empty_Scene;
      Occ_Scn  : Scene := Empty_Scene;
      Open_R, Occ_R : AO_Result;
      P : constant Point3 := (0.0, 0.0, 0.0);
      N : constant Normal3 := (0.0, 1.0, 0.0);
   begin
      --  Large sphere above the point blocks most of the hemisphere.
      Occ_Scn := Add_Sphere
        (Occ_Scn, (Center => (0.0, 1.5, 0.0), Radius => 1.2));
      Open_R := Hemisphere_AO (P, N, Open_Scn, Radius => 5.0, Samples => 16);
      Occ_R  := Hemisphere_AO (P, N, Occ_Scn,  Radius => 5.0, Samples => 16);
      Check (Open_R.Factor > 0.95, "Open scene nearly fully lit");
      Check (Occ_R.Factor < Open_R.Factor, "Occluder darkens AO");
      Check (Occ_R.Sample_Hits > 0, "Occluded case records hits");
      Check (Length (Open_R.Bent_Normal) > 0.9, "Bent normal is unit-ish");
   end;

   ---------------------------------------------------------------------
   Section ("6. MonteCarlo_Hemisphere_AO matches Hemisphere_AO");
   ---------------------------------------------------------------------
   declare
      Scn : Scene := Empty_Scene;
      A, B : AO_Result;
      P : constant Point3 := (0.0, 0.0, 0.0);
      N : constant Normal3 := (0.0, 1.0, 0.0);
   begin
      Scn := Add_Sphere (Scn, (Center => (0.0, 2.0, 0.0), Radius => 0.8));
      A := Hemisphere_AO (P, N, Scn, 4.0, 12);
      B := MonteCarlo_Hemisphere_AO (P, N, Scn, 4.0, 12);
      Check (abs (A.Factor - B.Factor) <= 1.0E-5,
             "MonteCarlo matches Hemisphere factor");
      Check (A.Sample_Hits = B.Sample_Hits, "Hit counts match");
      Check (B.Factor >= 0.0 and then B.Factor <= 1.0, "Factor in [0,1]");
   end;

   ---------------------------------------------------------------------
   Section ("7. Sky_Visibility_AO");
   ---------------------------------------------------------------------
   declare
      Open_Scn : constant Scene := Empty_Scene;
      Blocked  : Scene := Empty_Scene;
      Sky_Open, Sky_Block : AO_Factor;
      P : constant Point3 := (0.0, 0.0, 0.0);
      N : constant Normal3 := (0.0, 1.0, 0.0);
   begin
      Blocked := Add_Plane
        (Blocked, (Point => (0.0, 0.5, 0.0), Normal => (0.0, -1.0, 0.0)));
      Sky_Open  := Sky_Visibility_AO (P, N, Open_Scn, 10.0, 16);
      Sky_Block := Sky_Visibility_AO (P, N, Blocked, 10.0, 16);
      Check (Sky_Open > 0.95, "Open sky nearly fully visible");
      Check (Sky_Block < Sky_Open, "Ceiling plane reduces sky visibility");
      Check (Sky_Block >= 0.0, "Blocked sky still non-negative");
   end;

   ---------------------------------------------------------------------
   Section ("8. Accessibility_Shading");
   ---------------------------------------------------------------------
   declare
      Open_Scn : constant Scene := Empty_Scene;
      Tight    : Scene := Empty_Scene;
      A_Open, A_Tight : Accessibility_Result;
      P : constant Point3 := (0.0, 0.0, 0.0);
      N : constant Normal3 := (0.0, 1.0, 0.0);
   begin
      Tight := Add_Sphere (Tight, (Center => (0.0, 0.4, 0.0), Radius => 0.3));
      A_Open  := Accessibility_Shading (P, N, Open_Scn, 2.0, 12);
      A_Tight := Accessibility_Shading (P, N, Tight, 2.0, 12);
      Check (A_Open.Factor > 0.9, "Open accessibility high");
      Check (A_Tight.Factor < A_Open.Factor, "Nearby sphere lowers accessibility");
      Check (A_Tight.Reach_Radius < A_Open.Reach_Radius,
             "Reach radius smaller when occluded");
      Check (A_Open.Reach_Radius = 2.0, "Open reach equals probe radius");
   end;

   ---------------------------------------------------------------------
   Section ("9. Screen_Space_AO_Sample");
   ---------------------------------------------------------------------
   declare
      Depths  : Depth_Array := [others => 5.0];
      Offsets : Offset_Array := [others => (0.0, 0.0)];
      Flat, Occ : AO_Factor;
   begin
      --  Ring of offsets around center.
      Offsets (1) := (1.0, 0.0);
      Offsets (2) := (-1.0, 0.0);
      Offsets (3) := (0.0, 1.0);
      Offsets (4) := (0.0, -1.0);
      Depths (1) := 5.0;
      Depths (2) := 5.0;
      Depths (3) := 5.0;
      Depths (4) := 5.0;
      Flat := Screen_Space_AO_Sample
        (5.0, Depths, Offsets, 4, Radius_Px => 2.0);
      --  Closer depths => occluders.
      Depths (1) := 3.0;
      Depths (2) := 3.0;
      Depths (3) := 3.5;
      Depths (4) := 3.5;
      Occ := Screen_Space_AO_Sample
        (5.0, Depths, Offsets, 4, Radius_Px => 2.0, Intensity => 2.0);
      Check (Flat > 0.95, "Flat depth neighborhood => little SSAO");
      Check (Occ < Flat, "Closer neighbors increase occlusion");
      Check (Occ >= 0.0 and then Occ <= 1.0, "SSAO factor in [0,1]");
   end;

   ---------------------------------------------------------------------
   Section ("10. Horizon_Based_AO");
   ---------------------------------------------------------------------
   declare
      Flat_H, Wall_H : Height_Array := [others => 0.0];
      Flat_R, Wall_R : Horizon_AO_Result;
   begin
      --  Flat: heights stay ~0 along the walk.
      for I in Horizon_Step_Index loop
         Flat_H (I) := 0.0;
      end loop;
      --  Rising wall: heights climb with step index.
      for I in 1 .. 8 loop
         Wall_H (I) := Real (I) * 0.5;
      end loop;
      Flat_R := Horizon_Based_AO (Flat_H, 8, 4, Step_Length => 0.25);
      Wall_R := Horizon_Based_AO (Wall_H, 8, 4, Step_Length => 0.25);
      Check (Flat_R.Factor > 0.9, "Flat horizon => high AO factor");
      Check (Wall_R.Factor < Flat_R.Factor, "Rising wall darkens HBAO");
      Check (Wall_R.Mean_Horizon > Flat_R.Mean_Horizon,
             "Wall has higher mean horizon angle");
      Check (Wall_R.Direction_Count = 4, "Direction count recorded");
   end;

   ---------------------------------------------------------------------
   Section ("11. Ground_Truth_AO_Integral");
   ---------------------------------------------------------------------
   declare
      Open_A, Closed_A : Height_Array := [others => 0.0];
      G_Open, G_Closed : AO_Factor;
   begin
      for I in 1 .. 8 loop
         Open_A (I) := 0.05;       -- tiny horizon => mostly open
         Closed_A (I) := 1.2;      -- high horizon => occluded
      end loop;
      G_Open   := Ground_Truth_AO_Integral (Open_A, 8, 0.0);
      G_Closed := Ground_Truth_AO_Integral (Closed_A, 8, 0.0);
      Check (G_Open > G_Closed, "Low horizons => higher GTAO factor");
      Check (G_Open > 0.5, "Nearly open integral stays bright");
      Check (G_Closed < 0.8, "High horizons reduce integral");
      Check (G_Closed >= 0.0, "Closed integral non-negative");
   end;

   ---------------------------------------------------------------------
   Section ("12. Ray_Traced_AO");
   ---------------------------------------------------------------------
   declare
      Open_Scn : constant Scene := Empty_Scene;
      Occ_Scn  : Scene := Empty_Scene;
      Open_R, Occ_R : AO_Result;
      P : constant Point3 := (0.0, 0.0, 0.0);
      N : constant Normal3 := (0.0, 1.0, 0.0);
   begin
      Occ_Scn := Add_AABB
        (Occ_Scn,
         (Min_P => (-2.0, 0.2, -2.0), Max_P => (2.0, 1.0, 2.0)));
      Open_R := Ray_Traced_AO (P, N, Open_Scn, 5.0, 16);
      Occ_R  := Ray_Traced_AO (P, N, Occ_Scn, 5.0, 16);
      Check (Open_R.Factor > 0.95, "RTAO open scene fully unoccluded");
      Check (Occ_R.Factor < Open_R.Factor, "RTAO darkens under AABB lid");
      Check (Occ_R.Sample_Hits > 0, "RTAO records binary hits");
      Check (Length (Occ_R.Bent_Normal) > 0.5, "Bent normal present");
   end;

   ---------------------------------------------------------------------
   Section ("13. Tube_Occlusion_Demo");
   ---------------------------------------------------------------------
   declare
      Shallow : constant AO_Factor :=
        Tube_Occlusion_Demo (0.1, Tube_Radius => 1.0, Max_Depth => 10.0);
      Deep    : constant AO_Factor :=
        Tube_Occlusion_Demo (8.0, Tube_Radius => 1.0, Max_Depth => 10.0);
      Mid     : constant AO_Factor :=
        Tube_Occlusion_Demo (3.0, Tube_Radius => 1.0, Max_Depth => 10.0);
   begin
      Check (Shallow > Deep, "Deeper into tube is darker");
      Check (Shallow > Mid and then Mid > Deep, "Monotonic darkening with depth");
      Check (Deep < 0.5, "Deep tube factor is low");
      Check (Shallow > 0.5, "Shallow tube stays relatively bright");
   end;

   ---------------------------------------------------------------------
   Section ("14. Corner_Darkening");
   ---------------------------------------------------------------------
   declare
      Flat_Far : constant AO_Factor :=
        Corner_Darkening (3.0, 5.0, Influence_Radius => 1.0);
      Tight_Near : constant AO_Factor :=
        Corner_Darkening (0.3, 0.05, Influence_Radius => 1.0);
      Right_Mid : constant AO_Factor :=
        Corner_Darkening (1.570_796, 0.5, Influence_Radius => 1.0);
   begin
      Check (Flat_Far > Tight_Near, "Open far corner brighter than tight near");
      Check (Tight_Near < 0.5, "Tight near corner is dark");
      Check (Flat_Far > 0.5, "Nearly flat far corner stays bright");
      Check (Right_Mid > Tight_Near, "Right angle mid > acute near");
   end;

   ---------------------------------------------------------------------
   Section ("15. Degenerate_Geometry on Normalize");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Dummy : constant Direction3 := Normalize ((0.0, 0.0, 0.0));
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
      end;
      Check (Raised, "Normalize(0) raises Degenerate_Geometry");
      Check (Pass_Count > 0, "Passes accumulated before exception test");
      Check (Fail_Count = 0, "No failures before exception test");
   end;

   ---------------------------------------------------------------------
   Section ("16. Local_To_World preserves unit length");
   ---------------------------------------------------------------------
   declare
      N : constant Normal3 := Normalize ((0.0, 1.0, 0.0));
      T, B : Direction3;
      Loc  : constant Direction3 := Normalize ((0.5, 0.0, 0.866_025));
      W    : Direction3;
   begin
      Orthonormal_Basis (N, T, B);
      W := Local_To_World (Loc, N, T, B);
      Check (abs (Length (W) - 1.0) <= 1.0E-4, "World dir is unit");
      Check (Dot (W, N) > 0.0, "Mapped sample stays in hemisphere");
      Check (abs (Dot (T, B)) <= 1.0E-4, "T and B orthogonal");
   end;

   New_Line;
   Put_Line ("================================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   Put_Line ("================================");
   pragma Assert (Fail_Count = 0, "Some Ambient_Occlusion tests failed");
   Put_Line ("All tests passed.");
end Tests;
