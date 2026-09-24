--  Optics body — OPTICS clustering (Ankerst et al. 1999).

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Optics
  with SPARK_Mode => Off
is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   ---------------------------------------------------------------------------
   -- Local helpers
   ---------------------------------------------------------------------------

   procedure Require_Params (Params : Parameters) is
      pragma Unreferenced (Params);
   begin
      --  Parameters.Eps is Positive_Real and MinPts is Positive; invalid
      --  values are rejected at Make_Parameters / aggregate constraint.
      null;
   end Require_Params;

   procedure Require_Point (Data : Dataset; P : Point_Id) is
   begin
      if P not in Data'Range (1) then
         raise Invalid_Argument with "point id out of range";
      end if;
   end Require_Point;

   procedure Require_Capacity (Data : Dataset) is
   begin
      if Data'Length (1) > Max_Points then
         raise Capacity_Exceeded with "too many points";
      end if;
      if Data'Length (2) > Max_Dims then
         raise Capacity_Exceeded with "too many dimensions";
      end if;
      if Data'Length (1) = 0 or else Data'Length (2) = 0 then
         raise Invalid_Argument with "empty dataset";
      end if;
   end Require_Capacity;

   --  Collect ε-neighbors of P into Nbr (Count entries), distances into Dist.
   procedure Get_Neighbors
     (Data  : Dataset;
      P     : Point_Id;
      Eps   : Positive_Real;
      Nbr   : out Point_Id_Array;
      Dist  : out Real_Array;
      Count : out Natural)
   is
      D : Non_Negative;
   begin
      Count := 0;
      for Q in Data'Range (1) loop
         D := Distance (Data, P, Q);
         if D <= Eps then
            Count := Count + 1;
            Nbr (Data'First (1) + Count - 1) := Q;
            Dist (Data'First (1) + Count - 1) := D;
         end if;
      end loop;
   end Get_Neighbors;

   --  Selection: MinPts-th smallest among Dist (1 .. Count), 1-based.
   --  Simple insertion into a scratch buffer (Count ≤ Max_Points).
   function MinPts_Th_Distance
     (Dist   : Real_Array;
      First  : Point_Id;
      Count  : Natural;
      MinPts : Positive) return Real
   is
      --  Working copy of the first Count distances.
      Buf : array (1 .. Max_Points) of Real;
      Key : Real;
      J   : Natural;
   begin
      if Count < MinPts then
         return Undefined;
      end if;
      for I in 1 .. Count loop
         Buf (I) := Dist (First + I - 1);
      end loop;
      --  Insertion sort (educational; n ≤ Max_Points).
      for I in 2 .. Count loop
         Key := Buf (I);
         J := I - 1;
         while J >= 1 and then Buf (J) > Key loop
            Buf (J + 1) := Buf (J);
            J := J - 1;
         end loop;
         Buf (J + 1) := Key;
      end loop;
      return Buf (MinPts);
   end MinPts_Th_Distance;

   ---------------------------------------------------------------------------
   -- Min-heap priority queue on reachability (Seeds)
   ---------------------------------------------------------------------------

   type Heap_Node is record
      Id    : Point_Id := 1;
      Reach : Real     := Undefined;
   end record;

   type Heap_Store is array (1 .. Max_Points) of Heap_Node;

   type Seed_Heap is record
      Size  : Natural := 0;
      Store : Heap_Store;
   end record;

   function Reach_Less (A, B : Real) return Boolean is
   begin
      --  Undefined treated as +∞.
      if A < 0.0 then
         return False;
      elsif B < 0.0 then
         return True;
      else
         return A < B;
      end if;
   end Reach_Less;

   procedure Heap_Swap (H : in out Seed_Heap; I, J : Positive) is
      T : constant Heap_Node := H.Store (I);
   begin
      H.Store (I) := H.Store (J);
      H.Store (J) := T;
   end Heap_Swap;

   procedure Heap_Sift_Up (H : in out Seed_Heap; Start : Positive) is
      I : Positive := Start;
      P : Positive;
   begin
      while I > 1 loop
         P := I / 2;
         if Reach_Less (H.Store (I).Reach, H.Store (P).Reach) then
            Heap_Swap (H, I, P);
            I := P;
         else
            exit;
         end if;
      end loop;
   end Heap_Sift_Up;

   procedure Heap_Sift_Down (H : in out Seed_Heap; Start : Positive) is
      I : Positive := Start;
      L, R, Best : Positive;
   begin
      loop
         L := 2 * I;
         R := L + 1;
         Best := I;
         if L <= H.Size
           and then Reach_Less (H.Store (L).Reach, H.Store (Best).Reach)
         then
            Best := L;
         end if;
         if R <= H.Size
           and then Reach_Less (H.Store (R).Reach, H.Store (Best).Reach)
         then
            Best := R;
         end if;
         exit when Best = I;
         Heap_Swap (H, I, Best);
         I := Best;
      end loop;
   end Heap_Sift_Down;

   procedure Heap_Insert
     (H : in out Seed_Heap; Id : Point_Id; Reach : Real)
   is
   begin
      if H.Size >= Max_Points then
         raise Capacity_Exceeded with "seed heap full";
      end if;
      H.Size := H.Size + 1;
      H.Store (H.Size) := (Id => Id, Reach => Reach);
      Heap_Sift_Up (H, H.Size);
   end Heap_Insert;

   --  Decrease-key / move-up for an existing id.
   procedure Heap_Move_Up
     (H : in out Seed_Heap; Id : Point_Id; New_Reach : Real)
   is
      Found : Natural := 0;
   begin
      for I in 1 .. H.Size loop
         if H.Store (I).Id = Id then
            Found := I;
            exit;
         end if;
      end loop;
      if Found = 0 then
         --  Not in heap (should not happen per pseudocode); insert.
         Heap_Insert (H, Id, New_Reach);
         return;
      end if;
      H.Store (Found).Reach := New_Reach;
      Heap_Sift_Up (H, Found);
   end Heap_Move_Up;

   procedure Heap_Extract_Min
     (H     : in out Seed_Heap;
      Id    : out Point_Id;
      Reach : out Real;
      Ok    : out Boolean)
   is
   begin
      if H.Size = 0 then
         Ok := False;
         Id := 1;
         Reach := Undefined;
         return;
      end if;
      Ok := True;
      Id := H.Store (1).Id;
      Reach := H.Store (1).Reach;
      H.Store (1) := H.Store (H.Size);
      H.Size := H.Size - 1;
      if H.Size > 0 then
         Heap_Sift_Down (H, 1);
      end if;
   end Heap_Extract_Min;

   ---------------------------------------------------------------------------
   -- Public: Near / Make_Parameters
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Make_Parameters
     (Eps : Real; MinPts : Integer) return Parameters
   is
   begin
      if Eps <= 0.0 or else MinPts < 1 then
         raise Invalid_Argument with "Eps must be > 0 and MinPts >= 1";
      end if;
      return (Eps => Eps, MinPts => MinPts);
   end Make_Parameters;

   ---------------------------------------------------------------------------
   -- Distance / neighborhood
   ---------------------------------------------------------------------------

   function Distance
     (Data : Dataset;
      P, Q : Point_Id) return Non_Negative
   is
      Sum : Real := 0.0;
      D   : Real;
   begin
      Require_Point (Data, P);
      Require_Point (Data, Q);
      for C in Data'Range (2) loop
         D := Data (P, C) - Data (Q, C);
         Sum := Sum + D * D;
      end loop;
      if Sum <= 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Math.Sqrt (Sum));
   end Distance;

   function Neighbor_Count
     (Data : Dataset;
      P    : Point_Id;
      Eps  : Positive_Real) return Natural
   is
      N : Natural := 0;
   begin
      Require_Point (Data, P);
      if Eps <= 0.0 then
         raise Invalid_Argument with "Eps must be > 0";
      end if;
      for Q in Data'Range (1) loop
         if Distance (Data, P, Q) <= Eps then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Neighbor_Count;

   function Core_Distance
     (Data   : Dataset;
      P      : Point_Id;
      Params : Parameters) return Real
   is
      Nbr   : Point_Id_Array (Data'Range (1));
      Dist  : Real_Array (Data'Range (1));
      Count : Natural;
   begin
      Require_Point (Data, P);
      Require_Params (Params);
      Get_Neighbors (Data, P, Params.Eps, Nbr, Dist, Count);
      if Count < Params.MinPts then
         return Undefined;
      end if;
      return MinPts_Th_Distance
        (Dist, Data'First (1), Count, Params.MinPts);
   end Core_Distance;

   function Is_Core_Point
     (Data   : Dataset;
      P      : Point_Id;
      Params : Parameters) return Boolean
   is
   begin
      Require_Point (Data, P);
      Require_Params (Params);
      return Neighbor_Count (Data, P, Params.Eps) >= Params.MinPts;
   end Is_Core_Point;

   function Has_Defined_Core
     (Data   : Dataset;
      P      : Point_Id;
      Params : Parameters) return Boolean
   is
   begin
      return Is_Core_Point (Data, P, Params);
   end Has_Defined_Core;

   ---------------------------------------------------------------------------
   -- update(N, p, Seeds, ε, MinPts)
   ---------------------------------------------------------------------------

   procedure Update
     (Data     : Dataset;
      Nbr      : Point_Id_Array;
      N_Count  : Natural;
      N_First  : Point_Id;
      P        : Point_Id;
      Core_D   : Real;
      State    : in out Optics_Point_Array;
      Seeds    : in out Seed_Heap)
   is
      O              : Point_Id;
      New_Reach_Dist : Real;
      Dist_PO        : Non_Negative;
   begin
      for K in 0 .. N_Count - 1 loop
         O := Nbr (N_First + K);
         if not State (O).Processed then
            Dist_PO := Distance (Data, P, O);
            if Core_D > Dist_PO then
               New_Reach_Dist := Core_D;
            else
               New_Reach_Dist := Dist_PO;
            end if;
            if not State (O).Has_Reachability then
               State (O).Reachability_Distance := New_Reach_Dist;
               State (O).Has_Reachability := True;
               Heap_Insert (Seeds, O, New_Reach_Dist);
            elsif New_Reach_Dist < State (O).Reachability_Distance then
               State (O).Reachability_Distance := New_Reach_Dist;
               Heap_Move_Up (Seeds, O, New_Reach_Dist);
            end if;
         end if;
      end loop;
   end Update;

   ---------------------------------------------------------------------------
   -- Run_OPTICS
   ---------------------------------------------------------------------------

   function Run_OPTICS
     (Data   : Dataset;
      Params : Parameters) return Ordered_Result
   is
      N      : constant Point_Count := Data'Length (1);
      First  : constant Point_Id := Data'First (1);
      Last   : constant Point_Id := Data'Last (1);
      Result : Ordered_Result (First, Natural (Last));
      State  : Optics_Point_Array (First .. Last);
      Seeds  : Seed_Heap;
      Nbr    : Point_Id_Array (First .. Last);
      Dist   : Real_Array (First .. Last);
      N_Cnt  : Natural;
      Core_D : Real;
      Q      : Point_Id;
      Rch    : Real;
      Ok     : Boolean;
      Out_Ix : Natural := 0;

      procedure Emit (Pid : Point_Id) is
      begin
         Out_Ix := Out_Ix + 1;
         Result.Order (First + Out_Ix - 1) := Pid;
         Result.Core_Distance (First + Out_Ix - 1) :=
           State (Pid).Core_Distance;
         Result.Reachability (First + Out_Ix - 1) :=
           State (Pid).Reachability_Distance;
         Result.Has_Core_Distance (First + Out_Ix - 1) :=
           State (Pid).Has_Core_Distance;
         Result.Has_Reachability (First + Out_Ix - 1) :=
           State (Pid).Has_Reachability;
      end Emit;

      procedure Process_Point (P : Point_Id) is
      begin
         Get_Neighbors (Data, P, Params.Eps, Nbr, Dist, N_Cnt);
         State (P).Processed := True;
         --  Core distance for P.
         if N_Cnt >= Params.MinPts then
            Core_D := MinPts_Th_Distance
              (Dist, First, N_Cnt, Params.MinPts);
            State (P).Core_Distance := Core_D;
            State (P).Has_Core_Distance := True;
         else
            State (P).Core_Distance := Undefined;
            State (P).Has_Core_Distance := False;
            Core_D := Undefined;
         end if;
         Emit (P);
         if State (P).Has_Core_Distance then
            Update
              (Data, Nbr, N_Cnt, First, P, Core_D, State, Seeds);
            loop
               Heap_Extract_Min (Seeds, Q, Rch, Ok);
               exit when not Ok;
               if not State (Q).Processed then
                  Get_Neighbors (Data, Q, Params.Eps, Nbr, Dist, N_Cnt);
                  State (Q).Processed := True;
                  if N_Cnt >= Params.MinPts then
                     Core_D := MinPts_Th_Distance
                       (Dist, First, N_Cnt, Params.MinPts);
                     State (Q).Core_Distance := Core_D;
                     State (Q).Has_Core_Distance := True;
                  else
                     State (Q).Core_Distance := Undefined;
                     State (Q).Has_Core_Distance := False;
                     Core_D := Undefined;
                  end if;
                  Emit (Q);
                  if State (Q).Has_Core_Distance then
                     Update
                       (Data, Nbr, N_Cnt, First, Q, Core_D, State, Seeds);
                  end if;
               end if;
            end loop;
         end if;
      end Process_Point;

   begin
      Require_Capacity (Data);
      Require_Params (Params);

      Result.Count := 0;
      for I in First .. Last loop
         State (I) :=
           (Core_Distance         => Undefined,
            Reachability_Distance => Undefined,
            Has_Core_Distance     => False,
            Has_Reachability      => False,
            Processed             => False);
         Result.Order (I) := I;
         Result.Core_Distance (I) := Undefined;
         Result.Reachability (I) := Undefined;
         Result.Has_Core_Distance (I) := False;
         Result.Has_Reachability (I) := False;
      end loop;

      for P in First .. Last loop
         if not State (P).Processed then
            Seeds.Size := 0;
            Process_Point (P);
         end if;
      end loop;

      Result.Count := Point_Count (Out_Ix);
      if Result.Count /= N then
         raise Invalid_Argument with "OPTICS did not order all points";
      end if;
      return Result;
   end Run_OPTICS;

   ---------------------------------------------------------------------------
   -- Extraction
   ---------------------------------------------------------------------------

   function Extract_DBSCAN_Clustering
     (Ordered : Ordered_Result;
      Xi      : Positive_Real) return Labels
   is
      Lab          : Labels (Ordered.First .. Ordered.Last);
      Curr_Cluster : Cluster_Id := Noise_Label;
      Next_Id      : Cluster_Id := 0;
      Pid        : Point_Id;
      Reach      : Real;
      Core       : Real;
      Has_R      : Boolean;
      Has_C      : Boolean;
      Above      : Boolean;
   begin
      if Ordered.Count = 0 or else Ordered.Last < Natural (Ordered.First) then
         raise Invalid_Argument with "empty ordered result";
      end if;
      if Xi <= 0.0 then
         raise Invalid_Argument with "Xi must be > 0";
      end if;

      for I in Ordered.First .. Ordered.Last loop
         Lab (I) := Noise_Label;
      end loop;

      for Pos in 0 .. Ordered.Count - 1 loop
         declare
            Slot : constant Point_Id := Ordered.First + Pos;
         begin
            Pid   := Ordered.Order (Slot);
            Reach := Ordered.Reachability (Slot);
            Core  := Ordered.Core_Distance (Slot);
            Has_R := Ordered.Has_Reachability (Slot);
            Has_C := Ordered.Has_Core_Distance (Slot);

            --  Undefined reachability is treated as > ξ.
            Above := (not Has_R) or else (Reach > Xi);

            if Above then
               if Has_C and then Core <= Xi then
                  Next_Id := Next_Id + 1;
                  Curr_Cluster := Next_Id;
                  Lab (Pid) := Curr_Cluster;
               else
                  Lab (Pid) := Noise_Label;
               end if;
            else
               Lab (Pid) := Curr_Cluster;
            end if;
         end;
      end loop;

      return Lab;
   end Extract_DBSCAN_Clustering;

   function Labels_At_Xi
     (Ordered : Ordered_Result;
      Xi      : Positive_Real) return Labels
   is
   begin
      return Extract_DBSCAN_Clustering (Ordered, Xi);
   end Labels_At_Xi;

   function Cluster_Count_Of (Lab : Labels) return Natural is
      Max_Id : Natural := 0;
   begin
      for I in Lab'Range loop
         if Lab (I) > Max_Id then
            Max_Id := Lab (I);
         end if;
      end loop;
      return Max_Id;
   end Cluster_Count_Of;

   function Noise_Count_Of (Lab : Labels) return Natural is
      N : Natural := 0;
   begin
      for I in Lab'Range loop
         if Lab (I) = Noise_Label then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Noise_Count_Of;

end Optics;
