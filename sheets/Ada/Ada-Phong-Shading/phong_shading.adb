--  Package Body: Phong_Shading
--  Implements Phong normal interpolation, classic reflection, Blinn-Phong
--  specular half-vector formulation, vector transformations, and color clamping.

package body Phong_Shading with SPARK_Mode => On is

   Epsilon : constant Real := 1.0e-7;

   --  Clamps a scalar Real into the valid range [0.0, 1.0]
   function Clamp_01 (Val : Real) return Intensity_Value with
     Global => null,
     Post   => Clamp_01'Result in 0.0 .. 1.0
   is
   begin
      if Val < 0.0 then
         return 0.0;
      elsif Val > 1.0 then
         return 1.0;
      else
         return Intensity_Value (Val);
      end if;
   end Clamp_01;

   --  Clamps a non-negative value: max(0, val)
   function Max_Zero (Val : Real) return Real with
     Global => null,
     Post   => Max_Zero'Result >= 0.0
   is
   begin
      if Val < 0.0 then
         return 0.0;
      else
         return Val;
      end if;
   end Max_Zero;

   --  Safe scalar power function: Base**Exp with non-negative base
   function Safe_Power (Base : Real; Exp : Shininess_Value) return Real with
     Global => null,
     Pre    => Base >= 0.0,
     Post   => Safe_Power'Result >= 0.0
   is
   begin
      if Base <= Epsilon then
         return 0.0;
      else
         return Real_Math."**" (Base, Real (Exp));
      end if;
   end Safe_Power;

   --  ========================================================================
   --  Vector Operations
   --  ========================================================================

   function "+" (Left, Right : Vector_3D) return Vector_3D is
   begin
      return (X => Left.X + Right.X,
              Y => Left.Y + Right.Y,
              Z => Left.Z + Right.Z);
   end "+";

   function "-" (Left, Right : Vector_3D) return Vector_3D is
   begin
      return (X => Left.X - Right.X,
              Y => Left.Y - Right.Y,
              Z => Left.Z - Right.Z);
   end "-";

   function "-" (V : Vector_3D) return Vector_3D is
   begin
      return (X => -V.X,
              Y => -V.Y,
              Z => -V.Z);
   end "-";

   function "*" (Scalar : Real; V : Vector_3D) return Vector_3D is
   begin
      return (X => Scalar * V.X,
              Y => Scalar * V.Y,
              Z => Scalar * V.Z);
   end "*";

   function Dot_Product (Left, Right : Vector_3D) return Real is
   begin
      return (Left.X * Right.X) + (Left.Y * Right.Y) + (Left.Z * Right.Z);
   end Dot_Product;

   function Cross_Product (Left, Right : Vector_3D) return Vector_3D is
   begin
      return (X => Left.Y * Right.Z - Left.Z * Right.Y,
              Y => Left.Z * Right.X - Left.X * Right.Z,
              Z => Left.X * Right.Y - Left.Y * Right.X);
   end Cross_Product;

   function Squared_Norm (V : Vector_3D) return Real is
   begin
      return Dot_Product (V, V);
   end Squared_Norm;

   function Norm (V : Vector_3D) return Real is
      Sq : constant Real := Squared_Norm (V);
   begin
      if Sq <= 0.0 then
         return 0.0;
      else
         return Real_Math.Sqrt (Sq);
      end if;
   end Norm;

   function Normalize (V : Vector_3D) return Unit_Vector_3D is
      Len : constant Real := Norm (V);
   begin
      if Len < Epsilon then
         raise Zero_Vector_Error with "Cannot normalize near-zero vector";
      end if;
      return (X => V.X / Len,
              Y => V.Y / Len,
              Z => V.Z / Len);
   end Normalize;

   --  R = 2 * (L . N) * N - L
   function Reflect
     (L : Unit_Vector_3D;
      N : Unit_Vector_3D) return Unit_Vector_3D
   is
      N_Dot_L : constant Real := Dot_Product (N, L);
      Ref     : constant Vector_3D := (2.0 * N_Dot_L) * N - L;
   begin
      return Normalize (Ref);
   end Reflect;

   --  H = Normalize(L + V)
   function Halfway_Vector
     (L : Unit_Vector_3D;
      V : Unit_Vector_3D) return Unit_Vector_3D
   is
      Sum : constant Vector_3D := L + V;
   begin
      return Normalize (Sum);
   end Halfway_Vector;

   --  ========================================================================
   --  Color Operations
   --  ========================================================================

   function Make_Color (R, G, B : Real) return Color_RGB is
   begin
      return (R => Clamp_01 (R),
              G => Clamp_01 (G),
              B => Clamp_01 (B));
   end Make_Color;

   function Add_Colors (C1, C2 : Color_RGB) return Color_RGB is
   begin
      return (R => Clamp_01 (Real (C1.R) + Real (C2.R)),
              G => Clamp_01 (Real (C1.G) + Real (C2.G)),
              B => Clamp_01 (Real (C1.B) + Real (C2.B)));
   end Add_Colors;

   function Modulate_Colors (C1, C2 : Color_RGB) return Color_RGB is
   begin
      return (R => Clamp_01 (Real (C1.R) * Real (C2.R)),
              G => Clamp_01 (Real (C1.G) * Real (C2.G)),
              B => Clamp_01 (Real (C1.B) * Real (C2.B)));
   end Modulate_Colors;

   function Scale_Color
     (C     : Color_RGB;
      Scale : Intensity_Value) return Color_RGB
   is
   begin
      return (R => Clamp_01 (Real (C.R) * Real (Scale)),
              G => Clamp_01 (Real (C.G) * Real (Scale)),
              B => Clamp_01 (Real (C.B) * Real (Scale)));
   end Scale_Color;

   --  ========================================================================
   --  Normal Interpolation
   --  ========================================================================

   function Interpolate_Normal
     (Normals    : Triangle_Normals;
      W0, W1, W2 : Real) return Unit_Vector_3D
   is
      Interp : Vector_3D;
   begin
      --  Validate barycentric coordinates non-negativity and partition of unity
      if W0 < -0.0001 or else W1 < -0.0001 or else W2 < -0.0001
        or else abs (W0 + W1 + W2 - 1.0) > 0.001
      then
         raise Invalid_Barycentric_Coord with "Barycentric coords sum to 1";
      end if;

      Interp := (W0 * Normals.N0) + (W1 * Normals.N1) + (W2 * Normals.N2);

      if Norm (Interp) < Epsilon then
         raise Degenerate_Normal_Error with "Interpolated normal has zero norm";
      end if;

      return Normalize (Interp);
   end Interpolate_Normal;

   --  ========================================================================
   --  Attenuation Helper
   --  ========================================================================

   function Compute_Attenuation
     (Distance : Real;
      Atten    : Light_Attenuation) return Real
   is
      Denom : constant Real :=
        Real (Atten.Constant_Term) +
        Real (Atten.Linear_Term) * Distance +
        Real (Atten.Quadratic_Term) * (Distance * Distance);
   begin
      if Denom <= Epsilon then
         return 1.0;
      else
         return 1.0 / Denom;
      end if;
   end Compute_Attenuation;

   --  ========================================================================
   --  Illumination Models Implementation
   --  ========================================================================

   function Classic_Phong_Light
     (Surface_Pos   : Vector_3D;
      Normal        : Unit_Vector_3D;
      View_Dir      : Unit_Vector_3D;
      Light         : Point_Light;
      Material      : Material_Properties;
      Ambient_Light : Color_RGB) return Color_RGB
   is
      Light_Vec  : constant Vector_3D := Light.Position - Surface_Pos;
      Dist       : constant Real := Norm (Light_Vec);
      L          : Unit_Vector_3D;
      Atten      : Real;
      N_Dot_L    : Real;
      Diff_Fact  : Real;
      Spec_Fact  : Real := 0.0;
      R          : Unit_Vector_3D;
      R_Dot_V    : Real;

      Amb_Comp   : Color_RGB;
      Diff_Comp  : Color_RGB;
      Spec_Comp  : Color_RGB;
      Total_R    : Real;
      Total_G    : Real;
      Total_B    : Real;
   begin
      if Dist < Epsilon then
         L := Normal;
         Atten := 1.0;
      else
         L := Normalize (Light_Vec);
         Atten := Compute_Attenuation (Dist, Light.Attenuation);
      end if;

      --  Ambient Component: I_a = k_a * C_a * L_a
      Amb_Comp := Scale_Color
        (Modulate_Colors (Material.Ambient_Color, Ambient_Light),
         Material.Ambient_Coeff);

      N_Dot_L := Dot_Product (Normal, L);
      Diff_Fact := Max_Zero (N_Dot_L);

      --  Specular is only present if light hits the front of the surface
      if Diff_Fact > 0.0 then
         R := Reflect (L, Normal);
         R_Dot_V := Dot_Product (R, View_Dir);
         Spec_Fact := Safe_Power (Max_Zero (R_Dot_V), Material.Shininess);
      end if;

      --  Diffuse Component: I_d = k_d * (N . L) * C_d * L_c
      Diff_Comp := Modulate_Colors (Material.Diffuse_Color, Light.Color);

      --  Specular Component: I_s = k_s * (R . V)^alpha * C_s * L_c
      Spec_Comp := Modulate_Colors (Material.Specular_Color, Light.Color);

      Total_R := Real (Amb_Comp.R) + Atten *
        (Real (Material.Diffuse_Coeff) * Diff_Fact * Real (Diff_Comp.R) +
         Real (Material.Specular_Coeff) * Spec_Fact * Real (Spec_Comp.R));

      Total_G := Real (Amb_Comp.G) + Atten *
        (Real (Material.Diffuse_Coeff) * Diff_Fact * Real (Diff_Comp.G) +
         Real (Material.Specular_Coeff) * Spec_Fact * Real (Spec_Comp.G));

      Total_B := Real (Amb_Comp.B) + Atten *
        (Real (Material.Diffuse_Coeff) * Diff_Fact * Real (Diff_Comp.B) +
         Real (Material.Specular_Coeff) * Spec_Fact * Real (Spec_Comp.B));

      return Make_Color (Total_R, Total_G, Total_B);
   end Classic_Phong_Light;

   function Blinn_Phong_Light
     (Surface_Pos   : Vector_3D;
      Normal        : Unit_Vector_3D;
      View_Dir      : Unit_Vector_3D;
      Light         : Point_Light;
      Material      : Material_Properties;
      Ambient_Light : Color_RGB) return Color_RGB
   is
      Light_Vec : constant Vector_3D := Light.Position - Surface_Pos;
      Dist      : constant Real := Norm (Light_Vec);
      L         : Unit_Vector_3D;
      Atten     : Real;
      N_Dot_L   : Real;
      Diff_Fact : Real;
      Spec_Fact : Real := 0.0;
      H         : Unit_Vector_3D;
      N_Dot_H   : Real;

      Amb_Comp  : Color_RGB;
      Diff_Comp : Color_RGB;
      Spec_Comp : Color_RGB;
      Total_R   : Real;
      Total_G   : Real;
      Total_B   : Real;
   begin
      if Dist < Epsilon then
         L := Normal;
         Atten := 1.0;
      else
         L := Normalize (Light_Vec);
         Atten := Compute_Attenuation (Dist, Light.Attenuation);
      end if;

      Amb_Comp := Scale_Color
        (Modulate_Colors (Material.Ambient_Color, Ambient_Light),
         Material.Ambient_Coeff);

      N_Dot_L := Dot_Product (Normal, L);
      Diff_Fact := Max_Zero (N_Dot_L);

      --  Blinn-Phong calculates the halfway vector H = (L + V) / |L + V|
      if Diff_Fact > 0.0 then
         H := Halfway_Vector (L, View_Dir);
         N_Dot_H := Dot_Product (Normal, H);
         Spec_Fact := Safe_Power (Max_Zero (N_Dot_H), Material.Shininess);
      end if;

      Diff_Comp := Modulate_Colors (Material.Diffuse_Color, Light.Color);
      Spec_Comp := Modulate_Colors (Material.Specular_Color, Light.Color);

      Total_R := Real (Amb_Comp.R) + Atten *
        (Real (Material.Diffuse_Coeff) * Diff_Fact * Real (Diff_Comp.R) +
         Real (Material.Specular_Coeff) * Spec_Fact * Real (Spec_Comp.R));

      Total_G := Real (Amb_Comp.G) + Atten *
        (Real (Material.Diffuse_Coeff) * Diff_Fact * Real (Diff_Comp.G) +
         Real (Material.Specular_Coeff) * Spec_Fact * Real (Spec_Comp.G));

      Total_B := Real (Amb_Comp.B) + Atten *
        (Real (Material.Diffuse_Coeff) * Diff_Fact * Real (Diff_Comp.B) +
         Real (Material.Specular_Coeff) * Spec_Fact * Real (Spec_Comp.B));

      return Make_Color (Total_R, Total_G, Total_B);
   end Blinn_Phong_Light;

   function Classic_Phong_Directional
     (Normal        : Unit_Vector_3D;
      View_Dir      : Unit_Vector_3D;
      Light         : Directional_Light;
      Material      : Material_Properties;
      Ambient_Light : Color_RGB) return Color_RGB
   is
      --  Directional light specifies incoming rays: L points toward the light
      L         : constant Unit_Vector_3D := Normalize (-Light.Direction);
      N_Dot_L   : constant Real := Dot_Product (Normal, L);
      Diff_Fact : constant Real := Max_Zero (N_Dot_L);
      Spec_Fact : Real := 0.0;
      R         : Unit_Vector_3D;
      R_Dot_V   : Real;

      Amb_Comp  : Color_RGB;
      Diff_Comp : Color_RGB;
      Spec_Comp : Color_RGB;
   begin
      Amb_Comp := Scale_Color
        (Modulate_Colors (Material.Ambient_Color, Ambient_Light),
         Material.Ambient_Coeff);

      if Diff_Fact > 0.0 then
         R := Reflect (L, Normal);
         R_Dot_V := Dot_Product (R, View_Dir);
         Spec_Fact := Safe_Power (Max_Zero (R_Dot_V), Material.Shininess);
      end if;

      Diff_Comp := Modulate_Colors (Material.Diffuse_Color, Light.Color);
      Spec_Comp := Modulate_Colors (Material.Specular_Color, Light.Color);

      return Make_Color
        (Real (Amb_Comp.R) +
           Real (Material.Diffuse_Coeff) * Diff_Fact * Real (Diff_Comp.R) +
           Real (Material.Specular_Coeff) * Spec_Fact * Real (Spec_Comp.R),
         Real (Amb_Comp.G) +
           Real (Material.Diffuse_Coeff) * Diff_Fact * Real (Diff_Comp.G) +
           Real (Material.Specular_Coeff) * Spec_Fact * Real (Spec_Comp.G),
         Real (Amb_Comp.B) +
           Real (Material.Diffuse_Coeff) * Diff_Fact * Real (Diff_Comp.B) +
           Real (Material.Specular_Coeff) * Spec_Fact * Real (Spec_Comp.B));
   end Classic_Phong_Directional;

   function Blinn_Phong_Directional
     (Normal        : Unit_Vector_3D;
      View_Dir      : Unit_Vector_3D;
      Light         : Directional_Light;
      Material      : Material_Properties;
      Ambient_Light : Color_RGB) return Color_RGB
   is
      L         : constant Unit_Vector_3D := Normalize (-Light.Direction);
      N_Dot_L   : constant Real := Dot_Product (Normal, L);
      Diff_Fact : constant Real := Max_Zero (N_Dot_L);
      Spec_Fact : Real := 0.0;
      H         : Unit_Vector_3D;
      N_Dot_H   : Real;

      Amb_Comp  : Color_RGB;
      Diff_Comp : Color_RGB;
      Spec_Comp : Color_RGB;
   begin
      Amb_Comp := Scale_Color
        (Modulate_Colors (Material.Ambient_Color, Ambient_Light),
         Material.Ambient_Coeff);

      if Diff_Fact > 0.0 then
         H := Halfway_Vector (L, View_Dir);
         N_Dot_H := Dot_Product (Normal, H);
         Spec_Fact := Safe_Power (Max_Zero (N_Dot_H), Material.Shininess);
      end if;

      Diff_Comp := Modulate_Colors (Material.Diffuse_Color, Light.Color);
      Spec_Comp := Modulate_Colors (Material.Specular_Color, Light.Color);

      return Make_Color
        (Real (Amb_Comp.R) +
           Real (Material.Diffuse_Coeff) * Diff_Fact * Real (Diff_Comp.R) +
           Real (Material.Specular_Coeff) * Spec_Fact * Real (Spec_Comp.R),
         Real (Amb_Comp.G) +
           Real (Material.Diffuse_Coeff) * Diff_Fact * Real (Diff_Comp.G) +
           Real (Material.Specular_Coeff) * Spec_Fact * Real (Spec_Comp.G),
         Real (Amb_Comp.B) +
           Real (Material.Diffuse_Coeff) * Diff_Fact * Real (Diff_Comp.B) +
           Real (Material.Specular_Coeff) * Spec_Fact * Real (Spec_Comp.B));
   end Blinn_Phong_Directional;

end Phong_Shading;
