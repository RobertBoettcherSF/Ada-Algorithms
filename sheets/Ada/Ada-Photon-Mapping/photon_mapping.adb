with Ada.Numerics.Generic_Elementary_Functions;

package body Photon_Mapping with SPARK_Mode => On is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   PI : constant Real := 3.14159265358979323846;

   function Dot (A, B : Vector_3D) return Real is
   begin
      return (A.X * B.X) + (A.Y * B.Y) + (A.Z * B.Z);
   end Dot;

   function Norm_Sq (V : Vector_3D) return Real is
   begin
      return Dot (V, V);
   end Norm_Sq;

   function Norm (V : Vector_3D) return Real is
   begin
      return Sqrt (Norm_Sq (V));
   end Norm;

   function Normalize (V : Vector_3D) return Vector_3D is
      N : constant Real := Norm (V);
   begin
      return (X => V.X / N, Y => V.Y / N, Z => V.Z / N);
   end Normalize;

   function Vector_Add (A, B : Vector_3D) return Vector_3D is
   begin
      return (X => A.X + B.X, Y => A.Y + B.Y, Z => A.Z + B.Z);
   end Vector_Add;

   function Vector_Sub (A, B : Vector_3D) return Vector_3D is
   begin
      return (X => A.X - B.X, Y => A.Y - B.Y, Z => A.Z - B.Z);
   end Vector_Sub;

   function Vector_Scale (V : Vector_3D; S : Real) return Vector_3D is
   begin
      return (X => V.X * S, Y => V.Y * S, Z => V.Z * S);
   end Vector_Scale;

   function Distance_Sq (A, B : Vector_3D) return Real is
   begin
      return Norm_Sq (Vector_Sub (A, B));
   end Distance_Sq;

   function Spectral_Add (A, B : Spectral_Power) return Spectral_Power is
   begin
      return (R => A.R + B.R, G => A.G + B.G, B => A.B + B.B);
   end Spectral_Add;

   function Spectral_Scale (S : Spectral_Power; Factor : Real) return Spectral_Power is
   begin
      return (R => S.R * Factor, G => S.G * Factor, B => S.B * Factor);
   end Spectral_Scale;

   function Intersect_Sphere
     (R : Ray; S : Sphere; Hit_Point : out Vector_3D; Normal : out Vector_3D) return Boolean is
      OC   : constant Vector_3D := Vector_Sub (R.Origin, S.Center);
      A    : constant Real      := Norm_Sq (R.Direction);
      B    : constant Real      := 2.0 * Dot (OC, R.Direction);
      C    : constant Real      := Norm_Sq (OC) - (S.Radius * S.Radius);
      Disc : constant Real      := (B * B) - (4.0 * A * C);
      T0   : Real;
      T1   : Real;
      T    : Real;
   begin
      Hit_Point := (others => 0.0);
      Normal    := (others => 0.0);

      if Disc < 0.0 or else A = 0.0 then
         return False;
      end if;

      T0 := (-B - Sqrt (Disc)) / (2.0 * A);
      T1 := (-B + Sqrt (Disc)) / (2.0 * A);

      if T0 > 0.0001 then
         T := T0;
      elsif T1 > 0.0001 then
         T := T1;
      else
         return False;
      end if;

      Hit_Point := Vector_Add (R.Origin, Vector_Scale (R.Direction, T));
      Normal    := Normalize (Vector_Sub (Hit_Point, S.Center));
      return True;
   end Intersect_Sphere;

   function Russian_Roulette
     (Mat : Surface_Material; Random_Val : Real) return Surface_Interaction is
      P_Diff : constant Real := Mat.Diffuse_Reflectance;
      P_Spec : constant Real := P_Diff + Mat.Specular_Reflectance;
   begin
      if Random_Val < P_Diff then
         return Diffuse;
      elsif Random_Val < P_Spec then
         return Specular;
      else
         return Absorbed;
      end if;
   end Russian_Roulette;

   function Trace_Photon_Path
     (Initial_Ray : Ray;
      Power       : Spectral_Power;
      Scene_Obj   : Sphere;
      Random_Val  : Real) return Photon is
      Hit_Pt : Vector_3D;
      Norm_V : Vector_3D;
      Hit    : constant Boolean := Intersect_Sphere (Initial_Ray, Scene_Obj, Hit_Pt, Norm_V);
      Event  : Surface_Interaction;
   begin
      if not Hit then
         return (Position => (others => 0.0),
                 Power    => (others => 0.0),
                 Incident => (others => 0.0),
                 Plane    => 0);
      end if;

      Event := Russian_Roulette (Scene_Obj.Material, Random_Val);
      case Event is
         when Diffuse =>
            return (Position => Hit_Pt,
                    Power    => Power,
                    Incident => Initial_Ray.Direction,
                    Plane    => 0);
         when Specular =>
            declare
               Refl_Dir : constant Vector_3D :=
                 Vector_Sub (Initial_Ray.Direction,
                             Vector_Scale (Norm_V, 2.0 * Dot (Initial_Ray.Direction, Norm_V)));
            begin
               return (Position => Hit_Pt,
                       Power    => Power,
                       Incident => Refl_Dir,
                       Plane    => 0);
            end;
         when Absorbed =>
            return (Position => Hit_Pt,
                    Power    => (others => 0.0),
                    Incident => Initial_Ray.Direction,
                    Plane    => 0);
      end case;
   end Trace_Photon_Path;

   function Get_Coord (P : Vector_3D; Axis : Natural) return Real is
   begin
      case Axis is
         when 0      => return P.X;
         when 1      => return P.Y;
         when others => return P.Z;
      end case;
   end Get_Coord;

   procedure Build_Kd_Tree (Tree : in out Kd_Tree) is
      procedure Median_Split (Left, Right : Positive; Depth : Natural) is
         Axis   : constant Natural := Depth mod 3;
         Mid    : constant Positive := (Left + Right) / 2;
         Tmp    : Photon;
         J      : Positive;
      begin
         if Left >= Right then
            if Left <= Tree.Length then
               Tree.Photons (Left).Plane := Axis;
            end if;
            return;
         end if;

         for I in Left + 1 .. Right loop
            Tmp := Tree.Photons (I);
            J := I;
            while J > Left and then Get_Coord (Tree.Photons (J - 1).Position, Axis) > Get_Coord (Tmp.Position, Axis) loop
               Tree.Photons (J) := Tree.Photons (J - 1);
               J := J - 1;
            end loop;
            Tree.Photons (J) := Tmp;
         end loop;

         Tree.Photons (Mid).Plane := Axis;

         if Left < Mid then
            Median_Split (Left, Mid - 1, Depth + 1);
         end if;
         if Mid < Right then
            Median_Split (Mid + 1, Right, Depth + 1);
         end if;
      end Median_Split;
   begin
      if Tree.Length > 1 then
         Median_Split (1, Tree.Length, 0);
      elsif Tree.Length = 1 then
         Tree.Photons (1).Plane := 0;
      end if;
   end Build_Kd_Tree;

   procedure Insert_Query_Result
     (Res      : in out Query_Result;
      P        : Photon;
      Dist_Sq  : Real;
      Capacity : Positive) is
      Insert_Pos : Positive;
   begin
      if Res.Count < Capacity then
         Res.Count := Res.Count + 1;
         Insert_Pos := Res.Count;
         while Insert_Pos > 1 and then Res.Distances_Sq (Insert_Pos - 1) < Dist_Sq loop
            Res.Photons (Insert_Pos) := Res.Photons (Insert_Pos - 1);
            Res.Distances_Sq (Insert_Pos) := Res.Distances_Sq (Insert_Pos - 1);
            Insert_Pos := Insert_Pos - 1;
         end loop;
         Res.Photons (Insert_Pos) := P;
         Res.Distances_Sq (Insert_Pos) := Dist_Sq;
         
         if Res.Count = Capacity then
            Res.Max_Distance_Sq := Res.Distances_Sq (1);
         end if;
      elsif Dist_Sq < Res.Max_Distance_Sq then
         Res.Photons (1) := P;
         Res.Distances_Sq (1) := Dist_Sq;
         Insert_Pos := 1;
         while Insert_Pos < Res.Count and then Res.Distances_Sq (Insert_Pos) < Res.Distances_Sq (Insert_Pos + 1) loop
            declare
               Tmp_P : constant Photon := Res.Photons (Insert_Pos);
               Tmp_D : constant Real   := Res.Distances_Sq (Insert_Pos);
            begin
               Res.Photons (Insert_Pos) := Res.Photons (Insert_Pos + 1);
               Res.Distances_Sq (Insert_Pos) := Res.Distances_Sq (Insert_Pos + 1);
               Res.Photons (Insert_Pos + 1) := Tmp_P;
               Res.Distances_Sq (Insert_Pos + 1) := Tmp_D;
            end;
            Insert_Pos := Insert_Pos + 1;
         end loop;
         Res.Max_Distance_Sq := Res.Distances_Sq (1);
      end if;
   end Insert_Query_Result;

   procedure Locate_Photons
     (Tree        : Kd_Tree;
      Center      : Vector_3D;
      Max_Count   : Positive;
      Max_Dist_Sq : Real;
      Result      : out Query_Result) is
      procedure Search (Index : Positive) is
         Axis       : Natural;
         Diff_Coord : Real;
         Dist_Sq    : Real;
         Left       : constant Positive := Index * 2;
         Right      : constant Positive := (Index * 2) + 1;
      begin
         if Index > Tree.Length then
            return;
         end if;

         Dist_Sq := Distance_Sq (Tree.Photons (Index).Position, Center);
         if Dist_Sq <= Result.Max_Distance_Sq then
            Insert_Query_Result (Result, Tree.Photons (Index), Dist_Sq, Max_Count);
         end if;

         Axis := Tree.Photons (Index).Plane;
         Diff_Coord := Get_Coord (Center, Axis) - Get_Coord (Tree.Photons (Index).Position, Axis);

         if Diff_Coord < 0.0 then
            Search (Left);
            if (Diff_Coord * Diff_Coord) < Result.Max_Distance_Sq then
               Search (Right);
            end if;
         else
            Search (Right);
            if (Diff_Coord * Diff_Coord) < Result.Max_Distance_Sq then
               Search (Left);
            end if;
         end if;
      end Search;
   begin
      Result.Count := 0;
      Result.Max_Distance_Sq := Max_Dist_Sq;
      if Tree.Length > 0 then
         Search (1);
      end if;
   end Locate_Photons;

   function Estimate_Radiance_Surface
     (Tree        : Kd_Tree;
      Point       : Vector_3D;
      Normal      : Vector_3D;
      Max_Photons : Positive;
      Max_Dist_Sq : Real;
      Filter      : Filter_Kind) return Spectral_Power is
      Actual_Cap : constant Positive := Positive'Min (Max_Photons, Tree.Capacity + 1);
      Res        : Query_Result (Actual_Cap);
      Accum      : Spectral_Power := (0.0, 0.0, 0.0);
      R_Sq       : Real;
      Area       : Real;
      Norm_Dir   : Vector_3D;
      Cos_Theta  : Real;
      Weight     : Real := 1.0;
      Total_W    : Real := 0.0;
   begin
      if Tree.Length = 0 then
         return Accum;
      end if;

      Norm_Dir := Normalize (Normal);
      Locate_Photons (Tree, Point, Actual_Cap, Max_Dist_Sq, Res);

      if Res.Count = 0 then
         return Accum;
      end if;

      R_Sq := Res.Max_Distance_Sq;
      if R_Sq <= 0.000001 then
         return Accum;
      end if;

      for I in 1 .. Res.Count loop
         Cos_Theta := -Dot (Res.Photons (I).Incident, Norm_Dir);
         if Cos_Theta > 0.0 then
            case Filter is
               when Constant_Filter =>
                  Weight := 1.0;
               when Linear_Filter =>
                  declare
                     D : constant Real := Sqrt (Res.Distances_Sq (I));
                     R : constant Real := Sqrt (R_Sq);
                  begin
                     Weight := 1.0 - (D / (1.1 * R));
                     if Weight < 0.0 then
                        Weight := 0.0;
                     end if;
                  end;
               when Gaussian_Filter =>
                  declare
                     Alpha : constant Real := 0.918;
                     Beta  : constant Real := 1.953;
                     D_Sq  : constant Real := Res.Distances_Sq (I);
                  begin
                     Weight := Alpha * (1.0 - ((1.0 - Exp (-Beta * D_Sq / (2.0 * R_Sq))) /
                                              (1.0 - Exp (-Beta))));
                     if Weight < 0.0 then
                        Weight := 0.0;
                     end if;
                  end;
            end case;

            Accum := Spectral_Add (Accum, Spectral_Scale (Res.Photons (I).Power, Cos_Theta * Weight));
            Total_W := Total_W + Weight;
         end if;
      end loop;

      Area := PI * R_Sq;
      if Area > 0.0 and then Total_W > 0.0 then
         case Filter is
            when Constant_Filter =>
               Accum := Spectral_Scale (Accum, 1.0 / Area);
            when Linear_Filter | Gaussian_Filter =>
               Accum := Spectral_Scale (Accum, (1.0 / Area) * (Real (Res.Count) / Total_W));
         end case;
      end if;

      return Accum;
   end Estimate_Radiance_Surface;

   function Estimate_Radiance_Volume
     (Tree        : Kd_Tree;
      Point       : Vector_3D;
      Medium      : Medium_Properties;
      Max_Photons : Positive;
      Max_Dist_Sq : Real) return Spectral_Power is
      Actual_Cap : constant Positive := Positive'Min (Max_Photons, Tree.Capacity + 1);
      Res        : Query_Result (Actual_Cap);
      Accum      : Spectral_Power := (0.0, 0.0, 0.0);
      R          : Real;
      Volume     : Real;
   begin
      if Tree.Length = 0 or else Medium.Scattering_Coeff <= 0.0 then
         return Accum;
      end if;

      Locate_Photons (Tree, Point, Actual_Cap, Max_Dist_Sq, Res);

      if Res.Count = 0 or else Res.Max_Distance_Sq <= 0.000001 then
         return Accum;
      end if;

      R := Sqrt (Res.Max_Distance_Sq);
      Volume := (4.0 / 3.0) * PI * (R * R * R);

      for I in 1 .. Res.Count loop
         Accum := Spectral_Add (Accum, Res.Photons (I).Power);
      end loop;

      if Volume > 0.0 then
         Accum := Spectral_Scale (Accum, Medium.Scattering_Coeff / Volume);
      end if;

      return Accum;
   end Estimate_Radiance_Volume;

   function Combine_Two_Pass
     (Direct_Light     : Spectral_Power;
      Specular_Light   : Spectral_Power;
      Caustic_Estimate : Spectral_Power;
      Global_Estimate  : Spectral_Power) return Spectral_Power is
      Total : Spectral_Power := (0.0, 0.0, 0.0);
   begin
      Total := Spectral_Add (Direct_Light, Specular_Light);
      Total := Spectral_Add (Total, Caustic_Estimate);
      Total := Spectral_Add (Total, Global_Estimate);
      return Total;
   end Combine_Two_Pass;

end Photon_Mapping;
