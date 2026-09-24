--  Marching_Squares body — case table, edge interpolation, saddle
--  disambiguation, grid isolines/isobands, triangle isolines, fixtures.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Marching_Squares
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Internal helpers
   -------------------------------------------------------------------------

   function Sqrt_Safe (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      else
         return Real (Sqrt (Float (X)));
      end if;
   end Sqrt_Safe;

   --  Endpoints of the four cell edges among corners TL,TR,BR,BL = 0..3.
   type Edge_Ends is array (0 .. 1) of Cell_Corner;
   type Edge_Table is array (Cell_Edge) of Edge_Ends;

   Cell_Edge_Verts : constant Edge_Table :=
     [0 => [0, 1],   -- top:    TL–TR
      1 => [1, 2],   -- right:  TR–BR
      2 => [2, 3],   -- bottom: BR–BL
      3 => [3, 0]];  -- left:   BL–TL

   function Corner_Scalar
     (C : Cell_Corner; TL, TR, BR, BL : Real) return Real
   is
   begin
      case C is
         when 0 => return TL;
         when 1 => return TR;
         when 2 => return BR;
         when 3 => return BL;
      end case;
   end Corner_Scalar;

   function Corner_Point
     (C : Cell_Corner; TL, TR, BR, BL : Point2) return Point2
   is
   begin
      case C is
         when 0 => return TL;
         when 1 => return TR;
         when 2 => return BR;
         when 3 => return BL;
      end case;
   end Corner_Point;

   function In_Band (V, Lo, Hi : Real) return Boolean is
   begin
      return V >= Lo and then V <= Hi;
   end In_Band;

   -------------------------------------------------------------------------
   -- Vector helpers
   -------------------------------------------------------------------------

   function Length (V : Vec2) return Non_Negative is
      S : constant Real := V.X * V.X + V.Y * V.Y;
   begin
      return Non_Negative (Sqrt_Safe (S));
   end Length;

   function Normalize (V : Vec2) return Vec2 is
      L : constant Non_Negative := Length (V);
   begin
      if L = 0.0 then
         raise Degenerate_Geometry with "Normalize of zero vector";
      end if;
      return (V.X / L, V.Y / L);
   end Normalize;

   function Dot (A, B : Vec2) return Real is
   begin
      return A.X * B.X + A.Y * B.Y;
   end Dot;

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

   function Clamp (X, Lo, Hi : Real) return Real is
   begin
      if X < Lo then
         return Lo;
      elsif X > Hi then
         return Hi;
      else
         return X;
      end if;
   end Clamp;

   function Distance_Between (A, B : Vec2) return Non_Negative is
   begin
      return Length (A - B);
   end Distance_Between;

   function Cell_Corner_Offset (C : Cell_Corner) return Vec2 is
   begin
      --  Y-up unit cell: top-left (0,1), top-right (1,1),
      --  bottom-right (1,0), bottom-left (0,0).
      case C is
         when 0 => return (0.0, 1.0);
         when 1 => return (1.0, 1.0);
         when 2 => return (1.0, 0.0);
         when 3 => return (0.0, 0.0);
      end case;
   end Cell_Corner_Offset;

   -------------------------------------------------------------------------
   -- 1. Cell_Case_Index
   -------------------------------------------------------------------------

   function Cell_Case_Index
     (TL, TR, BR, BL : Real;
      Isolevel       : Real) return Case_Index
   is
      Idx : Natural := 0;
   begin
      if TL >= Isolevel then
         Idx := Idx + 8;
      end if;
      if TR >= Isolevel then
         Idx := Idx + 4;
      end if;
      if BR >= Isolevel then
         Idx := Idx + 2;
      end if;
      if BL >= Isolevel then
         Idx := Idx + 1;
      end if;
      return Case_Index (Idx);
   end Cell_Case_Index;

   -------------------------------------------------------------------------
   -- 2. Interpolate_Edge
   -------------------------------------------------------------------------

   function Interpolate_Edge
     (P0, P1 : Point2;
      V0, V1 : Real;
      Isolevel : Real) return Point2
   is
      Denom : constant Real := V1 - V0;
      T     : Real;
   begin
      if Denom = 0.0 then
         raise Degenerate_Geometry with "Interpolate_Edge: equal scalars";
      end if;
      T := (Isolevel - V0) / Denom;
      T := Clamp (T, 0.0, 1.0);
      return P0 + (T * (P1 - P0));
   end Interpolate_Edge;

   -------------------------------------------------------------------------
   -- 4. Disambiguate_Saddle
   -------------------------------------------------------------------------

   function Saddle_Center_Above
     (Center_Avg : Real;
      Isolevel   : Real) return Boolean
   is
   begin
      return Center_Avg >= Isolevel;
   end Saddle_Center_Above;

   function Disambiguate_Saddle
     (TL, TR, BR, BL : Real;
      Isolevel       : Real) return Boolean
   is
      Avg : constant Real := (TL + TR + BR + BL) / 4.0;
   begin
      return Saddle_Center_Above (Avg, Isolevel);
   end Disambiguate_Saddle;

   -------------------------------------------------------------------------
   -- 3. Lookup_Segments / March_Cell_Isoline
   -------------------------------------------------------------------------

   procedure Lookup_Segments
     (Index      : Case_Index;
      Center_Avg : Real;
      Isolevel   : Real;
      Edge_A     : out Integer;
      Edge_B     : out Integer;
      Edge_C     : out Integer;
      Edge_D     : out Integer;
      Seg_Count  : out Natural)
   is
      Above : constant Boolean := Saddle_Center_Above (Center_Avg, Isolevel);
   begin
      Edge_A := -1;
      Edge_B := -1;
      Edge_C := -1;
      Edge_D := -1;
      Seg_Count := 0;

      case Index is
         when 0 | 15 =>
            null;

         when 1 =>
            --  BL only: left–bottom
            Edge_A := 3; Edge_B := 2; Seg_Count := 1;

         when 2 =>
            --  BR only: bottom–right
            Edge_A := 2; Edge_B := 1; Seg_Count := 1;

         when 3 =>
            --  BL+BR: left–right
            Edge_A := 3; Edge_B := 1; Seg_Count := 1;

         when 4 =>
            --  TR only: top–right
            Edge_A := 0; Edge_B := 1; Seg_Count := 1;

         when 5 =>
            --  TR+BL saddle
            Seg_Count := 2;
            if Above then
               --  center above: top–right and bottom–left
               Edge_A := 0; Edge_B := 1;
               Edge_C := 2; Edge_D := 3;
            else
               --  center below: top–left and bottom–right
               Edge_A := 0; Edge_B := 3;
               Edge_C := 1; Edge_D := 2;
            end if;

         when 6 =>
            --  TR+BR: top–bottom
            Edge_A := 0; Edge_B := 2; Seg_Count := 1;

         when 7 =>
            --  all but TL: top–left
            Edge_A := 0; Edge_B := 3; Seg_Count := 1;

         when 8 =>
            --  TL only: top–left
            Edge_A := 0; Edge_B := 3; Seg_Count := 1;

         when 9 =>
            --  TL+BL: top–bottom
            Edge_A := 0; Edge_B := 2; Seg_Count := 1;

         when 10 =>
            --  TL+BR saddle
            Seg_Count := 2;
            if Above then
               --  center above: top–left and bottom–right
               Edge_A := 0; Edge_B := 3;
               Edge_C := 1; Edge_D := 2;
            else
               --  center below: top–right and bottom–left
               Edge_A := 0; Edge_B := 1;
               Edge_C := 2; Edge_D := 3;
            end if;

         when 11 =>
            --  all but TR: top–right
            Edge_A := 0; Edge_B := 1; Seg_Count := 1;

         when 12 =>
            --  TL+TR: left–right
            Edge_A := 3; Edge_B := 1; Seg_Count := 1;

         when 13 =>
            --  all but BR: bottom–right
            Edge_A := 2; Edge_B := 1; Seg_Count := 1;

         when 14 =>
            --  all but BL: left–bottom
            Edge_A := 3; Edge_B := 2; Seg_Count := 1;
      end case;
   end Lookup_Segments;

   procedure March_Cell_Isoline
     (TL, TR, BR, BL : Point2;
      V_TL, V_TR, V_BR, V_BL : Real;
      Isolevel : Real;
      Out_Segs : out Small_Segment_List;
      Out_Count : out Natural)
   is
      Idx : constant Case_Index :=
        Cell_Case_Index (V_TL, V_TR, V_BR, V_BL, Isolevel);
      Avg : constant Real := (V_TL + V_TR + V_BR + V_BL) / 4.0;
      EA, EB, EC, ED : Integer;
      N : Natural;

      function Edge_Point (E : Cell_Edge) return Point2 is
         C0 : constant Cell_Corner := Cell_Edge_Verts (E) (0);
         C1 : constant Cell_Corner := Cell_Edge_Verts (E) (1);
      begin
         return Interpolate_Edge
           (Corner_Point (C0, TL, TR, BR, BL),
            Corner_Point (C1, TL, TR, BR, BL),
            Corner_Scalar (C0, V_TL, V_TR, V_BR, V_BL),
            Corner_Scalar (C1, V_TL, V_TR, V_BR, V_BL),
            Isolevel);
      end Edge_Point;
   begin
      Out_Segs := [others => ((0.0, 0.0), (0.0, 0.0))];
      Lookup_Segments (Idx, Avg, Isolevel, EA, EB, EC, ED, N);
      Out_Count := N;
      if N >= 1 then
         Out_Segs (1) :=
           (Edge_Point (Cell_Edge (EA)), Edge_Point (Cell_Edge (EB)));
      end if;
      if N >= 2 then
         Out_Segs (2) :=
           (Edge_Point (Cell_Edge (EC)), Edge_Point (Cell_Edge (ED)));
      end if;
   end March_Cell_Isoline;

   -------------------------------------------------------------------------
   -- Polyline / band helpers
   -------------------------------------------------------------------------

   function Empty_Polyline return Polyline is
      P : Polyline;
   begin
      P.Count := 0;
      return P;
   end Empty_Polyline;

   function Empty_Band_List return Band_List is
      L : Band_List;
   begin
      L.Count := 0;
      return L;
   end Empty_Band_List;

   procedure Append_Segment (P : in out Polyline; S : Segment) is
   begin
      if P.Count = Max_Segments then
         raise Capacity_Exceeded with "Polyline segment capacity exceeded";
      end if;
      P.Count := P.Count + 1;
      P.Segs (P.Count) := S;
   end Append_Segment;

   procedure Append_Band (L : in out Band_List; B : Band_Polygon) is
   begin
      if B.Count < 3 then
         return;
      end if;
      if L.Count = Max_Bands then
         raise Capacity_Exceeded with "Band list capacity exceeded";
      end if;
      L.Count := L.Count + 1;
      L.Bands (L.Count) := B;
   end Append_Band;

   function Count_Segments (P : Polyline) return Natural is
   begin
      return Natural (P.Count);
   end Count_Segments;

   function Compute_Polyline_Stats (P : Polyline) return Polyline_Stats is
      S : Polyline_Stats;
      First : Boolean := True;
      procedure Consider (Q : Point2) is
      begin
         if First then
            S.Min_Corner := Q;
            S.Max_Corner := Q;
            First := False;
         else
            if Q.X < S.Min_Corner.X then
               S.Min_Corner.X := Q.X;
            end if;
            if Q.Y < S.Min_Corner.Y then
               S.Min_Corner.Y := Q.Y;
            end if;
            if Q.X > S.Max_Corner.X then
               S.Max_Corner.X := Q.X;
            end if;
            if Q.Y > S.Max_Corner.Y then
               S.Max_Corner.Y := Q.Y;
            end if;
         end if;
      end Consider;
   begin
      S.Segment_Count := Natural (P.Count);
      S.Total_Length := 0.0;
      for I in 1 .. P.Count loop
         Consider (P.Segs (I).A);
         Consider (P.Segs (I).B);
         S.Total_Length :=
           Non_Negative (S.Total_Length + Distance_Between
             (P.Segs (I).A, P.Segs (I).B));
      end loop;
      return S;
   end Compute_Polyline_Stats;

   -------------------------------------------------------------------------
   -- 5. March_Grid_Isolines
   -------------------------------------------------------------------------

   function March_Grid_Isolines
     (Values    : Scalar_Field;
      Positions : Position_Field;
      Isolevel  : Real) return Polyline
   is
      Acc : Polyline := Empty_Polyline;
      Segs : Small_Segment_List;
      N : Natural;
   begin
      if Values'Length (1) > Max_Grid_Dim
        or else Values'Length (2) > Max_Grid_Dim
      then
         raise Invalid_Argument with "Grid exceeds Max_Grid_Dim";
      end if;

      for I in Values'First (1) .. Values'Last (1) - 1 loop
         for J in Values'First (2) .. Values'Last (2) - 1 loop
            --  Field indexing: I = X/column, J = Y/row.
            --  Top = higher Y = J+1 when Y increases with J.
            March_Cell_Isoline
              (TL => Positions (I,     J + 1),
               TR => Positions (I + 1, J + 1),
               BR => Positions (I + 1, J),
               BL => Positions (I,     J),
               V_TL => Values (I,     J + 1),
               V_TR => Values (I + 1, J + 1),
               V_BR => Values (I + 1, J),
               V_BL => Values (I,     J),
               Isolevel => Isolevel,
               Out_Segs => Segs,
               Out_Count => N);
            for K in 1 .. N loop
               Append_Segment (Acc, Segs (K));
            end loop;
         end loop;
      end loop;
      return Acc;
   end March_Grid_Isolines;

   -------------------------------------------------------------------------
   -- 6. March_Cell_Isoband / March_Grid_Isobands
   -------------------------------------------------------------------------

   procedure Push_Vert (Poly : in out Band_Polygon; P : Point2) is
   begin
      if Poly.Count = Max_Band_Verts then
         return;
      end if;
      --  Skip near-duplicates of the previous vertex.
      if Poly.Count >= 1 then
         if Distance_Between (Poly.Verts (Poly.Count), P) <= 1.0E-8 then
            return;
         end if;
      end if;
      Poly.Count := Poly.Count + 1;
      Poly.Verts (Poly.Count) := P;
   end Push_Vert;

   procedure March_Cell_Isoband
     (TL, TR, BR, BL : Point2;
      V_TL, V_TR, V_BR, V_BL : Real;
      Lo, Hi : Real;
      Poly : out Band_Polygon)
   is
      --  Walk the four corners clockwise; emit in-band corners and
      --  interpolated Lo/Hi crossings on each edge (from start→end).
      type CV is record
         P : Point2;
         V : Real;
      end record;
      Corners : constant array (0 .. 3) of CV :=
        [0 => (TL, V_TL),
         1 => (TR, V_TR),
         2 => (BR, V_BR),
         3 => (BL, V_BL)];

      procedure Emit_Crossings (A, B : CV) is
         --  Emit Lo/Hi crossings on A→B ordered by parameter t in (0,1).
         type Cross is record
            T : Real;
            P : Point2;
            Used : Boolean := False;
         end record;
         Xs : array (1 .. 2) of Cross;
         N  : Natural := 0;

         procedure Consider (Level : Real) is
            Denom : constant Real := B.V - A.V;
            T : Real;
         begin
            if Denom = 0.0 then
               return;
            end if;
            --  Crossing only if Level strictly between A.V and B.V.
            if (A.V < Level and then B.V > Level)
              or else (A.V > Level and then B.V < Level)
            then
               T := (Level - A.V) / Denom;
               if T > 0.0 and then T < 1.0 then
                  N := N + 1;
                  Xs (N).T := T;
                  Xs (N).P := A.P + (T * (B.P - A.P));
                  Xs (N).Used := True;
               end if;
            end if;
         end Consider;
      begin
         Consider (Lo);
         Consider (Hi);
         --  Sort by t ascending (at most 2).
         if N = 2 and then Xs (2).T < Xs (1).T then
            declare
               Tmp : constant Cross := Xs (1);
            begin
               Xs (1) := Xs (2);
               Xs (2) := Tmp;
            end;
         end if;
         for K in 1 .. N loop
            Push_Vert (Poly, Xs (K).P);
         end loop;
      end Emit_Crossings;
   begin
      Poly.Count := 0;
      Poly.Verts := [others => (0.0, 0.0)];

      --  Degenerate: entire cell above Hi or below Lo → empty.
      if (V_TL < Lo and then V_TR < Lo
            and then V_BR < Lo and then V_BL < Lo)
        or else (V_TL > Hi and then V_TR > Hi
                   and then V_BR > Hi and then V_BL > Hi)
      then
         return;
      end if;

      --  Entire cell inside band → emit the quad.
      if In_Band (V_TL, Lo, Hi) and then In_Band (V_TR, Lo, Hi)
        and then In_Band (V_BR, Lo, Hi) and then In_Band (V_BL, Lo, Hi)
      then
         Push_Vert (Poly, TL);
         Push_Vert (Poly, TR);
         Push_Vert (Poly, BR);
         Push_Vert (Poly, BL);
         return;
      end if;

      for I in 0 .. 3 loop
         declare
            A : constant CV := Corners (I);
            B : constant CV := Corners ((I + 1) mod 4);
         begin
            if In_Band (A.V, Lo, Hi) then
               Push_Vert (Poly, A.P);
            end if;
            Emit_Crossings (A, B);
         end;
      end loop;

      --  Close: drop last if it duplicates first.
      if Poly.Count >= 2
        and then Distance_Between
          (Poly.Verts (1), Poly.Verts (Poly.Count)) <= 1.0E-8
      then
         Poly.Count := Poly.Count - 1;
      end if;
   end March_Cell_Isoband;

   function March_Grid_Isobands
     (Values    : Scalar_Field;
      Positions : Position_Field;
      Lo, Hi    : Real) return Band_List
   is
      Acc : Band_List := Empty_Band_List;
      Poly : Band_Polygon;
   begin
      if Values'Length (1) > Max_Grid_Dim
        or else Values'Length (2) > Max_Grid_Dim
      then
         raise Invalid_Argument with "Grid exceeds Max_Grid_Dim";
      end if;

      for I in Values'First (1) .. Values'Last (1) - 1 loop
         for J in Values'First (2) .. Values'Last (2) - 1 loop
            March_Cell_Isoband
              (TL => Positions (I,     J + 1),
               TR => Positions (I + 1, J + 1),
               BR => Positions (I + 1, J),
               BL => Positions (I,     J),
               V_TL => Values (I,     J + 1),
               V_TR => Values (I + 1, J + 1),
               V_BR => Values (I + 1, J),
               V_BL => Values (I,     J),
               Lo => Lo, Hi => Hi,
               Poly => Poly);
            Append_Band (Acc, Poly);
         end loop;
      end loop;
      return Acc;
   end March_Grid_Isobands;

   -------------------------------------------------------------------------
   -- 7. March_Triangle_Isoline
   -------------------------------------------------------------------------

   procedure March_Triangle_Isoline
     (P0, P1, P2 : Point2;
      S0, S1, S2 : Real;
      Isolevel   : Real;
      Out_Segs   : out Small_Segment_List;
      Out_Count  : out Natural)
   is
      Idx : Natural := 0;
   begin
      Out_Segs := [others => ((0.0, 0.0), (0.0, 0.0))];
      Out_Count := 0;

      if S0 >= Isolevel then
         Idx := Idx + 4;
      end if;
      if S1 >= Isolevel then
         Idx := Idx + 2;
      end if;
      if S2 >= Isolevel then
         Idx := Idx + 1;
      end if;

      case Idx is
         when 0 | 7 =>
            null;

         when 1 =>
            --  only P2 above: edges P2–P0 and P2–P1
            Out_Count := 1;
            Out_Segs (1) :=
              (Interpolate_Edge (P2, P0, S2, S0, Isolevel),
               Interpolate_Edge (P2, P1, S2, S1, Isolevel));

         when 2 =>
            --  only P1 above: edges P1–P0 and P1–P2
            Out_Count := 1;
            Out_Segs (1) :=
              (Interpolate_Edge (P1, P0, S1, S0, Isolevel),
               Interpolate_Edge (P1, P2, S1, S2, Isolevel));

         when 3 =>
            --  P1+P2: edges P0–P1 and P0–P2
            Out_Count := 1;
            Out_Segs (1) :=
              (Interpolate_Edge (P0, P1, S0, S1, Isolevel),
               Interpolate_Edge (P0, P2, S0, S2, Isolevel));

         when 4 =>
            --  only P0 above: edges P0–P1 and P0–P2
            Out_Count := 1;
            Out_Segs (1) :=
              (Interpolate_Edge (P0, P1, S0, S1, Isolevel),
               Interpolate_Edge (P0, P2, S0, S2, Isolevel));

         when 5 =>
            --  P0+P2: edges P0–P1 and P1–P2
            Out_Count := 1;
            Out_Segs (1) :=
              (Interpolate_Edge (P0, P1, S0, S1, Isolevel),
               Interpolate_Edge (P1, P2, S1, S2, Isolevel));

         when 6 =>
            --  P0+P1: edges P0–P2 and P1–P2
            Out_Count := 1;
            Out_Segs (1) :=
              (Interpolate_Edge (P0, P2, S0, S2, Isolevel),
               Interpolate_Edge (P1, P2, S1, S2, Isolevel));

         when others =>
            null;
      end case;
   end March_Triangle_Isoline;

   -------------------------------------------------------------------------
   -- 8. Field fixtures
   -------------------------------------------------------------------------

   procedure Fill_Height_Field
     (Values    : out Scalar_Field;
      Positions : out Position_Field;
      Origin    : Point2;
      Spacing   : Real;
      Slope_X   : Real;
      Slope_Y   : Real;
      Base      : Real := 0.0)
   is
   begin
      if Spacing <= 0.0 then
         raise Invalid_Argument with "Fill_Height_Field: Spacing must be > 0";
      end if;
      for I in Values'Range (1) loop
         for J in Values'Range (2) loop
            declare
               P : constant Point2 :=
                 (Origin.X + Real (I - Values'First (1)) * Spacing,
                  Origin.Y + Real (J - Values'First (2)) * Spacing);
            begin
               Positions (I, J) := P;
               Values (I, J) := Base + Slope_X * P.X + Slope_Y * P.Y;
            end;
         end loop;
      end loop;
   end Fill_Height_Field;

   procedure Fill_Radial_Field
     (Values    : out Scalar_Field;
      Positions : out Position_Field;
      Origin    : Point2;
      Spacing   : Real;
      Center    : Point2;
      Peak      : Real := 1.0)
   is
   begin
      if Spacing <= 0.0 then
         raise Invalid_Argument with "Fill_Radial_Field: Spacing must be > 0";
      end if;
      for I in Values'Range (1) loop
         for J in Values'Range (2) loop
            declare
               P : constant Point2 :=
                 (Origin.X + Real (I - Values'First (1)) * Spacing,
                  Origin.Y + Real (J - Values'First (2)) * Spacing);
               D : constant Non_Negative := Distance_Between (P, Center);
            begin
               Positions (I, J) := P;
               Values (I, J) := Peak - D;
            end;
         end loop;
      end loop;
   end Fill_Radial_Field;

end Marching_Squares;
