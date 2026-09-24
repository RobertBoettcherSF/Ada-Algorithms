--  Package implementation for Scanline Rendering (Ada 2023)

package body Scanline_Rendering with
  SPARK_Mode => Off
is

   --  Internal types for Edge Table (ET) and Active Edge Table (AET)
   type Edge_Record is record
      Y_Min     : Screen_Coordinate_Y;
      Y_Max     : Screen_Coordinate_Y;
      Current_X : Float;
      Inv_Slope : Float;
      Z_Min     : Depth_Value;
      Z_Slope   : Float; -- dz / dy
   end record;

   type Edge_Array is array (Positive range <>) of Edge_Record;

   ---------------------------------------------------------------------------
   -- Clear_Frame_Buffer
   ---------------------------------------------------------------------------
   procedure Clear_Frame_Buffer
     (Buffer : in out Frame_Buffer;
      Color  : in     Pixel_Color := Black)
   is
   begin
      for Y in Screen_Coordinate_Y loop
         for X in Screen_Coordinate_X loop
            Buffer (X, Y) := Color;
         end loop;
      end loop;
   end Clear_Frame_Buffer;

   ---------------------------------------------------------------------------
   -- Clear_Depth_Buffer
   ---------------------------------------------------------------------------
   procedure Clear_Depth_Buffer
     (Buffer : in out Depth_Buffer;
      Depth  : in     Depth_Value := Depth_Value'Last)
   is
   begin
      for Y in Screen_Coordinate_Y loop
         for X in Screen_Coordinate_X loop
            Buffer (X, Y) := Depth;
         end loop;
      end loop;
   end Clear_Depth_Buffer;

   ---------------------------------------------------------------------------
   -- Count_Colored_Pixels
   ---------------------------------------------------------------------------
   function Count_Colored_Pixels
     (Buffer : in Frame_Buffer;
      Color  : in Pixel_Color) return Natural
   is
      Count : Natural := 0;
   begin
      for Y in Screen_Coordinate_Y loop
         for X in Screen_Coordinate_X loop
            if Buffer (X, Y) = Color then
               Count := Count + 1;
            end if;
         end loop;
      end loop;
      return Count;
   end Count_Colored_Pixels;

   ---------------------------------------------------------------------------
   -- Is_Point_Inside_Convex_Hull (Cross-product half-plane test)
   ---------------------------------------------------------------------------
   function Is_Point_Inside_Convex_Hull
     (Pt       : in Point_2D;
      Vertices : in Point_2D_Array) return Boolean
   is
      Has_Pos : Boolean := False;
      Has_Neg : Boolean := False;
   begin
      for I in Vertices'Range loop
         declare
            Next_I : constant Positive :=
              (if I = Vertices'Last then Vertices'First else I + 1);
            V1 : constant Point_2D := Vertices (I);
            V2 : constant Point_2D := Vertices (Next_I);
            D  : constant Long_Integer :=
              (Long_Integer (Pt.X) - Long_Integer (V1.X)) *
              (Long_Integer (V2.Y) - Long_Integer (V1.Y)) -
              (Long_Integer (Pt.Y) - Long_Integer (V1.Y)) *
              (Long_Integer (V2.X) - Long_Integer (V1.X));
         begin
            if D > 0 then
               Has_Pos := True;
            elsif D < 0 then
               Has_Neg := True;
            end if;

            if Has_Pos and Has_Neg then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Point_Inside_Convex_Hull;

   ---------------------------------------------------------------------------
   -- Render_Polygon_2D (Scanline rasterization with Active Edge Table)
   ---------------------------------------------------------------------------
   procedure Render_Polygon_2D
     (Buffer   : in out Frame_Buffer;
      Vertices : in     Point_2D_Array;
      Color    : in     Pixel_Color)
   is
      Total_Edges : constant Natural := Vertices'Length;
      ET          : Edge_Array (1 .. Total_Edges);
      ET_Count    : Natural := 0;

      Min_Y : Screen_Coordinate_Y := Screen_Coordinate_Y'Last;
      Max_Y : Screen_Coordinate_Y := Screen_Coordinate_Y'First;
   begin
      if Vertices'Length < 3 then
         raise Degenerate_Polygon_Error;
      end if;

      --  Construct Edge Table (ignoring horizontal edges dy = 0)
      for I in Vertices'Range loop
         declare
            Next_I : constant Positive :=
              (if I = Vertices'Last then Vertices'First else I + 1);
            P1 : constant Point_2D := Vertices (I);
            P2 : constant Point_2D := Vertices (Next_I);
         begin
            if P1.Y /= P2.Y then
               declare
                  Lower_P : constant Point_2D := (if P1.Y < P2.Y then P1 else P2);
                  Upper_P : constant Point_2D := (if P1.Y < P2.Y then P2 else P1);
                  DY      : constant Float    := Float (Upper_P.Y) - Float (Lower_P.Y);
                  DX      : constant Float    := Float (Upper_P.X) - Float (Lower_P.X);
               begin
                  ET_Count := ET_Count + 1;
                  ET (ET_Count) :=
                    (Y_Min     => Lower_P.Y,
                     Y_Max     => Upper_P.Y,
                     Current_X => Float (Lower_P.X),
                     Inv_Slope => DX / DY,
                     Z_Min     => 0.0,
                     Z_Slope   => 0.0);

                  if Lower_P.Y < Min_Y then
                     Min_Y := Lower_P.Y;
                  end if;
                  if Upper_P.Y > Max_Y then
                     Max_Y := Upper_P.Y;
                  end if;
               end;
            end if;
         end;
      end loop;

      if ET_Count = 0 then
         --  All edges were horizontal
         return;
      end if;

      --  AET dynamic collection
      declare
         AET       : Edge_Array (1 .. ET_Count);
         AET_Count : Natural := 0;
      begin
         --  Process each scanline
         for Y in Min_Y .. Max_Y loop
            --  1. Add edges from ET where Y_Min = Y
            for I in 1 .. ET_Count loop
               if ET (I).Y_Min = Y then
                  AET_Count := AET_Count + 1;
                  AET (AET_Count) := ET (I);
               end if;
            end loop;

            --  2. Remove edges from AET where Y_Max = Y
            declare
               J : Positive := 1;
            begin
               while J <= AET_Count loop
                  if AET (J).Y_Max <= Y then
                     AET (J .. AET_Count - 1) := AET (J + 1 .. AET_Count);
                     AET_Count := AET_Count - 1;
                  else
                     J := J + 1;
                  end if;
               end loop;
            end;

            --  3. Sort AET by Current_X (Bubble Sort for simplicity and stability)
            if AET_Count > 1 then
               for I in 1 .. AET_Count - 1 loop
                  for J in 1 .. AET_Count - I loop
                     if AET (J).Current_X > AET (J + 1).Current_X then
                        declare
                           Temp : constant Edge_Record := AET (J);
                        begin
                           AET (J)     := AET (J + 1);
                           AET (J + 1) := Temp;
                        end;
                     end if;
                  end loop;
               end loop;
            end if;

            --  4. Fill spans using even-odd parity
            declare
               Idx : Positive := 1;
            begin
               while Idx + 1 <= AET_Count loop
                  declare
                     X_Start_F : constant Float := AET (Idx).Current_X;
                     X_End_F   : constant Float := AET (Idx + 1).Current_X;
                     X_Start   : Screen_Coordinate_X;
                     X_End     : Screen_Coordinate_X;
                  begin
                     if X_Start_F >= 0.0 then
                        X_Start := Screen_Coordinate_X (Float'Rounding (X_Start_F));
                     else
                        X_Start := 0;
                     end if;

                     if X_End_F <= Float (Screen_Coordinate_X'Last) then
                        X_End := Screen_Coordinate_X (Float'Rounding (X_End_F));
                     else
                        X_End := Screen_Coordinate_X'Last;
                     end if;

                     if X_Start <= X_End then
                        for X in X_Start .. X_End loop
                           Buffer (X, Y) := Color;
                        end loop;
                     end if;
                  end;
                  Idx := Idx + 2;
               end loop;
            end;

            --  5. Update Current_X for edges persisting to next scanline
            for I in 1 .. AET_Count loop
               AET (I).Current_X := AET (I).Current_X + AET (I).Inv_Slope;
            end loop;
         end loop;
      end;
   end Render_Polygon_2D;

   ---------------------------------------------------------------------------
   -- Render_Scene_3D_ZBuffer (Scanline Depth Buffering)
   ---------------------------------------------------------------------------
   procedure Render_Scene_3D_ZBuffer
     (FB       : in out Frame_Buffer;
      ZB       : in out Depth_Buffer;
      Polygons : in     Polygon_3D_Array)
   is
   begin
      for Poly of Polygons loop
         declare
            V : Point_3D_Array renames Poly.Vertices;
            --  Bounding scanlines for this triangle
            Min_Y : constant Screen_Coordinate_Y := Screen_Coordinate_Y'Min (V (1).Y, Screen_Coordinate_Y'Min (V (2).Y, V (3).Y));
            Max_Y : constant Screen_Coordinate_Y := Screen_Coordinate_Y'Max (V (1).Y, Screen_Coordinate_Y'Max (V (2).Y, V (3).Y));

            --  Calculate plane equation: Ax + By + Cz + D = 0
            --  Vector V1->V2 and V1->V3
            V12_X : constant Float := Float (V (2).X) - Float (V (1).X);
            V12_Y : constant Float := Float (V (2).Y) - Float (V (1).Y);
            V12_Z : constant Float := V (2).Z - V (1).Z;

            V13_X : constant Float := Float (V (3).X) - Float (V (1).X);
            V13_Y : constant Float := Float (V (3).Y) - Float (V (1).Y);
            V13_Z : constant Float := V (3).Z - V (1).Z;

            --  Normal components via cross product
            Plane_A : constant Float := (V12_Y * V13_Z) - (V12_Z * V13_Y);
            Plane_B : constant Float := (V12_Z * V13_X) - (V12_X * V13_Z);
            Plane_C : constant Float := (V12_X * V13_Y) - (V12_Y * V13_X);
            Plane_D : constant Float := -((Plane_A * Float (V (1).X)) +
                                          (Plane_B * Float (V (1).Y)) +
                                          (Plane_C * V (1).Z));

            --  Depth gradient per X pixel: dz/dx = -Plane_A / Plane_C
            DZ_DX   : constant Float := (if abs Plane_C > 1.0e-6 then -(Plane_A / Plane_C) else 0.0);
         begin
            --  Process scanlines within triangle's vertical range
            for Y in Min_Y .. Max_Y loop
               declare
                  Intersections : array (1 .. 3) of Float;
                  Count         : Natural := 0;
               begin
                  --  Intersect with 3 edges
                  for E in 1 .. 3 loop
                     declare
                        P1 : constant Point_3D := V (E);
                        P2 : constant Point_3D := V (if E = 3 then 1 else E + 1);
                     begin
                        if (P1.Y <= Y and then P2.Y > Y) or else (P2.Y <= Y and then P1.Y > Y) then
                           declare
                              T : constant Float := (Float (Y) - Float (P1.Y)) / (Float (P2.Y) - Float (P1.Y));
                              X : constant Float := Float (P1.X) + T * (Float (P2.X) - Float (P1.X));
                           begin
                              Count := Count + 1;
                              Intersections (Count) := X;
                           end;
                        end if;
                     end;
                  end loop;

                  if Count >= 2 then
                     declare
                        Left_X_F  : Float := Float'Min (Intersections (1), Intersections (2));
                        Right_X_F : Float := Float'Max (Intersections (1), Intersections (2));
                     begin
                        if Left_X_F < 0.0 then
                           Left_X_F := 0.0;
                        end if;
                        if Right_X_F > Float (Screen_Coordinate_X'Last) then
                           Right_X_F := Float (Screen_Coordinate_X'Last);
                        end if;

                        if Left_X_F <= Right_X_F then
                           declare
                              X_Start : constant Screen_Coordinate_X := Screen_Coordinate_X (Float'Rounding (Left_X_F));
                              X_End   : constant Screen_Coordinate_X := Screen_Coordinate_X (Float'Rounding (Right_X_F));
                              --  Initial depth at left point
                              Z_At_Left : Depth_Value;
                           begin
                              if abs Plane_C > 1.0e-6 then
                                 Z_At_Left := -((Plane_A * Float (X_Start)) +
                                                (Plane_B * Float (Y)) + Plane_D) / Plane_C;
                              else
                                 Z_At_Left := V (1).Z;
                              end if;

                              declare
                                 Cur_Z : Depth_Value := Z_At_Left;
                              begin
                                 for X in X_Start .. X_End loop
                                    --  Standard Z-test: closer surface has smaller depth value
                                    if Cur_Z < ZB (X, Y) then
                                       ZB (X, Y) := Cur_Z;
                                       FB (X, Y) := Poly.Color;
                                    end if;
                                    Cur_Z := Cur_Z + DZ_DX;
                                 end loop;
                              end;
                           end;
                        end if;
                     end;
                  end if;
               end;
            end loop;
         end;
      end loop;
   end Render_Scene_3D_ZBuffer;

   ---------------------------------------------------------------------------
   -- Render_Scanline_Spans (Hidden-Surface Removal per scanline span)
   ---------------------------------------------------------------------------
   procedure Render_Scanline_Spans
     (FB       : in out Frame_Buffer;
      Scan_Y   : in     Screen_Coordinate_Y;
      Polygons : in     Polygon_3D_Array)
   is
      type Span_Record is record
         Left_X  : Screen_Coordinate_X;
         Right_X : Screen_Coordinate_X;
         Z_Start : Depth_Value;
         Z_End   : Depth_Value;
         Color   : Pixel_Color;
      end record;

      Spans       : array (1 .. Polygons'Length) of Span_Record;
      Span_Count  : Natural := 0;
   begin
      --  Find intersection segments (spans) for each polygon at Scan_Y
      for Poly of Polygons loop
         declare
            V     : Point_3D_Array renames Poly.Vertices;
            Min_Y : constant Screen_Coordinate_Y := Screen_Coordinate_Y'Min (V (1).Y, Screen_Coordinate_Y'Min (V (2).Y, V (3).Y));
            Max_Y : constant Screen_Coordinate_Y := Screen_Coordinate_Y'Max (V (1).Y, Screen_Coordinate_Y'Max (V (2).Y, V (3).Y));
         begin
            if Scan_Y >= Min_Y and then Scan_Y <= Max_Y then
               declare
                  Inter_X : array (1 .. 3) of Float;
                  Inter_Z : array (1 .. 3) of Float;
                  Cnt     : Natural := 0;
               begin
                  for E in 1 .. 3 loop
                     declare
                        P1 : constant Point_3D := V (E);
                        P2 : constant Point_3D := V (if E = 3 then 1 else E + 1);
                     begin
                        if (P1.Y <= Scan_Y and then P2.Y > Scan_Y) or else
                           (P2.Y <= Scan_Y and then P1.Y > Scan_Y)
                        then
                           declare
                              T : constant Float := (Float (Scan_Y) - Float (P1.Y)) / (Float (P2.Y) - Float (P1.Y));
                              X : constant Float := Float (P1.X) + T * (Float (P2.X) - Float (P1.X));
                              Z : constant Float := P1.Z + T * (P2.Z - P1.Z);
                           begin
                              Cnt := Cnt + 1;
                              Inter_X (Cnt) := X;
                              Inter_Z (Cnt) := Z;
                           end;
                        end if;
                     end;
                  end loop;

                  if Cnt >= 2 then
                     declare
                        Left_Idx  : constant Positive := (if Inter_X (1) <= Inter_X (2) then 1 else 2);
                        Right_Idx : constant Positive := (if Left_Idx = 1 then 2 else 1);
                        LX        : constant Screen_Coordinate_X := Screen_Coordinate_X (Float'Max (0.0, Float'Rounding (Inter_X (Left_Idx))));
                        RX        : constant Screen_Coordinate_X := Screen_Coordinate_X (Float'Min (Float (Screen_Coordinate_X'Last), Float'Rounding (Inter_X (Right_Idx))));
                     begin
                        if LX <= RX then
                           Span_Count := Span_Count + 1;
                           Spans (Span_Count) :=
                             (Left_X  => LX,
                              Right_X => RX,
                              Z_Start => Inter_Z (Left_Idx),
                              Z_End   => Inter_Z (Right_Idx),
                              Color   => Poly.Color);
                        end if;
                     end;
                  end if;
               end;
            end if;
         end;
      end loop;

      --  Rasterize spans onto the scanline with per-pixel depth resolution
      for X in Screen_Coordinate_X loop
         declare
            Closest_Z     : Depth_Value := Depth_Value'Last;
            Closest_Color : Pixel_Color := FB (X, Scan_Y);
            Found         : Boolean     := False;
         begin
            for S in 1 .. Span_Count loop
               if X >= Spans (S).Left_X and then X <= Spans (S).Right_X then
                  declare
                     Len   : constant Float := Float (Spans (S).Right_X - Spans (S).Left_X);
                     T     : constant Float := (if Len > 0.0 then Float (X - Spans (S).Left_X) / Len else 0.0);
                     Pix_Z : constant Depth_Value := Spans (S).Z_Start + T * (Spans (S).Z_End - Spans (S).Z_Start);
                  begin
                     if Pix_Z < Closest_Z then
                        Closest_Z     := Pix_Z;
                        Closest_Color := Spans (S).Color;
                        Found         := True;
                     end if;
                  end;
               end if;
            end loop;

            if Found then
               FB (X, Scan_Y) := Closest_Color;
            end if;
         end;
      end loop;
   end Render_Scanline_Spans;

end Scanline_Rendering;
