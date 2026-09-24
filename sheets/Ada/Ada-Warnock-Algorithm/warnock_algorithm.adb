package body Warnock_Algorithm with
   SPARK_Mode => Off
is

   --  ----------------------------------------------------------------------
   --  Private Internal Helpers
   --  ----------------------------------------------------------------------

   function Blend_Colors
     (C1, C2, C3, C4 : RGBA_Color) return RGBA_Color is
      R_Sum : constant Natural :=
        Natural (C1.Red) + Natural (C2.Red) +
        Natural (C3.Red) + Natural (C4.Red);
      G_Sum : constant Natural :=
        Natural (C1.Green) + Natural (C2.Green) +
        Natural (C3.Green) + Natural (C4.Green);
      B_Sum : constant Natural :=
        Natural (C1.Blue) + Natural (C2.Blue) +
        Natural (C3.Blue) + Natural (C4.Blue);
      A_Sum : constant Natural :=
        Natural (C1.Alpha) + Natural (C2.Alpha) +
        Natural (C3.Alpha) + Natural (C4.Alpha);
   begin
      return
        (Red   => Color_Component (R_Sum / 4),
         Green => Color_Component (G_Sum / 4),
         Blue  => Color_Component (B_Sum / 4),
         Alpha => Color_Component (A_Sum / 4));
   end Blend_Colors;

   function Point_In_Area (P : Point_2D; Area : Viewport_Area) return Boolean is
   begin
      return P.X >= Area.Min_X and then P.X <= Area.Max_X
        and then P.Y >= Area.Min_Y and then P.Y <= Area.Max_Y;
   end Point_In_Area;

   function Area_Corner (Area : Viewport_Area; Index : Positive) return Point_2D is
   begin
      case Index is
         when 1 =>
            return (X => Area.Min_X, Y => Area.Min_Y);
         when 2 =>
            return (X => Area.Max_X, Y => Area.Min_Y);
         when 3 =>
            return (X => Area.Max_X, Y => Area.Max_Y);
         when 4 =>
            return (X => Area.Min_X, Y => Area.Max_Y);
         when others =>
            return (X => Area.Min_X, Y => Area.Min_Y);
      end case;
   end Area_Corner;

   --  Ray casting point-in-polygon test (Jordan Curve Theorem)
   function Point_In_Polygon
     (P    : Point_2D;
      Poly : Polygon_Record) return Boolean
   is
      Inside : Boolean := False;
      J      : Positive := Poly.Vertex_Count;
   begin
      for I in 1 .. Poly.Vertex_Count loop
         declare
            VI : constant Point_2D := Poly.Vertices (I);
            VJ : constant Point_2D := Poly.Vertices (J);
         begin
            if ((VI.Y > P.Y) /= (VJ.Y > P.Y))
              and then
                (P.X < (VJ.X - VI.X) * (P.Y - VI.Y) / (VJ.Y - VI.Y) + VI.X)
            then
               Inside := not Inside;
            end if;
         end;
         J := I;
      end loop;
      return Inside;
   end Point_In_Polygon;

   function Line_Segments_Intersect
     (P1, P2, P3, P4 : Point_2D) return Boolean
   is
      function Cross_Product (A, B, C : Point_2D) return Real is
      begin
         return (B.X - A.X) * (C.Y - A.Y) - (B.Y - A.Y) * (C.X - A.X);
      end Cross_Product;

      function On_Segment (A, B, C : Point_2D) return Boolean is
      begin
         return
           C.X >= Real'Min (A.X, B.X) and then C.X <= Real'Max (A.X, B.X)
           and then
           C.Y >= Real'Min (A.Y, B.Y) and then C.Y <= Real'Max (A.Y, B.Y);
      end On_Segment;

      D1 : constant Real := Cross_Product (P3, P4, P1);
      D2 : constant Real := Cross_Product (P3, P4, P2);
      D3 : constant Real := Cross_Product (P1, P2, P3);
      D4 : constant Real := Cross_Product (P1, P2, P4);
   begin
      if (((D1 > 0.0 and then D2 < 0.0) or else (D1 < 0.0 and then D2 > 0.0))
          and then
          ((D3 > 0.0 and then D4 < 0.0) or else (D3 < 0.0 and then D4 > 0.0)))
      then
         return True;
      end if;

      if D1 = 0.0 and then On_Segment (P3, P4, P1) then
         return True;
      end if;
      if D2 = 0.0 and then On_Segment (P3, P4, P2) then
         return True;
      end if;
      if D3 = 0.0 and then On_Segment (P1, P2, P3) then
         return True;
      end if;
      if D4 = 0.0 and then On_Segment (P1, P2, P4) then
         return True;
      end if;

      return False;
   end Line_Segments_Intersect;

   function Bounding_Boxes_Overlap
     (Poly : Polygon_Record; Area : Viewport_Area) return Boolean
   is
      Min_X, Max_X : Real;
      Min_Y, Max_Y : Real;
   begin
      Min_X := Poly.Vertices (1).X;
      Max_X := Poly.Vertices (1).X;
      Min_Y := Poly.Vertices (1).Y;
      Max_Y := Poly.Vertices (1).Y;

      for I in 2 .. Poly.Vertex_Count loop
         Min_X := Real'Min (Min_X, Poly.Vertices (I).X);
         Max_X := Real'Max (Max_X, Poly.Vertices (I).X);
         Min_Y := Real'Min (Min_Y, Poly.Vertices (I).Y);
         Max_Y := Real'Max (Max_Y, Poly.Vertices (I).Y);
      end loop;

      if Max_X < Area.Min_X or else Min_X > Area.Max_X
        or else Max_Y < Area.Min_Y or else Min_Y > Area.Max_Y
      then
         return False;
      end if;

      return True;
   end Bounding_Boxes_Overlap;

   --  ----------------------------------------------------------------------
   --  Public Implementations
   --  ----------------------------------------------------------------------

   function Is_Valid_Area (Area : Viewport_Area) return Boolean is
   begin
      return Area.Max_X > Area.Min_X and then Area.Max_Y > Area.Min_Y;
   end Is_Valid_Area;

   function Area_Width (Area : Viewport_Area) return Real is
   begin
      return Area.Max_X - Area.Min_X;
   end Area_Width;

   function Area_Height (Area : Viewport_Area) return Real is
   begin
      return Area.Max_Y - Area.Min_Y;
   end Area_Height;

   function Area_Center (Area : Viewport_Area) return Point_2D is
   begin
      return
        (X => Area.Min_X + (Area.Max_X - Area.Min_X) / 2.0,
         Y => Area.Min_Y + (Area.Max_Y - Area.Min_Y) / 2.0);
   end Area_Center;

   function Split_Area (Area : Viewport_Area) return Quad_Split is
      Mid_X : constant Real := Area.Min_X + (Area.Max_X - Area.Min_X) / 2.0;
      Mid_Y : constant Real := Area.Min_Y + (Area.Max_Y - Area.Min_Y) / 2.0;
      Result : Quad_Split;
   begin
      --  Quadrant 1: Bottom-Left
      Result (1) := (Min_X => Area.Min_X, Min_Y => Area.Min_Y,
                     Max_X => Mid_X,      Max_Y => Mid_Y);
      --  Quadrant 2: Bottom-Right
      Result (2) := (Min_X => Mid_X,      Min_Y => Area.Min_Y,
                     Max_X => Area.Max_X, Max_Y => Mid_Y);
      --  Quadrant 3: Top-Left
      Result (3) := (Min_X => Area.Min_X, Min_Y => Mid_Y,
                     Max_X => Mid_X,      Max_Y => Area.Max_Y);
      --  Quadrant 4: Top-Right
      Result (4) := (Min_X => Mid_X,      Min_Y => Mid_Y,
                     Max_X => Area.Max_X, Max_Y => Area.Max_Y);
      return Result;
   end Split_Area;

   function Evaluate_Z
     (Plane : Plane_Equation;
      P     : Point_2D) return Real is
   begin
      --  Plane: Ax + By + Cz + D = 0 => z = (-D - Ax - By) / C
      return (-Plane.D - (Plane.A * P.X) - (Plane.B * P.Y)) / Plane.C;
   end Evaluate_Z;

   function Classify_Relationship
     (Poly : Polygon_Record;
      Area : Viewport_Area) return Relationship_Type
   is
      Vertices_Inside : Natural := 0;
      Corners_Inside  : Natural := 0;
      Area_Edges      : constant array (1 .. 4, 1 .. 2) of Point_2D :=
        [1 => [Area_Corner (Area, 1), Area_Corner (Area, 2)],
         2 => [Area_Corner (Area, 2), Area_Corner (Area, 3)],
         3 => [Area_Corner (Area, 3), Area_Corner (Area, 4)],
         4 => [Area_Corner (Area, 4), Area_Corner (Area, 1)]];
   begin
      if not Bounding_Boxes_Overlap (Poly, Area) then
         return Disjoint_Polygon;
      end if;

      --  Count polygon vertices inside area
      for I in 1 .. Poly.Vertex_Count loop
         if Point_In_Area (Poly.Vertices (I), Area) then
            Vertices_Inside := Vertices_Inside + 1;
         end if;
      end loop;

      if Vertices_Inside = Poly.Vertex_Count then
         return Contained_Polygon;
      end if;

      --  Count area corners inside polygon
      for I in 1 .. 4 loop
         if Point_In_Polygon (Area_Corner (Area, I), Poly) then
            Corners_Inside := Corners_Inside + 1;
         end if;
      end loop;

      if Corners_Inside = 4 then
         return Surrounding_Polygon;
      end if;

      --  Check edge-edge intersections
      declare
         Prev : Positive := Poly.Vertex_Count;
      begin
         for I in 1 .. Poly.Vertex_Count loop
            for K in 1 .. 4 loop
               if Line_Segments_Intersect
                    (Poly.Vertices (Prev), Poly.Vertices (I),
                     Area_Edges (K, 1), Area_Edges (K, 2))
               then
                  return Intersecting_Polygon;
               end if;
            end loop;
            Prev := I;
         end loop;
      end;

      if Vertices_Inside > 0 or else Corners_Inside > 0 then
         return Intersecting_Polygon;
      end if;

      return Disjoint_Polygon;
   end Classify_Relationship;

   function Find_Frontmost_Surrounding
     (Polygons : Polygon_Array;
      Area     : Viewport_Area) return Natural
   is
      Best_Index : Natural := 0;
      Max_Z      : Real := Real'First;
      Center     : constant Point_2D := Area_Center (Area);
   begin
      for I in Polygons'Range loop
         if Classify_Relationship (Polygons (I), Area) = Surrounding_Polygon then
            declare
               Z_Val : constant Real := Evaluate_Z (Polygons (I).Plane, Center);
            begin
               if Best_Index = 0 or else Z_Val > Max_Z then
                  Max_Z := Z_Val;
                  Best_Index := I;
               end if;
            end;
         end if;
      end loop;
      return Best_Index;
   end Find_Frontmost_Surrounding;

   --  ----------------------------------------------------------------------
   --  Variant 1: Render_Standard
   --  ----------------------------------------------------------------------

   procedure Render_Standard
     (Polygons         : Polygon_Array;
      Area             : Viewport_Area;
      Background_Color : RGBA_Color;
      Resolution_Limit : Real;
      Output_Color     : out RGBA_Color)
   is
      Disjoint_Count    : Natural := 0;
      Contained_Index   : Natural := 0;
      Contained_Count   : Natural := 0;
      Surrounding_Index : Natural := 0;
      Surrounding_Count : Natural := 0;
      Intersecting_Count: Natural := 0;
      Center            : constant Point_2D := Area_Center (Area);
      Max_Surround_Z    : Real := Real'First;
   begin
      for I in Polygons'Range loop
         case Classify_Relationship (Polygons (I), Area) is
            when Disjoint_Polygon =>
               Disjoint_Count := Disjoint_Count + 1;
            when Contained_Polygon =>
               Contained_Count := Contained_Count + 1;
               Contained_Index := I;
            when Surrounding_Polygon =>
               Surrounding_Count := Surrounding_Count + 1;
               declare
                  Z : constant Real := Evaluate_Z (Polygons (I).Plane, Center);
               begin
                  if Surrounding_Index = 0 or else Z > Max_Surround_Z then
                     Max_Surround_Z := Z;
                     Surrounding_Index := I;
                  end if;
               end;
            when Intersecting_Polygon =>
               Intersecting_Count := Intersecting_Count + 1;
         end case;
      end loop;

      --  Warnock Rule 1: All polygons are disjoint from the area -> Background
      if Disjoint_Count = Polygons'Length then
         Output_Color := Background_Color;
         return;
      end if;

      --  Warnock Rule 2: Single contained polygon & no surround/intersect -> Poly color
      if Contained_Count = 1 and then Surrounding_Count = 0 and then Intersecting_Count = 0 then
         Output_Color := Polygons (Contained_Index).Color;
         return;
      end if;

      --  Warnock Rule 3: Single surrounding polygon & no contained/intersect -> Surround color
      if Surrounding_Count >= 1 and then Contained_Count = 0 and then Intersecting_Count = 0 then
         Output_Color := Polygons (Surrounding_Index).Color;
         return;
      end if;

      --  Warnock Rule 4: Surrounding polygon is entirely in front of everything else
      if Surrounding_Index /= 0 then
         declare
            Is_Completely_In_Front : Boolean := True;
         begin
            for I in Polygons'Range loop
               if I /= Surrounding_Index and then
                  Classify_Relationship (Polygons (I), Area) /= Disjoint_Polygon
               then
                  for Corner_Idx in 1 .. 4 loop
                     declare
                        Pt : constant Point_2D := Area_Corner (Area, Corner_Idx);
                        Z_Surround : constant Real :=
                          Evaluate_Z (Polygons (Surrounding_Index).Plane, Pt);
                        Z_Other    : constant Real :=
                          Evaluate_Z (Polygons (I).Plane, Pt);
                     begin
                        if Z_Surround <= Z_Other then
                           Is_Completely_In_Front := False;
                           exit;
                        end if;
                     end;
                  end loop;
               end if;
               exit when not Is_Completely_In_Front;
            end loop;

            if Is_Completely_In_Front then
               Output_Color := Polygons (Surrounding_Index).Color;
               return;
            end if;
         end;
      end if;

      --  Termination or Subdivide
      if Area_Width (Area) <= Resolution_Limit or else Area_Height (Area) <= Resolution_Limit then
         --  Sample center
         declare
            Best_Z     : Real := Real'First;
            Hit_Found  : Boolean := False;
            Hit_Color  : RGBA_Color := Background_Color;
         begin
            for I in Polygons'Range loop
               if Point_In_Polygon (Center, Polygons (I)) then
                  declare
                     Z : constant Real := Evaluate_Z (Polygons (I).Plane, Center);
                  begin
                     if (not Hit_Found) or else Z > Best_Z then
                        Best_Z    := Z;
                        Hit_Color := Polygons (I).Color;
                        Hit_Found := True;
                     end if;
                  end;
               end if;
            end loop;
            Output_Color := Hit_Color;
            return;
         end;
      end if;

      --  Subdivide into 4 quadrants
      declare
         Quads : constant Quad_Split := Split_Area (Area);
         Sub_Colors : array (1 .. 4) of RGBA_Color;
      begin
         for Q in 1 .. 4 loop
            Render_Standard
              (Polygons, Quads (Q), Background_Color, Resolution_Limit, Sub_Colors (Q));
         end loop;
         Output_Color := Blend_Colors
           (Sub_Colors (1), Sub_Colors (2), Sub_Colors (3), Sub_Colors (4));
      end;
   end Render_Standard;

   --  ----------------------------------------------------------------------
   --  Variant 2: Render_Framebuffer
   --  ----------------------------------------------------------------------

   procedure Render_Framebuffer
     (Polygons         : Polygon_Array;
      Area             : Viewport_Area;
      Background_Color : RGBA_Color;
      Buffer           : in out Framebuffer;
      Max_Depth        : Natural)
   is
      procedure Raster_Recursive
        (Curr_Area : Viewport_Area;
         X_Start, X_End : Pixel_Index;
         Y_Start, Y_End : Pixel_Index;
         Depth          : Natural)
      is
         Surround_Idx : constant Natural := Find_Frontmost_Surrounding (Polygons, Curr_Area);
         Any_Touch    : Boolean := False;
      begin
         for I in Polygons'Range loop
            if Classify_Relationship (Polygons (I), Curr_Area) /= Disjoint_Polygon then
               Any_Touch := True;
               exit;
            end if;
         end loop;

         if not Any_Touch then
            for Y in Y_Start .. Y_End loop
               for X in X_Start .. X_End loop
                  Buffer (X, Y) := Background_Color;
               end loop;
            end loop;
            return;
         end if;

         if Surround_Idx /= 0 then
            declare
               Center : constant Point_2D := Area_Center (Curr_Area);
               Surr_Z : constant Real := Evaluate_Z (Polygons (Surround_Idx).Plane, Center);
               Front  : Boolean := True;
            begin
               for I in Polygons'Range loop
                  if I /= Surround_Idx and then
                     Classify_Relationship (Polygons (I), Curr_Area) /= Disjoint_Polygon
                  then
                     if Evaluate_Z (Polygons (I).Plane, Center) >= Surr_Z then
                        Front := False;
                        exit;
                     end if;
                  end if;
               end loop;

               if Front then
                  for Y in Y_Start .. Y_End loop
                     for X in X_Start .. X_End loop
                        Buffer (X, Y) := Polygons (Surround_Idx).Color;
                     end loop;
                  end loop;
                  return;
               end if;
            end;
         end if;

         if Depth >= Max_Depth or else (X_Start = X_End and then Y_Start = Y_End) then
            for Y in Y_Start .. Y_End loop
               for X in X_Start .. X_End loop
                  declare
                     Px : constant Real :=
                       Curr_Area.Min_X +
                       (Real (X - X_Start) + 0.5) * Area_Width (Curr_Area) /
                       Real (X_End - X_Start + 1);
                     Py : constant Real :=
                       Curr_Area.Min_Y +
                       (Real (Y - Y_Start) + 0.5) * Area_Height (Curr_Area) /
                       Real (Y_End - Y_Start + 1);
                     P  : constant Point_2D := (X => Px, Y => Py);
                     Best_Z : Real := Real'First;
                     Hit    : Boolean := False;
                     Color  : RGBA_Color := Background_Color;
                  begin
                     for I in Polygons'Range loop
                        if Point_In_Polygon (P, Polygons (I)) then
                           declare
                              Z : constant Real := Evaluate_Z (Polygons (I).Plane, P);
                           begin
                              if (not Hit) or else Z > Best_Z then
                                 Best_Z := Z;
                                 Color  := Polygons (I).Color;
                                 Hit    := True;
                              end if;
                           end;
                        end if;
                     end loop;
                     Buffer (X, Y) := Color;
                  end;
               end loop;
            end loop;
            return;
         end if;

         --  Divide pixels and area
         declare
            Quads : constant Quad_Split := Split_Area (Curr_Area);
            Mid_X : constant Pixel_Index := X_Start + (X_End - X_Start) / 2;
            Mid_Y : constant Pixel_Index := Y_Start + (Y_End - Y_Start) / 2;
         begin
            Raster_Recursive (Quads (1), X_Start, Mid_X, Y_Start, Mid_Y, Depth + 1);
            Raster_Recursive (Quads (2), Mid_X + 1, X_End, Y_Start, Mid_Y, Depth + 1);
            Raster_Recursive (Quads (3), X_Start, Mid_X, Mid_Y + 1, Y_End, Depth + 1);
            Raster_Recursive (Quads (4), Mid_X + 1, X_End, Mid_Y + 1, Y_End, Depth + 1);
         end;
      end Raster_Recursive;

   begin
      Raster_Recursive
        (Curr_Area => Area,
         X_Start   => Buffer'First (1),
         X_End     => Buffer'Last (1),
         Y_Start   => Buffer'First (2),
         Y_End     => Buffer'Last (2),
         Depth     => 0);
   end Render_Framebuffer;

   --  ----------------------------------------------------------------------
   --  Variant 3: Render_Adaptive_Supersampled
   --  ----------------------------------------------------------------------

   procedure Render_Adaptive_Supersampled
     (Polygons         : Polygon_Array;
      Area             : Viewport_Area;
      Background_Color : RGBA_Color;
      Resolution_Limit : Real;
      Output_Color     : out RGBA_Color)
   is
      Disjoint_Count : Natural := 0;
   begin
      for I in Polygons'Range loop
         if Classify_Relationship (Polygons (I), Area) = Disjoint_Polygon then
            Disjoint_Count := Disjoint_Count + 1;
         end if;
      end loop;

      if Disjoint_Count = Polygons'Length then
         Output_Color := Background_Color;
         return;
      end if;

      declare
         Surr_Idx : constant Natural := Find_Frontmost_Surrounding (Polygons, Area);
      begin
         if Surr_Idx /= 0 then
            declare
               Center : constant Point_2D := Area_Center (Area);
               Surr_Z : constant Real := Evaluate_Z (Polygons (Surr_Idx).Plane, Center);
               Front  : Boolean := True;
            begin
               for I in Polygons'Range loop
                  if I /= Surr_Idx and then
                     Classify_Relationship (Polygons (I), Area) /= Disjoint_Polygon
                  then
                     if Evaluate_Z (Polygons (I).Plane, Center) >= Surr_Z then
                        Front := False;
                        exit;
                     end if;
                  end if;
               end loop;

               if Front then
                  Output_Color := Polygons (Surr_Idx).Color;
                  return;
               end if;
            end;
         end if;
      end;

      if Area_Width (Area) <= Resolution_Limit then
         --  Multisample 4 interior points for anti-aliasing
         declare
            Sub : constant Quad_Split := Split_Area (Area);
            Sub_Colors : array (1 .. 4) of RGBA_Color;
         begin
            for Q in 1 .. 4 loop
               declare
                  Center : constant Point_2D := Area_Center (Sub (Q));
                  Best_Z : Real := Real'First;
                  Hit    : Boolean := False;
                  Col    : RGBA_Color := Background_Color;
               begin
                  for I in Polygons'Range loop
                     if Point_In_Polygon (Center, Polygons (I)) then
                        declare
                           Z : constant Real := Evaluate_Z (Polygons (I).Plane, Center);
                        begin
                           if (not Hit) or else Z > Best_Z then
                              Best_Z := Z;
                              Col    := Polygons (I).Color;
                              Hit    := True;
                           end if;
                        end;
                     end if;
                  end loop;
                  Sub_Colors (Q) := Col;
               end;
            end loop;
            Output_Color := Blend_Colors
              (Sub_Colors (1), Sub_Colors (2), Sub_Colors (3), Sub_Colors (4));
            return;
         end;
      end if;

      declare
         Quads : constant Quad_Split := Split_Area (Area);
         Sub_Colors : array (1 .. 4) of RGBA_Color;
      begin
         for Q in 1 .. 4 loop
            Render_Adaptive_Supersampled
              (Polygons, Quads (Q), Background_Color, Resolution_Limit, Sub_Colors (Q));
         end loop;
         Output_Color := Blend_Colors
           (Sub_Colors (1), Sub_Colors (2), Sub_Colors (3), Sub_Colors (4));
      end;
   end Render_Adaptive_Supersampled;

   --  ----------------------------------------------------------------------
   --  Variant 4: Render_Diagnostic_Stats
   --  ----------------------------------------------------------------------

   procedure Render_Diagnostic_Stats
     (Polygons         : Polygon_Array;
      Area             : Viewport_Area;
      Background_Color : RGBA_Color;
      Resolution_Limit : Real;
      Total_Nodes      : out Natural;
      Max_Depth_Hit    : out Natural)
   is
      Nodes_Count : Natural := 0;
      Deepest     : Natural := 0;

      procedure Walk (Sub_Area : Viewport_Area; Current_Depth : Natural) is
         Disjoint_Count : Natural := 0;
      begin
         Nodes_Count := Nodes_Count + 1;
         if Current_Depth > Deepest then
            Deepest := Current_Depth;
         end if;

         for I in Polygons'Range loop
            if Classify_Relationship (Polygons (I), Sub_Area) = Disjoint_Polygon then
               Disjoint_Count := Disjoint_Count + 1;
            end if;
         end loop;

         if Disjoint_Count = Polygons'Length then
            return;
         end if;

         declare
            Surr_Idx : constant Natural := Find_Frontmost_Surrounding (Polygons, Sub_Area);
         begin
            if Surr_Idx /= 0 then
               declare
                  Center : constant Point_2D := Area_Center (Sub_Area);
                  Surr_Z : constant Real := Evaluate_Z (Polygons (Surr_Idx).Plane, Center);
                  Front  : Boolean := True;
               begin
                  for I in Polygons'Range loop
                     if I /= Surr_Idx and then
                        Classify_Relationship (Polygons (I), Sub_Area) /= Disjoint_Polygon
                     then
                        if Evaluate_Z (Polygons (I).Plane, Center) >= Surr_Z then
                           Front := False;
                           exit;
                        end if;
                     end if;
                  end loop;

                  if Front then
                     return;
                  end if;
               end;
            end if;
         end;

         if Area_Width (Sub_Area) <= Resolution_Limit then
            return;
         end if;

         declare
            Quads : constant Quad_Split := Split_Area (Sub_Area);
         begin
            for Q in 1 .. 4 loop
               Walk (Quads (Q), Current_Depth + 1);
            end loop;
         end;
      end Walk;
   begin
      Walk (Area, 0);
      Total_Nodes   := Nodes_Count;
      Max_Depth_Hit := Deepest;
      pragma Unreferenced (Background_Color);
   end Render_Diagnostic_Stats;

end Warnock_Algorithm;
