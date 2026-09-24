--  Sweep_And_Prune body — AABB helpers, endpoint sweep, brute & SAP.

pragma Ada_2022;

package body Sweep_And_Prune
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Local helpers
   -------------------------------------------------------------------------

   function Before (L, R : Endpoint) return Boolean is
   begin
      if L.Value < R.Value then
         return True;
      elsif L.Value > R.Value then
         return False;
      else
         --  Equal values: process starts (+1) before ends (-1) so that
         --  closed intervals that merely touch still overlap.
         return L.Kind > R.Kind;
      end if;
   end Before;

   function Pair_Less (L, R : Pair) return Boolean is
   begin
      if L.A < R.A then
         return True;
      elsif L.A > R.A then
         return False;
      else
         return L.B < R.B;
      end if;
   end Pair_Less;

   -------------------------------------------------------------------------
   -- AABB helpers
   -------------------------------------------------------------------------

   function Is_Valid_AABB (B : AABB_2D) return Boolean is
   begin
      return B.Min_X <= B.Max_X and then B.Min_Y <= B.Max_Y;
   end Is_Valid_AABB;

   function Is_Valid_AABB (B : AABB_3D) return Boolean is
   begin
      return B.Min_X <= B.Max_X
        and then B.Min_Y <= B.Max_Y
        and then B.Min_Z <= B.Max_Z;
   end Is_Valid_AABB;

   function Make_AABB
     (Min_X, Max_X, Min_Y, Max_Y : Real) return AABB_2D
   is
   begin
      if Min_X > Max_X or else Min_Y > Max_Y then
         raise Invalid_Argument with "Make_AABB: inverted extents";
      end if;
      return (Min_X, Max_X, Min_Y, Max_Y);
   end Make_AABB;

   function Make_AABB_3D
     (Min_X, Max_X, Min_Y, Max_Y, Min_Z, Max_Z : Real) return AABB_3D
   is
   begin
      if Min_X > Max_X
        or else Min_Y > Max_Y
        or else Min_Z > Max_Z
      then
         raise Invalid_Argument with "Make_AABB_3D: inverted extents";
      end if;
      return (Min_X, Max_X, Min_Y, Max_Y, Min_Z, Max_Z);
   end Make_AABB_3D;

   function Projections_Overlap
     (A_Min, A_Max, B_Min, B_Max : Real) return Boolean
   is
   begin
      return A_Max >= B_Min and then B_Max >= A_Min;
   end Projections_Overlap;

   function AABBs_Overlap (A, B : AABB_2D) return Boolean is
   begin
      return Projections_Overlap (A.Min_X, A.Max_X, B.Min_X, B.Max_X)
        and then Projections_Overlap (A.Min_Y, A.Max_Y, B.Min_Y, B.Max_Y);
   end AABBs_Overlap;

   function AABBs_Overlap (A, B : AABB_3D) return Boolean is
   begin
      return Projections_Overlap (A.Min_X, A.Max_X, B.Min_X, B.Max_X)
        and then Projections_Overlap (A.Min_Y, A.Max_Y, B.Min_Y, B.Max_Y)
        and then Projections_Overlap (A.Min_Z, A.Max_Z, B.Min_Z, B.Max_Z);
   end AABBs_Overlap;

   -------------------------------------------------------------------------
   -- World construction
   -------------------------------------------------------------------------

   function Empty_World return World is
   begin
      return (Boxes => [others => (0.0, 0.0, 0.0, 0.0)], Count => 0);
   end Empty_World;

   function Empty_World_3D return World_3D is
   begin
      return
        (Boxes => [others => (0.0, 0.0, 0.0, 0.0, 0.0, 0.0)], Count => 0);
   end Empty_World_3D;

   procedure Clear (W : in out World) is
   begin
      W.Count := 0;
   end Clear;

   procedure Clear (W : in out World_3D) is
   begin
      W.Count := 0;
   end Clear;

   procedure Add_Box (W : in out World; Box : AABB_2D) is
   begin
      if not Is_Valid_AABB (Box) then
         raise Invalid_Argument with "Add_Box: invalid AABB";
      end if;
      if W.Count = Max_Objects then
         raise Capacity_Exceeded with "Add_Box: Max_Objects reached";
      end if;
      W.Count := W.Count + 1;
      W.Boxes (W.Count) := Box;
   end Add_Box;

   procedure Add_Box (W : in out World_3D; Box : AABB_3D) is
   begin
      if not Is_Valid_AABB (Box) then
         raise Invalid_Argument with "Add_Box 3D: invalid AABB";
      end if;
      if W.Count = Max_Objects then
         raise Capacity_Exceeded with "Add_Box 3D: Max_Objects reached";
      end if;
      W.Count := W.Count + 1;
      W.Boxes (W.Count) := Box;
   end Add_Box;

   procedure Set_Box (W : in out World; Id : Object_Id; Box : AABB_2D) is
   begin
      if Id > W.Count then
         raise Invalid_Argument with "Set_Box: id out of range";
      end if;
      if not Is_Valid_AABB (Box) then
         raise Invalid_Argument with "Set_Box: invalid AABB";
      end if;
      W.Boxes (Id) := Box;
   end Set_Box;

   procedure Set_Box (W : in out World_3D; Id : Object_Id; Box : AABB_3D) is
   begin
      if Id > W.Count then
         raise Invalid_Argument with "Set_Box 3D: id out of range";
      end if;
      if not Is_Valid_AABB (Box) then
         raise Invalid_Argument with "Set_Box 3D: invalid AABB";
      end if;
      W.Boxes (Id) := Box;
   end Set_Box;

   -------------------------------------------------------------------------
   -- Pair list helpers
   -------------------------------------------------------------------------

   function Empty_Pair_List return Pair_List is
   begin
      return (Items => [others => (1, 1)], Count => 0);
   end Empty_Pair_List;

   procedure Clear (P : in out Pair_List) is
   begin
      P.Count := 0;
   end Clear;

   function Make_Pair (A, B : Object_Id) return Pair is
   begin
      if A = B then
         raise Invalid_Argument with "Make_Pair: identical ids";
      end if;
      if A < B then
         return (A, B);
      else
         return (B, A);
      end if;
   end Make_Pair;

   function Contains_Pair (P : Pair_List; A, B : Object_Id) return Boolean is
      Target : constant Pair := Make_Pair (A, B);
   begin
      for I in 1 .. P.Count loop
         if P.Items (I).A = Target.A and then P.Items (I).B = Target.B then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Pair;

   procedure Append_Pair (P : in out Pair_List; A, B : Object_Id) is
      Target : Pair;
   begin
      if A = B then
         raise Invalid_Argument with "Append_Pair: identical ids";
      end if;
      Target := Make_Pair (A, B);
      if Contains_Pair (P, Target.A, Target.B) then
         return;
      end if;
      if P.Count = Max_Pairs then
         raise Capacity_Exceeded with "Append_Pair: Max_Pairs reached";
      end if;
      P.Count := P.Count + 1;
      P.Items (P.Count) := Target;
   end Append_Pair;

   procedure Normalize_Pairs (P : in out Pair_List) is
      Write : Pair_Count := 0;
   begin
      for I in 2 .. P.Count loop
         declare
            Key : constant Pair := P.Items (I);
            J   : Natural := I - 1;
         begin
            while J >= 1 and then Pair_Less (Key, P.Items (J)) loop
               P.Items (J + 1) := P.Items (J);
               J := J - 1;
            end loop;
            P.Items (J + 1) := Key;
         end;
      end loop;

      for I in 1 .. P.Count loop
         if Write = 0
           or else P.Items (I).A /= P.Items (Write).A
           or else P.Items (I).B /= P.Items (Write).B
         then
            Write := Write + 1;
            P.Items (Write) := P.Items (I);
         end if;
      end loop;
      P.Count := Write;
   end Normalize_Pairs;

   function Same_Pair_Set (Left, Right : Pair_List) return Boolean is
      L : Pair_List := Left;
      R : Pair_List := Right;
   begin
      Normalize_Pairs (L);
      Normalize_Pairs (R);
      if L.Count /= R.Count then
         return False;
      end if;
      for I in 1 .. L.Count loop
         if L.Items (I).A /= R.Items (I).A
           or else L.Items (I).B /= R.Items (I).B
         then
            return False;
         end if;
      end loop;
      return True;
   end Same_Pair_Set;

   -------------------------------------------------------------------------
   -- Endpoint helpers
   -------------------------------------------------------------------------

   procedure Build_Endpoints
     (W     : World;
      Axis  : Axis_2D;
      Eps   : out Endpoint_Array;
      Count : out Endpoint_Count)
   is
      K : Endpoint_Count := 0;
   begin
      Eps := [others => (0.0, 1, 1)];
      for Id in 1 .. W.Count loop
         K := K + 1;
         case Axis is
            when Axis_X =>
               Eps (K) := (W.Boxes (Id).Min_X, +1, Id);
            when Axis_Y =>
               Eps (K) := (W.Boxes (Id).Min_Y, +1, Id);
         end case;
         K := K + 1;
         case Axis is
            when Axis_X =>
               Eps (K) := (W.Boxes (Id).Max_X, -1, Id);
            when Axis_Y =>
               Eps (K) := (W.Boxes (Id).Max_Y, -1, Id);
         end case;
      end loop;
      Count := K;
   end Build_Endpoints;

   procedure Build_Endpoints
     (W     : World_3D;
      Axis  : Axis_3D;
      Eps   : out Endpoint_Array;
      Count : out Endpoint_Count)
   is
      K : Endpoint_Count := 0;
   begin
      Eps := [others => (0.0, 1, 1)];
      for Id in 1 .. W.Count loop
         K := K + 1;
         case Axis is
            when Axis_X =>
               Eps (K) := (W.Boxes (Id).Min_X, +1, Id);
            when Axis_Y =>
               Eps (K) := (W.Boxes (Id).Min_Y, +1, Id);
            when Axis_Z =>
               Eps (K) := (W.Boxes (Id).Min_Z, +1, Id);
         end case;
         K := K + 1;
         case Axis is
            when Axis_X =>
               Eps (K) := (W.Boxes (Id).Max_X, -1, Id);
            when Axis_Y =>
               Eps (K) := (W.Boxes (Id).Max_Y, -1, Id);
            when Axis_Z =>
               Eps (K) := (W.Boxes (Id).Max_Z, -1, Id);
         end case;
      end loop;
      Count := K;
   end Build_Endpoints;

   procedure Sort_Endpoints
     (Eps   : in out Endpoint_Array;
      Count : Endpoint_Count)
   is
   begin
      Update_Sorted (Eps, Count);
   end Sort_Endpoints;

   procedure Update_Sorted
     (Eps   : in out Endpoint_Array;
      Count : Endpoint_Count)
   is
   begin
      for I in 2 .. Count loop
         declare
            Key : constant Endpoint := Eps (I);
            J   : Natural := I - 1;
         begin
            while J >= 1 and then Before (Key, Eps (J)) loop
               Eps (J + 1) := Eps (J);
               J := J - 1;
            end loop;
            Eps (J + 1) := Key;
         end;
      end loop;
   end Update_Sorted;

   function Endpoints_Sorted
     (Eps   : Endpoint_Array;
      Count : Endpoint_Count) return Boolean
   is
   begin
      for I in 2 .. Count loop
         if Before (Eps (I), Eps (I - 1)) then
            return False;
         end if;
      end loop;
      return True;
   end Endpoints_Sorted;

   -------------------------------------------------------------------------
   -- 1-D sweep: pair every start with currently active intervals
   -------------------------------------------------------------------------

   function Sweep_1D
     (Eps   : Endpoint_Array;
      Count : Endpoint_Count) return Pair_List
   is
      Result     : Pair_List := Empty_Pair_List;
      Active     : array (Object_Id) of Boolean := [others => False];
      Active_Ids : array (1 .. Max_Objects) of Object_Id := [others => 1];
      Active_N   : Object_Count := 0;
   begin
      for I in 1 .. Count loop
         declare
            E : constant Endpoint := Eps (I);
         begin
            if E.Kind > 0 then
               for J in 1 .. Active_N loop
                  Append_Pair (Result, E.Id, Active_Ids (J));
               end loop;
               if not Active (E.Id) then
                  Active (E.Id) := True;
                  Active_N := Active_N + 1;
                  Active_Ids (Active_N) := E.Id;
               end if;
            else
               if Active (E.Id) then
                  Active (E.Id) := False;
                  for J in 1 .. Active_N loop
                     if Active_Ids (J) = E.Id then
                        Active_Ids (J) := Active_Ids (Active_N);
                        Active_N := Active_N - 1;
                        exit;
                     end if;
                  end loop;
               end if;
            end if;
         end;
      end loop;
      return Result;
   end Sweep_1D;

   -------------------------------------------------------------------------
   -- Broad-phase queries
   -------------------------------------------------------------------------

   function Find_Overlapping_Pairs_Brute (W : World) return Pair_List is
      Result : Pair_List := Empty_Pair_List;
   begin
      for I in 1 .. W.Count loop
         for J in I + 1 .. W.Count loop
            if AABBs_Overlap (W.Boxes (I), W.Boxes (J)) then
               Append_Pair (Result, I, J);
            end if;
         end loop;
      end loop;
      return Result;
   end Find_Overlapping_Pairs_Brute;

   function Find_Overlapping_Pairs_Brute (W : World_3D) return Pair_List is
      Result : Pair_List := Empty_Pair_List;
   begin
      for I in 1 .. W.Count loop
         for J in I + 1 .. W.Count loop
            if AABBs_Overlap (W.Boxes (I), W.Boxes (J)) then
               Append_Pair (Result, I, J);
            end if;
         end loop;
      end loop;
      return Result;
   end Find_Overlapping_Pairs_Brute;

   function Find_1D_Overlap_Pairs
     (W : World; Axis : Axis_2D) return Pair_List
   is
      Eps   : Endpoint_Array;
      Count : Endpoint_Count;
   begin
      Build_Endpoints (W, Axis, Eps, Count);
      Sort_Endpoints (Eps, Count);
      return Sweep_1D (Eps, Count);
   end Find_1D_Overlap_Pairs;

   function Find_Overlapping_Pairs_SAP (W : World) return Pair_List is
      X_Pairs : Pair_List;
      Result  : Pair_List := Empty_Pair_List;
   begin
      if W.Count < 2 then
         return Result;
      end if;
      X_Pairs := Find_1D_Overlap_Pairs (W, Axis_X);
      for I in 1 .. X_Pairs.Count loop
         declare
            A : constant Object_Id := X_Pairs.Items (I).A;
            B : constant Object_Id := X_Pairs.Items (I).B;
         begin
            if Projections_Overlap
              (W.Boxes (A).Min_Y, W.Boxes (A).Max_Y,
               W.Boxes (B).Min_Y, W.Boxes (B).Max_Y)
            then
               Append_Pair (Result, A, B);
            end if;
         end;
      end loop;
      return Result;
   end Find_Overlapping_Pairs_SAP;

   function Find_Overlapping_Pairs_SAP (W : World_3D) return Pair_List is
      Eps     : Endpoint_Array;
      Count   : Endpoint_Count;
      X_Pairs : Pair_List;
      Result  : Pair_List := Empty_Pair_List;
   begin
      if W.Count < 2 then
         return Result;
      end if;
      Build_Endpoints (W, Axis_X, Eps, Count);
      Sort_Endpoints (Eps, Count);
      X_Pairs := Sweep_1D (Eps, Count);
      for I in 1 .. X_Pairs.Count loop
         declare
            A : constant Object_Id := X_Pairs.Items (I).A;
            B : constant Object_Id := X_Pairs.Items (I).B;
         begin
            if Projections_Overlap
                 (W.Boxes (A).Min_Y, W.Boxes (A).Max_Y,
                  W.Boxes (B).Min_Y, W.Boxes (B).Max_Y)
              and then Projections_Overlap
                (W.Boxes (A).Min_Z, W.Boxes (A).Max_Z,
                 W.Boxes (B).Min_Z, W.Boxes (B).Max_Z)
            then
               Append_Pair (Result, A, B);
            end if;
         end;
      end loop;
      return Result;
   end Find_Overlapping_Pairs_SAP;

end Sweep_And_Prune;
