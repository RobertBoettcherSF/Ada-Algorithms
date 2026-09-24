--  Flame_Clustering body — FLAME (Fuzzy clustering by Local Approximation
--  of MEmberships).  Density = 1 / mean KNN distance; NAE weights =
--  inverse-distance normalized with Distance_Eps.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Flame_Clustering
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Distance (A, B : Point) return Non_Negative is
      S : Real := 0.0;
      D : Real;
   begin
      if A'Length /= B'Length or else A'First /= B'First then
         raise Invalid_Argument with "Distance: shape mismatch";
      end if;
      for I in A'Range loop
         D := A (I) - B (I);
         S := S + D * D;
      end loop;
      if S <= 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Math.Sqrt (Long_Float (S)));
   end Distance;

   function Squared_Distance (A, B : Point) return Non_Negative is
      S : Real := 0.0;
      D : Real;
   begin
      if A'Length /= B'Length or else A'First /= B'First then
         raise Invalid_Argument with "Squared_Distance: shape mismatch";
      end if;
      for I in A'Range loop
         D := A (I) - B (I);
         S := S + D * D;
      end loop;
      if S < 0.0 then
         return 0.0;
      end if;
      return Non_Negative (S);
   end Squared_Distance;

   function Extract_Point
     (Data : Dataset; P : Point_Index) return Point
   is
      Result : Point (Data'Range (2));
   begin
      if P not in Data'Range (1) then
         raise Invalid_Argument with "Extract_Point: index out of range";
      end if;
      for D in Data'Range (2) loop
         Result (D) := Data (P, D);
      end loop;
      return Result;
   end Extract_Point;

   function Count_CSOs (Kinds : Kind_Array) return Cluster_Count is
      C : Cluster_Count := 0;
   begin
      for I in Kinds'Range loop
         if Kinds (I) = CSO then
            if C >= Max_Clusters then
               raise Capacity_Exceeded with "too many CSOs";
            end if;
            C := C + 1;
         end if;
      end loop;
      return C;
   end Count_CSOs;

   function Max_Membership_Delta
     (A, B : Membership_Matrix) return Non_Negative
   is
      M : Real := 0.0;
      D : Real;
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            D := abs (A (I, J) - B (I, J));
            if D > M then
               M := D;
            end if;
         end loop;
      end loop;
      return Non_Negative (M);
   end Max_Membership_Delta;

   ---------------------------------------------------------------------------
   -- Step 1
   ---------------------------------------------------------------------------

   function Build_KNN
     (Data : Dataset; K : Neighbor_Count) return KNN_Graph
   is
      N : constant Point_Count := Data'Length (1);
      G : KNN_Graph (Data'Range (1));
   begin
      --  Caps are encoded in Point_Count / Neighbor_Count / Dim_Index.
      if N < 2 then
         raise Invalid_Argument with "Build_KNN: need at least 2 points";
      end if;
      if K < 1 or else Natural (K) >= Natural (N) then
         raise Invalid_Argument with "Build_KNN: K must be in 1 .. N-1";
      end if;

      for I in Data'Range (1) loop
         declare
            Pi : constant Point := Extract_Point (Data, I);
            --  Collect distances to all others, then select K nearest.
            type Cand is record
               Id   : Point_Index := 1;
               Dist : Non_Negative := 0.0;
            end record;
            Cands : array (1 .. Max_Points - 1) of Cand;
            NC    : Natural := 0;
         begin
            for J in Data'Range (1) loop
               if J /= I then
                  NC := NC + 1;
                  Cands (NC) :=
                    (Id => J,
                     Dist => Distance (Pi, Extract_Point (Data, J)));
               end if;
            end loop;

            --  Partial selection sort for K nearest; ties → lower Id.
            for S in 1 .. Natural (K) loop
               declare
                  Best : Natural := S;
               begin
                  for T in S + 1 .. NC loop
                     if Cands (T).Dist < Cands (Best).Dist
                       or else
                         (Near (Cands (T).Dist, Cands (Best).Dist)
                            and then Cands (T).Id < Cands (Best).Id)
                     then
                        Best := T;
                     end if;
                  end loop;
                  if Best /= S then
                     declare
                        Tmp : constant Cand := Cands (S);
                     begin
                        Cands (S) := Cands (Best);
                        Cands (Best) := Tmp;
                     end;
                  end if;
               end;
            end loop;

            G (I).Count := K;
            for S in 1 .. Natural (K) loop
               G (I).Ids (Neighbor_Index (S)) := Cands (S).Id;
               G (I).Dists (Neighbor_Index (S)) := Cands (S).Dist;
            end loop;
         end;
      end loop;
      return G;
   end Build_KNN;

   function Estimate_Densities
     (Graph : KNN_Graph) return Densities
   is
      Dens : Densities (Graph'Range);
   begin
      for I in Graph'Range loop
         declare
            Row : constant KNN_Row := Graph (I);
            Sum : Real := 0.0;
            Mean : Real;
         begin
            if Row.Count < 1 then
               raise Invalid_Argument with "Estimate_Densities: empty KNN";
            end if;
            for S in 1 .. Row.Count loop
               Sum := Sum + Real (Row.Dists (S));
            end loop;
            Mean := Sum / Real (Row.Count);
            if Mean < Distance_Eps then
               Mean := Distance_Eps;
            end if;
            Dens (I) := 1.0 / Mean;
         end;
      end loop;
      return Dens;
   end Estimate_Densities;

   function Classify_Objects
     (Dens   : Densities;
      Graph  : KNN_Graph;
      Out_Th : Non_Negative) return Kind_Array
   is
      Kinds : Kind_Array (Dens'Range);
   begin
      for I in Dens'Range loop
         declare
            Row : constant KNN_Row := Graph (I);
            Higher_Than_All : Boolean := True;
            Lower_Than_All  : Boolean := True;
            Nd : Real;
         begin
            if Row.Count < 1 then
               raise Invalid_Argument with "Classify_Objects: empty KNN";
            end if;
            for S in 1 .. Row.Count loop
               Nd := Dens (Row.Ids (S));
               --  Strict comparisons: ties → neither CSO nor outlier vs nbr.
               if Dens (I) <= Nd then
                  Higher_Than_All := False;
               end if;
               if Dens (I) >= Nd then
                  Lower_Than_All := False;
               end if;
            end loop;

            if Higher_Than_All then
               Kinds (I) := CSO;
            elsif Lower_Than_All and then Dens (I) < Out_Th then
               Kinds (I) := Outlier;
            else
               Kinds (I) := Rest;
            end if;
         end;
      end loop;
      return Kinds;
   end Classify_Objects;

   ---------------------------------------------------------------------------
   -- Step 2
   ---------------------------------------------------------------------------

   function Neighborhood_Weights
     (Row : KNN_Row) return Neighbor_Dists
   is
      W : Neighbor_Dists (1 .. Max_K_Neighbors) := [others => 0.0];
      Sum : Real := 0.0;
      Inv : Real;
   begin
      if Row.Count < 1 then
         raise Invalid_Argument with "Neighborhood_Weights: empty row";
      end if;
      for S in 1 .. Row.Count loop
         Inv := 1.0 / (Real (Row.Dists (S)) + Distance_Eps);
         W (S) := Non_Negative (Inv);
         Sum := Sum + Inv;
      end loop;
      if Sum <= 0.0 then
         --  Degenerate: uniform fallback.
         declare
            U : constant Real := 1.0 / Real (Row.Count);
         begin
            for S in 1 .. Row.Count loop
               W (S) := Non_Negative (U);
            end loop;
         end;
      else
         for S in 1 .. Row.Count loop
            W (S) := Non_Negative (Real (W (S)) / Sum);
         end loop;
      end if;
      return W;
   end Neighborhood_Weights;

   procedure Init_Memberships
     (Kinds    : Kind_Array;
      Graph    : KNN_Graph;
      W        : out Membership_Matrix;
      Num_CSOs : out Cluster_Count;
      CSO_Of   : out CSO_List)
   is
      pragma Unreferenced (Graph);
      NC : Cluster_Count := 0;
      M  : Cluster_Count;
      Eq : Real;
   begin
      for J in CSO_Of'Range loop
         CSO_Of (J) := 1;
      end loop;

      for I in Kinds'Range loop
         if Kinds (I) = CSO then
            NC := NC + 1;
            if NC > Max_Clusters then
               raise Capacity_Exceeded with "Init_Memberships: too many CSOs";
            end if;
            CSO_Of (Cluster_Index (NC)) := I;
         end if;
      end loop;
      Num_CSOs := NC;
      M := NC + 1;  -- outlier group always present

      if M > W'Length (2) then
         raise Invalid_Argument with
           "Init_Memberships: Membership_Matrix columns < M";
      end if;

      --  Zero all used columns.
      for I in W'Range (1) loop
         for J in W'First (2) .. Cluster_Index (M) loop
            W (I, J) := 0.0;
         end loop;
      end loop;

      Eq := 1.0 / Real (M);

      declare
         CSO_Col : Cluster_Count := 0;
      begin
         for I in Kinds'Range loop
            case Kinds (I) is
               when CSO =>
                  CSO_Col := CSO_Col + 1;
                  W (I, Cluster_Index (CSO_Col)) := 1.0;
               when Outlier =>
                  W (I, Cluster_Index (M)) := 1.0;
               when Rest =>
                  for J in W'First (2) .. Cluster_Index (M) loop
                     W (I, J) := Eq;
                  end loop;
            end case;
         end loop;
      end;
   end Init_Memberships;

   function Neighborhood_Approximation_Error
     (Kinds : Kind_Array;
      Graph : KNN_Graph;
      W     : Membership_Matrix) return Non_Negative
   is
      Err : Real := 0.0;
      M_Last : constant Cluster_Index := W'Last (2);
   begin
      for I in Kinds'Range loop
         if Kinds (I) = Rest then
            declare
               Row : constant KNN_Row := Graph (I);
               Wt  : constant Neighbor_Dists := Neighborhood_Weights (Row);
               Diff : Real;
               Pred : Real;
               Sq   : Real := 0.0;
            begin
               for J in W'First (2) .. M_Last loop
                  Pred := 0.0;
                  for S in 1 .. Row.Count loop
                     Pred := Pred + Real (Wt (S)) * W (Row.Ids (S), J);
                  end loop;
                  Diff := W (I, J) - Pred;
                  Sq := Sq + Diff * Diff;
               end loop;
               Err := Err + Sq;
            end;
         end if;
      end loop;
      return Non_Negative (Err);
   end Neighborhood_Approximation_Error;

   procedure Approximate_Memberships
     (Kinds     : Kind_Array;
      Graph     : KNN_Graph;
      W         : in out Membership_Matrix;
      Max_Iters : Positive;
      Eps       : Non_Negative;
      Iters     : out Natural;
      Converged : out Boolean;
      Final_NAE : out Non_Negative)
   is
      N      : constant Point_Count := Kinds'Length;
      M_Last : constant Cluster_Index := W'Last (2);
      W_Old  : Membership_Matrix (W'Range (1), W'Range (2));
      Max_D : Real;
   begin
      pragma Assert (N = Graph'Length);
      Iters := 0;
      Converged := False;

      for Iter in 1 .. Max_Iters loop
         --  Snapshot for Jacobi update.
         for I in W'Range (1) loop
            for J in W'Range (2) loop
               W_Old (I, J) := W (I, J);
            end loop;
         end loop;

         for I in Kinds'Range loop
            if Kinds (I) = Rest then
               declare
                  Row : constant KNN_Row := Graph (I);
                  Wt  : constant Neighbor_Dists := Neighborhood_Weights (Row);
                  Pred : Real;
               begin
                  for J in W'First (2) .. M_Last loop
                     Pred := 0.0;
                     for S in 1 .. Row.Count loop
                        Pred := Pred
                          + Real (Wt (S)) * W_Old (Row.Ids (S), J);
                     end loop;
                     W (I, J) := Pred;
                  end loop;
               end;
            end if;
            --  CSO / Outlier rows remain fixed from Init.
         end loop;

         Max_D := Real (Max_Membership_Delta (W, W_Old));
         Iters := Iter;
         if Max_D < Eps then
            Converged := True;
            exit;
         end if;
      end loop;

      Final_NAE := Neighborhood_Approximation_Error (Kinds, Graph, W);
   end Approximate_Memberships;

   ---------------------------------------------------------------------------
   -- Step 3
   ---------------------------------------------------------------------------

   function Hard_Labels_From_Memberships
     (W : Membership_Matrix) return Labels
   is
      L : Labels (W'Range (1)) := [others => 0];
   begin
      for I in W'Range (1) loop
         declare
            Best_J : Cluster_Index := W'First (2);
            Best_V : Real := W (I, Best_J);
         begin
            for J in Cluster_Index'Succ (W'First (2)) .. W'Last (2) loop
               if W (I, J) > Best_V then
                  Best_V := W (I, J);
                  Best_J := J;
               end if;
            end loop;
            L (I) := Natural (Best_J);
         end;
      end loop;
      return L;
   end Hard_Labels_From_Memberships;

   function Threshold_Assign
     (W         : Membership_Matrix;
      Threshold : Unit_Interval) return Assignment_Matrix
   is
      A : Assignment_Matrix (W'Range (1), W'Range (2)) :=
        [others => [others => False]];
   begin
      for I in W'Range (1) loop
         for J in W'Range (2) loop
            A (I, J) := W (I, J) > Threshold;
         end loop;
      end loop;
      return A;
   end Threshold_Assign;

   function Run_FLAME
     (Data   : Dataset;
      Params : Parameters := Default_Parameters) return Flame_Result
   is
      N : constant Point_Count := Data'Length (1);
      Graph : constant KNN_Graph := Build_KNN (Data, Params.K);
      Dens  : constant Densities := Estimate_Densities (Graph);
      Kinds : constant Kind_Array :=
        Classify_Objects (Dens, Graph, Params.Outlier_Threshold);
      NC : constant Cluster_Count := Count_CSOs (Kinds);
      M  : constant Cluster_Count := NC + 1;
      W  : Membership_Matrix (Data'Range (1), 1 .. Cluster_Index (M));
      CSO_Of : CSO_List (1 .. Max_Clusters) := [others => 1];
      NC_Out : Cluster_Count;
      Iters : Natural;
      Conv  : Boolean;
      NAE   : Non_Negative;
      HL    : Labels (Data'Range (1));
   begin
      if Params.K < 1 or else Natural (Params.K) >= Natural (N) then
         raise Invalid_Argument with "Run_FLAME: invalid K";
      end if;

      Init_Memberships (Kinds, Graph, W, NC_Out, CSO_Of);
      pragma Assert (NC_Out = NC);

      Approximate_Memberships
        (Kinds, Graph, W, Params.Max_Iters, Params.Eps, Iters, Conv, NAE);

      HL := Hard_Labels_From_Memberships (W);

      declare
         R : Flame_Result (N => N, M => M);
      begin
         R.Densities := Dens;
         R.Kinds := Kinds;
         R.Graph := Graph;
         for I in W'Range (1) loop
            for J in W'Range (2) loop
               R.Memberships (I, J) := W (I, J);
            end loop;
         end loop;
         R.Num_CSOs := NC;
         R.CSO_Of := CSO_Of;
         R.Hard_Labels := HL;
         R.Iters := Iters;
         R.Converged := Conv;
         R.Final_NAE := NAE;
         return R;
      end;
   end Run_FLAME;

end Flame_Clustering;
