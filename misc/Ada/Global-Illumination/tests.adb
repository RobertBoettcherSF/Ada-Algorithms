--  Standalone test suite for Global_Illumination (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Global_Illumination; use Global_Illumination;

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
   Put_Line ("Global_Illumination test suite");
   Put_Line ("==============================");

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
   Section ("2. Color helpers / Clamp / Distance");
   ---------------------------------------------------------------------
   declare
      C1 : constant Color_RGB := Color_Add ((1.0, 0.0, 0.0), (0.0, 1.0, 0.5));
      C2 : constant Color_RGB := Color_Scale (2.0, (0.5, 0.25, 0.1));
      C3 : constant Color_RGB := Color_Mul ((0.5, 1.0, 0.0), (2.0, 0.5, 3.0));
      Lu : constant Non_Negative := Luminance ((1.0, 1.0, 1.0));
      Dist : constant Non_Negative :=
        Distance_Between ((0.0, 0.0, 0.0), (0.0, 0.0, 3.0));
   begin
      Check (abs (C1.R - 1.0) <= 1.0E-5 and then abs (C1.G - 1.0) <= 1.0E-5,
             "Color_Add channels");
      Check (abs (C2.R - 1.0) <= 1.0E-5, "Color_Scale doubles R");
      Check (abs (C3.R - 1.0) <= 1.0E-5 and then abs (C3.G - 0.5) <= 1.0E-5,
             "Color_Mul channels");
      Check (abs (Real (Lu) - 1.0) <= 1.0E-3, "White luminance ~ 1");
      Check (abs (Dist - 3.0) <= 1.0E-4, "Distance_Between along Z");
      Check (Clamp_Unit (1.5) = 1.0, "Clamp_Unit saturates at 1");
   end;

   ---------------------------------------------------------------------
   Section ("3. Patch / occluder builders & Segment_Occluded");
   ---------------------------------------------------------------------
   declare
      PS : Patch_Set := Empty_Patch_Set;
      OS : Occluder_Set := Empty_Occluders;
      P  : constant Patch :=
        (Center => (0.0, 0.0, 0.0),
         Normal => Up,
         Area   => 1.0,
         Reflectance => (0.8, 0.8, 0.8),
         Emission => (0.0, 0.0, 0.0),
         Radiosity => (0.0, 0.0, 0.0));
      Hit, Miss : Boolean;
   begin
      PS := Add_Patch (PS, P);
      OS := Add_Occluder (OS, (Center => (0.0, 0.5, 0.0), Radius => 0.3));
      Hit := Segment_Occluded
        ((0.0, 0.0, 0.0), (0.0, 2.0, 0.0), OS);
      Miss := Segment_Occluded
        ((2.0, 0.0, 0.0), (3.0, 0.0, 0.0), OS);
      Check (PS.Count = 1, "One patch in set");
      Check (OS.Count = 1, "One occluder in set");
      Check (Hit, "Segment through sphere is occluded");
      Check (not Miss, "Far segment misses occluder");
   end;

   ---------------------------------------------------------------------
   Section ("4. Direct_Illumination (point light, front vs back)");
   ---------------------------------------------------------------------
   declare
      Lgt : constant Light :=
        (Kind => Point_Light,
         Position => (0.0, 5.0, 0.0),
         Direction => (0.0, -1.0, 0.0),
         Intensity => (10.0, 10.0, 10.0));
      Front : constant Direct_Result := Direct_Illumination
        (P => Origin, N => Up, Albedo => (0.8, 0.8, 0.8), Lgt => Lgt);
      Back  : constant Direct_Result := Direct_Illumination
        (P => Origin, N => (0.0, -1.0, 0.0), Albedo => (0.8, 0.8, 0.8),
         Lgt => Lgt);
   begin
      Check (Luminance (Front.Radiance_Out) > 0.0, "Front-facing gets light");
      Check (Front.Cos_Term > 0.9, "Overhead point light cos ~ 1");
      Check (Luminance (Back.Radiance_Out) = 0.0, "Back-facing is dark");
      Check (not Front.Shadowed, "No shadows requested => not shadowed");
   end;

   ---------------------------------------------------------------------
   Section ("5. Direct_Illumination hard shadow via occluder");
   ---------------------------------------------------------------------
   declare
      Lgt : constant Light :=
        (Kind => Point_Light,
         Position => (0.0, 5.0, 0.0),
         Direction => (0.0, -1.0, 0.0),
         Intensity => (20.0, 20.0, 20.0));
      Occ : Occluder_Set := Empty_Occluders;
      Lit, Shaded : Direct_Result;
   begin
      Occ := Add_Occluder (Occ, (Center => (0.0, 2.0, 0.0), Radius => 0.5));
      Lit := Direct_Illumination
        (Origin, Up, (1.0, 1.0, 1.0), Lgt, Empty_Occluders, Use_Shadows => True);
      Shaded := Direct_Illumination
        (Origin, Up, (1.0, 1.0, 1.0), Lgt, Occ, Use_Shadows => True);
      Check (Luminance (Lit.Radiance_Out) > 0.0, "Unoccluded direct > 0");
      Check (Shaded.Shadowed, "Occluder marks Shadowed");
      Check (Luminance (Shaded.Radiance_Out) = 0.0, "Shadowed radiance is 0");
   end;

   ---------------------------------------------------------------------
   Section ("6. Direct_Illumination directional light");
   ---------------------------------------------------------------------
   declare
      Lgt : constant Light :=
        (Kind => Directional_Light,
         Position => Origin,
         Direction => (0.0, -1.0, 0.0),  -- light from +Y toward -Y
         Intensity => (3.14, 3.14, 3.14));
      R : constant Direct_Result := Direct_Illumination
        (Origin, Up, (1.0, 1.0, 1.0), Lgt);
   begin
      Check (R.Cos_Term > 0.99, "Directional overhead cos ~ 1");
      Check (Luminance (R.Radiance_Out) > 0.5, "Directional Lambertian > 0.5");
      Check (not R.Shadowed, "Directional without occluder not shadowed");
   end;

   ---------------------------------------------------------------------
   Section ("7. Radiosity_Form_Factor facing vs parallel");
   ---------------------------------------------------------------------
   declare
      Floor_P : constant Patch :=
        (Center => (0.0, 0.0, 0.0), Normal => Up, Area => 1.0,
         Reflectance => (0.5, 0.5, 0.5), Emission => (0.0, 0.0, 0.0),
         Radiosity => (0.0, 0.0, 0.0));
      Ceiling : constant Patch :=
        (Center => (0.0, 2.0, 0.0), Normal => (0.0, -1.0, 0.0), Area => 1.0,
         Reflectance => (0.5, 0.5, 0.5), Emission => (0.0, 0.0, 0.0),
         Radiosity => (0.0, 0.0, 0.0));
      Side : constant Patch :=
        (Center => (2.0, 1.0, 0.0), Normal => (1.0, 0.0, 0.0), Area => 1.0,
         Reflectance => (0.5, 0.5, 0.5), Emission => (0.0, 0.0, 0.0),
         Radiosity => (0.0, 0.0, 0.0));
      FF_Good : constant Unit_Interval :=
        Radiosity_Form_Factor (Floor_P, Ceiling);
      FF_Bad  : constant Unit_Interval :=
        Radiosity_Form_Factor (Floor_P, Side);
      FF_Self : constant Unit_Interval :=
        Radiosity_Form_Factor (Floor_P, Floor_P);
   begin
      Check (FF_Good > 0.0, "Facing patches have positive form factor");
      Check (FF_Good <= 1.0, "Form factor <= 1");
      Check (FF_Bad = 0.0 or else FF_Bad < FF_Good,
             "Side / glancing FF smaller or zero");
      Check (FF_Self = 0.0, "Self form factor is 0");
   end;

   ---------------------------------------------------------------------
   Section ("8. Indirect_Bounce / One_Bounce_GI color bleeding");
   ---------------------------------------------------------------------
   declare
      Floor_P : constant Patch :=
        (Center => (0.0, 0.0, 0.0), Normal => Up, Area => 1.0,
         Reflectance => (0.9, 0.9, 0.9), Emission => (0.0, 0.0, 0.0),
         Radiosity => (0.0, 0.0, 0.0));
      Red_Wall : constant Patch :=
        (Center => (0.0, 1.0, -1.0), Normal => (0.0, 0.0, 1.0), Area => 2.0,
         Reflectance => (0.8, 0.1, 0.1), Emission => (0.0, 0.0, 0.0),
         Radiosity => (4.0, 0.2, 0.2));
      Br : constant Bounce_Result := Indirect_Bounce (Floor_P, Red_Wall);
      Set : Patch_Set := Empty_Patch_Set;
      Ob  : Bounce_Result;
   begin
      Set := Add_Patch (Set, Red_Wall);
      Ob := One_Bounce_GI (Floor_P, Set);
      Check (Br.Visible, "Red wall visible to floor");
      Check (Br.Form_Factor > 0.0, "Positive bounce form factor");
      Check (Br.Indirect.R > Br.Indirect.G, "Red bleed dominates G");
      Check (Br.Indirect.R > Br.Indirect.B, "Red bleed dominates B");
      Check (Luminance (Ob.Indirect) > 0.0, "One_Bounce_GI accumulates");
   end;

   ---------------------------------------------------------------------
   Section ("9. Radiosity_Gather Jacobi step");
   ---------------------------------------------------------------------
   declare
      Recv : constant Patch :=
        (Center => (0.0, 0.0, 0.0), Normal => Up, Area => 1.0,
         Reflectance => (0.5, 0.5, 0.5), Emission => (0.1, 0.1, 0.1),
         Radiosity => (0.0, 0.0, 0.0));
      Emit : constant Patch :=
        (Center => (0.0, 1.5, 0.0), Normal => (0.0, -1.0, 0.0), Area => 1.0,
         Reflectance => (0.0, 0.0, 0.0), Emission => (2.0, 2.0, 2.0),
         Radiosity => (2.0, 2.0, 2.0));
      Neigh : Patch_Set := Empty_Patch_Set;
      G : Gather_Result;
   begin
      Neigh := Add_Patch (Neigh, Emit);
      G := Radiosity_Gather (Recv, Neigh);
      Check (G.Neighbor_N = 1, "Gathered from one neighbor");
      Check (Luminance (G.Incoming_Sum) > 0.0, "Incoming radiosity > 0");
      Check (Luminance (G.Radiosity) > Luminance (Recv.Emission),
             "Gathered B exceeds emission alone");
      Check (G.Radiosity.R >= Recv.Emission.R, "R channel at least Le");
   end;

   ---------------------------------------------------------------------
   Section ("10. Path_Throughput_Bounce");
   ---------------------------------------------------------------------
   declare
      Dirs  : constant Bounce_Dirs := [others => (0.0, 1.0, 0.0)];
      BRDFs : Bounce_BRDFs := [others => 0.0];
      Cos   : Bounce_Cos := [others => 0.0];
      PDFs  : Bounce_PDFs := [others => 1.0];
      T1, T0 : Throughput_Result;
      Inv_Pi : constant Real := 1.0 / 3.141_59;
   begin
      BRDFs (1) := Non_Negative (Inv_Pi);
      BRDFs (2) := Non_Negative (Inv_Pi);
      Cos (1) := 1.0;
      Cos (2) := 0.5;
      PDFs (1) := Positive_Real (Inv_Pi);  -- cosine-weighted pdf ≈ cos/π at cos=1
      PDFs (2) := Positive_Real (0.5 * Inv_Pi);
      T1 := Path_Throughput_Bounce
        ((1.0, 1.0, 1.0), Dirs, BRDFs, Cos, PDFs, Count => 2);
      --  Zero cosine kills path.
      Cos (1) := 0.0;
      T0 := Path_Throughput_Bounce
        ((1.0, 1.0, 1.0), Dirs, BRDFs, Cos, PDFs, Count => 1);
      Check (T1.Survived, "Nonzero path survives");
      Check (T1.Path_Length = 2, "Two bounces recorded");
      Check (abs (Real (T1.Throughput.R) - 1.0) <= 0.05,
             "Perfect cos-weighted throughput ~ 1");
      Check (not T0.Survived, "Zero cosine terminates path");
      Check (Luminance (T0.Throughput) = 0.0, "Dead path throughput is 0");
   end;

   ---------------------------------------------------------------------
   Section ("11. Color_Bleeding");
   ---------------------------------------------------------------------
   declare
      Recv : constant Patch :=
        (Center => (0.0, 0.0, 0.0), Normal => Up, Area => 1.0,
         Reflectance => (1.0, 1.0, 1.0), Emission => (0.0, 0.0, 0.0),
         Radiosity => (0.0, 0.0, 0.0));
      Green_E : constant Patch :=
        (Center => (0.0, 1.0, 0.0), Normal => (0.0, -1.0, 0.0), Area => 2.0,
         Reflectance => (0.1, 0.8, 0.1), Emission => (0.0, 0.0, 0.0),
         Radiosity => (0.2, 5.0, 0.2));
      Bleed : constant Color_RGB := Color_Bleeding (Recv, Green_E, 1.0);
      Half  : constant Color_RGB := Color_Bleeding (Recv, Green_E, 0.5);
   begin
      Check (Bleed.G > Bleed.R, "Green bleed dominates R");
      Check (Bleed.G > Bleed.B, "Green bleed dominates B");
      Check (abs (Real (Half.G) - Real (Bleed.G) * 0.5) <= 1.0E-4,
             "Strength 0.5 halves bleed");
   end;

   ---------------------------------------------------------------------
   Section ("12. Caustic_Proxy density estimate");
   ---------------------------------------------------------------------
   declare
      Hits : Direction_Array := [others => (0.0, 0.0, 0.0)];
      Pow  : Radiance_Array := [others => (0.0, 0.0, 0.0)];
      C_Near, C_Far : Caustic_Result;
   begin
      Hits (1) := (0.1, 0.0, 0.0);
      Hits (2) := (0.2, 0.0, 0.0);
      Hits (3) := (5.0, 0.0, 0.0);  -- outside kernel
      Pow (1) := (1.0, 1.0, 0.0);
      Pow (2) := (1.0, 1.0, 0.0);
      Pow (3) := (10.0, 10.0, 0.0);
      C_Near := Caustic_Proxy
        (Origin, Hits, Pow, Count => 3, Kernel_Radius => 1.0);
      C_Far := Caustic_Proxy
        (Origin, Hits, Pow, Count => 3, Kernel_Radius => 0.05);
      Check (C_Near.Photon_Count = 2, "Two photons inside r=1");
      Check (Luminance (C_Near.Density_Est) > 0.0, "Near density > 0");
      Check (C_Far.Photon_Count = 0, "Tiny kernel catches none");
      Check (Luminance (C_Far.Density_Est) = 0.0, "Empty kernel density 0");
   end;

   ---------------------------------------------------------------------
   Section ("13. Rendering_Equation_Sample");
   ---------------------------------------------------------------------
   declare
      Dirs : Direction_Array := [others => (0.0, 1.0, 0.0)];
      Li   : Radiance_Array := [others => (0.0, 0.0, 0.0)];
      BRDF : BRDF_Array := [others => 0.0];
      PDFs : PDF_Array := [others => 1.0];
      Inv_Pi : constant Real := 1.0 / 3.141_59;
      RE : RE_Sample_Result;
      Le : constant Color_RGB := (0.1, 0.1, 0.1);
   begin
      Dirs (1) := (0.0, 1.0, 0.0);
      Dirs (2) := (0.0, -1.0, 0.0);  -- below hemisphere — ignored
      Li (1) := (1.0, 1.0, 1.0);
      Li (2) := (5.0, 5.0, 5.0);
      BRDF (1) := Non_Negative (Inv_Pi);
      BRDF (2) := Non_Negative (Inv_Pi);
      PDFs (1) := Positive_Real (Inv_Pi);
      PDFs (2) := Positive_Real (Inv_Pi);
      RE := Rendering_Equation_Sample
        (Le, Up, Dirs, Li, BRDF, PDFs, Count => 2);
      Check (RE.Used = 1, "Only upper-hemisphere sample used");
      Check (RE.Lo.R > Le.R, "Lo exceeds emission");
      Check (abs (Real (RE.Sample_Sum.R) - 1.0) <= 0.05,
             "Single sample sum ~ Li for matching pdf");
      Check (Luminance (RE.Lo) > 0.0, "Outgoing radiance positive");
   end;

   ---------------------------------------------------------------------
   Section ("14. Ambient_Term_Vs_GI contrast");
   ---------------------------------------------------------------------
   declare
      Direct : constant Color_RGB := (0.5, 0.5, 0.5);
      Amb    : constant Color_RGB := (0.1, 0.1, 0.1);
      Ind    : constant Color_RGB := (0.4, 0.05, 0.05);  -- red bleed
      Albedo : constant Color_RGB := (0.8, 0.8, 0.8);
      Cmp : constant Ambient_Vs_GI_Result :=
        Ambient_Term_Vs_GI (Albedo, Amb, Direct, Ind);
   begin
      Check (Luminance (Cmp.Ambient_Only) > Luminance (Direct),
             "Ambient lifts direct");
      Check (Cmp.With_GI.R > Cmp.With_GI.G, "GI path shows red bleed");
      Check (Cmp.Delta_Luma >= 0.0, "Delta luma non-negative");
      Check (abs (Real (Cmp.Indirect.R) - 0.4) <= 1.0E-5,
             "Indirect preserved");
   end;

   ---------------------------------------------------------------------
   Section ("15. Degenerate_Geometry on Normalize");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Dummy : Direction3;
         begin
            Dummy := Normalize ((0.0, 0.0, 0.0));
            pragma Unreferenced (Dummy);
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
      end;
      Check (Raised, "Normalize zero raises Degenerate_Geometry");
      Check (Clamp (5.0, 0.0, 1.0) = 1.0, "Clamp upper still works");
      Check (Empty_Patch_Set.Count = 0, "Empty patch set count 0");
   end;

   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   pragma Assert (Fail_Count = 0);
   Put_Line ("All tests passed.");
end Tests;
