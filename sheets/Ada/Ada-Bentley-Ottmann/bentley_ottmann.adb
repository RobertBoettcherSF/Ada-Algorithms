--  Bentley_Ottmann body — educational sweep-line segment intersection.

pragma Ada_2022;

package body Bentley_Ottmann
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
      L : constant Point := Left_Of (S);
      R : constant Point := Right_Of (S);
      DX : constant Real := R.X - L.X;
      T  : Real;
   begin
      if abs (DX) <= Epsilon then
         --  Near-vertical: educational mean of endpoint Y.
         return 0.5 * (L.Y + R.Y);
      end if;
      T := (X - L.X) / DX;
      return L.Y + T * (R.Y - L.Y);
   end Y_At_X;

   function Event_Kind_Rank (K : Event_Kind) return Natural is
   begin
      case K is
         when Left_Endpoint  => return 0;
         when Crossing       => return 1;
         when Right_Endpoint => return 2;
      end case;
   end Event_Kind_Rank;

   function Event_Before (E1, E2 : Event) return Boolean is
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

   ---------------------------------------------------------------------------
   -- Proper segment intersection
   ---------------------------------------------------------------------------

   function Segments_Properly_Intersect (S, T : Segment) return Boolean is
      O1 : constant Real := Orient2D (S.A, S.B, T.A);
      O2 : constant Real := Orient2D (S.A, S.B, T.B);
      O3 : constant Real := Orient2D (T.A, T.B, S.A);
      O4 : constant Real := Orient2D (T.A, T.B, S.B);
   begin
      --  Strict opposite sides on both segments ⇒ proper crossing.
      --  Near-zero orientations (endpoint / collinear) are rejected:
      --  limited educational handling of overlapping collinear cases.
      if abs (O1) <= Epsilon or else abs (O2) <= Epsilon
        or else abs (O3) <= Epsilon or else abs (O4) <= Epsilon
      then
         return False;
      end if;
      return (O1 > 0.0) /= (O2 > 0.0)
        and then (O3 > 0.0) /= (O4 > 0.0);
   end Segments_Properly_Intersect;

   function Intersection_Point (S, T : Segment) return Point is
      A  : constant Point := S.A;
      B  : constant Point := S.B;
      C  : constant Point := T.A;
      D  : constant Point := T.B;
      DX1 : constant Real := B.X - A.X;
      DY1 : constant Real := B.Y - A.Y;
      DX2 : constant Real := D.X - C.X;
      DY2 : constant Real := D.Y - C.Y;
      Den : constant Real := DX1 * DY2 - DY1 * DX2;
      T_Param : Real;
   begin
      if abs (Den) <= Epsilon then
         --  Near-parallel educational fallback: midpoint of midpoints.
         return
           (X => 0.25 * (A.X + B.X + C.X + D.X),
            Y => 0.25 * (A.Y + B.Y + C.Y + D.Y));
      end if;
      T_Param := ((C.X - A.X) * DY2 - (C.Y - A.Y) * DX2) / Den;
      return
        (X => A.X + T_Param * DX1,
         Y => A.Y + T_Param * DY1);
   end Intersection_Point;

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

   type Reported_Matrix is
     array (Segment_Index, Segment_Index) of Boolean;

   procedure Append_Intersection
     (List     : in out Intersection_List;
      Reported : in out Reported_Matrix;
      Loc      : Point;
      I, J     : Segment_Index)
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

      if Reported (Lo, Hi) then
         return;
      end if;

      if List.Count = Max_Intersections then
         return;
      end if;
      List.Count := List.Count + 1;
      List.Items (List.Count) :=
        (Location => Loc, Seg_I => Lo, Seg_J => Hi);
      Reported (Lo, Hi) := True;
   end Append_Intersection;

   function Same_Intersection_Set
     (Left, Right : Intersection_List; Tol : Real := Epsilon) return Boolean
   is
      type Seen_Array is array (1 .. Max_Intersections) of Boolean;
      Used : Seen_Array := [others => False];
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

   ---------------------------------------------------------------------------
   -- Event queue (simple insertion into a sorted dense array)
   ---------------------------------------------------------------------------

   function Events_Equalish (E1, E2 : Event) return Boolean is
   begin
      return E1.Kind = E2.Kind
        and then Near_Point (E1.Loc, E2.Loc)
        and then E1.Seg_A = E2.Seg_A
        and then E1.Seg_B = E2.Seg_B;
   end Events_Equalish;

   procedure Insert_Event (Q : in out Event_Queue; E : Event) is
      Pos : Event_Count;
   begin
      --  Skip exact duplicates (same kind / point / segment pair).
      for K in 1 .. Q.Count loop
         if Events_Equalish (Q.Items (K), E) then
            return;
         end if;
      end loop;

      if Q.Count = Max_Events then
         return;
      end if;

      Pos := Q.Count + 1;
      while Pos > 1 and then Event_Before (E, Q.Items (Pos - 1)) loop
         Q.Items (Pos) := Q.Items (Pos - 1);
         Pos := Pos - 1;
      end loop;
      Q.Items (Pos) := E;
      Q.Count := Q.Count + 1;
   end Insert_Event;

   procedure Pop_Event (Q : in out Event_Queue; E : out Event) is
   begin
      E := Q.Items (1);
      for K in 2 .. Q.Count loop
         Q.Items (K - 1) := Q.Items (K);
      end loop;
      Q.Count := Q.Count - 1;
   end Pop_Event;

   ---------------------------------------------------------------------------
   -- Sweep status (dense array sorted by Y at sweep X)
   ---------------------------------------------------------------------------

   procedure Sort_Status
     (Status : in out Sweep_Status;
      Segs   : Segment_Array;
      X      : Real)
   is
      I, J : Natural;
      Key  : Segment_Index;
      Key_Y : Real;
   begin
      --  Insertion sort by Y_At_X; tie-break by segment index.
      I := 2;
      while I <= Status.Count loop
         Key := Status.Active (I);
         Key_Y := Y_At_X (Segs (Key), X);
         J := I;
         while J > 1
           and then
             (Y_At_X (Segs (Status.Active (J - 1)), X) > Key_Y + Epsilon
              or else
                (Near (Y_At_X (Segs (Status.Active (J - 1)), X), Key_Y)
                 and then Status.Active (J - 1) > Key))
         loop
            Status.Active (J) := Status.Active (J - 1);
            J := J - 1;
         end loop;
         Status.Active (J) := Key;
         I := I + 1;
      end loop;
   end Sort_Status;

   function Status_Index_Of
     (Status : Sweep_Status; Seg : Segment_Index) return Natural
   is
   begin
      for K in 1 .. Status.Count loop
         if Status.Active (K) = Seg then
            return K;
         end if;
      end loop;
      return 0;
   end Status_Index_Of;

   procedure Status_Insert
     (Status : in out Sweep_Status;
      Segs   : Segment_Array;
      Seg    : Segment_Index;
      X      : Real)
   is
   begin
      if Status.Count = Max_Segments then
         return;
      end if;
      if Status_Index_Of (Status, Seg) /= 0 then
         return;
      end if;
      Status.Count := Status.Count + 1;
      Status.Active (Status.Count) := Seg;
      Sort_Status (Status, Segs, X);
   end Status_Insert;

   procedure Status_Remove
     (Status : in out Sweep_Status; Seg : Segment_Index)
   is
      Pos : constant Natural := Status_Index_Of (Status, Seg);
   begin
      if Pos = 0 then
         return;
      end if;
      for K in Pos + 1 .. Status.Count loop
         Status.Active (K - 1) := Status.Active (K);
      end loop;
      Status.Count := Status.Count - 1;
   end Status_Remove;


   ---------------------------------------------------------------------------
   -- Enqueue a future crossing of two currently-adjacent status neighbours
   ---------------------------------------------------------------------------

   procedure Maybe_Enqueue_Crossing
     (Q        : in out Event_Queue;
      Segs     : Segment_Array;
      Reported : Reported_Matrix;
      I, J     : Segment_Index;
      Sweep_X  : Real)
   is
      P  : Point;
      Lo, Hi : Segment_Index;
   begin
      if I = J then
         return;
      end if;
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
      if not Segments_Properly_Intersect (Segs (I), Segs (J)) then
         return;
      end if;
      P := Intersection_Point (Segs (I), Segs (J));
      --  At or to the right of the sweep (needed for vertical segments
      --  whose crossing shares the current abscissa). Already-reported
      --  pairs are never re-enqueued, so same-X events cannot loop.
      if P.X + Epsilon < Sweep_X then
         return;
      end if;
      Insert_Event
        (Q,
         (Kind  => Crossing,
          Loc   => P,
          Seg_A => Lo,
          Seg_B => Hi));
   end Maybe_Enqueue_Crossing;

   ---------------------------------------------------------------------------
   -- Core sweep (shared by Find_Intersections and Any_Intersection)
   ---------------------------------------------------------------------------


   procedure Enqueue_All_Adjacent
     (Q        : in out Event_Queue;
      Status   : Sweep_Status;
      Segs     : Segment_Array;
      Reported : Reported_Matrix;
      Sweep_X  : Real)
   is
   begin
      --  Educational robustness for Max_Segments ≤ 32: after every event,
      --  re-consider crossings of all currently adjacent status pairs.
      for K in 1 .. Status.Count - 1 loop
         Maybe_Enqueue_Crossing
           (Q, Segs, Reported,
            Status.Active (K),
            Status.Active (K + 1),
            Sweep_X);
      end loop;
   end Enqueue_All_Adjacent;

   procedure Run_Sweep
     (Segments   : Segment_Array;
      First_Only : Boolean;
      Result     : out Intersection_List;
      Found_Any  : out Boolean)
   is
      Q        : Event_Queue;
      Status   : Sweep_Status;
      Reported : Reported_Matrix := [others => [others => False]];
      E        : Event;
      Pos, Above, Below : Natural;
      Si, Sj : Segment_Index;
      Sweep_X : Real;
      N : constant Natural := Segments'Length;
      Segs : Segment_Array (1 .. N);
   begin
      Result := Empty_Intersection_List;
      Found_Any := False;
      Status.Count := 0;
      Q.Count := 0;

      for K in Segments'Range loop
         Segs (K - Segments'First + 1) := Segments (K);
      end loop;

      for K in 1 .. N loop
         Insert_Event
           (Q,
            (Kind  => Left_Endpoint,
             Loc   => Left_Of (Segs (K)),
             Seg_A => Segment_Index (K),
             Seg_B => Segment_Index (K)));
         Insert_Event
           (Q,
            (Kind  => Right_Endpoint,
             Loc   => Right_Of (Segs (K)),
             Seg_A => Segment_Index (K),
             Seg_B => Segment_Index (K)));
      end loop;

      while Q.Count > 0 loop
         Pop_Event (Q, E);
         Sweep_X := E.Loc.X;

         case E.Kind is
            when Left_Endpoint =>
               Status_Insert (Status, Segs, E.Seg_A, Sweep_X);
               Pos := Status_Index_Of (Status, E.Seg_A);
               if Pos > 1 then
                  Maybe_Enqueue_Crossing
                    (Q, Segs, Reported,
                     Status.Active (Pos - 1), E.Seg_A, Sweep_X);
               end if;
               if Pos >= 1 and then Pos < Status.Count then
                  Maybe_Enqueue_Crossing
                    (Q, Segs, Reported,
                     E.Seg_A, Status.Active (Pos + 1), Sweep_X);
               end if;

            when Right_Endpoint =>
               Pos := Status_Index_Of (Status, E.Seg_A);
               if Pos > 0 then
                  Above := (if Pos < Status.Count then Pos + 1 else 0);
                  Below := (if Pos > 1 then Pos - 1 else 0);
                  Status_Remove (Status, E.Seg_A);
                  if Below > 0 and then Above > 0
                    and then Below < Status.Count
                  then
                     Maybe_Enqueue_Crossing
                       (Q, Segs, Reported,
                        Status.Active (Below),
                        Status.Active (Below + 1),
                        Sweep_X);
                  end if;
               end if;

            when Crossing =>
               --  de Berg-style multi-segment meeting point: gather every
               --  active segment whose supporting line passes near E.Loc,
               --  report all unreported proper pairs among them, then
               --  reverse that contiguous status block.
               declare
                  Involved : Status_Array := [others => 1];
                  N_Inv    : Natural := 0;
                  Min_Pos, Max_Pos : Natural := 0;
                  Pos_K : Natural;
                  Ok : Boolean;
                  Tmp : Segment_Index;
               begin
                  for K in 1 .. Status.Count loop
                     Si := Status.Active (K);
                     --  Near the sweep point on the segment's line, and
                     --  within the segment's x-span (educational).
                     if abs (Y_At_X (Segs (Si), Sweep_X)
                               - E.Loc.Y) <= 100.0 * Epsilon
                       and then Left_Of (Segs (Si)).X <= Sweep_X + Epsilon
                       and then Right_Of (Segs (Si)).X >= Sweep_X - Epsilon
                     then
                        N_Inv := N_Inv + 1;
                        Involved (N_Inv) := Si;
                        Pos_K := K;
                        if Min_Pos = 0 or else Pos_K < Min_Pos then
                           Min_Pos := Pos_K;
                        end if;
                        if Pos_K > Max_Pos then
                           Max_Pos := Pos_K;
                        end if;
                     end if;
                  end loop;

                  --  Fallback: at least the event's two segments.
                  if N_Inv < 2 then
                     N_Inv := 0;
                     if Status_Index_Of (Status, E.Seg_A) /= 0 then
                        N_Inv := N_Inv + 1;
                        Involved (N_Inv) := E.Seg_A;
                     end if;
                     if Status_Index_Of (Status, E.Seg_B) /= 0 then
                        N_Inv := N_Inv + 1;
                        Involved (N_Inv) := E.Seg_B;
                     end if;
                     Min_Pos := Status_Index_Of (Status, E.Seg_A);
                     Max_Pos := Status_Index_Of (Status, E.Seg_B);
                     if Min_Pos > Max_Pos then
                        Pos_K := Min_Pos;
                        Min_Pos := Max_Pos;
                        Max_Pos := Pos_K;
                     end if;
                  end if;

                  Ok := False;
                  for A in 1 .. N_Inv loop
                     for B in A + 1 .. N_Inv loop
                        Si := Involved (A);
                        Sj := Involved (B);
                        if not Reported (Segment_Index'Min (Si, Sj),
                                         Segment_Index'Max (Si, Sj))
                          and then
                            Segments_Properly_Intersect
                              (Segs (Si), Segs (Sj))
                        then
                           Append_Intersection
                             (Result, Reported, E.Loc, Si, Sj);
                           Ok := True;
                           Found_Any := True;
                           if First_Only then
                              return;
                           end if;
                        end if;
                     end loop;
                  end loop;

                  if Ok and then Min_Pos > 0 and then Max_Pos >= Min_Pos then
                     --  Reverse the contiguous involved block in status.
                     declare
                        L : Natural := Min_Pos;
                        R : Natural := Max_Pos;
                     begin
                        while L < R loop
                           Tmp := Status.Active (L);
                           Status.Active (L) := Status.Active (R);
                           Status.Active (R) := Tmp;
                           L := L + 1;
                           R := R - 1;
                        end loop;
                     end;
                     if Min_Pos > 1 then
                        Maybe_Enqueue_Crossing
                          (Q, Segs, Reported,
                           Status.Active (Min_Pos - 1),
                           Status.Active (Min_Pos),
                           Sweep_X);
                     end if;
                     if Max_Pos < Status.Count then
                        Maybe_Enqueue_Crossing
                          (Q, Segs, Reported,
                           Status.Active (Max_Pos),
                           Status.Active (Max_Pos + 1),
                           Sweep_X);
                     end if;
                  end if;
               end;
         end case;

         --  Order status as just to the right of the sweep (ε-perturbation).
         --  Shared endpoints / verticals otherwise tie-break by index and can
         --  hide true adjacencies needed to discover crossings.
         if Status.Count > 1 then
            Sort_Status (Status, Segs, Sweep_X + 10.0 * Epsilon);
         end if;
         Enqueue_All_Adjacent (Q, Status, Segs, Reported, Sweep_X);
      end loop;
   end Run_Sweep;

   ---------------------------------------------------------------------------
   -- Public entry points
   ---------------------------------------------------------------------------

   function Find_Intersections
     (Segments : Segment_Set) return Intersection_List
   is
      Result : Intersection_List;
      Any    : Boolean;
   begin
      Require_Segment_Count (Segments'Length);
      Run_Sweep (Segments, False, Result, Any);
      pragma Unreferenced (Any);
      return Result;
   end Find_Intersections;

   function Intersection_Count_Of
     (Segments : Segment_Set) return Intersection_Count
   is
      L : constant Intersection_List := Find_Intersections (Segments);
   begin
      return L.Count;
   end Intersection_Count_Of;

   function Any_Intersection (Segments : Segment_Set) return Boolean is
      Result : Intersection_List;
      Any    : Boolean;
   begin
      Require_Segment_Count (Segments'Length);
      Run_Sweep (Segments, True, Result, Any);
      pragma Unreferenced (Result);
      return Any;
   end Any_Intersection;

   function Brute_Force_Intersections
     (Segments : Segment_Set) return Intersection_List
   is
      Result   : Intersection_List := Empty_Intersection_List;
      Reported : Reported_Matrix := [others => [others => False]];
      N        : constant Natural := Segments'Length;
      I_Idx, J_Idx : Segment_Index;
      P : Point;
   begin
      Require_Segment_Count (N);
      for I in Segments'Range loop
         for J in I + 1 .. Segments'Last loop
            if Segments_Properly_Intersect (Segments (I), Segments (J)) then
               P := Intersection_Point (Segments (I), Segments (J));
               I_Idx := Segment_Index (I - Segments'First + 1);
               J_Idx := Segment_Index (J - Segments'First + 1);
               Append_Intersection (Result, Reported, P, I_Idx, J_Idx);
            end if;
         end loop;
      end loop;
      return Result;
   end Brute_Force_Intersections;

end Bentley_Ottmann;
