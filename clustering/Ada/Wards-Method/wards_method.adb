--  Wards_Method body — squared Euclidean, Ward Δ, Lance–Williams, linkage.

pragma Ada_2022;

package body Wards_Method
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   procedure Require_Dataset (Data : Dataset) is
   begin
      if Data'Length (1) = 0 or else Data'Length (2) = 0 then
         raise Invalid_Argument with "empty dataset";
      end if;
      if Data'Length (1) > Max_Points then
         raise Capacity_Exceeded with "more points than Max_Points";
      end if;
      if Data'Length (2) > Max_Dims then
         raise Capacity_Exceeded with "more dims than Max_Dims";
      end if;
   end Require_Dataset;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   -------------------------------------------------------------------------
   -- Geometry
   -------------------------------------------------------------------------

   function Squared_Euclidean (A, B : Point) return Non_Negative is
      Acc : Real := 0.0;
      Diff : Real;
   begin
      if A'Length = 0 or else B'Length = 0 then
         raise Invalid_Argument with "empty point";
      end if;
      if A'First /= B'First or else A'Last /= B'Last then
         raise Invalid_Argument with "point length mismatch";
      end if;
      for D in A'Range loop
         Diff := A (D) - B (D);
         Acc := Acc + Diff * Diff;
      end loop;
      return Acc;
   end Squared_Euclidean;

   function Centroid (Data : Dataset) return Point is
      N   : constant Natural := Data'Length (1);
      Res : Point (Data'Range (2));
      S   : Real;
   begin
      Require_Dataset (Data);
      for D in Data'Range (2) loop
         S := 0.0;
         for P in Data'Range (1) loop
            S := S + Data (P, D);
         end loop;
         Res (D) := S / Real (N);
      end loop;
      return Res;
   end Centroid;

   function Ward_Delta_From_Dist
     (Ni, Nj : Positive; Dist_Sq_Centroids : Non_Negative)
      return Non_Negative
   is
      Num : constant Real := Real (Ni) * Real (Nj);
      Den : constant Real := Real (Ni) + Real (Nj);
   begin
      return (Num / Den) * Dist_Sq_Centroids;
   end Ward_Delta_From_Dist;

   function Ward_Delta
     (Ni, Nj     : Positive;
      Mu_I, Mu_J : Point) return Non_Negative
   is
   begin
      if Mu_I'Length = 0 or else Mu_J'Length = 0 then
         raise Invalid_Argument with "empty centroid";
      end if;
      if Mu_I'First /= Mu_J'First or else Mu_I'Last /= Mu_J'Last then
         raise Invalid_Argument with "centroid length mismatch";
      end if;
      return Ward_Delta_From_Dist
        (Ni, Nj, Squared_Euclidean (Mu_I, Mu_J));
   end Ward_Delta;

   -------------------------------------------------------------------------
   -- Lance–Williams
   -------------------------------------------------------------------------

   function Lance_Williams_Ward
     (Ni, Nj, Nk : Positive;
      Dik, Djk, Dij : Real) return Real
   is
      Tot  : constant Real := Real (Ni) + Real (Nj) + Real (Nk);
      Alpha_I : constant Real := (Real (Ni) + Real (Nk)) / Tot;
      Alpha_J : constant Real := (Real (Nj) + Real (Nk)) / Tot;
      Beta    : constant Real := -Real (Nk) / Tot;
   begin
      return Alpha_I * Dik + Alpha_J * Djk + Beta * Dij;
   end Lance_Williams_Ward;

   -------------------------------------------------------------------------
   -- Ward linkage (naive O(n³))
   -------------------------------------------------------------------------

   function Ward_Linkage (Data : Dataset) return Dendrogram is
      N : constant Natural := Data'Length (1);
      --  Active cluster slots 1 .. N; initially singleton i holds point i.
      --  Dist(A,B) stores Lance–Williams Ward distance ( = 2·Δ ).
      Dist : array (1 .. Max_Points, 1 .. Max_Points) of Real :=
        [others => [others => 0.0]];
      Size : array (1 .. Max_Points) of Natural := [others => 0];
      Alive : array (1 .. Max_Points) of Boolean := [others => False];
      --  Map slot -> dendrogram cluster id (leaf 1..N or N+merge_index)
      Id : array (1 .. Max_Points) of Positive := [others => 1];
      --  Centroid coordinates per active slot
      Mu : array (1 .. Max_Points, 1 .. Max_Dims) of Real :=
        [others => [others => 0.0]];
      Dims : constant Natural := Data'Length (2);
      Tree : Dendrogram (1 .. N - 1);
      Active_Count : Natural := N;
      Merge_Idx : Natural := 0;

      function Slot_Centroid (S : Positive) return Point is
         Res : Point (Data'Range (2));
      begin
         for D in Data'Range (2) loop
            Res (D) := Mu (S, D);
         end loop;
         return Res;
      end Slot_Centroid;

      procedure Find_Best_Pair (Best_I, Best_J : out Positive; Best_D : out Real)
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
                        Dij : constant Real := Dist (I, J);
                     begin
                        --  Minimize Lance–Williams distance; ties → lowest I, then J.
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
            raise Degenerate_Geometry with "no alive pair to merge";
         end if;
      end Find_Best_Pair;

   begin
      Require_Dataset (Data);
      if N < 2 then
         raise Invalid_Argument with "Ward_Linkage needs at least 2 points";
      end if;

      --  Initialize singletons
      for I in 1 .. N loop
         Alive (I) := True;
         Size (I) := 1;
         Id (I) := I;
         for D in Data'Range (2) loop
            Mu (I, D) := Data (Data'First (1) + (I - 1), D);
         end loop;
      end loop;

      --  Initial distances: squared Euclidean (= 2·Δ for singletons)
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            declare
               Acc : Real := 0.0;
               Diff : Real;
            begin
               for D in 1 .. Dims loop
                  Diff := Mu (I, D) - Mu (J, D);
                  Acc := Acc + Diff * Diff;
               end loop;
               Dist (I, J) := Acc;
               Dist (J, I) := Acc;
            end;
         end loop;
      end loop;

      while Active_Count > 1 loop
         declare
            BI, BJ : Positive;
            BD : Real;
            Ni, Nj : Positive;
            New_Size : Positive;
            Merge_Cost : Non_Negative;
         begin
            Find_Best_Pair (BI, BJ, BD);
            Ni := Size (BI);
            Nj := Size (BJ);
            --  Height = Δ = d/2  (Ward LW distance is 2·Δ), equivalently
            --  Ward_Delta from centroids.
            Merge_Cost := Ward_Delta (Ni, Nj, Slot_Centroid (BI), Slot_Centroid (BJ));
            Merge_Idx := Merge_Idx + 1;
            Tree (Merge_Idx) :=
              (Left   => Id (BI),
               Right  => Id (BJ),
               Height => Merge_Cost);

            New_Size := Ni + Nj;
            --  New centroid in slot BI; retire BJ
            for D in 1 .. Dims loop
               Mu (BI, D) :=
                 (Real (Ni) * Mu (BI, D) + Real (Nj) * Mu (BJ, D))
                 / Real (New_Size);
            end loop;
            Size (BI) := New_Size;
            Id (BI) := N + Merge_Idx;
            Alive (BJ) := False;
            Size (BJ) := 0;

            --  Update distances from BI to all other alive clusters via LW
            for K in 1 .. N loop
               if Alive (K) and then K /= BI then
                  declare
                     Nk : constant Positive := Size (K);
                     Dik : constant Real := Dist (BI, K);
                     Djk : constant Real := Dist (BJ, K);
                     Dij : constant Real := BD;
                     New_D : Real;
                  begin
                     New_D := Lance_Williams_Ward (Ni, Nj, Nk, Dik, Djk, Dij);
                     Dist (BI, K) := New_D;
                     Dist (K, BI) := New_D;
                  end;
               end if;
            end loop;
            Dist (BI, BI) := 0.0;
            Active_Count := Active_Count - 1;
         end;
      end loop;

      return Tree;
   end Ward_Linkage;

   -------------------------------------------------------------------------
   -- Cut dendrogram into K clusters
   -------------------------------------------------------------------------

   function Cut_Dendrogram
     (Tree : Dendrogram;
      N    : Point_Count;
      K    : Positive) return Labels
   is
      --  Union–find on leaves; parent of cluster id
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
         --  Path compression
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
            A : constant Positive := Find (Mr.Left);
            B : constant Positive := Find (Mr.Right);
            New_Id : constant Positive := N + M;
         begin
            Parent (New_Id) := New_Id;
            Parent (A) := New_Id;
            Parent (B) := New_Id;
         end;
      end loop;

      --  Assign compact labels 1 .. K by first-seen root order
      for I in 1 .. N loop
         declare
            R : constant Positive := Find (I);
         begin
            if Root_Of (R) = 0 then
               Next_Label := Next_Label + 1;
               Root_Of (R) := Next_Label;
            end if;
            Lab (I) := Root_Of (R);
         end;
      end loop;

      if Next_Label /= K then
         raise Degenerate_Geometry
           with "cut did not produce exactly K clusters";
      end if;
      return Lab;
   end Cut_Dendrogram;

   -------------------------------------------------------------------------
   -- Within-cluster SSE
   -------------------------------------------------------------------------

   function Within_Cluster_SSE
     (Data : Dataset; Lab : Labels) return Non_Negative
   is
      N : constant Natural := Data'Length (1);
      Dims : constant Natural := Data'Length (2);
      --  Accumulate sums and counts per label (labels up to N)
      Count : array (0 .. Max_Points) of Natural := [others => 0];
      Sum : array (0 .. Max_Points, 1 .. Max_Dims) of Real :=
        [others => [others => 0.0]];
      SSE : Real := 0.0;
      Max_Lab : Natural := 0;
   begin
      Require_Dataset (Data);
      if Lab'Length /= N then
         raise Invalid_Argument with "label length mismatch";
      end if;

      for I in 1 .. N loop
         declare
            L : constant Natural := Lab (Lab'First + (I - 1));
            P : constant Point_Index := Data'First (1) + (I - 1);
         begin
            if L = 0 or else L > Max_Points then
               raise Invalid_Argument with "invalid label";
            end if;
            if L > Max_Lab then
               Max_Lab := L;
            end if;
            Count (L) := Count (L) + 1;
            for D in 1 .. Dims loop
               Sum (L, D) := Sum (L, D) + Data (P, Data'First (2) + (D - 1));
            end loop;
         end;
      end loop;

      for L in 1 .. Max_Lab loop
         if Count (L) > 0 then
            declare
               Mu : Point (Data'Range (2));
            begin
               for D in Data'Range (2) loop
                  declare
                     Di : constant Positive :=
                       Positive (D - Data'First (2) + 1);
                  begin
                     Mu (D) := Sum (L, Di) / Real (Count (L));
                  end;
               end loop;
               for I in 1 .. N loop
                  if Lab (Lab'First + (I - 1)) = L then
                     declare
                        P : constant Point_Index :=
                          Data'First (1) + (I - 1);
                        Acc : Real := 0.0;
                        Diff : Real;
                     begin
                        for D in Data'Range (2) loop
                           Diff := Data (P, D) - Mu (D);
                           Acc := Acc + Diff * Diff;
                        end loop;
                        SSE := SSE + Acc;
                     end;
                  end if;
               end loop;
            end;
         end if;
      end loop;

      return SSE;
   end Within_Cluster_SSE;

end Wards_Method;
