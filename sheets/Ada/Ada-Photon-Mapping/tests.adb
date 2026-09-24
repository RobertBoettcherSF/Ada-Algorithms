with Ada.Text_IO; use Ada.Text_IO;
with Photon_Mapping; use Photon_Mapping;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   V1 : constant Vector_3D := (X => 1.0, Y => 0.0, Z => 0.0);
   V2 : constant Vector_3D := (X => 0.0, Y => 2.0, Z => 0.0);
   V3 : constant Vector_3D := (X => 3.0, Y => 4.0, Z => 0.0);

   P1 : constant Spectral_Power := (R => 10.0, G => 20.0, B => 30.0);
   P2 : constant Spectral_Power := (R => 5.0,  G => 5.0,  B => 5.0);
begin
   -- TEST 1 — Vector Mathematics
   Put_Line ("TEST 1 — Vector Operations");
   Check ("1.1 Dot product of orthogonal vectors is zero", Dot (V1, V2) = 0.0);
   Check ("1.2 Norm calculation computes Pythagorean distance", Norm (V3) = 5.0);
   Check ("1.3 Vector scaling multiplies magnitude linearly", Vector_Scale (V1, 3.0).X = 3.0);

   -- TEST 2 — Spectral Color Arithmetic
   Put_Line ("TEST 2 — Spectral Operations");
   declare
      Sum : constant Spectral_Power := Spectral_Add (P1, P2);
      Scaled : constant Spectral_Power := Spectral_Scale (P1, 0.5);
   begin
      Check ("2.1 Spectral addition sums R component", Sum.R = 15.0);
      Check ("2.2 Spectral addition sums G component", Sum.G = 25.0);
      Check ("2.3 Spectral scaling halves power values", Scaled.B = 15.0);
   end;

   -- TEST 3 — Ray-Sphere Intersection: Direct Hit
   Put_Line ("TEST 3 — Ray-Sphere Intersection Direct Hit");
   declare
      R   : constant Ray := (Origin => (0.0, 0.0, -5.0), Direction => (0.0, 0.0, 1.0));
      S   : constant Sphere := (Center => (0.0, 0.0, 0.0), Radius => 1.0,
                                Material => (0.8, 0.0, 0.2));
      Hit_Pt : Vector_3D;
      Norm_V : Vector_3D;
      Is_Hit : Boolean;
   begin
      Is_Hit := Intersect_Sphere (R, S, Hit_Pt, Norm_V);
      Check ("3.1 Direct ray hits sphere", Is_Hit);
      Check ("3.2 Hit point matches surface front", Hit_Pt.Z = -1.0);
      Check ("3.3 Normal vector faces backwards along ray axis", Norm_V.Z = -1.0);
   end;

   -- TEST 4 — Ray-Sphere Intersection: Complete Miss
   Put_Line ("TEST 4 — Ray-Sphere Intersection Miss");
   declare
      R   : constant Ray := (Origin => (0.0, 5.0, -5.0), Direction => (0.0, 0.0, 1.0));
      S   : constant Sphere := (Center => (0.0, 0.0, 0.0), Radius => 1.0,
                                Material => (1.0, 0.0, 0.0));
      Hit_Pt : Vector_3D;
      Norm_V : Vector_3D;
      Is_Hit : Boolean;
   begin
      Is_Hit := Intersect_Sphere (R, S, Hit_Pt, Norm_V);
      Check ("4.1 Offset ray misses sphere", not Is_Hit);
      Check ("4.2 Hit point remains at default origin", Hit_Pt.X = 0.0 and Hit_Pt.Y = 0.0);
      Check ("4.3 Normal remains zeroed on miss", Norm_V.Z = 0.0);
   end;

   -- TEST 5 — Russian Roulette Surface Interaction
   Put_Line ("TEST 5 — Russian Roulette Probabilities");
   declare
      Mat : constant Surface_Material := (Diffuse_Reflectance => 0.6,
                                          Specular_Reflectance => 0.3,
                                          Absorption => 0.1);
   begin
      Check ("5.1 Low roll triggers diffuse scatter",
             Russian_Roulette (Mat, 0.2) = Diffuse);
      Check ("5.2 Mid-range roll triggers specular bounce",
             Russian_Roulette (Mat, 0.7) = Specular);
      Check ("5.3 High roll triggers absorption",
             Russian_Roulette (Mat, 0.95) = Absorbed);
   end;

   -- TEST 6 — Single Photon Path Emission and Scattering
   Put_Line ("TEST 6 — Single Photon Tracing");
   declare
      R   : constant Ray := (Origin => (0.0, 0.0, -5.0), Direction => (0.0, 0.0, 1.0));
      S   : constant Sphere := (Center => (0.0, 0.0, 0.0), Radius => 2.0,
                                Material => (Diffuse_Reflectance => 1.0,
                                             Specular_Reflectance => 0.0,
                                             Absorption => 0.0));
      P   : constant Photon := Trace_Photon_Path (R, P1, S, 0.5);
   begin
      Check ("6.1 Traced photon deposits at hit position Z", P.Position.Z = -2.0);
      Check ("6.2 Traced photon retains incoming power spectrum", P.Power.R = 10.0);
      Check ("6.3 Incident vector direction preserved", P.Incident.Z = 1.0);
   end;

   -- TEST 7 — Kd-Tree Spatial Organization (Empty & Single)
   Put_Line ("TEST 7 — Kd-Tree Edge Cases");
   declare
      Empty_Tree  : Kd_Tree (Capacity => 10);
      Single_Tree : Kd_Tree (Capacity => 10);
   begin
      Build_Kd_Tree (Empty_Tree);
      Check ("7.1 Empty tree remains zero length", Empty_Tree.Length = 0);

      Single_Tree.Length := 1;
      Single_Tree.Photons (1) := (Position => (1.0, 2.0, 3.0),
                                  Power    => P1,
                                  Incident => (0.0, 0.0, -1.0),
                                  Plane    => 0);
      Build_Kd_Tree (Single_Tree);
      Check ("7.2 Single element length intact", Single_Tree.Length = 1);
      Check ("7.3 Single root splits on X-axis (plane 0)", Single_Tree.Photons (1).Plane = 0);
   end;

   -- TEST 8 — Kd-Tree Multi-element Construction
   Put_Line ("TEST 8 — Kd-Tree Multi-Photon Construction");
   declare
      Tree : Kd_Tree (Capacity => 5);
   begin
      Tree.Length := 3;
      Tree.Photons (1) := (Position => (5.0, 0.0, 0.0), Power => P1, Incident => V1, Plane => 0);
      Tree.Photons (2) := (Position => (1.0, 0.0, 0.0), Power => P1, Incident => V1, Plane => 0);
      Tree.Photons (3) := (Position => (3.0, 0.0, 0.0), Power => P1, Incident => V1, Plane => 0);

      Build_Kd_Tree (Tree);
      Check ("8.1 Multi-tree preserves length count", Tree.Length = 3);
      Check ("8.2 Median element placed at root index 2", Tree.Photons (2).Position.X = 3.0);
      Check ("8.3 Left split element ordered before median", Tree.Photons (1).Position.X <= 3.0);
   end;

   -- TEST 9 — Nearest Neighbor Spatial Range Query
   Put_Line ("TEST 9 — Nearest Neighbor Photon Search");
   declare
      Tree : Kd_Tree (Capacity => 4);
      Res  : Query_Result (Max_Results => 2);
   begin
      Tree.Length := 3;
      Tree.Photons (1) := (Position => (0.1, 0.0, 0.0), Power => P1, Incident => (0.0, 0.0, -1.0), Plane => 0);
      Tree.Photons (2) := (Position => (0.2, 0.0, 0.0), Power => P1, Incident => (0.0, 0.0, -1.0), Plane => 0);
      Tree.Photons (3) := (Position => (10.0, 0.0, 0.0), Power => P1, Incident => (0.0, 0.0, -1.0), Plane => 0);
      Build_Kd_Tree (Tree);

      Locate_Photons (Tree, (0.0, 0.0, 0.0), 2, 1.0, Res);
      Check ("9.1 Search locates exactly two close neighbors", Res.Count = 2);
      Check ("9.2 Far point outside radius excluded", Res.Max_Distance_Sq < 1.0);
      Check ("9.3 Closest photon included in query result", Res.Photons (1).Position.X = 0.1 or Res.Photons (2).Position.X = 0.1);
   end;

   -- TEST 10 — Surface Radiance Estimation with Constant Filter
   Put_Line ("TEST 10 — Surface Radiance Estimation (Constant Filter)");
   declare
      Tree : Kd_Tree (Capacity => 4);
      Rad  : Spectral_Power;
   begin
      Tree.Length := 1;
      Tree.Photons (1) := (Position => (0.5, 0.0, 0.0),
                           Power    => (R => 10.0, G => 10.0, B => 10.0),
                           Incident => (0.0, 0.0, -1.0),
                           Plane    => 0);
      Build_Kd_Tree (Tree);

      Rad := Estimate_Radiance_Surface
        (Tree        => Tree,
         Point       => (0.0, 0.0, 0.0),
         Normal      => (0.0, 0.0, 1.0),
         Max_Photons => 1,
         Max_Dist_Sq => 1.0,
         Filter      => Constant_Filter);

      Check ("10.1 Surface radiance R is positive", Rad.R > 0.0);
      Check ("10.2 Constant filter computes uniform color channels", Rad.R = Rad.G);
      Check ("10.3 Radiance falls within physically expected limits", Rad.B < 100.0);
   end;

   -- TEST 11 — Filter Comparison: Linear and Gaussian Attenuation
   Put_Line ("TEST 11 — Linear and Gaussian Filtering Comparison");
   declare
      Tree     : Kd_Tree (Capacity => 4);
      Rad_Lin  : Spectral_Power;
      Rad_Gauss: Spectral_Power;
   begin
      Tree.Length := 1;
      Tree.Photons (1) := (Position => (0.5, 0.0, 0.0),
                           Power    => (R => 10.0, G => 10.0, B => 10.0),
                           Incident => (0.0, 0.0, -1.0),
                           Plane    => 0);
      Build_Kd_Tree (Tree);

      Rad_Lin := Estimate_Radiance_Surface
        (Tree, (0.0, 0.0, 0.0), (0.0, 0.0, 1.0), 1, 2.0, Linear_Filter);
      Rad_Gauss := Estimate_Radiance_Surface
        (Tree, (0.0, 0.0, 0.0), (0.0, 0.0, 1.0), 1, 2.0, Gaussian_Filter);

      Check ("11.1 Linear filter computes positive radiance", Rad_Lin.R > 0.0);
      Check ("11.2 Gaussian filter produces positive radiance", Rad_Gauss.R > 0.0);
      Check ("11.3 Differing filter weighting produces distinct values", Rad_Lin.R /= Rad_Gauss.R);
   end;

   -- TEST 12 — Volumetric Photon Radiance Estimation
   Put_Line ("TEST 12 — Volume Radiance Estimation");
   declare
      Tree   : Kd_Tree (Capacity => 4);
      Medium : constant Medium_Properties := (Scattering_Coeff => 0.5, Absorption_Coeff => 0.1);
      Rad    : Spectral_Power;
   begin
      Tree.Length := 1;
      Tree.Photons (1) := (Position => (0.1, 0.1, 0.1),
                           Power    => (R => 4.0, G => 4.0, B => 4.0),
                           Incident => (0.0, 1.0, 0.0),
                           Plane    => 0);
      Build_Kd_Tree (Tree);

      Rad := Estimate_Radiance_Volume (Tree, (0.0, 0.0, 0.0), Medium, 1, 1.0);
      Check ("12.1 Volumetric radiance produces non-zero red channel", Rad.R > 0.0);
      Check ("12.2 Volumetric radiance scales isotropically", Rad.R = Rad.G and Rad.G = Rad.B);

      declare
         Zero_Medium : constant Medium_Properties := (Scattering_Coeff => 0.0, Absorption_Coeff => 0.2);
         Zero_Rad    : constant Spectral_Power :=
           Estimate_Radiance_Volume (Tree, (0.0, 0.0, 0.0), Zero_Medium, 1, 1.0);
      begin
         Check ("12.3 Zero scattering coefficient yields zero volume radiance", Zero_Rad.R = 0.0);
      end;
   end;

   -- TEST 13 — Two-Pass Global Illumination Synthesis
   Put_Line ("TEST 13 — Full Two-Pass Synthesis");
   declare
      Direct_Light : constant Spectral_Power := (R => 1.0, G => 1.0, B => 1.0);
      Specular     : constant Spectral_Power := (R => 0.5, G => 0.5, B => 0.5);
      Caustic      : constant Spectral_Power := (R => 2.0, G => 1.0, B => 0.0);
      Global_Ind   : constant Spectral_Power := (R => 0.2, G => 0.3, B => 0.4);
      Combined     : Spectral_Power;
   begin
      Combined := Combine_Two_Pass (Direct_Light, Specular, Caustic, Global_Ind);
      Check ("13.1 Two-pass synthesis totals R channel", Combined.R = 3.7);
      Check ("13.2 Two-pass synthesis totals G channel", Combined.G = 2.8);
      Check ("13.3 Two-pass synthesis totals B channel", Combined.B = 1.9);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
