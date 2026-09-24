--  Implementation of K_Means_Clustering (Lloyd / naïve k-means + Forgy init).

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body K_Means_Clustering
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

   --  Numerical Recipes LCG constants.
   LCG_A : constant RNG_State := 1664525;
   LCG_C : constant RNG_State := 1013904223;

   -------------------------------------------------------------------------
   -- RNG
   -------------------------------------------------------------------------

   procedure Seed_RNG (State : out RNG_State; Seed : Natural) is
   begin
      --  Mix Seed into a non-zero state so Seed=0 is still usable.
      State := RNG_State (Seed) * LCG_A + LCG_C;
      if State = 0 then
         State := 1;
      end if;
   end Seed_RNG;

   function Draw_Unit (State : in out RNG_State) return Unit_Interval is
      M : constant := 2.0**32;
   begin
      State := State * LCG_A + LCG_C;
      return Unit_Interval (Long_Float (State) / M);
   end Draw_Unit;

   function Draw_Index
     (State : in out RNG_State; Lo, Hi : Point_Index) return Point_Index
   is
      Span : constant Natural := Natural (Hi) - Natural (Lo) + 1;
      U    : constant Unit_Interval := Draw_Unit (State);
      Off  : Natural;
   begin
      Off := Natural (Long_Float (U) * Long_Float (Span));
      if Off >= Span then
         Off := Span - 1;
      end if;
      return Point_Index (Natural (Lo) + Off);
   end Draw_Index;

   -------------------------------------------------------------------------
   -- Near
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   -------------------------------------------------------------------------
   -- Distance / Squared_Distance
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
      return Non_Negative (Math.Sqrt (Long_Float (Sq)));
   end Distance;

   -------------------------------------------------------------------------
   -- Extract helpers
   -------------------------------------------------------------------------

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
      for J in 1 .. D loop
         Result (J) := Data (P, Dim_Index (J + Off));
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
      for J in 1 .. D loop
         Result (J) := C (K, Dim_Index (J + Off));
      end loop;
      return Result;
   end Extract_Center;

   -------------------------------------------------------------------------
   -- Nearest_Center / Assign_Labels
   -------------------------------------------------------------------------

   function Nearest_Center
     (Query : Point; C : Centers) return Site_Index
   is
      Best       : Site_Index := C'First (1);
      Best_Sq    : Real := 0.0;
      Cand_Sq    : Real := 0.0;
      D          : constant Dim_Count := C'Length (2);
      Q          : Point (1 .. D);
      Off_Q      : constant Integer := Query'First - 1;
      Center_Pt  : Point (1 .. D);
      First_Hit  : Boolean := True;
   begin
      if C'Length (1) < 1 or else D < 1 or else Query'Length /= D then
         raise Invalid_Argument with "Nearest_Center: empty or dim mismatch";
      end if;
      for J in 1 .. D loop
         Q (J) := Query (Dim_Index (J + Off_Q));
      end loop;
      for K in C'Range (1) loop
         Center_Pt := Extract_Center (C, K);
         Cand_Sq := Squared_Distance (Q, Center_Pt);
         if First_Hit or else Cand_Sq < Best_Sq then
            Best_Sq := Cand_Sq;
            Best := K;
            First_Hit := False;
         end if;
      end loop;
      return Best;
   end Nearest_Center;

   function Assign_Labels
     (Data : Dataset; C : Centers) return Labels
   is
      N      : constant Point_Count := Data'Length (1);
      Result : Labels (Data'Range (1));
      Pt     : Point (1 .. Data'Length (2));
   begin
      if N < 1 or else C'Length (1) < 1
        or else C'Length (2) /= Data'Length (2)
      then
         raise Invalid_Argument with "Assign_Labels: bad extents";
      end if;
      --  Capacity enforced by Point_Count / Site_Count / Dim_Count subtypes.
      for P in Data'Range (1) loop
         Pt := Extract_Point (Data, P);
         Result (P) := Natural (Nearest_Center (Pt, C));
      end loop;
      return Result;
   end Assign_Labels;

   -------------------------------------------------------------------------
   -- Compute_Centroids
   -------------------------------------------------------------------------

   procedure Compute_Centroids
     (Data  : Dataset;
      Lab   : Labels;
      C     : in out Centers;
      Empty : out Empty_Flags)
   is
      K_Count  : constant Site_Count := C'Length (1);
      D        : constant Dim_Count := C'Length (2);
      Counts   : array (C'Range (1)) of Natural := [others => 0];
      Sums     : array (C'Range (1), 1 .. D) of Real :=
                   [others => [others => 0.0]];
      Lab_K    : Site_Index;
      Dim_Off  : constant Integer := Data'First (2) - 1;
      C_Off    : constant Integer := C'First (2) - 1;
   begin
      if Lab'Length /= Data'Length (1)
        or else Lab'First /= Data'First (1)
        or else Empty'Length /= K_Count
        or else Empty'First /= C'First (1)
        or else D /= Data'Length (2)
      then
         raise Invalid_Argument with "Compute_Centroids: extent mismatch";
      end if;

      for P in Data'Range (1) loop
         if Lab (P) < Natural (C'First (1))
           or else Lab (P) > Natural (C'Last (1))
         then
            raise Invalid_Argument with "Compute_Centroids: bad label";
         end if;
         Lab_K := Site_Index (Lab (P));
         Counts (Lab_K) := Counts (Lab_K) + 1;
         for J in 1 .. D loop
            Sums (Lab_K, J) :=
              Sums (Lab_K, J)
              + Data (P, Dim_Index (J + Dim_Off));
         end loop;
      end loop;

      for K in C'Range (1) loop
         if Counts (K) = 0 then
            Empty (K) := True;
            --  Keep previous center coordinates (documented empty policy).
         else
            Empty (K) := False;
            for J in 1 .. D loop
               C (K, Dim_Index (J + C_Off)) :=
                 Sums (K, J) / Real (Counts (K));
            end loop;
         end if;
      end loop;
   end Compute_Centroids;

   -------------------------------------------------------------------------
   -- Within_Cluster_SSE
   -------------------------------------------------------------------------

   function Within_Cluster_SSE
     (Data : Dataset; C : Centers; Lab : Labels) return Non_Negative
   is
      Total : Real := 0.0;
      Pt    : Point (1 .. Data'Length (2));
      Mu    : Point (1 .. Data'Length (2));
      K_Id  : Site_Index;
   begin
      if Lab'Length /= Data'Length (1)
        or else C'Length (2) /= Data'Length (2)
        or else C'Length (1) < 1
      then
         raise Invalid_Argument with "Within_Cluster_SSE: extent mismatch";
      end if;
      for P in Data'Range (1) loop
         if Lab (P) < Natural (C'First (1))
           or else Lab (P) > Natural (C'Last (1))
         then
            raise Invalid_Argument with "Within_Cluster_SSE: bad label";
         end if;
         K_Id := Site_Index (Lab (P));
         Pt := Extract_Point (Data, P);
         Mu := Extract_Center (C, K_Id);
         Total := Total + Squared_Distance (Pt, Mu);
      end loop;
      return Total;
   end Within_Cluster_SSE;

   -------------------------------------------------------------------------
   -- Init_Centers_Forgy
   -------------------------------------------------------------------------

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
      if N < 1 or else D < 1 or else K < 1 then
         raise Invalid_Argument with "Init_Centers_Forgy: empty/K";
      end if;
      --  Capacity enforced by Point_Count / Dim_Count / Site_Count subtypes.
      if K > N then
         raise Invalid_Argument with "Init_Centers_Forgy: K > N";
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
               --  Fallback: walk sequentially for an unused index.
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
         for C in 1 .. D loop
            Result (Site_Index (J), Dim_Index (C)) :=
              Data (Cand, Dim_Index (C + Dim_Off));
         end loop;
      end loop;
      return Result;
   end Init_Centers_Forgy;

   -------------------------------------------------------------------------
   -- Init_Centers_From_Indices
   -------------------------------------------------------------------------

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
      if K < 1 or else D < 1 then
         raise Invalid_Argument with "Init_Centers_From_Indices: empty";
      end if;
      --  Capacity enforced by Site_Count / Dim_Count subtypes.
      for J in 1 .. K loop
         Row := Idx (Site_Index (J + Idx_Off));
         if Row not in Data'Range (1) then
            raise Invalid_Argument with
              "Init_Centers_From_Indices: index out of range";
         end if;
         for C in 1 .. D loop
            Result (Site_Index (J), Dim_Index (C)) :=
              Data (Row, Dim_Index (C + Dim_Off));
         end loop;
      end loop;
      return Result;
   end Init_Centers_From_Indices;

   -------------------------------------------------------------------------
   -- Init_Centers_Spaced
   -------------------------------------------------------------------------

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
      if N < 1 or else D < 1 or else K < 1 then
         raise Invalid_Argument with "Init_Centers_Spaced: empty/K";
      end if;
      --  Capacity enforced by Point_Count / Dim_Count / Site_Count subtypes.
      if K > N then
         raise Invalid_Argument with "Init_Centers_Spaced: K > N";
      end if;

      for J in 1 .. K loop
         if K = 1 then
            Idx := Data'First (1);
         else
            --  Spaced indices: 1 + floor((j-1)*(N-1)/(K-1)) mapped into Data.
            Span := Integer (N - 1) * Integer (J - 1) / Integer (K - 1);
            Idx := Point_Index (Integer (Data'First (1)) + Span);
         end if;
         for C in 1 .. D loop
            Result (Site_Index (J), Dim_Index (C)) :=
              Data (Idx, Dim_Index (C + Dim_Off));
         end loop;
      end loop;
      return Result;
   end Init_Centers_Spaced;

   -------------------------------------------------------------------------
   -- Max center displacement / label equality
   -------------------------------------------------------------------------

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

   -------------------------------------------------------------------------
   -- Run_Lloyd (with explicit Init)
   -------------------------------------------------------------------------

   function Run_Lloyd
     (Data   : Dataset;
      Init   : Centers;
      Params : Parameters := Default_Parameters) return Result
   is
      N       : constant Point_Count := Data'Length (1);
      D       : constant Dim_Count := Data'Length (2);
      K       : constant Site_Count := Params.K;
      Outcome : Result (N => N, K => K, D => D);
      Prev    : Centers (1 .. K, 1 .. D);
      Disp    : Real;
      Lab_Tmp : Labels (Data'Range (1));
      Lab_Prev : Labels (Data'Range (1)) := [others => 0];
      First_Iter : Boolean := True;
   begin
      if N < 1 or else D < 1 or else K < 1 then
         raise Invalid_Argument with "Run_Lloyd: empty data/K";
      end if;
      --  Capacity enforced by Point_Count / Dim_Count / Site_Count subtypes.
      if Init'Length (1) /= K or else Init'Length (2) /= D then
         raise Invalid_Argument with "Run_Lloyd: Init extent mismatch";
      end if;

      --  Copy Init into Outcome.Centers (normalize index bases to 1 ..).
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
         --  Remap labels into Outcome.Lab with 1-based point indices.
         declare
            P_Off : constant Integer := Data'First (1) - 1;
         begin
            for P in Data'Range (1) loop
               Outcome.Lab (Point_Index (Integer (P) - P_Off)) := Lab_Tmp (P);
            end loop;
         end;
         Compute_Centroids
           (Data, Lab_Tmp, Outcome.Centers, Outcome.Empty);
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

      Outcome.WCSS :=
        Within_Cluster_SSE (Data, Outcome.Centers, Lab_Tmp);
      Outcome.Inertia := Outcome.WCSS;
      return Outcome;
   end Run_Lloyd;

   -------------------------------------------------------------------------
   -- Run_KMeans (Forgy one-shot)
   -------------------------------------------------------------------------

   function Run_KMeans
     (Data   : Dataset;
      Params : Parameters) return Result
   is
      Init : constant Centers :=
        Init_Centers_Forgy (Data, Params.K, Params.Seed);
   begin
      return Run_Lloyd (Data, Init, Params);
   end Run_KMeans;

end K_Means_Clustering;
