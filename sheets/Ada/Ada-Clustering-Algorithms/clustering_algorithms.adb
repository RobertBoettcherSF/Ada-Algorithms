--  Implementation of Clustering_Algorithms survey package:
--  Lloyd k-means, single-linkage, DBSCAN, WCSS / silhouette / Dunn.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Clustering_Algorithms
  with SPARK_Mode => Off
is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   LCG_A : constant RNG_State := 1664525;
   LCG_C : constant RNG_State := 1013904223;

   -------------------------------------------------------------------------
   -- Capacity / argument helpers
   -------------------------------------------------------------------------

   procedure Require_Dataset (Data : Dataset) is
   begin
      if Data'Length (1) = 0 or else Data'Length (2) = 0 then
         raise Invalid_Argument with "empty dataset";
      end if;
      if Data'Length (1) > Max_Points then
         raise Capacity_Exceeded with "too many points";
      end if;
      if Data'Length (2) > Max_Dims then
         raise Capacity_Exceeded with "too many dimensions";
      end if;
   end Require_Dataset;

   -------------------------------------------------------------------------
   -- Near / RNG
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural) is
   begin
      State := RNG_State (Seed) * LCG_A + LCG_C;
      if State = 0 then
         State := 1;
      end if;
   end Seed_RNG;

   function Draw_Unit (State : in out RNG_State) return Unit_Interval is
      M : constant := 2.0**32;
   begin
      State := State * LCG_A + LCG_C;
      return Unit_Interval (Real (State) / M);
   end Draw_Unit;

   function Draw_Index
     (State : in out RNG_State; Lo, Hi : Point_Index) return Point_Index
   is
      Span : constant Natural := Natural (Hi) - Natural (Lo) + 1;
      U    : constant Unit_Interval := Draw_Unit (State);
      Off  : Natural;
   begin
      Off := Natural (Real (U) * Real (Span));
      if Off >= Span then
         Off := Span - 1;
      end if;
      return Point_Index (Natural (Lo) + Off);
   end Draw_Index;

   -------------------------------------------------------------------------
   -- Geometry
   -------------------------------------------------------------------------

   function Squared_Distance (A, B : Point) return Non_Negative is
      Sum  : Real := 0.0;
      Diff : Real;
   begin
      if A'Length = 0 or else A'First /= B'First or else A'Last /= B'Last then
         raise Invalid_Argument with "Squared_Distance: length mismatch";
      end if;
      for I in A'Range loop
         Diff := A (I) - B (I);
         Sum := Sum + Diff * Diff;
      end loop;
      return Sum;
   end Squared_Distance;

   function Distance (A, B : Point) return Non_Negative is
      Sq : constant Non_Negative := Squared_Distance (A, B);
   begin
      if Sq = 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Math.Sqrt (Sq));
   end Distance;

   function Distance
     (Data : Dataset; P, Q : Point_Index) return Non_Negative
   is
      Sum  : Real := 0.0;
      Diff : Real;
   begin
      if P not in Data'Range (1) or else Q not in Data'Range (1) then
         raise Invalid_Argument with "Distance: point out of range";
      end if;
      for D in Data'Range (2) loop
         Diff := Data (P, D) - Data (Q, D);
         Sum := Sum + Diff * Diff;
      end loop;
      if Sum = 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Math.Sqrt (Sum));
   end Distance;

   function Extract_Point
     (Data : Dataset; P : Point_Index) return Point
   is
      D      : constant Dim_Count := Data'Length (2);
      Result : Point (1 .. D);
      Off    : constant Integer := Data'First (2) - 1;
   begin
      if P not in Data'Range (1) or else D < 1 then
         raise Invalid_Argument with "Extract_Point: bad index/dims";
      end if;
      for C in 1 .. D loop
         Result (Dim_Index (C)) := Data (P, Dim_Index (C + Off));
      end loop;
      return Result;
   end Extract_Point;

   function Extract_Center
     (C : Centers; K : Site_Index) return Point
   is
      D      : constant Dim_Count := C'Length (2);
      Result : Point (1 .. D);
      Off    : constant Integer := C'First (2) - 1;
   begin
      if K not in C'Range (1) or else D < 1 then
         raise Invalid_Argument with "Extract_Center: bad index/dims";
      end if;
      for Col in 1 .. D loop
         Result (Dim_Index (Col)) := C (K, Dim_Index (Col + Off));
      end loop;
      return Result;
   end Extract_Center;

   -------------------------------------------------------------------------
   -- Centroid model
   -------------------------------------------------------------------------

   function Nearest_Center
     (Query : Point; C : Centers) return Site_Index
   is
      Best   : Site_Index := C'First (1);
      Best_D : Real := Real'Last;
      Dist   : Real;
      Mu     : Point (1 .. C'Length (2));
   begin
      if C'Length (1) < 1 or else Query'Length /= C'Length (2) then
         raise Invalid_Argument with "Nearest_Center: empty/dims";
      end if;
      for K in C'Range (1) loop
         Mu := Extract_Center (C, K);
         Dist := Squared_Distance (Query, Mu);
         if Dist < Best_D then
            Best_D := Dist;
            Best := K;
         end if;
      end loop;
      return Best;
   end Nearest_Center;

   function Assign_Labels
     (Data : Dataset; C : Centers) return Labels
   is
      Lab : Labels (Data'Range (1));
      Pt  : Point (1 .. Data'Length (2));
   begin
      Require_Dataset (Data);
      if C'Length (1) < 1 or else C'Length (2) /= Data'Length (2) then
         raise Invalid_Argument with "Assign_Labels: centers mismatch";
      end if;
      for P in Data'Range (1) loop
         Pt := Extract_Point (Data, P);
         Lab (P) := Natural (Nearest_Center (Pt, C));
      end loop;
      return Lab;
   end Assign_Labels;

   procedure Update_Centroids
     (Data  : Dataset;
      Lab   : Labels;
      C     : in out Centers;
      Empty : out Empty_Flags)
   is
      D     : constant Dim_Count := Data'Length (2);
      Count : array (C'Range (1)) of Natural := [others => 0];
      Acc   : array (C'Range (1), 1 .. D) of Real :=
        [others => [others => 0.0]];
      K_Id  : Site_Index;
      Off   : constant Integer := Data'First (2) - 1;
   begin
      Empty := [others => True];
      for P in Data'Range (1) loop
         if Lab (P) < Natural (C'First (1))
           or else Lab (P) > Natural (C'Last (1))
         then
            raise Invalid_Argument with "Update_Centroids: bad label";
         end if;
         K_Id := Site_Index (Lab (P));
         Count (K_Id) := Count (K_Id) + 1;
         for Col in 1 .. D loop
            Acc (K_Id, Col) :=
              Acc (K_Id, Col)
              + Data (P, Dim_Index (Col + Off));
         end loop;
      end loop;
      for K in C'Range (1) loop
         if Count (K) = 0 then
            Empty (K) := True;
         else
            Empty (K) := False;
            for Col in 1 .. D loop
               C (K, Dim_Index (Integer (C'First (2)) + Col - 1)) :=
                 Acc (K, Col) / Real (Count (K));
            end loop;
         end if;
      end loop;
   end Update_Centroids;

   function Within_Cluster_SSE
     (Data : Dataset; C : Centers; Lab : Labels) return Non_Negative
   is
      Total : Real := 0.0;
      Pt, Mu : Point (1 .. Data'Length (2));
      K_Id  : Site_Index;
   begin
      if Lab'Length /= Data'Length (1)
        or else C'Length (2) /= Data'Length (2)
      then
         raise Invalid_Argument with "Within_Cluster_SSE: extent mismatch";
      end if;
      for P in Data'Range (1) loop
         if Lab (P) = Noise_Label then
            null;
         else
            if Lab (P) < Natural (C'First (1))
              or else Lab (P) > Natural (C'Last (1))
            then
               raise Invalid_Argument with "Within_Cluster_SSE: bad label";
            end if;
            K_Id := Site_Index (Lab (P));
            Pt := Extract_Point (Data, P);
            Mu := Extract_Center (C, K_Id);
            Total := Total + Squared_Distance (Pt, Mu);
         end if;
      end loop;
      return Total;
   end Within_Cluster_SSE;

   function Init_Centers_Forgy
     (Data : Dataset;
      K    : Site_Count;
      Seed : Natural) return Centers
   is
      N       : constant Point_Count := Data'Length (1);
      D       : constant Dim_Count := Data'Length (2);
      Result  : Centers (1 .. K, 1 .. D);
      State   : RNG_State;
      Chosen  : array (1 .. K) of Point_Index := [others => Data'First (1)];
      Cand    : Point_Index;
      Unique  : Boolean;
      Dim_Off : constant Integer := Data'First (2) - 1;
      Attempts : Natural;
   begin
      Require_Dataset (Data);
      if K < 1 or else K > N then
         raise Invalid_Argument with "Init_Centers_Forgy: bad K";
      end if;
      Seed_RNG (State, Seed);
      for J in 1 .. K loop
         Attempts := 0;
         loop
            Cand := Draw_Index
              (State, Data'First (1),
               Point_Index (Integer (Data'First (1)) + Integer (N) - 1));
            Unique := True;
            for Prev in 1 .. J - 1 loop
               if Chosen (Site_Index (Prev)) = Cand then
                  Unique := False;
                  exit;
               end if;
            end loop;
            Attempts := Attempts + 1;
            exit when Unique;
            if Attempts > N * 20 + 100 then
               for P in Data'Range (1) loop
                  Unique := True;
                  for Prev in 1 .. J - 1 loop
                     if Chosen (Site_Index (Prev)) = P then
                        Unique := False;
                        exit;
                     end if;
                  end loop;
                  if Unique then
                     Cand := P;
                     exit;
                  end if;
               end loop;
               exit;
            end if;
         end loop;
         Chosen (Site_Index (J)) := Cand;
         for Col in 1 .. D loop
            Result (Site_Index (J), Dim_Index (Col)) :=
              Data (Cand, Dim_Index (Col + Dim_Off));
         end loop;
      end loop;
      return Result;
   end Init_Centers_Forgy;

   function Init_Centers_Spaced
     (Data : Dataset; K : Site_Count) return Centers
   is
      N       : constant Point_Count := Data'Length (1);
      D       : constant Dim_Count := Data'Length (2);
      Result  : Centers (1 .. K, 1 .. D);
      Idx     : Point_Index;
      Span    : Integer;
      Dim_Off : constant Integer := Data'First (2) - 1;
   begin
      Require_Dataset (Data);
      if K < 1 or else K > N then
         raise Invalid_Argument with "Init_Centers_Spaced: bad K";
      end if;
      for J in 1 .. K loop
         if K = 1 then
            Idx := Data'First (1);
         else
            Span := Integer (N - 1) * Integer (J - 1) / Integer (K - 1);
            Idx := Point_Index (Integer (Data'First (1)) + Span);
         end if;
         for Col in 1 .. D loop
            Result (Site_Index (J), Dim_Index (Col)) :=
              Data (Idx, Dim_Index (Col + Dim_Off));
         end loop;
      end loop;
      return Result;
   end Init_Centers_Spaced;

   function Init_Centers_From_Indices
     (Data : Dataset; Idx : Index_List) return Centers
   is
      K       : constant Site_Count := Idx'Length;
      D       : constant Dim_Count := Data'Length (2);
      Result  : Centers (1 .. K, 1 .. D);
      Dim_Off : constant Integer := Data'First (2) - 1;
      Idx_Off : constant Integer := Idx'First - 1;
      Row     : Point_Index;
   begin
      Require_Dataset (Data);
      if K < 1 then
         raise Invalid_Argument with "Init_Centers_From_Indices: empty";
      end if;
      for J in 1 .. K loop
         Row := Idx (Site_Index (J + Idx_Off));
         if Row not in Data'Range (1) then
            raise Invalid_Argument with
              "Init_Centers_From_Indices: index out of range";
         end if;
         for Col in 1 .. D loop
            Result (Site_Index (J), Dim_Index (Col)) :=
              Data (Row, Dim_Index (Col + Dim_Off));
         end loop;
      end loop;
      return Result;
   end Init_Centers_From_Indices;

   function Max_Center_Displacement (A, B : Centers) return Non_Negative is
      Max_D : Real := 0.0;
      PA, PB : Point (1 .. A'Length (2));
      Dist : Real;
   begin
      for K in A'Range (1) loop
         PA := Extract_Center (A, K);
         PB := Extract_Center (B, K);
         Dist := Distance (PA, PB);
         if Dist > Max_D then
            Max_D := Dist;
         end if;
      end loop;
      return Max_D;
   end Max_Center_Displacement;

   function Labels_Equal (A, B : Labels) return Boolean is
   begin
      if A'Length /= B'Length or else A'First /= B'First then
         return False;
      end if;
      for I in A'Range loop
         if A (I) /= B (I) then
            return False;
         end if;
      end loop;
      return True;
   end Labels_Equal;

   function Run_KMeans
     (Data   : Dataset;
      Init   : Centers;
      Params : KMeans_Parameters := Default_KMeans) return KMeans_Result
   is
      N       : constant Point_Count := Data'Length (1);
      D       : constant Dim_Count := Data'Length (2);
      K       : constant Site_Count := Params.K;
      Outcome : KMeans_Result (N => N, K => K, D => D);
      Prev    : Centers (1 .. K, 1 .. D);
      Disp    : Real;
      Lab_Tmp : Labels (Data'Range (1));
      Lab_Prev : Labels (Data'Range (1)) := [others => 0];
      First_Iter : Boolean := True;
   begin
      Require_Dataset (Data);
      if K < 1 then
         raise Invalid_Argument with "Run_KMeans: K < 1";
      end if;
      if Init'Length (1) /= K or else Init'Length (2) /= D then
         raise Invalid_Argument with "Run_KMeans: Init extent mismatch";
      end if;

      declare
         S_Off1 : constant Integer := Init'First (1) - 1;
         S_Off2 : constant Integer := Init'First (2) - 1;
      begin
         for J in 1 .. K loop
            for Col in 1 .. D loop
               Outcome.Centers (Site_Index (J), Dim_Index (Col)) :=
                 Init
                   (Site_Index (J + S_Off1),
                    Dim_Index (Col + S_Off2));
            end loop;
         end loop;
      end;

      Outcome.Empty := [others => False];
      Outcome.Iters := 0;
      Outcome.Converged := False;

      for Iter in 1 .. Params.Max_Iters loop
         Prev := Outcome.Centers;
         Lab_Tmp := Assign_Labels (Data, Outcome.Centers);
         declare
            P_Off : constant Integer := Data'First (1) - 1;
         begin
            for P in Data'Range (1) loop
               Outcome.Lab (Point_Index (Integer (P) - P_Off)) := Lab_Tmp (P);
            end loop;
         end;
         Update_Centroids (Data, Lab_Tmp, Outcome.Centers, Outcome.Empty);
         Outcome.Iters := Iter;
         Disp := Max_Center_Displacement (Prev, Outcome.Centers);
         if Disp < Params.Tol then
            Outcome.Converged := True;
            exit;
         end if;
         if not First_Iter and then Labels_Equal (Lab_Tmp, Lab_Prev) then
            Outcome.Converged := True;
            exit;
         end if;
         Lab_Prev := Lab_Tmp;
         First_Iter := False;
      end loop;

      Outcome.WCSS := Within_Cluster_SSE (Data, Outcome.Centers, Lab_Tmp);
      return Outcome;
   end Run_KMeans;

   function Run_KMeans
     (Data   : Dataset;
      Params : KMeans_Parameters) return KMeans_Result
   is
      Init : Centers (1 .. Params.K, 1 .. Data'Length (2));
   begin
      case Params.Init is
         when Forgy =>
            Init := Init_Centers_Forgy (Data, Params.K, Params.Seed);
         when Spaced =>
            Init := Init_Centers_Spaced (Data, Params.K);
      end case;
      return Run_KMeans (Data, Init, Params);
   end Run_KMeans;

   -------------------------------------------------------------------------
   -- Connectivity model — single-linkage
   -------------------------------------------------------------------------

   function Build_Distance_Matrix (Data : Dataset) return Distance_Matrix is
      N      : constant Point_Count := Data'Length (1);
      Result : Distance_Matrix (1 .. N, 1 .. N);
      Base   : constant Integer := Integer (Data'First (1));
   begin
      Require_Dataset (Data);
      for I in 1 .. N loop
         Result (Point_Index (I), Point_Index (I)) := 0.0;
         for J in I + 1 .. N loop
            declare
               Pi  : constant Point_Index := Point_Index (Base + I - 1);
               Pj  : constant Point_Index := Point_Index (Base + J - 1);
               Dij : constant Non_Negative := Distance (Data, Pi, Pj);
            begin
               Result (Point_Index (I), Point_Index (J)) := Dij;
               Result (Point_Index (J), Point_Index (I)) := Dij;
            end;
         end loop;
      end loop;
      return Result;
   end Build_Distance_Matrix;

   function Run_Single_Linkage (Dist : Distance_Matrix) return Dendrogram is
      N : constant Point_Count := Dist'Length (1);
      Prox : array (1 .. Max_Points, 1 .. Max_Points) of Real :=
        [others => [others => 0.0]];
      Size  : array (1 .. Max_Points) of Natural := [others => 0];
      Alive : array (1 .. Max_Points) of Boolean := [others => False];
      Id : array (1 .. Max_Points) of Positive := [others => 1];
      Tree : Dendrogram (1 .. N - 1);
      Active_Count : Natural := N;
      Merge_Idx    : Natural := 0;

      procedure Find_Best_Pair
        (Best_I, Best_J : out Positive; Best_D : out Real)
      is
         First : Boolean := True;
      begin
         Best_I := 1;
         Best_J := 2;
         Best_D := Real'Last;
         for I in 1 .. N loop
            if Alive (I) then
               for J in I + 1 .. N loop
                  if Alive (J) then
                     declare
                        Dij : constant Real := Prox (I, J);
                     begin
                        if First or else Dij < Best_D then
                           Best_D := Dij;
                           Best_I := I;
                           Best_J := J;
                           First := False;
                        elsif Dij = Best_D then
                           if I < Best_I
                             or else (I = Best_I and then J < Best_J)
                           then
                              Best_I := I;
                              Best_J := J;
                           end if;
                        end if;
                     end;
                  end if;
               end loop;
            end if;
         end loop;
         if First then
            raise Invalid_Argument with "no alive pair to merge";
         end if;
      end Find_Best_Pair;

   begin
      if Dist'Length (1) /= Dist'Length (2) then
         raise Invalid_Argument with "distance matrix not square";
      end if;
      if N < 2 then
         raise Invalid_Argument with "Run_Single_Linkage needs N >= 2";
      end if;

      for I in 1 .. N loop
         Alive (I) := True;
         Size (I) := 1;
         Id (I) := I;
         for J in 1 .. N loop
            Prox (I, J) :=
              Dist
                (Dist'First (1) + (I - 1),
                 Dist'First (2) + (J - 1));
         end loop;
      end loop;

      while Active_Count > 1 loop
         declare
            BI, BJ   : Positive;
            BD       : Real;
            Ni, Nj   : Positive;
            New_Size : Positive;
         begin
            Find_Best_Pair (BI, BJ, BD);
            Ni := Size (BI);
            Nj := Size (BJ);
            New_Size := Ni + Nj;
            Merge_Idx := Merge_Idx + 1;
            Tree (Merge_Idx) :=
              (Left   => Id (BI),
               Right  => Id (BJ),
               Height => BD,
               Size   => New_Size);

            Size (BI) := New_Size;
            Id (BI) := N + Merge_Idx;
            Alive (BJ) := False;
            Size (BJ) := 0;

            for K in 1 .. N loop
               if Alive (K) and then K /= BI then
                  declare
                     Dik   : constant Real := Prox (BI, K);
                     Djk   : constant Real := Prox (BJ, K);
                     New_D : Real;
                  begin
                     if Dik <= Djk then
                        New_D := Dik;
                     else
                        New_D := Djk;
                     end if;
                     Prox (BI, K) := New_D;
                     Prox (K, BI) := New_D;
                  end;
               end if;
            end loop;
            Prox (BI, BI) := 0.0;
            Active_Count := Active_Count - 1;
         end;
      end loop;

      return Tree;
   end Run_Single_Linkage;

   function Run_Single_Linkage (Data : Dataset) return Dendrogram is
   begin
      Require_Dataset (Data);
      if Data'Length (1) < 2 then
         raise Invalid_Argument with "Run_Single_Linkage needs N >= 2";
      end if;
      return Run_Single_Linkage (Build_Distance_Matrix (Data));
   end Run_Single_Linkage;

   function Labels_At_Height
     (Tree   : Dendrogram;
      N      : Point_Count;
      Height : Non_Negative) return Labels
   is
      Max_Id : constant Positive := N + (N - 1);
      Parent : array (1 .. Max_Id) of Natural := [others => 0];
      Lab : Labels (1 .. N);
      Next_Label : Natural := 0;
      Root_Of : array (1 .. Max_Id) of Natural := [others => 0];
      New_Cluster : Natural := N;

      function Find (X : Positive) return Positive is
         R : Positive := X;
         P : Positive;
      begin
         while Parent (R) /= 0 and then Parent (R) /= R loop
            R := Parent (R);
         end loop;
         P := X;
         while P /= R loop
            declare
               Next : constant Natural := Parent (P);
            begin
               Parent (P) := R;
               exit when Next = 0 or else Next = P;
               P := Next;
            end;
         end loop;
         return R;
      end Find;

   begin
      if N < 2 then
         raise Invalid_Argument with "Labels_At_Height needs N >= 2";
      end if;
      if Tree'Length /= N - 1 then
         raise Invalid_Argument with "dendrogram length must be N-1";
      end if;

      for I in 1 .. N loop
         Parent (I) := I;
      end loop;

      for M in Tree'Range loop
         if Tree (M).Height <= Height then
            declare
               Mr : constant Merge_Record := Tree (M);
               A  : constant Positive := Find (Mr.Left);
               B  : constant Positive := Find (Mr.Right);
            begin
               if A /= B then
                  New_Cluster := New_Cluster + 1;
                  Parent (New_Cluster) := New_Cluster;
                  Parent (A) := New_Cluster;
                  Parent (B) := New_Cluster;
               end if;
            end;
         end if;
      end loop;

      for I in 1 .. N loop
         declare
            R : constant Positive := Find (I);
         begin
            if Root_Of (R) = 0 then
               Next_Label := Next_Label + 1;
               Root_Of (R) := Next_Label;
            end if;
            Lab (Point_Index (I)) := Root_Of (R);
         end;
      end loop;
      return Lab;
   end Labels_At_Height;

   function Run_Single_Linkage_Cut
     (Data   : Dataset;
      Height : Non_Negative) return Labels
   is
      Tree : constant Dendrogram := Run_Single_Linkage (Data);
      N    : constant Point_Count := Data'Length (1);
   begin
      return Labels_At_Height (Tree, N, Height);
   end Run_Single_Linkage_Cut;

   function Cut_Dendrogram
     (Tree : Dendrogram;
      N    : Point_Count;
      K    : Positive) return Labels
   is
      Max_Id : constant Positive := N + (N - 1);
      Parent : array (1 .. Max_Id) of Natural := [others => 0];
      Lab : Labels (1 .. N);
      Merges_To_Apply : Natural;
      Next_Label : Natural := 0;
      Root_Of : array (1 .. Max_Id) of Natural := [others => 0];

      function Find (X : Positive) return Positive is
         R : Positive := X;
         P : Positive;
      begin
         while Parent (R) /= 0 and then Parent (R) /= R loop
            R := Parent (R);
         end loop;
         P := X;
         while P /= R loop
            declare
               Next : constant Natural := Parent (P);
            begin
               Parent (P) := R;
               exit when Next = 0 or else Next = P;
               P := Next;
            end;
         end loop;
         return R;
      end Find;

   begin
      if N < 2 then
         raise Invalid_Argument with "Cut_Dendrogram needs N >= 2";
      end if;
      if Tree'Length /= N - 1 then
         raise Invalid_Argument with "dendrogram length must be N-1";
      end if;
      if K > N then
         raise Invalid_Argument with "K out of range";
      end if;

      for I in 1 .. N loop
         Parent (I) := I;
      end loop;

      Merges_To_Apply := N - K;
      for M in 1 .. Merges_To_Apply loop
         declare
            Mr : constant Merge_Record := Tree (Tree'First + (M - 1));
            A  : constant Positive := Find (Mr.Left);
            B  : constant Positive := Find (Mr.Right);
            New_Id : constant Positive := N + M;
         begin
            Parent (New_Id) := New_Id;
            Parent (A) := New_Id;
            Parent (B) := New_Id;
         end;
      end loop;

      for I in 1 .. N loop
         declare
            R : constant Positive := Find (I);
         begin
            if Root_Of (R) = 0 then
               Next_Label := Next_Label + 1;
               Root_Of (R) := Next_Label;
            end if;
            Lab (Point_Index (I)) := Root_Of (R);
         end;
      end loop;

      if Next_Label /= K then
         raise Invalid_Argument
           with "cut did not produce exactly K clusters";
      end if;
      return Lab;
   end Cut_Dendrogram;

   -------------------------------------------------------------------------
   -- Density model — DBSCAN
   -------------------------------------------------------------------------

   function Neighbor_Count
     (Data : Dataset;
      P    : Point_Index;
      Eps  : Positive_Real) return Natural
   is
      Count : Natural := 0;
   begin
      if P not in Data'Range (1) then
         raise Invalid_Argument with "Neighbor_Count: bad point";
      end if;
      for Q in Data'Range (1) loop
         if Distance (Data, P, Q) <= Eps then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Neighbor_Count;

   function Range_Query
     (Data : Dataset;
      P    : Point_Index;
      Eps  : Positive_Real) return Point_Id_Array
   is
      Count : constant Natural := Neighbor_Count (Data, P, Eps);
      Nbr   : Point_Id_Array (1 .. Count);
      Ix    : Natural := 0;
   begin
      for Q in Data'Range (1) loop
         if Distance (Data, P, Q) <= Eps then
            Ix := Ix + 1;
            Nbr (Point_Index (Ix)) := Q;
         end if;
      end loop;
      return Nbr;
   end Range_Query;

   function Cluster_Count_Of (Lab : Labels) return Natural is
      Seen : array (1 .. Max_Points) of Boolean := [others => False];
      C    : Natural := 0;
      Id   : Integer;
   begin
      for I in Lab'Range loop
         Id := Integer (Lab (I));
         if Id > 0 and then Id <= Max_Points and then not Seen (Id) then
            Seen (Id) := True;
            C := C + 1;
         end if;
      end loop;
      return C;
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

   function Run_DBSCAN
     (Data   : Dataset;
      Params : DBSCAN_Parameters) return DBSCAN_Result
   is
      First : constant Point_Index := Data'First (1);
      Last  : constant Natural := Natural (Data'Last (1));

      Lab : Labels (First .. Last);

      Seed_Q   : array (1 .. Max_Points) of Point_Index;
      Seed_Len : Natural := 0;
      In_Seed  : array (1 .. Max_Points) of Boolean := [others => False];

      C_Id : Natural := 0;
      Outcome : DBSCAN_Result (First, Last);
      Undefined : constant Natural := Natural'Last;

      procedure Seed_Clear is
      begin
         for I in 1 .. Seed_Len loop
            In_Seed (Seed_Q (I)) := False;
         end loop;
         Seed_Len := 0;
      end Seed_Clear;

      procedure Seed_Add (Q : Point_Index) is
      begin
         if not In_Seed (Q) then
            if Seed_Len >= Max_Points then
               raise Capacity_Exceeded with "seed set overflow";
            end if;
            Seed_Len := Seed_Len + 1;
            Seed_Q (Seed_Len) := Q;
            In_Seed (Q) := True;
         end if;
      end Seed_Add;

   begin
      Require_Dataset (Data);
      --  Eps is Positive_Real and MinPts is Positive (subtype-enforced).

      for P in First .. Last loop
         Lab (P) := Undefined;
      end loop;

      for P in First .. Last loop
         if Lab (P) = Undefined then
            declare
               N_P : constant Point_Id_Array :=
                 Range_Query (Data, P, Params.Eps);
            begin
               if N_P'Length < Params.MinPts then
                  Lab (P) := Noise_Label;
               else
                  C_Id := C_Id + 1;
                  Lab (P) := C_Id;
                  Seed_Clear;
                  for K in N_P'Range loop
                     if N_P (K) /= P then
                        Seed_Add (N_P (K));
                     end if;
                  end loop;

                  declare
                     Si : Natural := 1;
                  begin
                     while Si <= Seed_Len loop
                        declare
                           Q : constant Point_Index := Seed_Q (Si);
                        begin
                           if Lab (Q) = Noise_Label then
                              Lab (Q) := C_Id;
                           end if;
                           if Lab (Q) = Undefined then
                              Lab (Q) := C_Id;
                              declare
                                 N_Q : constant Point_Id_Array :=
                                   Range_Query (Data, Q, Params.Eps);
                              begin
                                 if N_Q'Length >= Params.MinPts then
                                    for K in N_Q'Range loop
                                       Seed_Add (N_Q (K));
                                    end loop;
                                 end if;
                              end;
                           end if;
                        end;
                        Si := Si + 1;
                     end loop;
                  end;
               end if;
            end;
         end if;
      end loop;

      for P in First .. Last loop
         if Lab (P) = Undefined then
            Lab (P) := Noise_Label;
         end if;
      end loop;

      Outcome.Lab := Lab;
      Outcome.Cluster_Count := Cluster_Count_Of (Lab);
      Outcome.Noise_Count := Noise_Count_Of (Lab);
      return Outcome;
   end Run_DBSCAN;

   -------------------------------------------------------------------------
   -- Internal evaluation
   -------------------------------------------------------------------------

   function Mean_Silhouette
     (Data : Dataset; Lab : Labels) return Real
   is
      N : constant Point_Count := Data'Length (1);
      --  Collect distinct positive cluster ids
      Seen : array (1 .. Max_K) of Boolean := [others => False];
      Cluster_Ids : array (1 .. Max_K) of Natural := [others => 0];
      N_Clusters : Natural := 0;
      Sizes : array (1 .. Max_K) of Natural := [others => 0];
      Sum_S : Real := 0.0;
      Count_S : Natural := 0;
   begin
      Require_Dataset (Data);
      if Lab'Length /= N or else Lab'First /= Data'First (1) then
         raise Invalid_Argument with "Mean_Silhouette: label extent";
      end if;

      for P in Data'Range (1) loop
         declare
            L : constant Natural := Lab (P);
         begin
            if L > 0 then
               if L > Max_K then
                  raise Invalid_Argument with
                    "Mean_Silhouette: label > Max_K";
               end if;
               if not Seen (L) then
                  Seen (L) := True;
                  N_Clusters := N_Clusters + 1;
                  Cluster_Ids (N_Clusters) := L;
               end if;
               Sizes (L) := Sizes (L) + 1;
            end if;
         end;
      end loop;

      if N_Clusters < 2 then
         raise Invalid_Argument with
           "Mean_Silhouette needs >= 2 clusters";
      end if;

      for P in Data'Range (1) loop
         declare
            L : constant Natural := Lab (P);
         begin
            if L > 0 then
               declare
                  A : Real := 0.0;
                  B : Real := Real'Last;
                  Intra_N : Natural := 0;
                  S_I : Real;
               begin
                  --  a(i): mean distance to other points in same cluster
                  if Sizes (L) <= 1 then
                     S_I := 0.0;
                  else
                     for Q in Data'Range (1) loop
                        if Q /= P and then Lab (Q) = L then
                           A := A + Distance (Data, P, Q);
                           Intra_N := Intra_N + 1;
                        end if;
                     end loop;
                     if Intra_N > 0 then
                        A := A / Real (Intra_N);
                     end if;

                     --  b(i): min mean distance to another cluster
                     for Ci in 1 .. N_Clusters loop
                        declare
                           Other : constant Natural := Cluster_Ids (Ci);
                           Mean_O : Real := 0.0;
                           No : Natural := 0;
                        begin
                           if Other /= L then
                              for Q in Data'Range (1) loop
                                 if Lab (Q) = Other then
                                    Mean_O := Mean_O + Distance (Data, P, Q);
                                    No := No + 1;
                                 end if;
                              end loop;
                              if No > 0 then
                                 Mean_O := Mean_O / Real (No);
                                 if Mean_O < B then
                                    B := Mean_O;
                                 end if;
                              end if;
                           end if;
                        end;
                     end loop;

                     --  s = (b - a) / max(a, b)
                     if B = Real'Last then
                        S_I := 0.0;
                     else
                        declare
                           Den : Real;
                        begin
                           if A > B then
                              Den := A;
                           else
                              Den := B;
                           end if;
                           if Den = 0.0 then
                              S_I := 0.0;
                           else
                              S_I := (B - A) / Den;
                           end if;
                        end;
                     end if;
                  end if;
                  Sum_S := Sum_S + S_I;
                  Count_S := Count_S + 1;
               end;
            end if;
         end;
      end loop;

      if Count_S = 0 then
         raise Invalid_Argument with "Mean_Silhouette: no labeled points";
      end if;
      return Sum_S / Real (Count_S);
   end Mean_Silhouette;

   function Dunn_Index
     (Data : Dataset; Lab : Labels) return Non_Negative
   is
      Min_Inter : Real := Real'Last;
      Max_Intra : Real := 0.0;
      N_Clusters : Natural := 0;
      Seen : array (1 .. Max_K) of Boolean := [others => False];
      Have_Inter : Boolean := False;
   begin
      Require_Dataset (Data);
      if Lab'Length /= Data'Length (1)
        or else Lab'First /= Data'First (1)
      then
         raise Invalid_Argument with "Dunn_Index: label extent";
      end if;

      for P in Data'Range (1) loop
         if Lab (P) > 0 then
            if Lab (P) > Max_K then
               raise Invalid_Argument with "Dunn_Index: label > Max_K";
            end if;
            if not Seen (Lab (P)) then
               Seen (Lab (P)) := True;
               N_Clusters := N_Clusters + 1;
            end if;
         end if;
      end loop;

      if N_Clusters < 2 then
         raise Invalid_Argument with "Dunn_Index needs >= 2 clusters";
      end if;

      for P in Data'Range (1) loop
         if Lab (P) > 0 then
            for Q in Data'Range (1) loop
               if Q > P and then Lab (Q) > 0 then
                  declare
                     Dpq : constant Non_Negative := Distance (Data, P, Q);
                  begin
                     if Lab (P) = Lab (Q) then
                        if Dpq > Max_Intra then
                           Max_Intra := Dpq;
                        end if;
                     else
                        Have_Inter := True;
                        if Dpq < Min_Inter then
                           Min_Inter := Dpq;
                        end if;
                     end if;
                  end;
               end if;
            end loop;
         end if;
      end loop;

      if not Have_Inter then
         raise Invalid_Argument with "Dunn_Index: no inter-cluster pair";
      end if;
      if Max_Intra = 0.0 then
         --  All clusters are singletons / coincident → very large Dunn
         return 1.0E12;
      end if;
      return Non_Negative (Min_Inter / Max_Intra);
   end Dunn_Index;

end Clustering_Algorithms;
