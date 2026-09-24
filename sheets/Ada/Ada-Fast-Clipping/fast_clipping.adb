--  Fast_Clipping body — window helpers, 9-region outcodes, Fast_Clip_Case
--  line-encoding dispatch, Clip_Against_Edge, Fast_Clip, plus Cohen–
--  Sutherland and Liang–Barsky lite references.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Fast_Clipping
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

   function Same_Clipped_Segment
     (A, B : Segment; Tol : Real := Epsilon) return Boolean
   is
   begin
      return
        (Near_Point (A.P0, B.P0, Tol) and then Near_Point (A.P1, B.P1, Tol))
        or else
        (Near_Point (A.P0, B.P1, Tol) and then Near_Point (A.P1, B.P0, Tol));
   end Same_Clipped_Segment;

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
   -- Region_Outcode / Classify_Point / Encode_Line
   -----------------------------------------------------------------------

   function Region_Outcode
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
   end Region_Outcode;

   function Classify_Point
     (P : Vec2; W : Clip_Window) return Out_Code
   is
   begin
      return Region_Outcode (P, W);
   end Classify_Point;

   function Encode_Line (Code0, Code1 : Out_Code) return Line_Code is
   begin
      return Line_Code (Natural (Code0) * 16 + Natural (Code1));
   end Encode_Line;

   -----------------------------------------------------------------------
   -- Fast_Clip_Case
   -----------------------------------------------------------------------

   function Fast_Clip_Case
     (Code0, Code1 : Out_Code) return Fast_Clip_Decision
   is
      D : Fast_Clip_Decision;
   begin
      if Code0 = 0 and then Code1 = 0 then
         D.Kind     := Case_Accept;
         D.Edges_P0 := 0;
         D.Edges_P1 := 0;
      elsif (Code0 and Code1) /= 0 then
         --  Both endpoints share an outside half-plane ⇒ invisible.
         D.Kind     := Case_Reject;
         D.Edges_P0 := Code0 and Code1;
         D.Edges_P1 := Code0 and Code1;
      else
         D.Kind     := Case_Need_Clip;
         D.Edges_P0 := Code0;
         D.Edges_P1 := Code1;
      end if;
      return D;
   end Fast_Clip_Case;

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
   -- Prefer one edge bit from an outcode (Top > Bottom > Right > Left),
   -- matching the usual CS pick order used in the reference clipper.
   -----------------------------------------------------------------------

   function Pick_Edge (C : Out_Code) return Window_Edge is
   begin
      if (C and Bit_Top) /= 0 then
         return Top_Edge;
      elsif (C and Bit_Bottom) /= 0 then
         return Bottom_Edge;
      elsif (C and Bit_Right) /= 0 then
         return Right_Edge;
      else
         return Left_Edge;
      end if;
   end Pick_Edge;

   -----------------------------------------------------------------------
   -- Need_Clip handler: clip using Clip_Against_Edge on the outside
   -- endpoint chosen by current outcodes (line-encoding path). Fast_Clip
   -- already ruled out trivial Accept/Reject via Fast_Clip_Case.
   -----------------------------------------------------------------------

   function Clip_Need
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      P0 : Vec2 := S.P0;
      P1 : Vec2 := S.P1;
      C0 : Out_Code := Region_Outcode (P0, W);
      C1 : Out_Code := Region_Outcode (P1, W);
      C_Out : Out_Code;
      Edge  : Window_Edge;
      Hit   : Vec2;
      Local : Segment;
      Steps : Natural := 0;
   begin
      loop
         if (C0 or C1) = 0 then
            P0.X := Clamp (P0.X, W.X_Min, W.X_Max);
            P0.Y := Clamp (P0.Y, W.Y_Min, W.Y_Max);
            P1.X := Clamp (P1.X, W.X_Min, W.X_Max);
            P1.Y := Clamp (P1.Y, W.Y_Min, W.Y_Max);
            return Accepted (P0, P1);
         elsif (C0 and C1) /= 0 then
            return Rejected;
         end if;

         Steps := Steps + 1;
         if Steps > 8 then
            return Rejected;
         end if;

         C_Out := (if C0 /= 0 then C0 else C1);
         Edge  := Pick_Edge (C_Out);
         Local := Make_Segment (P0, P1);
         begin
            Hit := Clip_Against_Edge (Local, W, Edge);
         exception
            when Degenerate_Geometry =>
               return Rejected;
         end;

         if C_Out = C0 then
            P0 := Hit;
            C0 := Region_Outcode (P0, W);
         else
            P1 := Hit;
            C1 := Region_Outcode (P1, W);
         end if;
      end loop;
   end Clip_Need;

   -----------------------------------------------------------------------
   -- Fast_Clip
   -----------------------------------------------------------------------

   function Fast_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      C0 : constant Out_Code := Region_Outcode (S.P0, W);
      C1 : constant Out_Code := Region_Outcode (S.P1, W);
      D  : constant Fast_Clip_Decision := Fast_Clip_Case (C0, C1);
   begin
      case D.Kind is
         when Case_Accept =>
            return Accepted (S.P0, S.P1);

         when Case_Reject =>
            return Rejected;

         when Case_Need_Clip =>
            --  Specialized Need_Clip handler for this (code0, code1) pair:
            --  intersect only against edges implied by the outcodes via
            --  Clip_Against_Edge (no blind four-edge parametric sweep).
            pragma Assert (D.Edges_P0 = C0 and then D.Edges_P1 = C1);
            return Clip_Need (S, W);
      end case;
   end Fast_Clip;

   -----------------------------------------------------------------------
   -- Cohen–Sutherland reference
   -----------------------------------------------------------------------

   function Cohen_Sutherland_Clip
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      X0 : Real := S.P0.X;
      Y0 : Real := S.P0.Y;
      X1 : Real := S.P1.X;
      Y1 : Real := S.P1.Y;
      C0 : Out_Code := Region_Outcode ((X0, Y0), W);
      C1 : Out_Code := Region_Outcode ((X1, Y1), W);
      C_Out : Out_Code;
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
               C0 := Region_Outcode ((X0, Y0), W);
            else
               X1 := X;
               Y1 := Y;
               C1 := Region_Outcode ((X1, Y1), W);
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

end Fast_Clipping;
