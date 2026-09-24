--  Package body for Gouraud Shading
--  Compliant with Ada 2022 / Ada 2023 (ISO/IEC 8652:2023)

with Ada.Numerics.Generic_Elementary_Functions;

package body Gouraud_Shading with SPARK_Mode => Off is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   --  -------------------------------------------------------------
   --  Helper Implementations
   --  -------------------------------------------------------------

   function Dot_Product (U, V : Vector_3D) return Real is
   begin
      return (U.X * V.X) + (U.Y * V.Y) + (U.Z * V.Z);
   end Dot_Product;

   function Vector_Length (V : Vector_3D) return Real is
      Sum_Squares : constant Real := Dot_Product (V, V);
   begin
      if Sum_Squares <= 0.0 then
         return 0.0;
      else
         return Sqrt (Sum_Squares);
      end if;
   end Vector_Length;

   function Normalize (V : Vector_3D) return Vector_3D is
      Len : constant Real := Vector_Length (V);
   begin
      if Len <= 1.0e-9 then
         raise Invalid_Normal_Error with "Vector has zero or near-zero length";
      end if;
      return (X => V.X / Len, Y => V.Y / Len, Z => V.Z / Len);
   end Normalize;

   function Cross_Product (U, V : Vector_3D) return Vector_3D is
   begin
      return (X => (U.Y * V.Z) - (U.Z * V.Y),
              Y => (U.Z * V.X) - (U.X * V.Z),
              Z => (U.X * V.Y) - (U.Y * V.X));
   end Cross_Product;

   function Add_Colors (C1, C2 : RGB_Color) return RGB_Color is
      R_Sum : constant Real := Real (C1.R) + Real (C2.R);
      G_Sum : constant Real := Real (C1.G) + Real (C2.G);
      B_Sum : constant Real := Real (C1.B) + Real (C2.B);
   begin
      return (R => Color_Component (Real'Min (1.0, Real'Max (0.0, R_Sum))),
              G => Color_Component (Real'Min (1.0, Real'Max (0.0, G_Sum))),
              B => Color_Component (Real'Min (1.0, Real'Max (0.0, B_Sum))));
   end Add_Colors;

   function Scale_Color (C : RGB_Color; Factor : Real) return RGB_Color is
      R_Val : constant Real := Real (C.R) * Factor;
      G_Val : constant Real := Real (C.G) * Factor;
      B_Val : constant Real := Real (C.B) * Factor;
   begin
      return (R => Color_Component (Real'Min (1.0, Real'Max (0.0, R_Val))),
              G => Color_Component (Real'Min (1.0, Real'Max (0.0, G_Val))),
              B => Color_Component (Real'Min (1.0, Real'Max (0.0, B_Val))));
   end Scale_Color;

   function Multiply_Colors (C1, C2 : RGB_Color) return RGB_Color is
   begin
      return (R => Color_Component (Real (C1.R) * Real (C2.R)),
              G => Color_Component (Real (C1.G) * Real (C2.G)),
              B => Color_Component (Real (C1.B) * Real (C2.B)));
   end Multiply_Colors;

   function Clamp_Color (C : RGB_Color) return RGB_Color is
   begin
      return (R => Color_Component (Real'Min (1.0, Real'Max (0.0, Real (C.R)))),
              G => Color_Component (Real'Min (1.0, Real'Max (0.0, Real (C.G)))),
              B => Color_Component (Real'Min (1.0, Real'Max (0.0, Real (C.B)))));
   end Clamp_Color;

   function Clamp_Intensity (Val : Real) return Intensity is
   begin
      return Intensity (Real'Min (1.0, Real'Max (0.0, Val)));
   end Clamp_Intensity;

   function Lerp_Intensity (I1, I2 : Intensity; T : Real) return Intensity is
      Val : constant Real := Real (I1) + (Real (I2) - Real (I1)) * T;
   begin
      return Clamp_Intensity (Val);
   end Lerp_Intensity;

   function Lerp_Color (C1, C2 : RGB_Color; T : Real) return RGB_Color is
      R_Val : constant Real := Real (C1.R) + (Real (C2.R) - Real (C1.R)) * T;
      G_Val : constant Real := Real (C1.G) + (Real (C2.G) - Real (C1.G)) * T;
      B_Val : constant Real := Real (C1.B) + (Real (C2.B) - Real (C1.B)) * T;
   begin
      return (R => Color_Component (Real'Min (1.0, Real'Max (0.0, R_Val))),
              G => Color_Component (Real'Min (1.0, Real'Max (0.0, G_Val))),
              B => Color_Component (Real'Min (1.0, Real'Max (0.0, B_Val))));
   end Lerp_Color;

   --  -------------------------------------------------------------
   --  Variant 1: Vertex Normal Averaging
   --  -------------------------------------------------------------

   function Compute_Vertex_Normals
     (Vertices  : Vertex_3D_Array;
      Triangles : Triangle_Index_Array) return Vector_3D_Array
   is
      Result_Normals : Vector_3D_Array (Vertices'Range) :=
        [others => (X => 0.0, Y => 0.0, Z => 0.0)];
   begin
      for Tri of Triangles loop
         if Tri.V1 not in Vertices'Range or else
            Tri.V2 not in Vertices'Range or else
            Tri.V3 not in Vertices'Range
         then
            raise Constraint_Error with "Triangle index out of vertex array bounds";
         end if;

         declare
            P1 : constant Vector_3D := Vertices (Tri.V1).Pos;
            P2 : constant Vector_3D := Vertices (Tri.V2).Pos;
            P3 : constant Vector_3D := Vertices (Tri.V3).Pos;

            Edge1 : constant Vector_3D :=
              (X => P2.X - P1.X, Y => P2.Y - P1.Y, Z => P2.Z - P1.Z);
            Edge2 : constant Vector_3D :=
              (X => P3.X - P1.X, Y => P3.Y - P1.Y, Z => P3.Z - P1.Z);

            Face_Normal : constant Vector_3D := Cross_Product (Edge1, Edge2);
         begin
            --  Accumulate unnormalized face normal to weight by polygon area
            Result_Normals (Tri.V1) :=
              (X => Result_Normals (Tri.V1).X + Face_Normal.X,
               Y => Result_Normals (Tri.V1).Y + Face_Normal.Y,
               Z => Result_Normals (Tri.V1).Z + Face_Normal.Z);

            Result_Normals (Tri.V2) :=
              (X => Result_Normals (Tri.V2).X + Face_Normal.X,
               Y => Result_Normals (Tri.V2).Y + Face_Normal.Y,
               Z => Result_Normals (Tri.V2).Z + Face_Normal.Z);

            Result_Normals (Tri.V3) :=
              (X => Result_Normals (Tri.V3).X + Face_Normal.X,
               Y => Result_Normals (Tri.V3).Y + Face_Normal.Y,
               Z => Result_Normals (Tri.V3).Z + Face_Normal.Z);
         end;
      end loop;

      --  Normalize accumulated normals
      for I in Result_Normals'Range loop
         if Vector_Length (Result_Normals (I)) > 1.0e-9 then
            Result_Normals (I) := Normalize (Result_Normals (I));
         else
            --  Fall back to existing normal or default Z
            if Vector_Length (Vertices (I).Normal) > 1.0e-9 then
               Result_Normals (I) := Normalize (Vertices (I).Normal);
            else
               Result_Normals (I) := (X => 0.0, Y => 0.0, Z => 1.0);
            end if;
         end if;
      end loop;

      return Result_Normals;
   end Compute_Vertex_Normals;

   --  -------------------------------------------------------------
   --  Variant 2: Vertex Illumination Calculation
   --  -------------------------------------------------------------

   function Calculate_Vertex_Lambert_Intensity
     (Surface_Normal : Vector_3D;
      Light_Dir      : Vector_3D;
      Ambient        : Intensity := 0.1;
      Diffuse        : Intensity := 0.9) return Intensity
   is
      Norm_N : constant Vector_3D := Normalize (Surface_Normal);
      Norm_L : constant Vector_3D := Normalize (Light_Dir);
      N_Dot_L : constant Real := Dot_Product (Norm_N, Norm_L);
      Diff_Term : constant Real := Real'Max (0.0, N_Dot_L);
      Total : constant Real := Real (Ambient) + Real (Diffuse) * Diff_Term;
   begin
      return Clamp_Intensity (Total);
   end Calculate_Vertex_Lambert_Intensity;

   function Calculate_Vertex_Phong_Color
     (Position       : Vector_3D;
      Normal         : Vector_3D;
      View_Pos       : Vector_3D;
      Light_Pos      : Vector_3D;
      Light_Color    : RGB_Color;
      Material_Color : RGB_Color;
      Ka             : Real := 0.1;
      Kd             : Real := 0.7;
      Ks             : Real := 0.2;
      Shininess      : Real := 32.0) return RGB_Color
   is
      N : constant Vector_3D := Normalize (Normal);
      L_Unnorm : constant Vector_3D :=
        (X => Light_Pos.X - Position.X,
         Y => Light_Pos.Y - Position.Y,
         Z => Light_Pos.Z - Position.Z);
      V_Unnorm : constant Vector_3D :=
        (X => View_Pos.X - Position.X,
         Y => View_Pos.Y - Position.Y,
         Z => View_Pos.Z - Position.Z);

      L : constant Vector_3D := Normalize (L_Unnorm);
      V : constant Vector_3D := Normalize (V_Unnorm);

      --  Halfway vector for Blinn-Phong
      H_Unnorm : constant Vector_3D :=
        (X => L.X + V.X, Y => L.Y + V.Y, Z => L.Z + V.Z);
      H : constant Vector_3D := Normalize (H_Unnorm);

      N_Dot_L : constant Real := Real'Max (0.0, Dot_Product (N, L));
      N_Dot_H : constant Real := Real'Max (0.0, Dot_Product (N, H));

      Spec_Factor : Real := 0.0;
   begin
      if N_Dot_L > 0.0 and then N_Dot_H > 0.0 then
         Spec_Factor := N_Dot_H ** Shininess;
      end if;

      --  Compute Ambient, Diffuse, Specular components
      declare
         Ambient_Color : constant RGB_Color :=
           Scale_Color (Multiply_Colors (Material_Color, Light_Color), Ka);

         Diffuse_Color : constant RGB_Color :=
           Scale_Color (Multiply_Colors (Material_Color, Light_Color), Kd * N_Dot_L);

         Specular_Color : constant RGB_Color :=
           Scale_Color (Light_Color, Ks * Spec_Factor);
      begin
         return Add_Colors (Add_Colors (Ambient_Color, Diffuse_Color), Specular_Color);
      end;
   end Calculate_Vertex_Phong_Color;

   --  -------------------------------------------------------------
   --  Variant 3: Analytical Barycentric Gouraud Interpolation
   --  -------------------------------------------------------------

   function Barycentric_Weights
     (V1, V2, V3 : Vertex_2D;
      P          : Vertex_2D;
      W1, W2, W3 : out Real) return Boolean
   is
      Denom : constant Real :=
        (V2.Y - V3.Y) * (V1.X - V3.X) + (V3.X - V2.X) * (V1.Y - V3.Y);
   begin
      if abs (Denom) < 1.0e-9 then
         W1 := 0.0;
         W2 := 0.0;
         W3 := 0.0;
         return False;
      end if;

      W1 := ((V2.Y - V3.Y) * (P.X - V3.X) + (V3.X - V2.X) * (P.Y - V3.Y)) / Denom;
      W2 := ((V3.Y - V1.Y) * (P.X - V3.X) + (V1.X - V3.X) * (P.Y - V3.Y)) / Denom;
      W3 := 1.0 - W1 - W2;

      return True;
   end Barycentric_Weights;

   function Interpolate_Barycentric_Intensity
     (V1, V2, V3 : Shaded_Vertex_Scalar;
      P          : Vertex_2D) return Intensity
   is
      W1, W2, W3 : Real;
      Success : constant Boolean :=
        Barycentric_Weights (V1.Pos, V2.Pos, V3.Pos, P, W1, W2, W3);
   begin
      if not Success then
         raise Degenerate_Triangle_Error with "Triangle area is zero or collinear";
      end if;

      declare
         Interp_Val : constant Real :=
           W1 * Real (V1.Intensity) +
           W2 * Real (V2.Intensity) +
           W3 * Real (V3.Intensity);
      begin
         return Clamp_Intensity (Interp_Val);
      end;
   end Interpolate_Barycentric_Intensity;

   function Interpolate_Barycentric_Color
     (V1, V2, V3 : Shaded_Vertex_RGB;
      P          : Vertex_2D) return RGB_Color
   is
      W1, W2, W3 : Real;
      Success : constant Boolean :=
        Barycentric_Weights (V1.Pos, V2.Pos, V3.Pos, P, W1, W2, W3);
   begin
      if not Success then
         raise Degenerate_Triangle_Error with "Triangle area is zero or collinear";
      end if;

      declare
         R_Val : constant Real :=
           W1 * Real (V1.Color.R) + W2 * Real (V2.Color.R) + W3 * Real (V3.Color.R);
         G_Val : constant Real :=
           W1 * Real (V1.Color.G) + W2 * Real (V2.Color.G) + W3 * Real (V3.Color.G);
         B_Val : constant Real :=
           W1 * Real (V1.Color.B) + W2 * Real (V2.Color.B) + W3 * Real (V3.Color.B);
      begin
         return (R => Color_Component (Real'Min (1.0, Real'Max (0.0, R_Val))),
                 G => Color_Component (Real'Min (1.0, Real'Max (0.0, G_Val))),
                 B => Color_Component (Real'Min (1.0, Real'Max (0.0, B_Val))));
      end;
   end Interpolate_Barycentric_Color;

   --  -------------------------------------------------------------
   --  Variant 4: Scanline Gouraud Rasterization (Scalar Intensity)
   --  -------------------------------------------------------------

   procedure Rasterize_Triangle_Scalar
     (V1, V2, V3 : Shaded_Vertex_Scalar;
      Buffer     : in out Framebuffer;
      Base_Color : RGB_Color := (R => 1.0, G => 1.0, B => 1.0))
   is
      C1 : constant RGB_Color := Scale_Color (Base_Color, Real (V1.Intensity));
      C2 : constant RGB_Color := Scale_Color (Base_Color, Real (V2.Intensity));
      C3 : constant RGB_Color := Scale_Color (Base_Color, Real (V3.Intensity));

      RGB_V1 : constant Shaded_Vertex_RGB := (Pos => V1.Pos, Color => C1);
      RGB_V2 : constant Shaded_Vertex_RGB := (Pos => V2.Pos, Color => C2);
      RGB_V3 : constant Shaded_Vertex_RGB := (Pos => V3.Pos, Color => C3);
   begin
      Rasterize_Triangle_RGB (RGB_V1, RGB_V2, RGB_V3, Buffer);
   end Rasterize_Triangle_Scalar;

   --  -------------------------------------------------------------
   --  Variant 5: Scanline Gouraud Rasterization (Full RGB Colors)
   --  -------------------------------------------------------------

   procedure Rasterize_Triangle_RGB
     (V1, V2, V3 : Shaded_Vertex_RGB;
      Buffer     : in out Framebuffer)
   is
      A : Shaded_Vertex_RGB := V1;
      B : Shaded_Vertex_RGB := V2;
      C : Shaded_Vertex_RGB := V3;

      procedure Swap (X, Y : in out Shaded_Vertex_RGB) is
         Tmp : constant Shaded_Vertex_RGB := X;
      begin
         X := Y;
         Y := Tmp;
      end Swap;

      procedure Draw_Scanline
        (Y : Integer;
         X_Start, X_End : Real;
         C_Start, C_End : RGB_Color)
      is
         Actual_X_Start : Real := X_Start;
         Actual_X_End   : Real := X_End;
         Actual_C_Start : RGB_Color := C_Start;
         Actual_C_End   : RGB_Color := C_End;
      begin
         if Y not in Buffer'Range (1) then
            return;
         end if;

         if Actual_X_Start > Actual_X_End then
            declare
               Tmp_X : constant Real := Actual_X_Start;
               Tmp_C : constant RGB_Color := Actual_C_Start;
            begin
               Actual_X_Start := Actual_X_End;
               Actual_X_End   := Tmp_X;
               Actual_C_Start := Actual_C_End;
               Actual_C_End   := Tmp_C;
            end;
         end if;

         declare
            Min_X : constant Integer := Integer'Max (Buffer'First (2), Integer (Real'Floor (Actual_X_Start)));
            Max_X : constant Integer := Integer'Min (Buffer'Last (2), Integer (Real'Ceiling (Actual_X_End)));
            Span_Dist : constant Real := Actual_X_End - Actual_X_Start;
         begin
            for X in Min_X .. Max_X loop
               declare
                  T : Real := 0.0;
               begin
                  if Span_Dist > 1.0e-7 then
                     T := (Real (X) - Actual_X_Start) / Span_Dist;
                     T := Real'Min (1.0, Real'Max (0.0, T));
                  end if;
                  Buffer (Y, X) := Lerp_Color (Actual_C_Start, Actual_C_End, T);
               end;
            end loop;
         end;
      end Draw_Scanline;

   begin
      --  Sort vertices by Y ascending (A.Y <= B.Y <= C.Y)
      if A.Pos.Y > B.Pos.Y then
         Swap (A, B);
      end if;
      if A.Pos.Y > C.Pos.Y then
         Swap (A, C);
      end if;
      if B.Pos.Y > C.Pos.Y then
         Swap (B, C);
      end if;

      --  Check for degenerate triangle (zero height)
      if abs (C.Pos.Y - A.Pos.Y) < 1.0e-7 then
         return;
      end if;

      declare
         Y_Start : constant Integer := Integer'Max (Buffer'First (1), Integer (Real'Floor (A.Pos.Y)));
         Y_End   : constant Integer := Integer'Min (Buffer'Last (1), Integer (Real'Ceiling (C.Pos.Y)));
         Total_Height : constant Real := C.Pos.Y - A.Pos.Y;
      begin
         for Y_Current in Y_Start .. Y_End loop
            declare
               Y_Real : constant Real := Real (Y_Current);
               Second_Half : constant Boolean :=
                 Y_Real > B.Pos.Y or else abs (B.Pos.Y - A.Pos.Y) < 1.0e-7;
               Segment_Height : constant Real :=
                 (if Second_Half then C.Pos.Y - B.Pos.Y else B.Pos.Y - A.Pos.Y);

               Alpha : constant Real :=
                 Real'Min (1.0, Real'Max (0.0, (Y_Real - A.Pos.Y) / Total_Height));

               Beta : Real := 0.0;

               X_A : Real;
               X_B : Real;
               Col_A : RGB_Color;
               Col_B : RGB_Color;
            begin
               if Segment_Height > 1.0e-7 then
                  Beta := (if Second_Half
                           then (Y_Real - B.Pos.Y) / Segment_Height
                           else (Y_Real - A.Pos.Y) / Segment_Height);
                  Beta := Real'Min (1.0, Real'Max (0.0, Beta));
               end if;

               --  Interpolate along long edge A->C
               X_A := A.Pos.X + (C.Pos.X - A.Pos.X) * Alpha;
               Col_A := Lerp_Color (A.Color, C.Color, Alpha);

               --  Interpolate along split edge A->B or B->C
               if Second_Half then
                  X_B := B.Pos.X + (C.Pos.X - B.Pos.X) * Beta;
                  Col_B := Lerp_Color (B.Color, C.Color, Beta);
               else
                  X_B := A.Pos.X + (B.Pos.X - A.Pos.X) * Beta;
                  Col_B := Lerp_Color (A.Color, B.Color, Beta);
               end if;

               Draw_Scanline (Y_Current, X_A, X_B, Col_A, Col_B);
            end;
         end loop;
      end;
   end Rasterize_Triangle_RGB;

end Gouraud_Shading;
