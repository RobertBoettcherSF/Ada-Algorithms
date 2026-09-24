--  Line_Segment_Intersection body — educational survey of segment–segment
--  intersection classification and reporting.

pragma Ada_2022;

package body Line_Segment_Intersection
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   procedure Require_Segment_Count (N : Natural) is
   begin
      if N < 1 or else N > Max_Segments then
         raise Invalid_Argument;
      end if;
   end Require_Segment_Count;

   procedure Require_Nondegenerate (S : Segment) is
   begin
      if Is_Degenerate (S) then
         raise Invalid_Argument;
      end if;
   end Require_Nondegenerate;

   procedure Require_All_Nondegenerate (Segments : Segment_Set) is
   begin
      for I in Segments'Range loop
         Require_Nondegenerate (Segments (I));
      end loop;
   end Require_All_Nondegenerate;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Point (A, B : Point; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Near_Point;

   function Dist2 (A, B : Point) return Real is
      DX : constant Real := A.X - B.X;
      DY : constant Real := A.Y - B.Y;
   begin
      return DX * DX + DY * DY;
   end Dist2;

   function Orient2D (A, B, C : Point) return Real is
   begin
      return (B.X - A.X) * (C.Y - A.Y) - (C.X - A.X) * (B.Y - A.Y);
   end Orient2D;

   function Is_Degenerate (S : Segment) return Boolean is
   begin
      return Near_Point (S.A, S.B);
   end Is_Degenerate;

   function On_Segment (P : Point; S : Segment) return Boolean is
      Min_X, Max_X, Min_Y, Max_Y : Real;
   begin
      if abs (Orient2D (S.A, S.B, P)) > Epsilon then
         return False;
      end if;
      Min_X := Real'Min (S.A.X, S.B.X) - Epsilon;
      Max_X := Real'Max (S.A.X, S.B.X) + Epsilon;
      Min_Y := Real'Min (S.A.Y, S.B.Y) - Epsilon;
      Max_Y := Real'Max (S.A.Y, S.B.Y) + Epsilon;
      return P.X >= Min_X and then P.X <= Max_X
        and then P.Y >= Min_Y and then P.Y <= Max_Y;
   end On_Segment;

   ---------------------------------------------------------------------------
   -- Parametric helpers / collinear overlap
   ---------------------------------------------------------------------------

   --  Project P onto the supporting line of S as a scalar parameter t
   --  where Point(t) = A + t (B−A). Uses the longer axis for stability.
   function Param_On (P : Point; S : Segment) return Real is
      DX : constant Real := S.B.X - S.A.X;
      DY : constant Real := S.B.Y - S.A.Y;
   begin
      if abs (DX) >= abs (DY) then
         if abs (DX) <= Epsilon then
            return 0.0;
         end if;
         return (P.X - S.A.X) / DX;
      else
         if abs (DY) <= Epsilon then
            return 0.0;
         end if;
         return (P.Y - S.A.Y) / DY;
      end if;
   end Param_On;

   function Point_At (S : Segment; T : Real) return Point is
   begin
      return
        (X => S.A.X + T * (S.B.X - S.A.X),
         Y => S.A.Y + T * (S.B.Y - S.A.Y));
   end Point_At;

   --  Clamp interval [Lo, Hi] assumed Lo <= Hi; intersect with [0,1].
   procedure Clamp01 (Lo, Hi : in out Real; Empty : out Boolean) is
   begin
      if Lo < 0.0 then
         Lo := 0.0;
      end if;
      if Hi > 1.0 then
         Hi := 1.0;
      end if;
      Empty := Lo > Hi + Epsilon;
   end Clamp01;

   --  Collinear case: project T's endpoints onto S, intersect [0,1] ×
   --  projected interval. Returns Kind + optional representative.
   procedure Classify_Collinear
     (S, T          : Segment;
      Kind          : out Intersection_Kind;
      Representative : out Point)
   is
      T0, T1, Lo, Hi : Real;
      Empty          : Boolean;
      Mid            : Real;
   begin
      T0 := Param_On (T.A, S);
      T1 := Param_On (T.B, S);
      if T0 <= T1 then
         Lo := T0;
         Hi := T1;
      else
         Lo := T1;
         Hi := T0;
      end if;
      Clamp01 (Lo, Hi, Empty);
      if Empty then
         Kind := None;
         Representative := (0.0, 0.0);
         return;
      end if;
      Mid := 0.5 * (Lo + Hi);
      Representative := Point_At (S, Mid);
      --  Positive-length overlap vs single-point (endpoint) touch.
      if Hi - Lo > Epsilon then
         Kind := Collinear_Overlap;
      else
         Kind := Improper;
      end if;
   end Classify_Collinear;

   function Line_Intersection_Parametric (S, T : Segment) return Point is
      A   : constant Point := S.A;
      B   : constant Point := S.B;
      C   : constant Point := T.A;
      D   : constant Point := T.B;
      DX1 : constant Real := B.X - A.X;
      DY1 : constant Real := B.Y - A.Y;
      DX2 : constant Real := D.X - C.X;
      DY2 : constant Real := D.Y - C.Y;
      Den : constant Real := DX1 * DY2 - DY1 * DX2;
      Tp  : Real;
   begin
      if abs (Den) <= Epsilon then
         --  Should not be reached for Proper/Improper non-collinear cases.
         return
           (X => 0.25 * (A.X + B.X + C.X + D.X),
            Y => 0.25 * (A.Y + B.Y + C.Y + D.Y));
      end if;
      Tp := ((C.X - A.X) * DY2 - (C.Y - A.Y) * DX2) / Den;
      return (X => A.X + Tp * DX1, Y => A.Y + Tp * DY1);
   end Line_Intersection_Parametric;

   ---------------------------------------------------------------------------
   -- Classification
   ---------------------------------------------------------------------------

   function Classify_Intersection (S, T : Segment) return Intersection_Kind is
      O1, O2, O3, O4 : Real;
      Dummy          : Point;
      Kind           : Intersection_Kind;
      Collinear_All  : Boolean;
   begin
      Require_Nondegenerate (S);
      Require_Nondegenerate (T);

      O1 := Orient2D (S.A, S.B, T.A);
      O2 := Orient2D (S.A, S.B, T.B);
      O3 := Orient2D (T.A, T.B, S.A);
      O4 := Orient2D (T.A, T.B, S.B);

      Collinear_All :=
        abs (O1) <= Epsilon and then abs (O2) <= Epsilon
        and then abs (O3) <= Epsilon and then abs (O4) <= Epsilon;

      if Collinear_All then
         Classify_Collinear (S, T, Kind, Dummy);
         return Kind;
      end if;

      --  Proper: strict opposite sides on both segments.
      if abs (O1) > Epsilon and then abs (O2) > Epsilon
        and then abs (O3) > Epsilon and then abs (O4) > Epsilon
        and then (O1 > 0.0) /= (O2 > 0.0)
        and then (O3 > 0.0) /= (O4 > 0.0)
      then
         return Proper;
      end if;

      --  Improper: an endpoint of one lies on the other.
      if abs (O1) <= Epsilon and then On_Segment (T.A, S) then
         return Improper;
      end if;
      if abs (O2) <= Epsilon and then On_Segment (T.B, S) then
         return Improper;
      end if;
      if abs (O3) <= Epsilon and then On_Segment (S.A, T) then
         return Improper;
      end if;
      if abs (O4) <= Epsilon and then On_Segment (S.B, T) then
         return Improper;
      end if;

      return None;
   end Classify_Intersection;

   function Segments_Intersect (S, T : Segment) return Boolean is
   begin
      return Classify_Intersection (S, T) /= None;
   end Segments_Intersect;

   function Has_Unique_Intersection_Point (S, T : Segment) return Boolean is
      K : constant Intersection_Kind := Classify_Intersection (S, T);
   begin
      return K = Proper or else K = Improper;
   end Has_Unique_Intersection_Point;

   function Intersection_Point (S, T : Segment) return Point is
      K : Intersection_Kind;
      O1, O2, O3, O4 : Real;
   begin
      Require_Nondegenerate (S);
      Require_Nondegenerate (T);
      K := Classify_Intersection (S, T);
      if K /= Proper and then K /= Improper then
         raise Invalid_Argument;
      end if;

      --  For Improper with an endpoint on the other segment, prefer that
      --  endpoint (avoids parametric noise at T-junctions).
      if K = Improper then
         O1 := Orient2D (S.A, S.B, T.A);
         O2 := Orient2D (S.A, S.B, T.B);
         O3 := Orient2D (T.A, T.B, S.A);
         O4 := Orient2D (T.A, T.B, S.B);
         if abs (O1) <= Epsilon and then On_Segment (T.A, S) then
            return T.A;
         end if;
         if abs (O2) <= Epsilon and then On_Segment (T.B, S) then
            return T.B;
         end if;
         if abs (O3) <= Epsilon and then On_Segment (S.A, T) then
            return S.A;
         end if;
         if abs (O4) <= Epsilon and then On_Segment (S.B, T) then
            return S.B;
         end if;
      end if;

      return Line_Intersection_Parametric (S, T);
   end Intersection_Point;

   function Overlap_Representative (S, T : Segment) return Point is
      Kind : Intersection_Kind;
      Rep  : Point;
   begin
      Require_Nondegenerate (S);
      Require_Nondegenerate (T);
      Classify_Collinear (S, T, Kind, Rep);
      --  Only valid when the four orientations are all ~0 AND overlap.
      if Classify_Intersection (S, T) /= Collinear_Overlap then
         raise Invalid_Argument;
      end if;
      return Rep;
   end Overlap_Representative;

   ---------------------------------------------------------------------------
   -- Accessors / constructors
   ---------------------------------------------------------------------------

   function Empty_Intersection_List return Intersection_List is
      L : Intersection_List;
   begin
      L.Count := 0;
      return L;
   end Empty_Intersection_List;

   function Make_Segment (Ax, Ay, Bx, By : Real) return Segment is
   begin
      return (A => (X => Ax, Y => Ay), B => (X => Bx, Y => By));
   end Make_Segment;

   function Make_Point (X, Y : Real) return Point is
   begin
      return (X => X, Y => Y);
   end Make_Point;

   ---------------------------------------------------------------------------
   -- Intersection list helpers
   ---------------------------------------------------------------------------

   procedure Append_Intersection
     (List : in out Intersection_List;
      Loc  : Point;
      I, J : Segment_Index;
      Kind : Intersection_Kind)
   is
      Lo, Hi : Segment_Index;
   begin
      if I < J then
         Lo := I;
         Hi := J;
      else
         Lo := J;
         Hi := I;
      end if;
      --  Skip duplicates (same unordered pair).
      for K in 1 .. List.Count loop
         if List.Items (K).Seg_I = Lo and then List.Items (K).Seg_J = Hi then
            return;
         end if;
      end loop;
      if List.Count = Max_Intersections then
         return;
      end if;
      List.Count := List.Count + 1;
      List.Items (List.Count) :=
        (Location => Loc, Seg_I => Lo, Seg_J => Hi, Kind => Kind);
   end Append_Intersection;

   function Same_Intersection_Set
     (Left, Right : Intersection_List; Tol : Real := Epsilon) return Boolean
   is
      type Seen_Array is array (1 .. Max_Intersections) of Boolean;
      Used  : Seen_Array := [others => False];
      Found : Boolean;
   begin
      if Left.Count /= Right.Count then
         return False;
      end if;
      for I in 1 .. Left.Count loop
         Found := False;
         for J in 1 .. Right.Count loop
            if not Used (J)
              and then Left.Items (I).Seg_I = Right.Items (J).Seg_I
              and then Left.Items (I).Seg_J = Right.Items (J).Seg_J
              and then Left.Items (I).Kind = Right.Items (J).Kind
              and then Near_Point
                         (Left.Items (I).Location,
                          Right.Items (J).Location,
                          Tol)
            then
               Used (J) := True;
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            return False;
         end if;
      end loop;
      return True;
   end Same_Intersection_Set;

   function Filter_By_Kind
     (List : Intersection_List; Kind : Intersection_Kind)
      return Intersection_List
   is
      Out_L : Intersection_List;
   begin
      Out_L.Count := 0;
      for I in 1 .. List.Count loop
         if List.Items (I).Kind = Kind then
            if Out_L.Count < Max_Intersections then
               Out_L.Count := Out_L.Count + 1;
               Out_L.Items (Out_L.Count) := List.Items (I);
            end if;
         end if;
      end loop;
      return Out_L;
   end Filter_By_Kind;

   ---------------------------------------------------------------------------
   -- Brute-force all-pairs
   ---------------------------------------------------------------------------

   function Representative_For
     (S, T : Segment; Kind : Intersection_Kind) return Point
   is
      Rep : Point;
      K2  : Intersection_Kind;
   begin
      case Kind is
         when Proper | Improper =>
            return Intersection_Point (S, T);
         when Collinear_Overlap =>
            Classify_Collinear (S, T, K2, Rep);
            pragma Unreferenced (K2);
            return Rep;
         when None =>
            return (0.0, 0.0);
      end case;
   end Representative_For;

   function Brute_Force_Find_All
     (Segments : Segment_Set) return Intersection_List
   is
      List : Intersection_List;
      Kind : Intersection_Kind;
      Loc  : Point;
      I0   : Segment_Index;
      J0   : Segment_Index;
   begin
      Require_Segment_Count (Segments'Length);
      Require_All_Nondegenerate (Segments);
      List.Count := 0;
      for I in Segments'Range loop
         for J in Segments'Range loop
            if J > I then
               Kind := Classify_Intersection (Segments (I), Segments (J));
               if Kind /= None then
                  Loc := Representative_For (Segments (I), Segments (J), Kind);
                  I0 := Segment_Index (I - Segments'First + 1);
                  J0 := Segment_Index (J - Segments'First + 1);
                  Append_Intersection (List, Loc, I0, J0, Kind);
               end if;
            end if;
         end loop;
      end loop;
      return List;
   end Brute_Force_Find_All;

   ---------------------------------------------------------------------------
   -- Thin Bentley–Ottmann-style Find_All (Proper crossings only)
   ---------------------------------------------------------------------------
   --  Educational dense-array sweep with endpoint + discovered-crossing
   --  events (Bentley & Ottmann 1979 sketch). Status is a dense array
   --  ordered by Y_At_X — not a balanced BST. Fine for Max_Segments ≤ 32.

   function Point_Before (P, Q : Point) return Boolean is
   begin
      if not Near (P.X, Q.X) then
         return P.X < Q.X;
      end if;
      if not Near (P.Y, Q.Y) then
         return P.Y < Q.Y;
      end if;
      return False;
   end Point_Before;

   function Left_Of (S : Segment) return Point is
   begin
      if Point_Before (S.A, S.B) then
         return S.A;
      else
         return S.B;
      end if;
   end Left_Of;

   function Right_Of (S : Segment) return Point is
   begin
      if Point_Before (S.A, S.B) then
         return S.B;
      else
         return S.A;
      end if;
   end Right_Of;

   function Y_At_X (S : Segment; X : Real) return Real is
      L  : constant Point := Left_Of (S);
      R  : constant Point := Right_Of (S);
      DX : constant Real := R.X - L.X;
      Tp : Real;
   begin
      if abs (DX) <= Epsilon then
         return 0.5 * (L.Y + R.Y);
      end if;
      Tp := (X - L.X) / DX;
      return L.Y + Tp * (R.Y - L.Y);
   end Y_At_X;

   type Event_Kind is (Left_Endpoint, Crossing, Right_Endpoint);

   type Sweep_Event is record
      Kind  : Event_Kind := Left_Endpoint;
      Loc   : Point := (0.0, 0.0);
      Seg_A : Segment_Index := 1;
      Seg_B : Segment_Index := 1;
   end record;

   Max_Events : constant Positive := 2 * Max_Segments + Max_Intersections;
   type Event_Array is array (1 .. Max_Events) of Sweep_Event;
   type Status_Array is array (1 .. Max_Segments) of Segment_Index;
   type Reported_Matrix is array (Segment_Index, Segment_Index) of Boolean;

   function Event_Kind_Rank (K : Event_Kind) return Natural is
   begin
      case K is
         when Left_Endpoint  => return 0;
         when Crossing       => return 1;
         when Right_Endpoint => return 2;
      end case;
   end Event_Kind_Rank;

   function Event_Before (E1, E2 : Sweep_Event) return Boolean is
   begin
      if not Near (E1.Loc.X, E2.Loc.X) then
         return E1.Loc.X < E2.Loc.X;
      end if;
      if not Near (E1.Loc.Y, E2.Loc.Y) then
         return E1.Loc.Y < E2.Loc.Y;
      end if;
      if E1.Kind /= E2.Kind then
         return Event_Kind_Rank (E1.Kind) < Event_Kind_Rank (E2.Kind);
      end if;
      if E1.Seg_A /= E2.Seg_A then
         return E1.Seg_A < E2.Seg_A;
      end if;
      return E1.Seg_B < E2.Seg_B;
   end Event_Before;

   procedure Sort_Events (E : in out Event_Array; N : Natural) is
      Tmp : Sweep_Event;
      J   : Integer;
   begin
      for I in 2 .. N loop
         Tmp := E (I);
         J := I - 1;
         while J >= 1 and then Event_Before (Tmp, E (J)) loop
            E (J + 1) := E (J);
            J := J - 1;
         end loop;
         E (J + 1) := Tmp;
      end loop;
   end Sort_Events;

   function Find_All (Segments : Segment_Set) return Intersection_List is
      N       : constant Natural := Segments'Length;
      List    : Intersection_List;
      Ev      : Event_Array;
      Ev_N    : Natural := 0;
      Active  : Status_Array := [others => 1];
      A_Count : Natural := 0;
      Sweep_X : Real := 0.0;
      Reported : Reported_Matrix := [others => [others => False]];

      function Seg_At (Idx : Segment_Index) return Segment is
        (Segments (Segments'First + Integer (Idx) - 1));

      function Status_Y (Idx : Segment_Index) return Real is
        (Y_At_X (Seg_At (Idx), Sweep_X));

      procedure Enqueue_Crossing (I, J : Segment_Index) is
         S : constant Segment := Seg_At (I);
         T : constant Segment := Seg_At (J);
         Lo, Hi : Segment_Index;
         P : Point;
         Exists : Boolean := False;
      begin
         if Classify_Intersection (S, T) /= Proper then
            return;
         end if;
         if I < J then
            Lo := I;
            Hi := J;
         else
            Lo := J;
            Hi := I;
         end if;
         --  Already reported (or currently being processed) — do not requeue.
         if Reported (Lo, Hi) then
            return;
         end if;
         P := Intersection_Point (S, T);
         --  Keep crossings at or to the right of the sweep abscissa.
         --  (Strictly-right-only would miss vertical/horizontal Proper hits
         --  whose meeting X equals the inserted left endpoint's X.)
         if P.X < Sweep_X - Epsilon then
            return;
         end if;
         for K in 1 .. Ev_N loop
            if Ev (K).Kind = Crossing
              and then Ev (K).Seg_A = Lo
              and then Ev (K).Seg_B = Hi
            then
               Exists := True;
               exit;
            end if;
         end loop;
         if Exists or else Ev_N = Max_Events then
            return;
         end if;
         Ev_N := Ev_N + 1;
         Ev (Ev_N) :=
           (Kind => Crossing, Loc => P, Seg_A => Lo, Seg_B => Hi);
      end Enqueue_Crossing;

      procedure Report_Proper (I, J : Segment_Index; Loc : Point) is
         Lo, Hi : Segment_Index;
      begin
         if I < J then
            Lo := I;
            Hi := J;
         else
            Lo := J;
            Hi := I;
         end if;
         if Reported (Lo, Hi) then
            return;
         end if;
         Reported (Lo, Hi) := True;
         Append_Intersection (List, Loc, Lo, Hi, Proper);
      end Report_Proper;

      function Find_Pos (Idx : Segment_Index) return Natural is
      begin
         for K in 1 .. A_Count loop
            if Active (K) = Idx then
               return K;
            end if;
         end loop;
         return 0;
      end Find_Pos;

      procedure Insert_Status (Idx : Segment_Index) is
         Pos : Natural := A_Count + 1;
         Y   : constant Real := Status_Y (Idx);
      begin
         for K in 1 .. A_Count loop
            if Y < Status_Y (Active (K)) - Epsilon then
               Pos := K;
               exit;
            end if;
         end loop;
         for K in reverse Pos .. A_Count loop
            Active (K + 1) := Active (K);
         end loop;
         Active (Pos) := Idx;
         A_Count := A_Count + 1;
         if Pos > 1 then
            Enqueue_Crossing (Active (Pos - 1), Idx);
         end if;
         if Pos < A_Count then
            Enqueue_Crossing (Idx, Active (Pos + 1));
         end if;
      end Insert_Status;

      procedure Delete_Status (Idx : Segment_Index) is
         Pos : constant Natural := Find_Pos (Idx);
      begin
         if Pos = 0 then
            return;
         end if;
         if Pos > 1 and then Pos < A_Count then
            Enqueue_Crossing (Active (Pos - 1), Active (Pos + 1));
         end if;
         for K in Pos .. A_Count - 1 loop
            Active (K) := Active (K + 1);
         end loop;
         A_Count := A_Count - 1;
      end Delete_Status;

      procedure Swap_Status (I, J : Segment_Index) is
         Pi : constant Natural := Find_Pos (I);
         Pj : constant Natural := Find_Pos (J);
         Tmp : Segment_Index;
         Lo, Hi : Natural;
      begin
         if Pi = 0 or else Pj = 0 then
            return;
         end if;
         Tmp := Active (Pi);
         Active (Pi) := Active (Pj);
         Active (Pj) := Tmp;
         if Pi < Pj then
            Lo := Pi;
            Hi := Pj;
         else
            Lo := Pj;
            Hi := Pi;
         end if;
         --  New outer neighbours after the swap.
         if Lo > 1 then
            Enqueue_Crossing (Active (Lo - 1), Active (Lo));
         end if;
         if Hi < A_Count then
            Enqueue_Crossing (Active (Hi), Active (Hi + 1));
         end if;
      end Swap_Status;

   begin
      Require_Segment_Count (N);
      Require_All_Nondegenerate (Segments);
      List.Count := 0;

      for I in 1 .. N loop
         declare
            Idx : constant Segment_Index := Segment_Index (I);
            S   : constant Segment := Seg_At (Idx);
         begin
            Ev_N := Ev_N + 1;
            Ev (Ev_N) :=
              (Kind  => Left_Endpoint,
               Loc   => Left_Of (S),
               Seg_A => Idx,
               Seg_B => Idx);
            Ev_N := Ev_N + 1;
            Ev (Ev_N) :=
              (Kind  => Right_Endpoint,
               Loc   => Right_Of (S),
               Seg_A => Idx,
               Seg_B => Idx);
         end;
      end loop;

      declare
         E_I : Natural := 1;
      begin
         while E_I <= Ev_N loop
            --  Re-sort remaining queue when crossings were appended.
            Sort_Events (Ev, Ev_N);
            --  After sort, find the next unprocessed by re-scanning from
            --  the start for the chronologically first event not yet done
            --  is awkward; instead process head and compact.
            declare
               Cur : constant Sweep_Event := Ev (1);
            begin
               --  Shift queue left (pop front).
               for K in 1 .. Ev_N - 1 loop
                  Ev (K) := Ev (K + 1);
               end loop;
               Ev_N := Ev_N - 1;
               Sweep_X := Cur.Loc.X;
               case Cur.Kind is
                  when Left_Endpoint =>
                     Insert_Status (Cur.Seg_A);
                  when Right_Endpoint =>
                     Delete_Status (Cur.Seg_A);
                  when Crossing =>
                     Report_Proper (Cur.Seg_A, Cur.Seg_B, Cur.Loc);
                     Swap_Status (Cur.Seg_A, Cur.Seg_B);
               end case;
            end;
            E_I := 1;  -- always process front after re-sort next iteration
            --  Loop condition uses Ev_N; E_I unused except to structure.
            exit when Ev_N = 0;
         end loop;
      end;

      return List;
   end Find_All;

   function Intersection_Count_Of
     (Segments : Segment_Set) return Intersection_Count
   is
      L : constant Intersection_List := Find_All (Segments);
   begin
      return L.Count;
   end Intersection_Count_Of;

end Line_Segment_Intersection;
