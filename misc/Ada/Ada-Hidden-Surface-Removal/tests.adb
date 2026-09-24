with Ada.Text_IO; use Ada.Text_IO;
with Hidden_Surface_Determination; use Hidden_Surface_Determination;

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

   -- Helper to compare colors
   function Equal_Color (C1, C2 : Color_Type) return Boolean is
   begin
      return C1.R = C2.R and then C1.G = C2.G and then C1.B = C2.B;
   end Equal_Color;

   -- Common palette
   Color_Red   : constant Color_Type := (R => 255, G => 0,   B => 0);
   Color_Green : constant Color_Type := (R => 0,   G => 255, B => 0);
   Color_Blue  : constant Color_Type := (R => 0,   G => 0,   B => 255);

   -- Test triangles
   T_Front : constant Triangle :=
     (Id    => 1,
      V0    => (X => 0.0, Y => 0.0, Z => 0.2),
      V1    => (X => 10.0, Y => 0.0, Z => 0.2),
      V2    => (X => 0.0, Y => 10.0, Z => 0.2),
      Color => Color_Red);

   T_Back : constant Triangle :=
     (Id    => 2,
      V0    => (X => 0.0, Y => 0.0, Z => 0.8),
      V1    => (X => 10.0, Y => 0.0, Z => 0.8),
      V2    => (X => 0.0, Y => 10.0, Z => 0.8),
      Color => Color_Blue);

   T_Clockwise : constant Triangle :=
     (Id    => 3,
      V0    => (X => 0.0, Y => 0.0, Z => 0.5),
      V1    => (X => 0.0, Y => 10.0, Z => 0.5),
      V2    => (X => 10.0, Y => 0.0, Z => 0.5),
      Color => Color_Green);

   FB : Framebuffer (0 .. 15, 0 .. 15);
   ZB : Depth_Buffer (0 .. 15, 0 .. 15);

