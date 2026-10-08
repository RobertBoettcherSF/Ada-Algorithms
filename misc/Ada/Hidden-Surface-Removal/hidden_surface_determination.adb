with Ada.Numerics.Generic_Elementary_Functions;

package body Hidden_Surface_Determination with
  SPARK_Mode => Off
is

   package Float_Math is new Ada.Numerics.Generic_Elementary_Functions (Float);

   function Min_Coord (A, B, C : Coordinate) return Coordinate is
      M : Coordinate := A;
   begin
      if B < M then
         M := B;
      end if;
      if C < M then
         M := C;
      end if;
      return M;
   end Min_Coord;

   function Max_Coord (A, B, C : Coordinate) return Coordinate is
      M : Coordinate := A;
   begin
      if B > M then
         M := B;
      end if;
      if C > M then
         M := C;
      end if;
      return M;
   end Max_Coord;

   function Cross_Product (U, V : Vector_3D) return Vector_3D is
   begin
      return
        (X => Coordinate (Float (U.Y) * Float (V.Z) - Float (U.Z) * Float (V.Y)),
         Y => Coordinate (Float (U.Z) * Float (V.X) - Float (U.X) * Float (V.Z)),
         Z => Coordinate (Float (U.X) * Float (V.Y) - Float (U.Y) * Float (V.X)));
   end Cross_Product;

   function Dot_Product (U, V : Vector_3D) return Coordinate is
   begin
      return Coordinate
        (Float (U.X) * Float (V.X) +
         Float (U.Y) * Float (V.Y) +
         Float (U.Z) * Float (V.Z));
   end Dot_Product;

   function Vector_Magnitude (V : Vector_3D) return Coordinate is
      Sum : constant Float :=
        Float (V.X) ** 2 + Float (V.Y) ** 2 + Float (V.Z) ** 2;
   begin
      return Coordinate (Float_Math.Sqrt (Sum));
   end Vector_Magnitude;

   function Normalize (V : Vector_3D) return Vector_3D is
      Mag : constant Coordinate := Vector_Magnitude (V);
   begin
      if Mag < 0.00001 then
         raise Zero_Vector_Error with "Vector magnitude is zero";
      end if;
      return
        (X => Coordinate (Float (V.X) / Float (Mag)),
         Y => Coordinate (Float (V.Y) / Float (Mag)),
         Z => Coordinate (Float (V.Z) / Float (Mag)));
   end Normalize;

   function Compute_Normal (T : Triangle) return Vector_3D is
      Edge1 : constant Vector_3D :=
        (X => T.V1.X - T.V0.X,
         Y => T.V1.Y - T.V0.Y,
         Z => Coordinate (Float (T.V1.Z) - Float (T.V0.Z)));
      Edge2 : constant Vector_3D :=
        (X => T.V2.X - T.V0.X,
         Y => T.V2.Y - T.V0.Y,
         Z => Coordinate (Float (T.V2.Z) - Float (T.V0.Z)));
      Cross : constant Vector_3D := Cross_Product (Edge1, Edge2);
   begin
      if Vector_Magnitude (Cross) < 0.00001 then
         raise Invalid_Triangle_Error with "Collinear triangle points";
      end if;
      return Normalize (Cross);
   end Compute_Normal;

   function Barycentric_Coordinates
     (P, A, B, C : Point_3D;
      W0, W1, W2 : out Float) return Boolean
   is
      V0X : constant Float := Float (B.X - A.X);
      V0Y : constant Float := Float (B.Y - A.Y);
      V1X : constant Float := Float (C.X - A.X);
      V1Y : constant Float := Float (C.Y - A.Y);
      V2X : constant Float := Float (P.X - A.X);
      V2Y : constant Float := Float (P.Y - A.Y);

      Denom : constant Float := V0X * V1Y - V1X * V0Y;
   begin
      if abs (Denom) < 0.000001 then
         W0 := 0.0;
         W1 := 0.0;
         W2 := 0.0;
         return False;
      end if;

      declare
         Inv_Denom : constant Float := 1.0 / Denom;
         V : constant Float := (V2X * V1Y - V1X * V2Y) * Inv_Denom;
         W : constant Float := (V0X * V2Y - V2X * V0Y) * Inv_Denom;
         U : constant Float := 1.0 - V - W;
      begin
         W0 := U;
         W1 := V;
         W2 := W;
         return (U >= -0.0001 and then V >= -0.0001 and then W >= -0.0001);
      end;
   end Barycentric_Coordinates;

   function Intersect_Ray_Triangle
     (R : Ray;
      T : Triangle) return Intersection_Result
   is
      No_Hit : constant Intersection_Result :=
        (Hit       => False,
         Depth     => Depth_Value'Last,
         Hit_Poly  => No_Polygon,
         Hit_Color => Color_Black);

      E1 : constant Vector_3D :=
        (X => T.V1.X - T.V0.X,
         Y => T.V1.Y - T.V0.Y,
         Z => Coordinate (Float (T.V1.Z) - Float (T.V0.Z)));
      E2 : constant Vector_3D :=
        (X => T.V2.X - T.V0.X,
         Y => T.V2.Y - T.V0.Y,
         Z => Coordinate (Float (T.V2.Z) - Float (T.V0.Z)));
      Pvec : constant Vector_3D := Cross_Product (R.Direction, E2);
      Det  : constant Float := Float (Dot_Product (E1, Pvec));
   begin
      if abs (Det) < 0.000001 then
         return No_Hit;
      end if;

      declare
         Inv_Det : constant Float := 1.0 / Det;
         Tvec : constant Vector_3D :=
           (X => R.Origin.X - T.V0.X,
            Y => R.Origin.Y - T.V0.Y,
            Z => Coordinate (Float (R.Origin.Z) - Float (T.V0.Z)));
         U : constant Float := Float (Dot_Product (Tvec, Pvec)) * Inv_Det;
      begin
         if U < 0.0 or else U > 1.0 then
            return No_Hit;
         end if;

         declare
            Qvec : constant Vector_3D := Cross_Product (Tvec, E1);
            V    : constant Float :=
              Float (Dot_Product (R.Direction, Qvec)) * Inv_Det;
         begin
            if V < 0.0 or else (U + V) > 1.0 then
               return No_Hit;
            end if;

            declare
               Dist : constant Float :=
                 Float (Dot_Product (E2, Qvec)) * Inv_Det;
            begin
               if Dist < 0.0 or else Dist > 1.0 then
                  return No_Hit;
               end if;

               return
                 (Hit       => True,
                  Depth     => Depth_Value (Dist),
                  Hit_Poly  => T.Id,
                  Hit_Color => T.Color);
            end;
         end;
      end;
   end Intersect_Ray_Triangle;

   function Is_Back_Face
     (T            : Triangle;
      View_Vector  : Vector_3D) return Boolean
   is
      Normal : constant Vector_3D := Compute_Normal (T);
      Dot    : constant Coordinate := Dot_Product (Normal, View_Vector);
   begin
      -- Back-facing when surface normal points away from viewer
      return Dot > 0.0;
   end Is_Back_Face;

   procedure Cull_Back_Faces
     (Input_Triangles  : Triangle_Array;
      View_Vector      : Vector_3D;
      Output_Triangles : out Triangle_Array;
      Output_Count     : out Natural)
   is
      Current_Index : Positive := Output_Triangles'First;
   begin
      Output_Count := 0;
      for I in Input_Triangles'Range loop
         if not Is_Back_Face (Input_Triangles (I), View_Vector) then
            Output_Triangles (Current_Index) := Input_Triangles (I);
            Output_Count := Output_Count + 1;
            if Current_Index < Output_Triangles'Last then
               Current_Index := Current_Index + 1;
            end if;
         end if;
      end loop;
   end Cull_Back_Faces;

   function Max_Z (T : Triangle) return Depth_Value is
      M : Depth_Value := T.V0.Z;
   begin
      if T.V1.Z > M then
         M := T.V1.Z;
      end if;
      if T.V2.Z > M then
         M := T.V2.Z;
      end if;
      return M;
   end Max_Z;

   procedure Sort_Polygons_By_Depth
     (Triangles : in out Triangle_Array;
      Ascending : Boolean := True)
   is
      -- Insertion sort for small/moderate polygon lists
      Temp : Triangle;
      J    : Integer;
   begin
      if Triangles'Length <= 1 then
         return;
      end if;

      for I in Triangles'First + 1 .. Triangles'Last loop
         Temp := Triangles (I);
         J := I - 1;

         while J >= Triangles'First loop
            declare
               Condition : Boolean;
            begin
               if Ascending then
                  Condition := Max_Z (Triangles (J)) > Max_Z (Temp);
               else
                  Condition := Max_Z (Triangles (J)) < Max_Z (Temp);
               end if;

               if Condition then
                  Triangles (J + 1) := Triangles (J);
                  J := J - 1;
               else
                  exit;
               end if;
            end;
         end loop;
         Triangles (J + 1) := Temp;
      end loop;
   end Sort_Polygons_By_Depth;

   procedure Render_Painters
     (Triangles : Triangle_Array;
      FB        : in out Framebuffer)
   is
      Sorted : Triangle_Array := Triangles;
      W0, W1, W2 : Float;
      Inside : Boolean;
   begin
      -- Painter's algorithm renders from furthest (largest Z) to nearest (smallest Z)
      Sort_Polygons_By_Depth (Sorted, Ascending => False);

      for T_Idx in Sorted'Range loop
         declare
            T : Triangle renames Sorted (T_Idx);
            Min_X_Coord : constant Coordinate := Min_Coord (T.V0.X, T.V1.X, T.V2.X);
            Max_X_Coord : constant Coordinate := Max_Coord (T.V0.X, T.V1.X, T.V2.X);
            Min_Y_Coord : constant Coordinate := Min_Coord (T.V0.Y, T.V1.Y, T.V2.Y);
            Max_Y_Coord : constant Coordinate := Max_Coord (T.V0.Y, T.V1.Y, T.V2.Y);

            Min_PX : constant Screen_X := Screen_X'Max
              (FB'First(1), Screen_X (Float'Max (0.0, Float (Min_X_Coord))));
            Max_PX : constant Screen_X := Screen_X'Min
              (FB'Last(1), Screen_X (Float'Min (Float (Screen_X'Last), Float (Max_X_Coord))));
            Min_PY : constant Screen_Y := Screen_Y'Max
              (FB'First(2), Screen_Y (Float'Max (0.0, Float (Min_Y_Coord))));
            Max_PY : constant Screen_Y := Screen_Y'Min
              (FB'Last(2), Screen_Y (Float'Min (Float (Screen_Y'Last), Float (Max_Y_Coord))));
         begin
            if Min_PX <= Max_PX and then Min_PY <= Max_PY then
               for Y in Min_PY .. Max_PY loop
                  for X in Min_PX .. Max_PX loop
                     Inside := Barycentric_Coordinates
                       (Point_3D'(X => Coordinate (X), Y => Coordinate (Y), Z => 0.0),
                        T.V0, T.V1, T.V2, W0, W1, W2);
                     if Inside then
                        FB (X, Y) := T.Color;
                     end if;
                  end loop;
               end loop;
            end if;
         end;
      end loop;
   end Render_Painters;

   procedure Clear_Buffers
     (FB    : in out Framebuffer;
      ZB    : in out Depth_Buffer;
      Clear : Color_Type := Color_Black)
   is
   begin
      for Y in FB'Range(2) loop
         for X in FB'Range(1) loop
            FB (X, Y) := Clear;
            ZB (X, Y) := Depth_Value'Last;
         end loop;
      end loop;
   end Clear_Buffers;

   procedure Render_Z_Buffer
     (Triangles : Triangle_Array;
      FB        : in out Framebuffer;
      ZB        : in out Depth_Buffer)
   is
      W0, W1, W2 : Float;
      Inside     : Boolean;
      Interpolated_Z : Float;
   begin
      for T_Idx in Triangles'Range loop
         declare
            T : Triangle renames Triangles (T_Idx);
            Min_X_Coord : constant Coordinate := Min_Coord (T.V0.X, T.V1.X, T.V2.X);
            Max_X_Coord : constant Coordinate := Max_Coord (T.V0.X, T.V1.X, T.V2.X);
            Min_Y_Coord : constant Coordinate := Min_Coord (T.V0.Y, T.V1.Y, T.V2.Y);
            Max_Y_Coord : constant Coordinate := Max_Coord (T.V0.Y, T.V1.Y, T.V2.Y);

            Min_PX : constant Screen_X := Screen_X'Max
              (FB'First(1), Screen_X (Float'Max (0.0, Float (Min_X_Coord))));
            Max_PX : constant Screen_X := Screen_X'Min
              (FB'Last(1), Screen_X (Float'Min (Float (Screen_X'Last), Float (Max_X_Coord))));
            Min_PY : constant Screen_Y := Screen_Y'Max
              (FB'First(2), Screen_Y (Float'Max (0.0, Float (Min_Y_Coord))));
            Max_PY : constant Screen_Y := Screen_Y'Min
              (FB'Last(2), Screen_Y (Float'Min (Float (Screen_Y'Last), Float (Max_Y_Coord))));
         begin
            if Min_PX <= Max_PX and then Min_PY <= Max_PY then
               for Y in Min_PY .. Max_PY loop
                  for X in Min_PX .. Max_PX loop
                     Inside := Barycentric_Coordinates
                       (Point_3D'(X => Coordinate (X), Y => Coordinate (Y), Z => 0.0),
                        T.V0, T.V1, T.V2, W0, W1, W2);
                     if Inside then
                        Interpolated_Z :=
                          W0 * Float (T.V0.Z) +
                          W1 * Float (T.V1.Z) +
                          W2 * Float (T.V2.Z);

                        if Interpolated_Z >= 0.0 and then Interpolated_Z <= 1.0 then
                           if Depth_Value (Interpolated_Z) < ZB (X, Y) then
                              ZB (X, Y) := Depth_Value (Interpolated_Z);
                              FB (X, Y) := T.Color;
                           end if;
                        end if;
                     end if;
                  end loop;
               end loop;
            end if;
         end;
      end loop;
   end Render_Z_Buffer;

   procedure Render_Ray_Casting
     (Triangles : Triangle_Array;
      FB        : in out Framebuffer;
      Eye_Point : Point_3D)
   is
   begin
      for Y in FB'Range(2) loop
         for X in FB'Range(1) loop
            declare
               Ray_Vec : constant Vector_3D :=
                 (X => Coordinate (X) - Eye_Point.X,
                  Y => Coordinate (Y) - Eye_Point.Y,
                  Z => 1.0);
               Dir : constant Vector_3D := Normalize (Ray_Vec);
               R : constant Ray :=
                 (Origin    => Eye_Point,
                  Direction => Dir);
               Nearest_Hit : Intersection_Result :=
                 (Hit       => False,
                  Depth     => Depth_Value'Last,
                  Hit_Poly  => No_Polygon,
                  Hit_Color => Color_Black);
            begin
               for T_Idx in Triangles'Range loop
                  declare
                     Res : constant Intersection_Result :=
                       Intersect_Ray_Triangle (R, Triangles (T_Idx));
                  begin
                     if Res.Hit and then Res.Depth < Nearest_Hit.Depth then
                        Nearest_Hit := Res;
                     end if;
                  end;
               end loop;

               if Nearest_Hit.Hit then
                  FB (X, Y) := Nearest_Hit.Hit_Color;
               end if;
            end;
         end loop;
      end loop;
   end Render_Ray_Casting;

   procedure Render_Scanline_Z_Buffer
     (Triangles : Triangle_Array;
      FB        : in out Framebuffer;
      ZB        : in out Depth_Buffer)
   is
      -- Scanline Z-buffer evaluates one horizontal scanline Y across all active triangles
      W0, W1, W2 : Float;
      Inside     : Boolean;
      Interpolated_Z : Float;
   begin
      for Y in FB'Range(2) loop
         -- Scanline loop: evaluate each pixel on line Y
         for X in FB'Range(1) loop
            for T_Idx in Triangles'Range loop
               declare
                  T : Triangle renames Triangles (T_Idx);
                  Min_Y : constant Coordinate := Min_Coord (T.V0.Y, T.V1.Y, T.V2.Y);
                  Max_Y : constant Coordinate := Max_Coord (T.V0.Y, T.V1.Y, T.V2.Y);
               begin
                  if Coordinate (Y) >= Min_Y and then Coordinate (Y) <= Max_Y then
                     Inside := Barycentric_Coordinates
                       (Point_3D'(X => Coordinate (X), Y => Coordinate (Y), Z => 0.0),
                        T.V0, T.V1, T.V2, W0, W1, W2);
                     if Inside then
                        Interpolated_Z :=
                          W0 * Float (T.V0.Z) +
                          W1 * Float (T.V1.Z) +
                          W2 * Float (T.V2.Z);

                        if Interpolated_Z >= 0.0 and then Interpolated_Z <= 1.0 then
                           if Depth_Value (Interpolated_Z) < ZB (X, Y) then
                              ZB (X, Y) := Depth_Value (Interpolated_Z);
                              FB (X, Y) := T.Color;
                           end if;
                        end if;
                     end if;
                  end if;
               end;
            end loop;
         end loop;
      end loop;
   end Render_Scanline_Z_Buffer;

end Hidden_Surface_Determination;
