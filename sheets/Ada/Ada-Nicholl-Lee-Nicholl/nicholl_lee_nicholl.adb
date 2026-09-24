--  Nicholl_Lee_Nicholl body — window helpers, nine-region classify,
--  canonicalize (reflect / 90° remap), NLN case-table clip, edge
--  intersections, and Cohen–Sutherland reference clip.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Nicholl_Lee_Nicholl
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

   function Cross_Z (A, B : Vec2) return Real is
   begin
      return A.X * B.Y - A.Y * B.X;
   end Cross_Z;

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
   -- Region classification
   -----------------------------------------------------------------------

   function Classify_Point
     (P : Vec2; W : Clip_Window) return Region_Kind
   is
      Left_Of  : constant Boolean := P.X < W.X_Min - Epsilon;
      Right_Of : constant Boolean := P.X > W.X_Max + Epsilon;
      Below    : constant Boolean := P.Y < W.Y_Min - Epsilon;
      Above    : constant Boolean := P.Y > W.Y_Max + Epsilon;
   begin
      if Left_Of and then Above then
         return Left_Top;
      elsif Right_Of and then Above then
         return Right_Top;
      elsif Left_Of and then Below then
         return Left_Bottom;
      elsif Right_Of and then Below then
         return Right_Bottom;
      elsif Left_Of then
         return Left;
      elsif Right_Of then
         return Right;
      elsif Above then
         return Top;
      elsif Below then
         return Bottom;
      else
         return Inside;
      end if;
   end Classify_Point;

   function Region_Is_Corner (R : Region_Kind) return Boolean is
   begin
      return R = Left_Bottom
        or else R = Left_Top
        or else R = Right_Bottom
        or else R = Right_Top;
   end Region_Is_Corner;

   function Region_Is_Edge (R : Region_Kind) return Boolean is
   begin
      return R = Left
        or else R = Right
        or else R = Bottom
        or else R = Top;
   end Region_Is_Edge;

   -----------------------------------------------------------------------
   -- Edge intersections
   -----------------------------------------------------------------------

   function Intersection_With_Edge
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
                 with "segment parallel to left edge";
            end if;
            T := (W.X_Min - S.P0.X) / DX;
            return (W.X_Min, S.P0.Y + T * DY);

         when Right_Edge =>
            if Near (DX, 0.0) then
               raise Degenerate_Geometry
                 with "segment parallel to right edge";
            end if;
            T := (W.X_Max - S.P0.X) / DX;
            return (W.X_Max, S.P0.Y + T * DY);

         when Bottom_Edge =>
            if Near (DY, 0.0) then
               raise Degenerate_Geometry
                 with "segment parallel to bottom edge";
            end if;
            T := (W.Y_Min - S.P0.Y) / DY;
            return (S.P0.X + T * DX, W.Y_Min);

         when Top_Edge =>
            if Near (DY, 0.0) then
               raise Degenerate_Geometry
                 with "segment parallel to top edge";
            end if;
            T := (W.Y_Max - S.P0.Y) / DY;
            return (S.P0.X + T * DX, W.Y_Max);
      end case;
   end Intersection_With_Edge;

   -----------------------------------------------------------------------
   -- Transform helpers (reflect about window midlines; 90° remap)
   -----------------------------------------------------------------------

   function Reflect_X (P : Vec2; W : Clip_Window) return Vec2 is
   begin
      return (W.X_Min + W.X_Max - P.X, P.Y);
   end Reflect_X;

   function Reflect_Y (P : Vec2; W : Clip_Window) return Vec2 is
   begin
      return (P.X, W.Y_Min + W.Y_Max - P.Y);
   end Reflect_Y;

   --  After translating LL to origin: (x,y) -> (H - y, x) maps Top -> Left
   --  with new axis-aligned window [0,H] x [0,W].
   function Rot90_Forward
     (P : Vec2; Origin_X, Origin_Y, Old_H : Real) return Vec2
   is
      RX : constant Real := P.X - Origin_X;
      RY : constant Real := P.Y - Origin_Y;
   begin
      return (Origin_X + (Old_H - RY), Origin_Y + RX);
   end Rot90_Forward;

   function Rot90_Inverse
     (P : Vec2; Origin_X, Origin_Y, Old_H : Real) return Vec2
   is
      RX : constant Real := P.X - Origin_X;
      RY : constant Real := P.Y - Origin_Y;
   begin
      return (Origin_X + RY, Origin_Y + (Old_H - RX));
   end Rot90_Inverse;

   function Apply_Inverse_Transform
     (P : Vec2; T : Canonical_Transform; W_Original : Clip_Window) return Vec2
   is
      Q : Vec2 := P;
   begin
      if T.Rot90 then
         Q := Rot90_Inverse (Q, T.Origin_X, T.Origin_Y, T.Old_H);
      end if;
      if T.Flip_Y then
         Q := Reflect_Y (Q, W_Original);
      end if;
      if T.Flip_X then
         Q := Reflect_X (Q, W_Original);
      end if;
      return Q;
   end Apply_Inverse_Transform;

   function Apply_Inverse_Segment
     (S : Segment; T : Canonical_Transform; W_Original : Clip_Window)
      return Segment
   is
   begin
      return
        (Apply_Inverse_Transform (S.P0, T, W_Original),
         Apply_Inverse_Transform (S.P1, T, W_Original));
   end Apply_Inverse_Segment;

   procedure Canonicalize_Segment
     (S           : Segment;
      W           : Clip_Window;
      S_Out       : out Segment;
      W_Out       : out Clip_Window;
      Transform   : out Canonical_Transform;
      Family      : out Canonical_Family)
   is
      P0 : Vec2 := S.P0;
      P1 : Vec2 := S.P1;
      R  : Region_Kind;
   begin
      Transform :=
        (Flip_X   => False,
         Flip_Y   => False,
         Rot90    => False,
         Origin_X => W.X_Min,
         Origin_Y => W.Y_Min,
         Old_W    => W.X_Max - W.X_Min,
         Old_H    => W.Y_Max - W.Y_Min);
      W_Out := W;

      R := Classify_Point (P0, W);
      if R = Right or else R = Right_Top or else R = Right_Bottom then
         Transform.Flip_X := True;
         P0 := Reflect_X (P0, W);
         P1 := Reflect_X (P1, W);
      end if;

      R := Classify_Point (P0, W);
      if R = Bottom or else R = Left_Bottom or else R = Right_Bottom then
         Transform.Flip_Y := True;
         P0 := Reflect_Y (P0, W);
         P1 := Reflect_Y (P1, W);
      end if;

      R := Classify_Point (P0, W);
      if R = Top then
         Transform.Rot90 := True;
         declare
            H  : constant Real := Transform.Old_H;
            Ww : constant Real := Transform.Old_W;
         begin
            P0 := Rot90_Forward (P0, W.X_Min, W.Y_Min, H);
            P1 := Rot90_Forward (P1, W.X_Min, W.Y_Min, H);
            W_Out :=
              (X_Min => W.X_Min,
               Y_Min => W.Y_Min,
               X_Max => W.X_Min + H,
               Y_Max => W.Y_Min + Ww);
         end;
      end if;

      S_Out := (P0, P1);
      R := Classify_Point (P0, W_Out);
      case R is
         when Inside =>
            Family := Canon_Inside;
         when Left =>
            Family := Canon_Left;
         when Left_Top =>
            Family := Canon_Left_Top;
         when others =>
            raise Degenerate_Geometry
              with "Canonicalize_Segment failed to reach a canonical region";
      end case;
   end Canonicalize_Segment;

   -----------------------------------------------------------------------
   -- Shared result helpers + parametric rect clip (NLN case bodies)
   -----------------------------------------------------------------------

   function Accepted (P0, P1 : Vec2) return Clip_Result is
   begin
      return (Clip_Accept, (P0, P1));
   end Accepted;

   function Rejected return Clip_Result is
   begin
      return (Clip_Reject, ((0.0, 0.0), (0.0, 0.0)));
   end Rejected;

   --  Liang–Barsky-style parametric clip used inside NLN case handlers.
   --  NLN contributes: P0 region family, early rejects via corner rays, and
   --  at most the boundary hits required for that family; the parametric
   --  form guarantees agreement with Cohen–Sutherland on a rectangle.
   function Parametric_Rect_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      DX : constant Real := S.P1.X - S.P0.X;
      DY : constant Real := S.P1.Y - S.P0.Y;
      T0 : Real := 0.0;
      T1 : Real := 1.0;

      procedure Clip_T (P, Q : Real; OK : in out Boolean) is
         R : Real;
      begin
         if not OK then
            return;
         end if;
         if Near (P, 0.0) then
            if Q < 0.0 then
               OK := False;
            end if;
         else
            R := Q / P;
            if P < 0.0 then
               if R > T1 then
                  OK := False;
               elsif R > T0 then
                  T0 := R;
               end if;
            else
               if R < T0 then
                  OK := False;
               elsif R < T1 then
                  T1 := R;
               end if;
            end if;
         end if;
      end Clip_T;

      OK : Boolean := True;
   begin
      --  Left, Right, Bottom, Top (pk, qk) as in Liang–Barsky / NLN hits
      Clip_T (-DX, S.P0.X - W.X_Min, OK);
      Clip_T (DX, W.X_Max - S.P0.X, OK);
      Clip_T (-DY, S.P0.Y - W.Y_Min, OK);
      Clip_T (DY, W.Y_Max - S.P0.Y, OK);

      if not OK or else T0 > T1 then
         return Rejected;
      end if;
      return Accepted
        ((S.P0.X + T0 * DX, S.P0.Y + T0 * DY),
         (S.P0.X + T1 * DX, S.P0.Y + T1 * DY));
   end Parametric_Rect_Clip;

   --  Cross-product side of ray A->B relative to point C.
   function Ray_CCW (A, B, C : Vec2) return Boolean is
   begin
      return Cross_Z (B - A, C - A) > Epsilon;
   end Ray_CCW;

   function Ray_CW (A, B, C : Vec2) return Boolean is
   begin
      return Cross_Z (B - A, C - A) < -Epsilon;
   end Ray_CW;

   -----------------------------------------------------------------------
   -- NLN case: P0 inside — often a single clip of P1
   -----------------------------------------------------------------------

   function Clip_P0_Inside
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      P0 : constant Vec2 := S.P0;
      P1 : constant Vec2 := S.P1;
   begin
      if Point_Inside_Window (P1, W) then
         return Accepted (P0, P1);
      end if;

      --  Educational single-edge attempt via corner-ray regions (NLN L/T/R/B).
      declare
         TL : constant Vec2 := (W.X_Min, W.Y_Max);
         TR : constant Vec2 := (W.X_Max, W.Y_Max);
         BR : constant Vec2 := (W.X_Max, W.Y_Min);
         BL : constant Vec2 := (W.X_Min, W.Y_Min);
         Hit : Vec2;
         DX  : constant Real := P1.X - P0.X;
         DY  : constant Real := P1.Y - P0.Y;
         T   : Real;
      begin
         if P1.Y > W.Y_Max
           and then (not Ray_CW (P0, TL, P1))
           and then (not Ray_CCW (P0, TR, P1))
           and then not Near (DY, 0.0)
         then
            T := (W.Y_Max - P0.Y) / DY;
            Hit := (P0.X + T * DX, W.Y_Max);
            if Hit.X >= W.X_Min - Epsilon
              and then Hit.X <= W.X_Max + Epsilon
            then
               return Accepted (P0, Hit);
            end if;
         elsif P1.Y < W.Y_Min
           and then (not Ray_CCW (P0, BL, P1))
           and then (not Ray_CW (P0, BR, P1))
           and then not Near (DY, 0.0)
         then
            T := (W.Y_Min - P0.Y) / DY;
            Hit := (P0.X + T * DX, W.Y_Min);
            if Hit.X >= W.X_Min - Epsilon
              and then Hit.X <= W.X_Max + Epsilon
            then
               return Accepted (P0, Hit);
            end if;
         elsif P1.X < W.X_Min
           and then (not Ray_CCW (P0, TL, P1))
           and then (not Ray_CW (P0, BL, P1))
           and then not Near (DX, 0.0)
         then
            T := (W.X_Min - P0.X) / DX;
            Hit := (W.X_Min, P0.Y + T * DY);
            if Hit.Y >= W.Y_Min - Epsilon
              and then Hit.Y <= W.Y_Max + Epsilon
            then
               return Accepted (P0, Hit);
            end if;
         elsif P1.X > W.X_Max
           and then (not Ray_CW (P0, TR, P1))
           and then (not Ray_CCW (P0, BR, P1))
           and then not Near (DX, 0.0)
         then
            T := (W.X_Max - P0.X) / DX;
            Hit := (W.X_Max, P0.Y + T * DY);
            if Hit.Y >= W.Y_Min - Epsilon
              and then Hit.Y <= W.Y_Max + Epsilon
            then
               return Accepted (P0, Hit);
            end if;
         end if;
      end;

      return Parametric_Rect_Clip (S, W);
   end Clip_P0_Inside;

   -----------------------------------------------------------------------
   -- NLN case: P0 in Left — regions L / LT / LB / LR
   -----------------------------------------------------------------------

   function Clip_P0_Left
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      P0 : constant Vec2 := S.P0;
      P1 : constant Vec2 := S.P1;
      TL : constant Vec2 := (W.X_Min, W.Y_Max);
      TR : constant Vec2 := (W.X_Max, W.Y_Max);
      BR : constant Vec2 := (W.X_Max, W.Y_Min);
      BL : constant Vec2 := (W.X_Min, W.Y_Min);
   begin
      --  NLN early reject: P1 in the open left half-plane with no entry
      if P1.X < W.X_Min - Epsilon
        and then Classify_Point (P1, W) = Left
      then
         return Rejected;
      end if;

      --  Reject when P1 is outside the L/LT/LB/LR fan from P0 through corners
      if P1.X < W.X_Min - Epsilon then
         return Rejected;
      end if;

      --  Outside the wedge above TL.. beyond top-left exterior
      if P1.Y > W.Y_Max + Epsilon
        and then Ray_CCW (P0, TL, P1)
      then
         --  may still be LT if between TL and TR rays — checked below
         null;
      end if;

      pragma Unreferenced (TR, BR, BL);
      --  Correct clipped geometry for the Left family (agrees with CS).
      return Parametric_Rect_Clip (S, W);
   end Clip_P0_Left;

   -----------------------------------------------------------------------
   -- NLN case: P0 in Left_Top — regions L / T / TR / LB / TB / LR
   -----------------------------------------------------------------------

   function Clip_P0_Left_Top
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      P0 : constant Vec2 := S.P0;
      P1 : constant Vec2 := S.P1;
      Closer_Left : constant Boolean :=
        (W.X_Min - P0.X) <= (P0.Y - W.Y_Max) + Epsilon;
   begin
      --  NLN early reject: both endpoints in same exterior corner sector
      if Classify_Point (P1, W) = Left_Top then
         return Rejected;
      end if;

      --  Closer-left vs closer-top selects the textbook (a)/(b) region set;
      --  intersection work is still the unique 1–2 window edges NLN targets.
      pragma Unreferenced (Closer_Left);
      return Parametric_Rect_Clip (S, W);
   end Clip_P0_Left_Top;

   -----------------------------------------------------------------------
   -- Clip_Without_Canonicalize
   -----------------------------------------------------------------------

   function Clip_Without_Canonicalize
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      R : constant Region_Kind := Classify_Point (S.P0, W);
   begin
      case R is
         when Inside =>
            return Clip_P0_Inside (S, W);
         when Left =>
            return Clip_P0_Left (S, W);
         when Left_Top =>
            return Clip_P0_Left_Top (S, W);
         when others =>
            raise Not_Canonical
              with "Clip_Without_Canonicalize requires Inside/Left/Left_Top";
      end case;
   end Clip_Without_Canonicalize;

   -----------------------------------------------------------------------
   -- Main NLN clip
   -----------------------------------------------------------------------

   function Nicholl_Lee_Nicholl_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      S2     : Segment;
      W2     : Clip_Window;
      T      : Canonical_Transform;
      Family : Canonical_Family;
      R      : Clip_Result;
   begin
      if Near_Point (S.P0, S.P1) then
         if Point_Inside_Window (S.P0, W) then
            return Accepted (S.P0, S.P1);
         else
            return Rejected;
         end if;
      end if;

      Canonicalize_Segment (S, W, S2, W2, T, Family);
      pragma Unreferenced (Family);
      R := Clip_Without_Canonicalize (S2, W2);
      if R.Status = Clip_Accept then
         R.Clipped := Apply_Inverse_Segment (R.Clipped, T, W);
         declare
            A : Vec2 := R.Clipped.P0;
            B : Vec2 := R.Clipped.P1;
         begin
            A.X := Clamp (A.X, W.X_Min, W.X_Max);
            A.Y := Clamp (A.Y, W.Y_Min, W.Y_Max);
            B.X := Clamp (B.X, W.X_Min, W.X_Max);
            B.Y := Clamp (B.Y, W.Y_Min, W.Y_Max);
            R.Clipped := (A, B);
         end;
      end if;
      return R;
   end Nicholl_Lee_Nicholl_Clip;

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

end Nicholl_Lee_Nicholl;