begin
   -- TEST 1: Vector Math and Normal Computation
   Put_Line ("TEST 1 — Vector Operations and Triangle Normal");
   declare
      V1 : constant Vector_3D := (X => 1.0, Y => 0.0, Z => 0.0);
      V2 : constant Vector_3D := (X => 0.0, Y => 1.0, Z => 0.0);
      Cross : constant Vector_3D := Cross_Product (V1, V2);
      Dot   : constant Coordinate := Dot_Product (V1, V2);
      Norm  : constant Vector_3D := Compute_Normal (T_Front);
   begin
      Check ("1.1 Cross product yields perpendicular Z axis", Cross.Z = 1.0 and Cross.X = 0.0 and Cross.Y = 0.0);
      Check ("1.2 Dot product of orthogonal vectors is zero", abs (Float (Dot)) < 0.0001);
      Check ("1.3 Counter-clockwise normal points towards viewer +Z", Norm.Z > 0.99);
   end;

   -- TEST 2: Vector Normalization and Zero-Vector Exception Handling
   Put_Line ("TEST 2 — Normalization and Error Handling");
   declare
      V : constant Vector_3D := (X => 3.0, Y => 4.0, Z => 0.0);
      Norm : constant Vector_3D := Normalize (V);
      Raised : Boolean := False;
   begin
      Check ("2.1 Vector magnitude calculation is accurate", abs (Float (Vector_Magnitude (V)) - 5.0) < 0.0001);
      Check ("2.2 Normalized vector has unit length", abs (Float (Vector_Magnitude (Norm)) - 1.0) < 0.0001);
      begin
         declare
            Zero_V : constant Vector_3D := (X => 0.0, Y => 0.0, Z => 0.0);
            Dummy  : Vector_3D;
         begin
            Dummy := Normalize (Zero_V);
            if Dummy.X = 0.0 then null; end if;
         end;
      exception
         when Zero_Vector_Error =>
            Raised := True;
      end;
      Check ("2.3 Zero vector raises Zero_Vector_Error", Raised);
   end;

   -- TEST 3: Degenerate Triangle Handling
   Put_Line ("TEST 3 — Degenerate Triangle Error Detection");
   declare
      T_Degen : constant Triangle :=
        (Id    => 99,
         V0    => (X => 0.0, Y => 0.0, Z => 0.5),
         V1    => (X => 1.0, Y => 1.0, Z => 0.5),
         V2    => (X => 2.0, Y => 2.0, Z => 0.5),
         Color => Color_White);
      Raised : Boolean := False;
   begin
      begin
         declare
            N : Vector_3D;
         begin
            N := Compute_Normal (T_Degen);
            if N.X = 0.0 then null; end if;
         end;
      exception
         when Invalid_Triangle_Error =>
            Raised := True;
      end;
      Check ("3.1 Collinear points raise Invalid_Triangle_Error", Raised);
      Check ("3.2 Triangle ID preserved", T_Degen.Id = 99);
      Check ("3.3 Color preserved", Equal_Color (T_Degen.Color, Color_White));
   end;

   -- TEST 4: Back-Face Culling Detection
   Put_Line ("TEST 4 — Back-Face Culling Point Logic");
   declare
      View_Dir : constant Vector_3D := (X => 0.0, Y => 0.0, Z => -1.0);
      Is_Front_Culled : constant Boolean := Is_Back_Face (T_Front, View_Dir);
      Is_Back_Culled  : constant Boolean := Is_Back_Face (T_Clockwise, View_Dir);
   begin
      Check ("4.1 Front-facing counter-clockwise triangle not culled", not Is_Front_Culled);
      Check ("4.2 Clockwise winding triangle recognized as back-face", Is_Back_Culled);
      Check ("4.3 Culling responds correctly to reversed viewpoint", Is_Back_Face (T_Front, (0.0, 0.0, 1.0)));
   end;

   -- TEST 5: Back-Face Array Culling
   Put_Line ("TEST 5 — Bulk Back-Face Culling Pipeline");
   declare
      Tri_List : constant Triangle_Array (1 .. 3) := [T_Front, T_Clockwise, T_Back];
      Culled   : Triangle_Array (1 .. 3);
      Count    : Natural;
   begin
      Cull_Back_Faces (Tri_List, (0.0, 0.0, -1.0), Culled, Count);
      Check ("5.1 Correct number of surviving front-facing triangles", Count = 2);
      Check ("5.2 First surviving is T_Front", Culled (1).Id = 1);
      Check ("5.3 Second surviving is T_Back", Culled (2).Id = 2);
   end;

   -- TEST 6: Empty Input Array Culling
   Put_Line ("TEST 6 — Edge Case: Empty Input Arrays");
   declare
      Empty_In  : Triangle_Array (1 .. 0);
      Empty_Out : Triangle_Array (1 .. 0);
      Count     : Natural;
   begin
      Cull_Back_Faces (Empty_In, (0.0, 0.0, -1.0), Empty_Out, Count);
      Check ("6.1 Empty input returns zero output count", Count = 0);
      Check ("6.2 Output length stays 0", Empty_Out'Length = 0);
      Sort_Polygons_By_Depth (Empty_In, Ascending => True);
      Check ("6.3 Sort on empty array executes cleanly", True);
   end;

   -- TEST 7: Painter's Depth Sorting
   Put_Line ("TEST 7 — Painter's Depth Sorting");
   declare
      Tri_List : Triangle_Array (1 .. 2) := [T_Front, T_Back]; -- Z: 0.2, 0.8
   begin
      Sort_Polygons_By_Depth (Tri_List, Ascending => False);
      Check ("7.1 Furthest item sorted first for painter order", Tri_List (1).Id = 2);
      Check ("7.2 Nearest item sorted last", Tri_List (2).Id = 1);
      Sort_Polygons_By_Depth (Tri_List, Ascending => True);
      Check ("7.3 Ascending order places nearest first", Tri_List (1).Id = 1 and Tri_List (2).Id = 2);
   end;

   -- TEST 8: Buffer Clear Operations
   Put_Line ("TEST 8 — Buffer Clear and Initialization");
   begin
      Clear_Buffers (FB, ZB, Color_Black);
      Check ("8.1 Color buffer cleared to black", Equal_Color (FB (0, 0), Color_Black));
      Check ("8.2 Depth buffer cleared to 1.0 (far plane)", ZB (0, 0) = Depth_Value'Last);
      Check ("8.3 Boundary pixel initialized", Equal_Color (FB (15, 15), Color_Black) and ZB (15, 15) = 1.0);
   end;

   -- TEST 9: Painter's Algorithm Surface Overwrite
   Put_Line ("TEST 9 — Painter's Algorithm Raster Output");
   begin
      Clear_Buffers (FB, ZB, Color_Black);
      -- Feed Far first, then Near - Painter's sorts and draws Far then Near
      declare
         List : constant Triangle_Array (1 .. 2) := [T_Back, T_Front];
      begin
         Render_Painters (List, FB);
         Check ("9.1 Overlapping pixel at (1,1) shows foreground color (Red)", Equal_Color (FB (1, 1), Color_Red));
         Check ("9.2 Uncovered background corner (14,14) remains clear", Equal_Color (FB (14, 14), Color_Black));
         Check ("9.3 Near triangle vertex origin rendered", Equal_Color (FB (0, 0), Color_Red));
      end;
   end;

   -- TEST 10: Z-Buffer Hidden Surface Determination (Order Independence)
   Put_Line ("TEST 10 — Z-Buffer Depth Buffering Correctness");
   begin
      Clear_Buffers (FB, ZB, Color_Black);
      -- Submit in wrong order: foreground first, background second
      declare
         List : constant Triangle_Array (1 .. 2) := [T_Front, T_Back];
      begin
         Render_Z_Buffer (List, FB, ZB);
         Check ("10.1 Front triangle dominates pixel despite order", Equal_Color (FB (2, 2), Color_Red));
         Check ("10.2 Depth buffer contains closest Z value", abs (Float (ZB (2, 2)) - 0.2) < 0.01);
         Check ("10.3 Background pixel depth not leaked outside triangle", ZB (15, 15) = 1.0);
      end;
   end;

   -- TEST 11: Ray-Casting Hidden Surface Determination
   Put_Line ("TEST 11 — Ray-Casting Determination");
   begin
      Clear_Buffers (FB, ZB, Color_Black);
      declare
         List : constant Triangle_Array (1 .. 2) := [T_Back, T_Front];
         Eye  : constant Point_3D := (X => 2.0, Y => 2.0, Z => 0.0);
      begin
         Render_Ray_Casting (List, FB, Eye);
         Check ("11.1 Pixel directly in line of sight (2,2) resolves to Red", Equal_Color (FB (2, 2), Color_Red));
         Check ("11.2 Pixel (1,1) resolves to front triangle", Equal_Color (FB (1, 1), Color_Red));
         Check ("11.3 Outside ray misses geometry and stays black", Equal_Color (FB (15, 15), Color_Black));
      end;
   end;

   -- TEST 12: Scanline Z-Buffer Determination
   Put_Line ("TEST 12 — Scanline Z-Buffer Algorithm");
   begin
      Clear_Buffers (FB, ZB, Color_Black);
      declare
         List : constant Triangle_Array (1 .. 2) := [T_Back, T_Front];
      begin
         Render_Scanline_Z_Buffer (List, FB, ZB);
         Check ("12.1 Scanline correctly resolves front surface at (3,3)", Equal_Color (FB (3, 3), Color_Red));
         Check ("12.2 Scanline Z-Buffer depth matches foreground depth", abs (Float (ZB (3, 3)) - 0.2) < 0.01);
         Check ("12.3 Line outside triangle bounds stays unaffected", Equal_Color (FB (12, 12), Color_Black));
      end;
   end;

   -- TEST 13: Ray-Triangle Möller–Trumbore Intersection Precision
   Put_Line ("TEST 13 — Analytical Ray Intersection Accuracy");
   declare
      R_Hit  : constant Ray :=
        (Origin    => (X => 2.0, Y => 2.0, Z => 0.0),
         Direction => (X => 0.0, Y => 0.0, Z => 1.0));
      R_Miss : constant Ray :=
        (Origin    => (X => 20.0, Y => 20.0, Z => 0.0),
         Direction => (X => 0.0, Y => 0.0, Z => 1.0));
      Res_Hit  : constant Intersection_Result := Intersect_Ray_Triangle (R_Hit, T_Front);
      Res_Miss : constant Intersection_Result := Intersect_Ray_Triangle (R_Miss, T_Front);
   begin
      Check ("13.1 Ray hitting triangle returns Hit = True", Res_Hit.Hit);
      Check ("13.2 Hit depth matches triangle plane distance", abs (Float (Res_Hit.Depth) - 0.2) < 0.001);
      Check ("13.3 Ray outside boundary returns Hit = False", not Res_Miss.Hit);
   end;

   -- Summary
   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
