--  Subclu body — DBSCAN-in-subspace + Apriori bottom-up SUBCLU (SDM'04).

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Subclu
  with SPARK_Mode => Off
is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   ---------------------------------------------------------------------------
   -- Local helpers
   ---------------------------------------------------------------------------

   procedure Validate_Params (Params : Parameters) is
   begin
      --  MinPts is Positive (always >= 1); Eps is Positive_Real (always > 0).
      --  Defensive no-op kept for call-site symmetry / future subtype changes.
      if Params.Eps <= 0.0 then
         raise Invalid_Argument with "Eps must be > 0";
      end if;
   end Validate_Params;

   procedure Validate_Space (Data : Dataset; Space : Subspace) is
   begin
      if Space.Count = 0 then
         raise Invalid_Argument with "empty subspace";
      end if;
      for I in 1 .. Space.Count loop
         if not Dim_In_Range (Data, Space.Attrs (I)) then
            raise Invalid_Argument with "attribute outside dataset dims";
         end if;
      end loop;
   end Validate_Space;

   procedure Validate_Active (Data : Dataset; Active : Point_Subset) is
   begin
      for I in 1 .. Active.Count loop
         if Active.Ids (I) not in Data'Range (1) then
            raise Invalid_Argument with "Active point id out of range";
         end if;
      end loop;
   end Validate_Active;

   function Contains_Id
     (Active : Point_Subset; P : Point_Id) return Boolean
   is
   begin
      for I in 1 .. Active.Count loop
         if Active.Ids (I) = P then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Id;

   --  Drop attribute at position Drop_Pos (1 .. S.Count) → k−1 subspace.
   function Drop_Attr (S : Subspace; Drop_Pos : Positive) return Subspace is
      R : Subspace;
      N : Dim_Count := 0;
   begin
      for I in 1 .. S.Count loop
         if I /= Drop_Pos then
            N := N + 1;
            R.Attrs (N) := S.Attrs (I);
         end if;
      end loop;
      R.Count := N;
      return R;
   end Drop_Attr;

   function In_List
     (List : Subspace_List; Count : Subspace_Count; S : Subspace)
      return Boolean
   is
   begin
      for I in 1 .. Count loop
         if Subspace_Equal (List (I), S) then
            return True;
         end if;
      end loop;
      return False;
   end In_List;

   procedure Append_Unique
     (List  : in out Subspace_List;
      Count : in out Subspace_Count;
      S     : Subspace)
   is
   begin
      if In_List (List, Count, S) then
         return;
      end if;
      if Count = Max_Subspaces then
         raise Capacity_Exceeded with "too many subspaces";
      end if;
      Count := Count + 1;
      List (Count) := S;
   end Append_Unique;

   ---------------------------------------------------------------------------
   -- Public helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Empty_Subspace return Subspace is
   begin
      return (Count => 0, Attrs => [others => 1]);
   end Empty_Subspace;

   function Make_Subspace (Attrs : Dim_Id_Array) return Subspace is
      R : Subspace;
      --  Insertion sort into unique ascending order.
   begin
      R.Count := 0;
      for A of Attrs loop
         if not A'Valid then
            raise Invalid_Argument with "attribute id out of capacity";
         end if;
         if not Subspace_Contains (R, A) then
            if R.Count = Max_Dims then
               raise Capacity_Exceeded with "too many attributes";
            end if;
            R.Count := R.Count + 1;
            R.Attrs (R.Count) := A;
            --  Bubble into place.
            declare
               J : Natural := R.Count;
            begin
               while J > 1 and then R.Attrs (J - 1) > R.Attrs (J) loop
                  declare
                     T : constant Dim_Id := R.Attrs (J - 1);
                  begin
                     R.Attrs (J - 1) := R.Attrs (J);
                     R.Attrs (J) := T;
                  end;
                  J := J - 1;
               end loop;
            end;
         end if;
      end loop;
      return R;
   end Make_Subspace;

   function Subspace_Contains
     (S : Subspace; A : Dim_Id) return Boolean
   is
   begin
      for I in 1 .. S.Count loop
         if S.Attrs (I) = A then
            return True;
         end if;
      end loop;
      return False;
   end Subspace_Contains;

   function Subspace_Equal (A, B : Subspace) return Boolean is
   begin
      if A.Count /= B.Count then
         return False;
      end if;
      for I in 1 .. A.Count loop
         if A.Attrs (I) /= B.Attrs (I) then
            return False;
         end if;
      end loop;
      return True;
   end Subspace_Equal;

   function Subspace_Subset (A, B : Subspace) return Boolean is
   begin
      for I in 1 .. A.Count loop
         if not Subspace_Contains (B, A.Attrs (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Subspace_Subset;

   function Subspace_Union (A, B : Subspace) return Subspace is
      R : Subspace := A;
   begin
      for I in 1 .. B.Count loop
         if not Subspace_Contains (R, B.Attrs (I)) then
            if R.Count = Max_Dims then
               raise Capacity_Exceeded with "union exceeds Max_Dims";
            end if;
            R.Count := R.Count + 1;
            R.Attrs (R.Count) := B.Attrs (I);
            declare
               J : Natural := R.Count;
            begin
               while J > 1 and then R.Attrs (J - 1) > R.Attrs (J) loop
                  declare
                     T : constant Dim_Id := R.Attrs (J - 1);
                  begin
                     R.Attrs (J - 1) := R.Attrs (J);
                     R.Attrs (J) := T;
                  end;
                  J := J - 1;
               end loop;
            end;
         end if;
      end loop;
      return R;
   end Subspace_Union;

   function Subspace_Intersection (A, B : Subspace) return Subspace is
      R : Subspace;
   begin
      R.Count := 0;
      for I in 1 .. A.Count loop
         if Subspace_Contains (B, A.Attrs (I)) then
            R.Count := R.Count + 1;
            R.Attrs (R.Count) := A.Attrs (I);
         end if;
      end loop;
      return R;
   end Subspace_Intersection;

   function Differ_By_One (A, B : Subspace) return Boolean is
      Inter : constant Subspace := Subspace_Intersection (A, B);
      Uni   : constant Subspace := Subspace_Union (A, B);
   begin
      if A.Count = 0 or else B.Count = 0 then
         return False;
      end if;
      if A.Count /= B.Count then
         return False;
      end if;
      return Inter.Count = A.Count - 1
        and then Uni.Count = A.Count + 1;
   end Differ_By_One;

   function Dim_In_Range
     (Data : Dataset; A : Dim_Id) return Boolean
   is
   begin
      return A in Data'Range (2);
   end Dim_In_Range;

   function Distance
     (Data  : Dataset;
      P, Q  : Point_Id;
      Space : Subspace) return Non_Negative
   is
      Sum : Real := 0.0;
      D   : Real;
   begin
      if P not in Data'Range (1) or else Q not in Data'Range (1) then
         raise Invalid_Argument with "point id out of range";
      end if;
      Validate_Space (Data, Space);
      for I in 1 .. Space.Count loop
         D := Data (P, Space.Attrs (I)) - Data (Q, Space.Attrs (I));
         Sum := Sum + D * D;
      end loop;
      if Sum <= 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Math.Sqrt (Sum));
   end Distance;

   function Neighborhood_Count
     (Data   : Dataset;
      P      : Point_Id;
      Space  : Subspace;
      Eps    : Positive_Real;
      Active : Point_Subset) return Natural
   is
      C : Natural := 0;
   begin
      if P not in Data'Range (1) then
         raise Invalid_Argument with "point id out of range";
      end if;
      Validate_Space (Data, Space);
      Validate_Active (Data, Active);
      for I in 1 .. Active.Count loop
         if Distance (Data, P, Active.Ids (I), Space) <= Eps then
            C := C + 1;
         end if;
      end loop;
      return C;
   end Neighborhood_Count;

   function Is_Core_Point
     (Data   : Dataset;
      P      : Point_Id;
      Space  : Subspace;
      Params : Parameters;
      Active : Point_Subset) return Boolean
   is
   begin
      Validate_Params (Params);
      return Neighborhood_Count
        (Data, P, Space, Params.Eps, Active) >= Params.MinPts;
   end Is_Core_Point;

   function Full_Point_Subset (N : Point_Count) return Point_Subset is
      S : Point_Subset;
   begin
      S.Count := N;
      for I in 1 .. N loop
         S.Ids (I) := Point_Id (I);
      end loop;
      return S;
   end Full_Point_Subset;

   function Make_Parameters
     (Eps : Real; MinPts : Integer) return Parameters
   is
   begin
      if Eps <= 0.0 then
         raise Invalid_Argument with "Eps must be > 0";
      end if;
      if MinPts < 1 then
         raise Invalid_Argument with "MinPts must be >= 1";
      end if;
      return (Eps => Positive_Real (Eps), MinPts => Positive (MinPts));
   end Make_Parameters;

   ---------------------------------------------------------------------------
   -- DBSCAN
   ---------------------------------------------------------------------------

   function DBSCAN
     (Data   : Dataset;
      Space  : Subspace;
      Params : Parameters;
      Active : Point_Subset) return DBSCAN_Result
   is
      N : constant Natural := Data'Length (1);
      Result : DBSCAN_Result
        (First => Data'First (1),
         Last  => (if N = 0 then 0 else Data'Last (1)));

      type Visit_Array is array (Point_Id range <>) of Boolean;
      Visited : Visit_Array (Result.First .. Result.Last) :=
        [others => False];

      --  Collect ε-neighbors of P among Active into Seeds.
      procedure Region_Query
        (P     : Point_Id;
         Seeds : out Point_Subset)
      is
      begin
         Seeds.Count := 0;
         for I in 1 .. Active.Count loop
            declare
               Q : constant Point_Id := Active.Ids (I);
            begin
               if Distance (Data, P, Q, Space) <= Params.Eps then
                  Seeds.Count := Seeds.Count + 1;
                  Seeds.Ids (Seeds.Count) := Q;
               end if;
            end;
         end loop;
      end Region_Query;

      procedure Expand_Cluster
        (P           : Point_Id;
         Seeds       : in out Point_Subset;
         Cluster_Num : Cluster_Id)
      is
         Idx : Positive := 1;
         Neighbor_Seeds : Point_Subset;
      begin
         Result.Labels (P) := Cluster_Num;
         while Idx <= Seeds.Count loop
            declare
               Q : constant Point_Id := Seeds.Ids (Idx);
            begin
               if not Visited (Q) then
                  Visited (Q) := True;
                  Region_Query (Q, Neighbor_Seeds);
                  if Neighbor_Seeds.Count >= Params.MinPts then
                     --  Union neighbor seeds into Seeds.
                     for J in 1 .. Neighbor_Seeds.Count loop
                        declare
                           R : constant Point_Id := Neighbor_Seeds.Ids (J);
                           Found : Boolean := False;
                        begin
                           for K in 1 .. Seeds.Count loop
                              if Seeds.Ids (K) = R then
                                 Found := True;
                                 exit;
                              end if;
                           end loop;
                           if not Found then
                              if Seeds.Count = Max_Points then
                                 raise Capacity_Exceeded
                                   with "seed set overflow";
                              end if;
                              Seeds.Count := Seeds.Count + 1;
                              Seeds.Ids (Seeds.Count) := R;
                           end if;
                        end;
                     end loop;
                  end if;
               end if;
               if Result.Labels (Q) = Noise_Label then
                  Result.Labels (Q) := Cluster_Num;
               end if;
            end;
            Idx := Idx + 1;
         end loop;
      end Expand_Cluster;

   begin
      if Data'Length (1) = 0 or else Data'Length (2) = 0 then
         raise Invalid_Argument with "empty dataset";
      end if;
      Validate_Params (Params);
      Validate_Space (Data, Space);
      Validate_Active (Data, Active);

      for I in Result.Labels'Range loop
         Result.Labels (I) := Noise_Label;
      end loop;
      Result.Cluster_Count := 0;
      Result.Noise_Count := 0;

      for I in 1 .. Active.Count loop
         declare
            P : constant Point_Id := Active.Ids (I);
            Seeds : Point_Subset;
         begin
            if not Visited (P) then
               Visited (P) := True;
               Region_Query (P, Seeds);
               if Seeds.Count < Params.MinPts then
                  Result.Labels (P) := Noise_Label;
               else
                  if Result.Cluster_Count = Max_Clusters then
                     raise Capacity_Exceeded with "too many DBSCAN clusters";
                  end if;
                  Result.Cluster_Count := Result.Cluster_Count + 1;
                  Expand_Cluster (P, Seeds, Result.Cluster_Count);
               end if;
            end if;
         end;
      end loop;

      for I in Result.Labels'Range loop
         if Contains_Id (Active, I) and then Result.Labels (I) = Noise_Label
         then
            Result.Noise_Count := Result.Noise_Count + 1;
         end if;
      end loop;

      return Result;
   end DBSCAN;

   ---------------------------------------------------------------------------
   -- Generate_Candidate_Subspaces
   ---------------------------------------------------------------------------

   procedure Generate_Candidate_Subspaces
     (Sk         : Subspace_List;
      Sk_Count   : Subspace_Count;
      Cand       : out Subspace_List;
      Cand_Count : out Subspace_Count)
   is
      Raw       : Subspace_List;
      Raw_Count : Subspace_Count := 0;
      K         : Dim_Count := 0;
   begin
      Cand_Count := 0;
      if Sk_Count = 0 then
         return;
      end if;

      K := Sk (1).Count;
      if K = 0 then
         raise Invalid_Argument with "Sk entries must be non-empty";
      end if;
      for I in 2 .. Sk_Count loop
         if Sk (I).Count /= K then
            raise Invalid_Argument
              with "Sk subspaces must share the same dimensionality";
         end if;
      end loop;

      --  Pairwise join.
      for I in 1 .. Sk_Count loop
         for J in I + 1 .. Sk_Count loop
            if Differ_By_One (Sk (I), Sk (J)) then
               Append_Unique
                 (Raw, Raw_Count, Subspace_Union (Sk (I), Sk (J)));
            end if;
         end loop;
      end loop;

      --  Prune: every k-subset of cand must be in Sk.
      for C in 1 .. Raw_Count loop
         declare
            Keep : Boolean := True;
            Cand_S : constant Subspace := Raw (C);
         begin
            --  Cand has k+1 attrs; each leave-one-out is a k-subset.
            for Drop in 1 .. Cand_S.Count loop
               declare
                  Sub : constant Subspace := Drop_Attr (Cand_S, Drop);
               begin
                  if not In_List (Sk, Sk_Count, Sub) then
                     Keep := False;
                     exit;
                  end if;
               end;
            end loop;
            if Keep then
               Append_Unique (Cand, Cand_Count, Cand_S);
            end if;
         end;
      end loop;
   end Generate_Candidate_Subspaces;

   ---------------------------------------------------------------------------
   -- Run_SUBCLU
   ---------------------------------------------------------------------------

   --  Internal storage of clusters per subspace at dimension k.
   type Level_Cluster is record
      Space   : Subspace;
      Size    : Point_Count := 0;
      Members : Point_Id_Array := [others => 1];
   end record;

   type Level_Cluster_Array is array (1 .. Max_Clusters) of Level_Cluster;

   procedure Push_Result_Cluster
     (Result  : in out SUBCLU_Result;
      Space   : Subspace;
      Size    : Point_Count;
      Members : Point_Id_Array)
   is
   begin
      if Result.Cluster_Count = Max_Clusters then
         raise Capacity_Exceeded with "SUBCLU cluster capacity exceeded";
      end if;
      Result.Cluster_Count := Result.Cluster_Count + 1;
      Result.Clusters (Result.Cluster_Count) :=
        (Space   => Space,
         Label   => Cluster_Id (Result.Cluster_Count),
         Size    => Size,
         Members => Members);
      if not In_List
        (Result.Subspaces, Result.Subspace_Count, Space)
      then
         if Result.Subspace_Count = Max_Subspaces then
            raise Capacity_Exceeded with "SUBCLU subspace capacity exceeded";
         end if;
         Result.Subspace_Count := Result.Subspace_Count + 1;
         Result.Subspaces (Result.Subspace_Count) := Space;
      end if;
   end Push_Result_Cluster;

   function Sum_Sizes_For_Space
     (Clusters : Level_Cluster_Array;
      Count    : Cluster_Count;
      Space    : Subspace) return Natural
   is
      S : Natural := 0;
   begin
      for I in 1 .. Count loop
         if Subspace_Equal (Clusters (I).Space, Space) then
            S := S + Natural (Clusters (I).Size);
         end if;
      end loop;
      return S;
   end Sum_Sizes_For_Space;

   function Run_SUBCLU
     (Data   : Dataset;
      Params : Parameters) return SUBCLU_Result
   is
      Result : SUBCLU_Result;
      N      : constant Point_Count := Point_Count (Data'Length (1));
      D      : constant Dim_Count := Dim_Count (Data'Length (2));
      Active_All : constant Point_Subset := Full_Point_Subset (N);

      --  Current level Sk / Ck
      Sk       : Subspace_List;
      Sk_Count : Subspace_Count := 0;
      Ck       : Level_Cluster_Array;
      Ck_Count : Cluster_Count := 0;

      Cand       : Subspace_List;
      Cand_Count : Subspace_Count;
   begin
      if Data'Length (1) = 0 or else Data'Length (2) = 0 then
         raise Invalid_Argument with "empty dataset";
      end if;
      Validate_Params (Params);

      Result.Cluster_Count := 0;
      Result.Subspace_Count := 0;

      --  1D pass: DBSCAN on each single attribute.
      for A in Data'Range (2) loop
         declare
            Space : constant Subspace :=
              Make_Subspace (Dim_Id_Array'(1 => Dim_Id (A)));
            DR : constant DBSCAN_Result :=
              DBSCAN (Data, Space, Params, Active_All);
         begin
            if DR.Cluster_Count > 0 then
               Append_Unique (Sk, Sk_Count, Space);
               for Lab in 1 .. DR.Cluster_Count loop
                  declare
                     Members : Point_Id_Array := [others => 1];
                     Size    : Point_Count := 0;
                  begin
                     for P in DR.Labels'Range loop
                        if DR.Labels (P) = Lab then
                           Size := Size + 1;
                           Members (Size) := P;
                        end if;
                     end loop;
                     if Size > 0 then
                        if Ck_Count = Max_Clusters then
                           raise Capacity_Exceeded
                             with "1D cluster capacity exceeded";
                        end if;
                        Ck_Count := Ck_Count + 1;
                        Ck (Ck_Count) :=
                          (Space => Space, Size => Size, Members => Members);
                        Push_Result_Cluster (Result, Space, Size, Members);
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;

      --  Higher dimensions.
      while Ck_Count > 0 and then Sk_Count > 0 loop
         Generate_Candidate_Subspaces (Sk, Sk_Count, Cand, Cand_Count);

         declare
            Next_Sk       : Subspace_List;
            Next_Sk_Count : Subspace_Count := 0;
            Next_Ck       : Level_Cluster_Array;
            Next_Ck_Count : Cluster_Count := 0;
         begin
            if Cand_Count = 0 then
               exit;
            end if;

            for Ci in 1 .. Cand_Count loop
               declare
                  Cand_S : constant Subspace := Cand (Ci);
                  Best_Idx : Subspace_Count := 0;
                  Best_Sum : Natural := Natural'Last;
                  Cand_Clusters_Found : Boolean := False;
               begin
                  --  bestSubspace = k-subset of cand with minimal Σ |Ci|.
                  for Drop in 1 .. Cand_S.Count loop
                     declare
                        Sub : constant Subspace := Drop_Attr (Cand_S, Drop);
                     begin
                        if In_List (Sk, Sk_Count, Sub) then
                           declare
                              Ssum : constant Natural :=
                                Sum_Sizes_For_Space (Ck, Ck_Count, Sub);
                           begin
                              if Ssum < Best_Sum then
                                 Best_Sum := Ssum;
                                 --  find index of Sub in Sk
                                 for Si in 1 .. Sk_Count loop
                                    if Subspace_Equal (Sk (Si), Sub) then
                                       Best_Idx := Si;
                                       exit;
                                    end if;
                                 end loop;
                              end if;
                           end;
                        end if;
                     end;
                  end loop;

                  if Best_Idx /= 0 then
                     declare
                        Best_Space : constant Subspace := Sk (Best_Idx);
                     begin
                        --  For each cluster cl in best subspace, DBSCAN(cl, cand).
                        for Cl in 1 .. Ck_Count loop
                           if Subspace_Equal (Ck (Cl).Space, Best_Space) then
                              declare
                                 Active_Cl : Point_Subset;
                                 DR : DBSCAN_Result
                                   (First => Data'First (1),
                                    Last  => Data'Last (1));
                              begin
                                 Active_Cl.Count := Ck (Cl).Size;
                                 for M in 1 .. Ck (Cl).Size loop
                                    Active_Cl.Ids (M) := Ck (Cl).Members (M);
                                 end loop;
                                 DR := DBSCAN
                                   (Data, Cand_S, Params, Active_Cl);
                                 for Lab in 1 .. DR.Cluster_Count loop
                                    declare
                                       Members : Point_Id_Array :=
                                         [others => 1];
                                       Size : Point_Count := 0;
                                    begin
                                       for P in DR.Labels'Range loop
                                          if DR.Labels (P) = Lab then
                                             Size := Size + 1;
                                             Members (Size) := P;
                                          end if;
                                       end loop;
                                       if Size > 0 then
                                          Cand_Clusters_Found := True;
                                          if Next_Ck_Count = Max_Clusters then
                                             raise Capacity_Exceeded
                                               with "higher-D capacity exceeded";
                                          end if;
                                          Next_Ck_Count := Next_Ck_Count + 1;
                                          Next_Ck (Next_Ck_Count) :=
                                            (Space   => Cand_S,
                                             Size    => Size,
                                             Members => Members);
                                          Push_Result_Cluster
                                            (Result, Cand_S, Size, Members);
                                       end if;
                                    end;
                                 end loop;
                              end;
                           end if;
                        end loop;
                     end;

                     if Cand_Clusters_Found then
                        Append_Unique (Next_Sk, Next_Sk_Count, Cand_S);
                     end if;
                  end if;
               end;
            end loop;

            Sk := Next_Sk;
            Sk_Count := Next_Sk_Count;
            Ck := Next_Ck;
            Ck_Count := Next_Ck_Count;
         end;

         --  Safety: stop if dimensionality would exceed available dims.
         if Sk_Count > 0 and then Sk (1).Count >= D then
            exit;
         end if;
      end loop;

      return Result;
   end Run_SUBCLU;

   function Clustered_In_Subspace
     (Result : SUBCLU_Result;
      Space  : Subspace;
      P      : Point_Id) return Boolean
   is
   begin
      for I in 1 .. Result.Cluster_Count loop
         if Subspace_Equal (Result.Clusters (I).Space, Space) then
            for M in 1 .. Result.Clusters (I).Size loop
               if Result.Clusters (I).Members (M) = P then
                  return True;
               end if;
            end loop;
         end if;
      end loop;
      return False;
   end Clustered_In_Subspace;

   function Total_Clustered_Points
     (Result : SUBCLU_Result;
      Space  : Subspace) return Point_Count
   is
      S : Point_Count := 0;
   begin
      for I in 1 .. Result.Cluster_Count loop
         if Subspace_Equal (Result.Clusters (I).Space, Space) then
            S := S + Result.Clusters (I).Size;
         end if;
      end loop;
      return S;
   end Total_Clustered_Points;

end Subclu;
