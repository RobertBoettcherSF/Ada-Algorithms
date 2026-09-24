--  Liang_Barsky body — window helpers, Compute_PQ, Clip_Parameters,
--  Point_At_Parameter, Liang–Barsky clip, and Cohen–Sutherland reference.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Liang_Barsky
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

   -----------------------------------------------------------------------
   -- Vector helpers
   -----------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Point (A, B : Vec2; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
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
   -- Segment / point helpers
   -----------------------------------------------------------------------

   function Make_Segment (P0, P1 : Vec2) return Segment is
   begin
      return (P0, P1);
   end Make_Segment;

   function Length (S : Segment) return Non_Negative is
      D : constant Vec2 := S.P1 - S.P0;
   begin
      return Sqrt_Safe (D.X * D.X + D.Y * D.Y);
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

   -----------------------------------------------------------------------
   -- Window construction
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

   -----------------------------------------------------------------------
   -- Compute_PQ
   -----------------------------------------------------------------------

   function Compute_PQ
     (S : Segment; W : Clip_Window) return PQ_Values
   is
      DX : constant Real := S.P1.X - S.P0.X;
      DY : constant Real := S.P1.Y - S.P0.Y;
      R  : PQ_Values;
   begin
      --  1 left, 2 right, 3 bottom, 4 top
      R.P (1) := -DX;
      R.Q (1) := S.P0.X - W.X_Min;
      R.P (2) := DX;
      R.Q (2) := W.X_Max - S.P0.X;
      R.P (3) := -DY;
      R.Q (3) := S.P0.Y - W.Y_Min;
      R.P (4) := DY;
      R.Q (4) := W.Y_Max - S.P0.Y;
      return R;
   end Compute_PQ;

   -----------------------------------------------------------------------
   -- Clip_Parameters
   -----------------------------------------------------------------------

   function Clip_Parameters
     (S : Segment; W : Clip_Window) return Parameter_Result
   is
      PQ      : constant PQ_Values := Compute_PQ (S, W);
      T_Enter : Real := 0.0;
      T_Leave : Real := 1.0;
      U       : Real;
      Result  : Parameter_Result;
   begin
      for I in Boundary_Index loop
         if Near (PQ.P (I), 0.0) then
            --  Parallel to this boundary: outside ⇒ reject.
            if PQ.Q (I) < 0.0 then
               Result.Accepted := False;
               Result.T_Enter  := 0.0;
               Result.T_Leave  := 1.0;
               return Result;
            end if;
         else
            U := PQ.Q (I) / PQ.P (I);
            if PQ.P (I) < 0.0 then
               --  Entering (outside → inside)
               if U > T_Enter then
                  T_Enter := U;
               end if;
            else
               --  Leaving (inside → outside)
               if U < T_Leave then
                  T_Leave := U;
               end if;
            end if;
         end if;
      end loop;

      if T_Enter > T_Leave then
         Result.Accepted := False;
         Result.T_Enter  := 0.0;
         Result.T_Leave  := 1.0;
         return Result;
      end if;

      --  Clamp into Parameter subtype safely (algorithm guarantees [0,1]
      --  when Accepted, but floating noise may slightly exceed bounds).
      Result.Accepted := True;
      Result.T_Enter  := Parameter (Clamp (T_Enter, 0.0, 1.0));
      Result.T_Leave  := Parameter (Clamp (T_Leave, 0.0, 1.0));
      if Result.T_Enter > Result.T_Leave then
         Result.Accepted := False;
      end if;
      return Result;
   end Clip_Parameters;

   -----------------------------------------------------------------------
   -- Point_At_Parameter
   -----------------------------------------------------------------------

   function Point_At_Parameter
     (S : Segment; T : Parameter) return Vec2
   is
      DX : constant Real := S.P1.X - S.P0.X;
      DY : constant Real := S.P1.Y - S.P0.Y;
   begin
      return (S.P0.X + T * DX, S.P0.Y + T * DY);
   end Point_At_Parameter;

   -----------------------------------------------------------------------
   -- Liang_Barsky_Clip / Liang_Barsky_Clip_Params
   -----------------------------------------------------------------------

   function Liang_Barsky_Clip_Params
     (S : Segment; W : Clip_Window) return Clip_Params_Result
   is
      PR : constant Parameter_Result := Clip_Parameters (S, W);
      R  : Clip_Params_Result;
      A, B : Vec2;
   begin
      if not PR.Accepted then
         R.Status  := Clip_Reject;
         R.Clipped := ((0.0, 0.0), (0.0, 0.0));
         R.T0      := 0.0;
         R.T1      := 0.0;
         return R;
      end if;

      A := Point_At_Parameter (S, PR.T_Enter);
      B := Point_At_Parameter (S, PR.T_Leave);

      --  Nudge onto the closed window to absorb float noise.
      A.X := Clamp (A.X, W.X_Min, W.X_Max);
      A.Y := Clamp (A.Y, W.Y_Min, W.Y_Max);
      B.X := Clamp (B.X, W.X_Min, W.X_Max);
      B.Y := Clamp (B.Y, W.Y_Min, W.Y_Max);

      R.Status  := Clip_Accept;
      R.Clipped := (A, B);
      R.T0      := PR.T_Enter;
      R.T1      := PR.T_Leave;
      return R;
   end Liang_Barsky_Clip_Params;

   function Liang_Barsky_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      P : constant Clip_Params_Result := Liang_Barsky_Clip_Params (S, W);
   begin
      return (Status => P.Status, Clipped => P.Clipped);
   end Liang_Barsky_Clip;

   -----------------------------------------------------------------------
   -- Cohen–Sutherland reference
   -----------------------------------------------------------------------

   type Outcode is mod 16;
   Bit_Left   : constant Outcode := 2#0001#;
   Bit_Right  : constant Outcode := 2#0010#;
   Bit_Bottom : constant Outcode := 2#0100#;
   Bit_Top    : constant Outcode := 2#1000#;

   function Compute_Outcode (P : Vec2; W : Clip_Window) return Outcode is
      C : Outcode := 0;
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
   end Compute_Outcode;

   function Cohen_Sutherland_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      X0 : Real := S.P0.X;
      Y0 : Real := S.P0.Y;
      X1 : Real := S.P1.X;
      Y1 : Real := S.P1.Y;
      C0 : Outcode := Compute_Outcode ((X0, Y0), W);
      C1 : Outcode := Compute_Outcode ((X1, Y1), W);
      C_Out : Outcode;
      X, Y  : Real;
      Accept_Flag : Boolean := False;
      Done        : Boolean := False;
   begin
      loop
         if (C0 or C1) = 0 then
            Accept_Flag := True;
            Done := True;
         elsif (C0 and C1) /= 0 then
            Done := True;
         else
            C_Out := (if C0 /= 0 then C0 else C1);
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
               C0 := Compute_Outcode ((X0, Y0), W);
            else
               X1 := X;
               Y1 := Y;
               C1 := Compute_Outcode ((X1, Y1), W);
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

   function Same_Clipped_Segment
     (A, B : Segment; Tol : Real := Epsilon) return Boolean
   is
   begin
      return
        (Near_Point (A.P0, B.P0, Tol) and then Near_Point (A.P1, B.P1, Tol))
        or else
        (Near_Point (A.P0, B.P1, Tol) and then Near_Point (A.P1, B.P0, Tol));
   end Same_Clipped_Segment;

end Liang_Barsky;
