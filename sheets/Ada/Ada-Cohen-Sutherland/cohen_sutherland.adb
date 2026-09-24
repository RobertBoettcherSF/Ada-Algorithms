--  Cohen_Sutherland body — window/box helpers, outcodes, trivial
--  accept/reject, Clip_Against_Edge, classic 2-D clip loop, 3-D lite
--  clip, and Liang–Barsky lite reference.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Cohen_Sutherland
  with SPARK_Mode => Off
is

   -----------------------------------------------------------------------
   -- Internal numeric helpers
   -----------------------------------------------------------------------

   function Sqrt_Safe (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      else
         return Real (Sqrt (Float (X)));
      end if;
   end Sqrt_Safe;

   function Clamp (V, Lo, Hi : Real) return Real is
   begin
      if V < Lo then
         return Lo;
      elsif V > Hi then
         return Hi;
      else
         return V;
      end if;
   end Clamp;

   function Accepted (A, B : Vec2) return Clip_Result is
   begin
      return (Status => Clip_Accept, Clipped => (A, B));
   end Accepted;

   function Rejected return Clip_Result is
   begin
      return (Status => Clip_Reject, Clipped => ((0.0, 0.0), (0.0, 0.0)));
   end Rejected;

   function Accepted3 (A, B : Vec3) return Clip_Result_3D is
   begin
      return (Status => Clip_Accept, Clipped => (A, B));
   end Accepted3;

   function Rejected3 return Clip_Result_3D is
   begin
      return
        (Status  => Clip_Reject,
         Clipped => ((0.0, 0.0, 0.0), (0.0, 0.0, 0.0)));
   end Rejected3;

   -----------------------------------------------------------------------
   -- Vector helpers (2-D)
   -----------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Point (A, B : Vec2; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Near_Point;

   function Near_Point (A, B : Vec3; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol)
        and then Near (A.Y, B.Y, Tol)
        and then Near (A.Z, B.Z, Tol);
   end Near_Point;

   function "-" (A, B : Vec2) return Vec2 is
   begin
      return (A.X - B.X, A.Y - B.Y);
   end "-";

   function "+" (A, B : Vec2) return Vec2 is
   begin
      return (A.X + B.X, A.Y + B.Y);
   end "+";

   function "*" (S : Real; V : Vec2) return Vec2 is
   begin
      return (S * V.X, S * V.Y);
   end "*";

   function Dot (A, B : Vec2) return Real is
   begin
      return A.X * B.X + A.Y * B.Y;
   end Dot;

   -----------------------------------------------------------------------
   -- Vector helpers (3-D)
   -----------------------------------------------------------------------

   function "-" (A, B : Vec3) return Vec3 is
   begin
      return (A.X - B.X, A.Y - B.Y, A.Z - B.Z);
   end "-";

   function "+" (A, B : Vec3) return Vec3 is
   begin
      return (A.X + B.X, A.Y + B.Y, A.Z + B.Z);
   end "+";

   function "*" (S : Real; V : Vec3) return Vec3 is
   begin
      return (S * V.X, S * V.Y, S * V.Z);
   end "*";

   function Dot (A, B : Vec3) return Real is
   begin
      return A.X * B.X + A.Y * B.Y + A.Z * B.Z;
   end Dot;

   -----------------------------------------------------------------------
   -- Segment / point helpers
   -----------------------------------------------------------------------

   function Make_Segment (P0, P1 : Vec2) return Segment is
   begin
      return (P0, P1);
   end Make_Segment;

   function Make_Segment (P0, P1 : Vec3) return Segment3 is
   begin
      return (P0, P1);
   end Make_Segment;

   function Length (S : Segment) return Non_Negative is
      D : constant Vec2 := S.P1 - S.P0;
   begin
      return Sqrt_Safe (D.X * D.X + D.Y * D.Y);
   end Length;

   function Length (S : Segment3) return Non_Negative is
      D : constant Vec3 := S.P1 - S.P0;
   begin
      return Sqrt_Safe (D.X * D.X + D.Y * D.Y + D.Z * D.Z);
   end Length;

   function Point_Inside_Window
     (P : Vec2; W : Clip_Window) return Boolean
   is
   begin
      return P.X >= W.X_Min - Epsilon
        and then P.X <= W.X_Max + Epsilon
        and then P.Y >= W.Y_Min - Epsilon
        and then P.Y <= W.Y_Max + Epsilon;
   end Point_Inside_Window;

   function Point_Inside_Box
     (P : Vec3; B : Clip_Box) return Boolean
   is
   begin
      return P.X >= B.X_Min - Epsilon
        and then P.X <= B.X_Max + Epsilon
        and then P.Y >= B.Y_Min - Epsilon
        and then P.Y <= B.Y_Max + Epsilon
        and then P.Z >= B.Z_Min - Epsilon
        and then P.Z <= B.Z_Max + Epsilon;
   end Point_Inside_Box;

   function Same_Clipped_Segment
     (A, B : Segment; Tol : Real := Epsilon) return Boolean
   is
   begin
      return
        (Near_Point (A.P0, B.P0, Tol) and then Near_Point (A.P1, B.P1, Tol))
        or else
        (Near_Point (A.P0, B.P1, Tol) and then Near_Point (A.P1, B.P0, Tol));
   end Same_Clipped_Segment;

   function Same_Clipped_Segment
     (A, B : Segment3; Tol : Real := Epsilon) return Boolean
   is
   begin
      return
        (Near_Point (A.P0, B.P0, Tol) and then Near_Point (A.P1, B.P1, Tol))
        or else
        (Near_Point (A.P0, B.P1, Tol) and then Near_Point (A.P1, B.P0, Tol));
   end Same_Clipped_Segment;

   -----------------------------------------------------------------------
   -- Window / box construction
   -----------------------------------------------------------------------

   function Is_Valid_Window (W : Clip_Window) return Boolean is
   begin
      return W.X_Max > W.X_Min and then W.Y_Max > W.Y_Min;
   end Is_Valid_Window;

   function Make_Window
     (X_Min, Y_Min, X_Max, Y_Max : Real) return Clip_Window
   is
   begin
      if not (X_Max > X_Min and then Y_Max > Y_Min) then
         raise Invalid_Argument with "Make_Window requires positive extents";
      end if;
      return (X_Min, Y_Min, X_Max, Y_Max);
   end Make_Window;

   function Is_Valid_Box (B : Clip_Box) return Boolean is
   begin
      return B.X_Max > B.X_Min
        and then B.Y_Max > B.Y_Min
        and then B.Z_Max > B.Z_Min;
   end Is_Valid_Box;

   function Make_Box
     (X_Min, Y_Min, Z_Min, X_Max, Y_Max, Z_Max : Real) return Clip_Box
   is
   begin
      if not (X_Max > X_Min
              and then Y_Max > Y_Min
              and then Z_Max > Z_Min)
      then
         raise Invalid_Argument with "Make_Box requires positive extents";
      end if;
      return (X_Min, Y_Min, Z_Min, X_Max, Y_Max, Z_Max);
   end Make_Box;

   -----------------------------------------------------------------------
   -- Compute_OutCode (2-D / 3-D)
   -----------------------------------------------------------------------

   function Compute_OutCode
     (P : Vec2; W : Clip_Window) return Out_Code
   is
      C : Out_Code := 0;
   begin
      if P.X < W.X_Min then
         C := C or Bit_Left;
      elsif P.X > W.X_Max then
         C := C or Bit_Right;
      end if;
      if P.Y < W.Y_Min then
         C := C or Bit_Bottom;
      elsif P.Y > W.Y_Max then
         C := C or Bit_Top;
      end if;
      return C;
   end Compute_OutCode;

   function Compute_OutCode
     (P : Vec3; B : Clip_Box) return Out_Code_3D
   is
      C : Out_Code_3D := 0;
   begin
      if P.X < B.X_Min then
         C := C or Bit3_Left;
      elsif P.X > B.X_Max then
         C := C or Bit3_Right;
      end if;
      if P.Y < B.Y_Min then
         C := C or Bit3_Bottom;
      elsif P.Y > B.Y_Max then
         C := C or Bit3_Top;
      end if;
      if P.Z < B.Z_Min then
         C := C or Bit3_Near;
      elsif P.Z > B.Z_Max then
         C := C or Bit3_Far;
      end if;
      return C;
   end Compute_OutCode;

   -----------------------------------------------------------------------
   -- Trivial_Accept / Trivial_Reject
   -----------------------------------------------------------------------

   function Trivial_Accept (Code0, Code1 : Out_Code) return Boolean is
   begin
      return (Code0 or Code1) = 0;
   end Trivial_Accept;

   function Trivial_Reject (Code0, Code1 : Out_Code) return Boolean is
   begin
      return (Code0 and Code1) /= 0;
   end Trivial_Reject;

   function Trivial_Accept (Code0, Code1 : Out_Code_3D) return Boolean is
   begin
      return (Code0 or Code1) = 0;
   end Trivial_Accept;

   function Trivial_Reject (Code0, Code1 : Out_Code_3D) return Boolean is
   begin
      return (Code0 and Code1) /= 0;
   end Trivial_Reject;

   -----------------------------------------------------------------------
   -- Clip_Against_Edge
   -----------------------------------------------------------------------

   function Clip_Against_Edge
     (S : Segment; W : Clip_Window; Edge : Window_Edge) return Vec2
   is
      DX : constant Real := S.P1.X - S.P0.X;
      DY : constant Real := S.P1.Y - S.P0.Y;
      T  : Real;
   begin
      case Edge is
         when Left_Edge =>
            if Near (DX, 0.0) then
               raise Degenerate_Geometry
                 with "Clip_Against_Edge: parallel to left";
            end if;
            T := (W.X_Min - S.P0.X) / DX;
            return (W.X_Min, S.P0.Y + T * DY);

         when Right_Edge =>
            if Near (DX, 0.0) then
               raise Degenerate_Geometry
                 with "Clip_Against_Edge: parallel to right";
            end if;
            T := (W.X_Max - S.P0.X) / DX;
            return (W.X_Max, S.P0.Y + T * DY);

         when Bottom_Edge =>
            if Near (DY, 0.0) then
               raise Degenerate_Geometry
                 with "Clip_Against_Edge: parallel to bottom";
            end if;
            T := (W.Y_Min - S.P0.Y) / DY;
            return (S.P0.X + T * DX, W.Y_Min);

         when Top_Edge =>
            if Near (DY, 0.0) then
               raise Degenerate_Geometry
                 with "Clip_Against_Edge: parallel to top";
            end if;
            T := (W.Y_Max - S.P0.Y) / DY;
            return (S.P0.X + T * DX, W.Y_Max);
      end case;
   end Clip_Against_Edge;

   -----------------------------------------------------------------------
   -- Cohen_Sutherland_Clip (classic iterative 2-D)
   -----------------------------------------------------------------------

   function Cohen_Sutherland_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      X0 : Real := S.P0.X;
      Y0 : Real := S.P0.Y;
      X1 : Real := S.P1.X;
      Y1 : Real := S.P1.Y;
      C0 : Out_Code := Compute_OutCode ((X0, Y0), W);
      C1 : Out_Code := Compute_OutCode ((X1, Y1), W);
      C_Out : Out_Code;
      X, Y  : Real;
      Accept_Flag : Boolean := False;
      Done        : Boolean := False;
      Steps       : Natural := 0;
   begin
      loop
         if Trivial_Accept (C0, C1) then
            Accept_Flag := True;
            Done := True;
         elsif Trivial_Reject (C0, C1) then
            Done := True;
         else
            Steps := Steps + 1;
            if Steps > 8 then
               Done := True;
            else
               --  Pick an outside endpoint (prefer C0 when both outside).
               C_Out := (if C0 /= 0 then C0 else C1);

               --  Intersect with one crossed edge (Top > Bottom > Right > Left).
               if (C_Out and Bit_Top) /= 0 then
                  X := X0 + (X1 - X0) * (W.Y_Max - Y0) / (Y1 - Y0);
                  Y := W.Y_Max;
               elsif (C_Out and Bit_Bottom) /= 0 then
                  X := X0 + (X1 - X0) * (W.Y_Min - Y0) / (Y1 - Y0);
                  Y := W.Y_Min;
               elsif (C_Out and Bit_Right) /= 0 then
                  Y := Y0 + (Y1 - Y0) * (W.X_Max - X0) / (X1 - X0);
                  X := W.X_Max;
               else
                  Y := Y0 + (Y1 - Y0) * (W.X_Min - X0) / (X1 - X0);
                  X := W.X_Min;
               end if;

               if C_Out = C0 then
                  X0 := X;
                  Y0 := Y;
                  C0 := Compute_OutCode ((X0, Y0), W);
               else
                  X1 := X;
                  Y1 := Y;
                  C1 := Compute_OutCode ((X1, Y1), W);
               end if;
            end if;
         end if;
         exit when Done;
      end loop;

      if Accept_Flag then
         return Accepted ((X0, Y0), (X1, Y1));
      else
         return Rejected;
      end if;
   end Cohen_Sutherland_Clip;

   -----------------------------------------------------------------------
   -- Cohen_Sutherland_Clip_3D_Lite
   -----------------------------------------------------------------------

   function Cohen_Sutherland_Clip_3D_Lite
     (S : Segment3; B : Clip_Box) return Clip_Result_3D
   is
      X0 : Real := S.P0.X;
      Y0 : Real := S.P0.Y;
      Z0 : Real := S.P0.Z;
      X1 : Real := S.P1.X;
      Y1 : Real := S.P1.Y;
      Z1 : Real := S.P1.Z;
      C0 : Out_Code_3D := Compute_OutCode ((X0, Y0, Z0), B);
      C1 : Out_Code_3D := Compute_OutCode ((X1, Y1, Z1), B);
      C_Out : Out_Code_3D;
      X, Y, Z : Real;
      Accept_Flag : Boolean := False;
      Done        : Boolean := False;
      Steps       : Natural := 0;
   begin
      loop
         if Trivial_Accept (C0, C1) then
            Accept_Flag := True;
            Done := True;
         elsif Trivial_Reject (C0, C1) then
            Done := True;
         else
            Steps := Steps + 1;
            if Steps > 12 then
               Done := True;
            else
               C_Out := (if C0 /= 0 then C0 else C1);

               if (C_Out and Bit3_Far) /= 0 then
                  X := X0 + (X1 - X0) * (B.Z_Max - Z0) / (Z1 - Z0);
                  Y := Y0 + (Y1 - Y0) * (B.Z_Max - Z0) / (Z1 - Z0);
                  Z := B.Z_Max;
               elsif (C_Out and Bit3_Near) /= 0 then
                  X := X0 + (X1 - X0) * (B.Z_Min - Z0) / (Z1 - Z0);
                  Y := Y0 + (Y1 - Y0) * (B.Z_Min - Z0) / (Z1 - Z0);
                  Z := B.Z_Min;
               elsif (C_Out and Bit3_Top) /= 0 then
                  X := X0 + (X1 - X0) * (B.Y_Max - Y0) / (Y1 - Y0);
                  Z := Z0 + (Z1 - Z0) * (B.Y_Max - Y0) / (Y1 - Y0);
                  Y := B.Y_Max;
               elsif (C_Out and Bit3_Bottom) /= 0 then
                  X := X0 + (X1 - X0) * (B.Y_Min - Y0) / (Y1 - Y0);
                  Z := Z0 + (Z1 - Z0) * (B.Y_Min - Y0) / (Y1 - Y0);
                  Y := B.Y_Min;
               elsif (C_Out and Bit3_Right) /= 0 then
                  Y := Y0 + (Y1 - Y0) * (B.X_Max - X0) / (X1 - X0);
                  Z := Z0 + (Z1 - Z0) * (B.X_Max - X0) / (X1 - X0);
                  X := B.X_Max;
               else
                  Y := Y0 + (Y1 - Y0) * (B.X_Min - X0) / (X1 - X0);
                  Z := Z0 + (Z1 - Z0) * (B.X_Min - X0) / (X1 - X0);
                  X := B.X_Min;
               end if;

               if C_Out = C0 then
                  X0 := X;
                  Y0 := Y;
                  Z0 := Z;
                  C0 := Compute_OutCode ((X0, Y0, Z0), B);
               else
                  X1 := X;
                  Y1 := Y;
                  Z1 := Z;
                  C1 := Compute_OutCode ((X1, Y1, Z1), B);
               end if;
            end if;
         end if;
         exit when Done;
      end loop;

      if Accept_Flag then
         return Accepted3 ((X0, Y0, Z0), (X1, Y1, Z1));
      else
         return Rejected3;
      end if;
   end Cohen_Sutherland_Clip_3D_Lite;

   -----------------------------------------------------------------------
   -- Liang–Barsky lite reference
   -----------------------------------------------------------------------

   function Liang_Barsky_Clip_Lite
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      DX : constant Real := S.P1.X - S.P0.X;
      DY : constant Real := S.P1.Y - S.P0.Y;
      T_Enter : Real := 0.0;
      T_Leave : Real := 1.0;

      procedure Update (P, Q : Real; Ok : in out Boolean) is
         U : Real;
      begin
         if not Ok then
            return;
         end if;
         if Near (P, 0.0) then
            if Q < 0.0 then
               Ok := False;
            end if;
         else
            U := Q / P;
            if P < 0.0 then
               if U > T_Enter then
                  T_Enter := U;
               end if;
            else
               if U < T_Leave then
                  T_Leave := U;
               end if;
            end if;
         end if;
      end Update;

      Ok : Boolean := True;
      A, B : Vec2;
   begin
      --  left, right, bottom, top
      Update (-DX, S.P0.X - W.X_Min, Ok);
      Update (DX,  W.X_Max - S.P0.X, Ok);
      Update (-DY, S.P0.Y - W.Y_Min, Ok);
      Update (DY,  W.Y_Max - S.P0.Y, Ok);

      if not Ok or else T_Enter > T_Leave then
         return Rejected;
      end if;

      A :=
        (S.P0.X + T_Enter * DX,
         S.P0.Y + T_Enter * DY);
      B :=
        (S.P0.X + T_Leave * DX,
         S.P0.Y + T_Leave * DY);
      A.X := Clamp (A.X, W.X_Min, W.X_Max);
      A.Y := Clamp (A.Y, W.Y_Min, W.Y_Max);
      B.X := Clamp (B.X, W.X_Min, W.X_Max);
      B.Y := Clamp (B.Y, W.Y_Min, W.Y_Max);
      return Accepted (A, B);
   end Liang_Barsky_Clip_Lite;

end Cohen_Sutherland;
