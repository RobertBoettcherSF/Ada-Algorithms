--  Average_Linkage_Clustering body — Euclidean distances, mean pairwise
--  (UPGMA) linkage, size-weighted proximity updates, dendrogram cut / labels.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Average_Linkage_Clustering
  with SPARK_Mode => Off
is

   package EF is new Ada.Numerics.Generic_Elementary_Functions (Real);

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

   procedure Require_Square_Dist (Dist : Distance_Matrix) is
   begin
      if Dist'Length (1) = 0 or else Dist'Length (2) = 0 then
         raise Invalid_Argument with "empty distance matrix";
      end if;
      if Dist'Length (1) /= Dist'Length (2) then
         raise Invalid_Argument with "distance matrix not square";
      end if;
      if Dist'Length (1) > Max_Points then
         raise Capacity_Exceeded with "more points than Max_Points";
      end if;
   end Require_Square_Dist;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   -------------------------------------------------------------------------
   -- Distances
   -------------------------------------------------------------------------

   function Euclidean_Distance (A, B : Point) return Non_Negative is
      Acc  : Real := 0.0;
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
      return EF.Sqrt (Acc);
   end Euclidean_Distance;

   function Build_Distance_Matrix (Data : Dataset) return Distance_Matrix is
      N    : constant Natural := Data'Length (1);
      Dist : Distance_Matrix (1 .. N, 1 .. N) :=
        [others => [others => 0.0]];
   begin
      Require_Dataset (Data);
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            declare
               Acc  : Real := 0.0;
               Diff : Real;
               Dij  : Non_Negative;
            begin
               for D in Data'Range (2) loop
                  Diff :=
                    Data (Data'First (1) + (I - 1), D)
                    - Data (Data'First (1) + (J - 1), D);
                  Acc := Acc + Diff * Diff;
               end loop;
               Dij := EF.Sqrt (Acc);
               Dist (I, J) := Dij;
               Dist (J, I) := Dij;
            end;
         end loop;
      end loop;
      return Dist;
   end Build_Distance_Matrix;

   function Average_Linkage_Distance
     (Dist : Distance_Matrix;
      XA   : Labels;
      XB   : Labels) return Non_Negative
   is
      N     : constant Natural := Dist'Length (1);
      Acc   : Real := 0.0;
      Count : Natural := 0;
      Pi, Pj : Natural;
   begin
      Require_Square_Dist (Dist);
      if XA'Length = 0 or else XB'Length = 0 then
         raise Invalid_Argument with "empty cluster membership";
      end if;

      for A in XA'Range loop
         Pi := XA (A);
         if Pi < 1 or else Pi > N then
            raise Invalid_Argument with "cluster A index out of range";
         end if;
         for B in XB'Range loop
            Pj := XB (B);
            if Pj < 1 or else Pj > N then
               raise Invalid_Argument with "cluster B index out of range";
            end if;
            declare
               Di : constant Point_Index :=
                 Dist'First (1) + (Pi - 1);
               Dj : constant Point_Index :=
                 Dist'First (2) + (Pj - 1);
            begin
               Acc := Acc + Dist (Di, Dj);
               Count := Count + 1;
            end;
         end loop;
      end loop;

      if Count = 0 then
         raise Invalid_Argument with "no pairwise distance found";
      end if;
      return Acc / Real (Count);
   end Average_Linkage_Distance;

   -------------------------------------------------------------------------
   -- Naive UPGMA / average-linkage agglomeration
   -------------------------------------------------------------------------

   function Run_Average_Linkage (Dist : Distance_Matrix) return Dendrogram is
      N : constant Natural := Dist'Length (1);
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
      Require_Square_Dist (Dist);
      if N < 2 then
         raise Invalid_Argument
           with "Run_Average_Linkage needs at least 2 points";
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

            --  Size-weighted / proportional averaging (UPGMA):
            --  d(A∪B, X) = (|A|·d(A,X) + |B|·d(B,X)) / (|A|+|B|)
            for K in 1 .. N loop
               if Alive (K) and then K /= BI and then K /= BJ then
                  declare
                     Dik   : constant Real := Prox (BI, K);
                     Djk   : constant Real := Prox (BJ, K);
                     New_D : constant Real :=
                       (Real (Ni) * Dik + Real (Nj) * Djk)
                       / Real (Ni + Nj);
                  begin
                     Prox (BI, K) := New_D;
                     Prox (K, BI) := New_D;
                  end;
               end if;
            end loop;

            Size (BI) := New_Size;
            Id (BI) := N + Merge_Idx;
            Alive (BJ) := False;
            Size (BJ) := 0;
            Prox (BI, BI) := 0.0;
            Active_Count := Active_Count - 1;
         end;
      end loop;

      return Tree;
   end Run_Average_Linkage;

   function Run_Average_Linkage (Data : Dataset) return Dendrogram is
   begin
      Require_Dataset (Data);
      if Data'Length (1) < 2 then
         raise Invalid_Argument
           with "Run_Average_Linkage needs at least 2 points";
      end if;
      return Run_Average_Linkage (Build_Distance_Matrix (Data));
   end Run_Average_Linkage;

   function Merge_Height
     (Tree : Dendrogram; Step : Positive) return Non_Negative
   is
   begin
      if Step not in Tree'Range then
         raise Invalid_Argument with "merge step out of range";
      end if;
      return Tree (Step).Height;
   end Merge_Height;

   -------------------------------------------------------------------------
   -- Cutting the dendrogram
   -------------------------------------------------------------------------

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
            Lab (I) := Root_Of (R);
         end;
      end loop;

      if Next_Label /= K then
         raise Invalid_Argument
           with "cut did not produce exactly K clusters";
      end if;
      return Lab;
   end Cut_Dendrogram;

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
               New_Cluster := New_Cluster + 1;
               Parent (New_Cluster) := New_Cluster;
               Parent (A) := New_Cluster;
               Parent (B) := New_Cluster;
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
            Lab (I) := Root_Of (R);
         end;
      end loop;

      return Lab;
   end Labels_At_Height;

   function Labels_At_Height
     (Tree : Dendrogram;
      N    : Point_Count;
      P    : Parameters) return Labels
   is
   begin
      return Labels_At_Height (Tree, N, P.Cut_Height);
   end Labels_At_Height;

end Average_Linkage_Clustering;
