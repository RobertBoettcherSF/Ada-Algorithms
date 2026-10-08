package body Painter_Algorithm is

   ----------------------------------------------------------------------------
   -- Helper Implementations
   ----------------------------------------------------------------------------

   function Max_Depth (P : Polygon) return Depth_Value is
      Result : Depth_Value;
   begin
      Result := P.Vertices (P.Vertices'First).Z;
      for I in P.Vertices'First + 1 .. P.Vertices'Last loop
         if P.Vertices (I).Z > Result then
            Result := P.Vertices (I).Z;
         end if;
      end loop;
      return Result;
   end Max_Depth;

   function Centroid_Depth (P : Polygon) return Depth_Value is
      Sum : Depth_Value := 0.0;
   begin
      for I in P.Vertices'Range loop
         Sum := Sum + P.Vertices (I).Z;
      end loop;
      return Sum / Depth_Value (P.Vertex_Count);
   end Centroid_Depth;

   procedure Get_Bounds_2D (P      : Polygon;
                            Min_X  : out Coordinate;
                            Max_X  : out Coordinate;
                            Min_Y  : out Coordinate;
                            Max_Y  : out Coordinate) is
   begin
      Min_X := P.Vertices (P.Vertices'First).X;
      Max_X := Min_X;
      Min_Y := P.Vertices (P.Vertices'First).Y;
      Max_Y := Min_Y;

      for I in P.Vertices'First + 1 .. P.Vertices'Last loop
         if P.Vertices (I).X < Min_X then
            Min_X := P.Vertices (I).X;
         end if;
         if P.Vertices (I).X > Max_X then
            Max_X := P.Vertices (I).X;
         end if;
         if P.Vertices (I).Y < Min_Y then
            Min_Y := P.Vertices (I).Y;
         end if;
         if P.Vertices (I).Y > Max_Y then
            Max_Y := P.Vertices (I).Y;
         end if;
      end loop;
   end Get_Bounds_2D;

   function Bounding_Boxes_Overlap_2D (P, Q : Polygon) return Boolean is
      P_Min_X, P_Max_X, P_Min_Y, P_Max_Y : Coordinate;
      Q_Min_X, Q_Max_X, Q_Min_Y, Q_Max_Y : Coordinate;
   begin
      Get_Bounds_2D (P, P_Min_X, P_Max_X, P_Min_Y, P_Max_Y);
      Get_Bounds_2D (Q, Q_Min_X, Q_Max_X, Q_Min_Y, Q_Max_Y);

      if P_Max_X < Q_Min_X or else Q_Max_X < P_Min_X then
         return False;
      end if;
      if P_Max_Y < Q_Min_Y or else Q_Max_Y < P_Min_Y then
         return False;
      end if;

      return True;
   end Bounding_Boxes_Overlap_2D;

   function Point_In_Polygon_2D (Pt : Point_2D; Poly : Polygon) return Boolean is
      Inside : Boolean := False;
      J      : Positive := Poly.Vertices'Last;
      XI, YI, XJ, YJ : Coordinate;
   begin
      for I in Poly.Vertices'Range loop
         XI := Poly.Vertices (I).X;
         YI := Poly.Vertices (I).Y;
         XJ := Poly.Vertices (J).X;
         YJ := Poly.Vertices (J).Y;

         if ((YI > Pt.Y) /= (YJ > Pt.Y)) and then
            (Pt.X < (XJ - XI) * (Pt.Y - YI) / (YJ - YI) + XI)
         then
            Inside := not Inside;
         end if;
         J := I;
      end loop;
      return Inside;
   end Point_In_Polygon_2D;

   procedure Clear_Framebuffer (Buffer : in out Framebuffer;
                                Color  : RGBA_Color := Black_Color) is
   begin
      for X in Buffer'Range (1) loop
         for Y in Buffer'Range (2) loop
            Buffer (X, Y) := Color;
         end loop;
      end loop;
   end Clear_Framebuffer;

   procedure Rasterize_Polygon (P      : Polygon;
                                Buffer : in out Framebuffer) is
      Min_X, Max_X, Min_Y, Max_Y : Coordinate;
      IX_Start, IX_End : Screen_X;
      IY_Start, IY_End : Screen_Y;
      Pt : Point_2D;
   begin
      Get_Bounds_2D (P, Min_X, Max_X, Min_Y, Max_Y);

      -- Clamp bounding box to screen dimensions
      if Max_X < Coordinate (Buffer'First (1)) or else
         Min_X > Coordinate (Buffer'Last (1)) or else
         Max_Y < Coordinate (Buffer'First (2)) or else
         Min_Y > Coordinate (Buffer'Last (2))
      then
         return;
      end if;

      IX_Start := Screen_X (Coordinate'Max (Coordinate (Buffer'First (1)), Min_X));
      IX_End   := Screen_X (Coordinate'Min (Coordinate (Buffer'Last (1)), Max_X));
      IY_Start := Screen_Y (Coordinate'Max (Coordinate (Buffer'First (2)), Min_Y));
      IY_End   := Screen_Y (Coordinate'Min (Coordinate (Buffer'Last (2)), Max_Y));

      for Y in IY_Start .. IY_End loop
         for X in IX_Start .. IX_End loop
            Pt := (X => Coordinate (X) + 0.5, Y => Coordinate (Y) + 0.5);
            if Point_In_Polygon_2D (Pt, P) then
               Buffer (X, Y) := P.Color;
            end if;
         end loop;
      end loop;
   end Rasterize_Polygon;

   ----------------------------------------------------------------------------
   -- Sorting Implementations
   ----------------------------------------------------------------------------

   procedure Sort_Polygons_Depth (Polygons : in out Polygon_Array) is
   begin
      if Polygons'Length <= 1 then
         return;
      end if;

      -- Descending sort by Max_Depth (farthest first)
      for I in Polygons'First .. Polygons'Last - 1 loop
         for J in I + 1 .. Polygons'Last loop
            if Max_Depth (Polygons (J)) > Max_Depth (Polygons (I)) then
               declare
                  T : constant Polygon := Polygons (I);
               begin
                  Polygons (I) := Polygons (J);
                  Polygons (J) := T;
               end;
            end if;
         end loop;
      end loop;
   end Sort_Polygons_Depth;

   procedure Render_Standard (Polygons : in out Polygon_Array;
                              Buffer   : in out Framebuffer) is
   begin
      if Polygons'Length = 0 then
         return;
      end if;
      Sort_Polygons_Depth (Polygons);
      for I in Polygons'Range loop
         Rasterize_Polygon (Polygons (I), Buffer);
      end loop;
   end Render_Standard;

   procedure Sort_Polygons_Centroid (Polygons : in out Polygon_Array) is
   begin
      if Polygons'Length <= 1 then
         return;
      end if;

      for I in Polygons'First .. Polygons'Last - 1 loop
         for J in I + 1 .. Polygons'Last loop
            if Centroid_Depth (Polygons (J)) > Centroid_Depth (Polygons (I)) then
               declare
                  T : constant Polygon := Polygons (I);
               begin
                  Polygons (I) := Polygons (J);
                  Polygons (J) := T;
               end;
            end if;
         end loop;
      end loop;
   end Sort_Polygons_Centroid;

   procedure Render_Centroid (Polygons : in out Polygon_Array;
                              Buffer   : in out Framebuffer) is
   begin
      if Polygons'Length = 0 then
         return;
      end if;
      Sort_Polygons_Centroid (Polygons);
      for I in Polygons'Range loop
         Rasterize_Polygon (Polygons (I), Buffer);
      end loop;
   end Render_Centroid;

   ----------------------------------------------------------------------------
   -- Newell-Newell-Sancha Depth-Sort
   ----------------------------------------------------------------------------

   function Polygons_Must_Precede (P, Q : Polygon) return Boolean is
   begin
      -- Test 1: No Z-extent overlap (P is completely behind Q)
      if Min_Depth (P) >= Max_Depth (Q) then
         return True;
      end if;

      -- Test 2: No 2D bounding-box overlap in the screen plane
      if not Bounding_Boxes_Overlap_2D (P, Q) then
         return True;
      end if;

      -- Fallback to Centroid depth when bounds overlap
      return Centroid_Depth (P) >= Centroid_Depth (Q);
   end Polygons_Must_Precede;

   procedure Render_Newell_Sorted (Polygons : in out Polygon_Array;
                                   Buffer   : in out Framebuffer) is
   begin
      if Polygons'Length = 0 then
         return;
      end if;

      -- Primary preliminary ordering by Max_Depth
      Sort_Polygons_Depth (Polygons);

      -- Refinement pass via pairwise priority checks
      for I in Polygons'First .. Polygons'Last - 1 loop
         for J in I + 1 .. Polygons'Last loop
            if not Polygons_Must_Precede (Polygons (I), Polygons (J)) and then
               Polygons_Must_Precede (Polygons (J), Polygons (I))
            then
               declare
                  T : constant Polygon := Polygons (I);
               begin
                  Polygons (I) := Polygons (J);
                  Polygons (J) := T;
               end;
            end if;
         end loop;
      end loop;

      for I in Polygons'Range loop
         Rasterize_Polygon (Polygons (I), Buffer);
      end loop;
   end Render_Newell_Sorted;

   ----------------------------------------------------------------------------
   -- Topological Sorting Variant with Cycle Detection
   ----------------------------------------------------------------------------

   procedure Render_Topological (Polygons : in Polygon_Array;
                                 Buffer   : in out Framebuffer) is
      N : constant Natural := Polygons'Length;

      -- Dynamic array types indexed over the actual polygon indices
      subtype Poly_Index is Positive range 1 .. (if N = 0 then 1 else N);
      type Dep_Matrix is array (Poly_Index, Poly_Index) of Boolean;
      type Count_Array is array (Poly_Index) of Natural;
      type Seen_Array is array (Poly_Index) of Boolean;

      Dep           : Dep_Matrix  := [others => [others => False]];
      In_Degree     : Count_Array := [others => 0];
      Processed     : Seen_Array  := [others => False];
      Total_Emitted : Natural     := 0;

      P_Idx, Q_Idx    : Poly_Index;
      Found_Candidate : Boolean;
   begin
      if N = 0 then
         return;
      end if;

      -- Construct dependency graph
      for I in Polygons'Range loop
         P_Idx := Poly_Index (I - Polygons'First + 1);
         for J in Polygons'Range loop
            if I /= J then
               Q_Idx := Poly_Index (J - Polygons'First + 1);
               if Bounding_Boxes_Overlap_2D (Polygons (I), Polygons (J)) and then
                  Centroid_Depth (Polygons (I)) > Centroid_Depth (Polygons (J))
               then
                  Dep (P_Idx, Q_Idx) := True;
                  In_Degree (Q_Idx)  := In_Degree (Q_Idx) + 1;
               end if;
            end if;
         end loop;
      end loop;

      -- Kahn's topological sort
      while Total_Emitted < N loop
         Found_Candidate := False;
         for K in 1 .. N loop
            if not Processed (K) and then In_Degree (K) = 0 then
               Found_Candidate := True;
               Processed (K) := True;
               Total_Emitted := Total_Emitted + 1;

               -- Render polygon K
               declare
                  Original_Idx : constant Positive := Polygons'First + K - 1;
               begin
                  Rasterize_Polygon (Polygons (Original_Idx), Buffer);
               end;

               -- Remove outgoing edges
               for M in 1 .. N loop
                  if Dep (K, M) then
                     Dep (K, M) := False;
                     In_Degree (M) := In_Degree (M) - 1;
                  end if;
               end loop;
               exit;
            end if;
         end loop;

         if not Found_Candidate then
            -- Graph contains a directed cycle (cyclic overlap)
            raise Cyclic_Overlap_Error;
         end if;
      end loop;
   end Render_Topological;

end Painter_Algorithm;
