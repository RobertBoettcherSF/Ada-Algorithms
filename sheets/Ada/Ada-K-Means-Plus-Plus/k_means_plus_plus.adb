--  Implementation of K_Means_Plus_Plus (D² seeding + local Lloyd).

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body K_Means_Plus_Plus
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
   -- Nearest_Center / Min_Squared_Distance
   -------------------------------------------------------------------------

   function Nearest_Center
     (Query : Point; C : Centers) return Site_Index
   is
      Best       : Site_Index := C'First (1);
      Best_Sq    : Real := 0.0;
      Cand_Sq    : Real;
      D          : constant Dim_Count := C'Length (2);
      Q          : Point (1 .. D);
      Off_Q      : constant Integer := Query'First - 1;
      First_Site : Boolean := True;
      Ctr        : Point (1 .. D);
   begin
      if C'Length (1) < 1 or else D < 1 or else Query'Length /= D then
         raise Invalid_Argument with "Nearest_Center: empty or dim mismatch";
      end if;
      for J in 1 .. D loop
         Q (J) := Query (Dim_Index (J + Off_Q));
      end loop;
      for K in C'Range (1) loop
         Ctr := Extract_Center (C, K);
         Cand_Sq := Squared_Distance (Q, Ctr);
         if First_Site or else Cand_Sq < Best_Sq then
            Best_Sq := Cand_Sq;
            Best := K;
            First_Site := False;
         end if;
      end loop;
      return Best;
   end Nearest_Center;

   function Min_Squared_Distance_To_Centers
     (Query : Point; C : Centers) return Non_Negative
   is
      Best_Sq    : Real := 0.0;
      Cand_Sq    : Real;
      D          : constant Dim_Count := C'Length (2);
      Q          : Point (1 .. D);
      Off_Q      : constant Integer := Query'First - 1;
      First_Site : Boolean := True;
      Ctr        : Point (1 .. D);
   begin
      if C'Length (1) < 1 or else D < 1 or else Query'Length /= D then
         raise Invalid_Argument with
           "Min_Squared_Distance_To_Centers: empty or dim mismatch";
      end if;
      for J in 1 .. D loop
         Q (J) := Query (Dim_Index (J + Off_Q));
      end loop;
      for K in C'Range (1) loop
         Ctr := Extract_Center (C, K);
         Cand_Sq := Squared_Distance (Q, Ctr);
         if First_Site or else Cand_Sq < Best_Sq then
            Best_Sq := Cand_Sq;
            First_Site := False;
         end if;
      end loop;
      return Best_Sq;
   end Min_Squared_Distance_To_Centers;

   function Compute_D2_Weights
     (Data : Dataset; C : Centers) return D2_Weights
   is
      W  : D2_Weights (Data'Range (1));
      Pt : Point (1 .. Data'Length (2));
   begin
      if Data'Length (1) < 1 or else C'Length (1) < 1
        or else C'Length (2) /= Data'Length (2)
      then
         raise Invalid_Argument with "Compute_D2_Weights: bad extents";
      end if;
      for P in Data'Range (1) loop
         Pt := Extract_Point (Data, P);
         W (P) := Min_Squared_Distance_To_Centers (Pt, C);
      end loop;
      return W;
   end Compute_D2_Weights;

   function Sum_D2 (W : D2_Weights) return Non_Negative is
      Total : Real := 0.0;
   begin
      for I in W'Range loop
         Total := Total + W (I);
      end loop;
      return Total;
   end Sum_D2;

   -------------------------------------------------------------------------
   -- Assign_Labels / Compute_Centroids / SSE
   -------------------------------------------------------------------------

   function Assign_Labels
     (Data : Dataset; C : Centers) return Labels
   is
      Result : Labels (Data'Range (1));
      Pt     : Point (1 .. Data'Length (2));
   begin
      if Data'Length (1) < 1 or else C'Length (1) < 1
        or else C'Length (2) /= Data'Length (2)
      then
         raise Invalid_Argument with "Assign_Labels: bad extents";
      end if;
      for P in Data'Range (1) loop
         Pt := Extract_Point (Data, P);
         Result (P) := Natural (Nearest_Center (Pt, C));
      end loop;
      return Result;
   end Assign_Labels;

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
      Site_Off : constant Integer := C'First (2) - 1;
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
              Sums (Lab_K, J) + Data (P, Dim_Index (J + Dim_Off));
         end loop;
      end loop;

      for K in C'Range (1) loop
         if Counts (K) = 0 then
            Empty (K) := True;
         else
            Empty (K) := False;
            for J in 1 .. D loop
               C (K, Dim_Index (J + Site_Off)) :=
                 Sums (K, J) / Real (Counts (K));
            end loop;
         end if;
      end loop;
   end Compute_Centroids;

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
   -- Copy one data row into a Centers slot
   -------------------------------------------------------------------------

   procedure Copy_Point_To_Center
     (Data : Dataset;
      P    : Point_Index;
      C    : in out Centers;
      Slot : Site_Index)
   is
      D   : constant Dim_Count := Data'Length (2);
      Off : constant Integer := Data'First (2) - 1;
      COff : constant Integer := C'First (2) - 1;
   begin
      for J in 1 .. D loop
         C (Slot, Dim_Index (J + COff)) :=
           Data (P, Dim_Index (J + Off));
      end loop;
   end Copy_Point_To_Center;


   -------------------------------------------------------------------------
   -- Sample index with probability ∝ W(i) using draw U in [0,1)
   -------------------------------------------------------------------------

   function Sample_Weighted
     (W : D2_Weights; U : Unit_Interval) return Point_Index
   is
      Total      : constant Non_Negative := Sum_D2 (W);
      Threshold  : Real;
      Cumulative : Real := 0.0;
   begin
      if Total <= 0.0 then
         --  All remaining points coincide with centers; pick first index.
         return W'First;
      end if;
      Threshold := Real (U) * Total;
      --  Guard U=1.0 edge: clamp into half-open [0, Total).
      if Threshold >= Total then
         Threshold := Total - Real'Model_Small;
         if Threshold < 0.0 then
            Threshold := 0.0;
         end if;
      end if;
      for I in W'Range loop
         Cumulative := Cumulative + W (I);
         if Cumulative > Threshold or else Cumulative >= Total then
            return I;
         end if;
      end loop;
      return W'Last;
   end Sample_Weighted;

   -------------------------------------------------------------------------
   -- Init_Centers_Uniform_First
   -------------------------------------------------------------------------

   function Init_Centers_Uniform_First
     (Data : Dataset; Seed : Natural) return Centers
   is
      D      : constant Dim_Count := Data'Length (2);
      Result : Centers (1 .. 1, 1 .. D);
      State  : RNG_State;
      Idx    : Point_Index;
   begin
      if Data'Length (1) < 1 or else D < 1 then
         raise Invalid_Argument with "Init_Centers_Uniform_First: empty";
      end if;
      --  Capacity enforced by Point_Index / Dim_Index subtypes.
      Seed_RNG (State, Seed);
      Idx := Draw_Index (State, Data'First (1), Data'Last (1));
      Copy_Point_To_Center (Data, Idx, Result, 1);
      return Result;
   end Init_Centers_Uniform_First;

   -------------------------------------------------------------------------
   -- Shared k-means++ body driven by draw callback via array / LCG
   -------------------------------------------------------------------------

   function Init_Centers_KMeansPP
     (Data : Dataset;
      K    : Site_Count;
      Seed : Natural) return Centers
   is
      D      : constant Dim_Count := Data'Length (2);
      N      : constant Point_Count := Data'Length (1);
      Result : Centers (1 .. K, 1 .. D);
      State  : RNG_State;
      Idx    : Point_Index;
      W      : D2_Weights (Data'Range (1));
      Chosen  : Natural := 0;
      U       : Unit_Interval;
   begin
      if N < 1 or else D < 1 or else K < 1 then
         raise Invalid_Argument with "Init_Centers_KMeansPP: empty/K";
      end if;
      --  Capacity enforced by Point_Count / Dim_Count / Site_Count subtypes.
      if K > N then
         raise Invalid_Argument with "Init_Centers_KMeansPP: K > N";
      end if;

      Seed_RNG (State, Seed);

      --  Step 1: first center uniform.
      Idx := Draw_Index (State, Data'First (1), Data'Last (1));
      Copy_Point_To_Center (Data, Idx, Result, 1);
      Chosen := 1;

      --  Steps 2–4: D² sampling.
      while Chosen < Natural (K) loop
         declare
            Used : Centers (1 .. Site_Count (Chosen), 1 .. D);
         begin
            for S in 1 .. Chosen loop
               for C in 1 .. D loop
                  Used (Site_Index (S), Dim_Index (C)) :=
                    Result (Site_Index (S), Dim_Index (C));
               end loop;
            end loop;
            W := Compute_D2_Weights (Data, Used);
         end;
         U := Draw_Unit (State);
         Idx := Sample_Weighted (W, U);
         Chosen := Chosen + 1;
         Copy_Point_To_Center (Data, Idx, Result, Site_Index (Chosen));
      end loop;

      return Result;
   end Init_Centers_KMeansPP;

   function Init_Centers_KMeansPP
     (Data  : Dataset;
      K     : Site_Count;
      Draws : Uniform_Draws) return Centers
   is
      D       : constant Dim_Count := Data'Length (2);
      N       : constant Point_Count := Data'Length (1);
      Result  : Centers (1 .. K, 1 .. D);
      Idx     : Point_Index;
      W       : D2_Weights (Data'Range (1));
      Chosen  : Natural := 0;
      Draw_Ix : Positive := Draws'First;
      U       : Unit_Interval;
      Span    : Natural;
      Off     : Natural;
   begin
      if N < 1 or else D < 1 or else K < 1 then
         raise Invalid_Argument with "Init_Centers_KMeansPP(draws): empty/K";
      end if;
      --  Capacity enforced by Point_Count / Dim_Count / Site_Count subtypes.
      if K > N then
         raise Invalid_Argument with "Init_Centers_KMeansPP(draws): K > N";
      end if;
      if Draws'Length < Natural (K) then
         raise Invalid_Argument with "Init_Centers_KMeansPP(draws): too few";
      end if;

      --  First center from Draws(1).
      U := Draws (Draw_Ix);
      Draw_Ix := Draw_Ix + 1;
      Span := Natural (N);
      Off := Natural (Long_Float (U) * Long_Float (Span));
      if Off >= Span then
         Off := Span - 1;
      end if;
      Idx := Point_Index (Natural (Data'First (1)) + Off);
      Copy_Point_To_Center (Data, Idx, Result, 1);
      Chosen := 1;

      while Chosen < Natural (K) loop
         declare
            Used : Centers (1 .. Site_Count (Chosen), 1 .. D);
         begin
            for S in 1 .. Chosen loop
               for C in 1 .. D loop
                  Used (Site_Index (S), Dim_Index (C)) :=
                    Result (Site_Index (S), Dim_Index (C));
               end loop;
            end loop;
            W := Compute_D2_Weights (Data, Used);
         end;
         U := Draws (Draw_Ix);
         Draw_Ix := Draw_Ix + 1;
         Idx := Sample_Weighted (W, U);
         Chosen := Chosen + 1;
         Copy_Point_To_Center (Data, Idx, Result, Site_Index (Chosen));
      end loop;

      return Result;
   end Init_Centers_KMeansPP;

   -------------------------------------------------------------------------
   -- Init_Centers_Farthest_Point (greedy D² max)
   -------------------------------------------------------------------------

   function Init_Centers_Farthest_Point
     (Data        : Dataset;
      K           : Site_Count;
      First_Index : Point_Index) return Centers
   is
      D      : constant Dim_Count := Data'Length (2);
      N      : constant Point_Count := Data'Length (1);
      Result : Centers (1 .. K, 1 .. D);
      Chosen : Natural := 0;
      W      : D2_Weights (Data'Range (1));
      Best   : Point_Index;
      Best_W : Real;
   begin
      if N < 1 or else D < 1 or else K < 1 then
         raise Invalid_Argument with "Init_Centers_Farthest_Point: empty/K";
      end if;
      --  Capacity enforced by Point_Count / Dim_Count / Site_Count subtypes.
      if K > N then
         raise Invalid_Argument with "Init_Centers_Farthest_Point: K > N";
      end if;
      if First_Index not in Data'Range (1) then
         raise Invalid_Argument with
           "Init_Centers_Farthest_Point: bad First_Index";
      end if;

      Copy_Point_To_Center (Data, First_Index, Result, 1);
      Chosen := 1;

      while Chosen < Natural (K) loop
         declare
            Used : Centers (1 .. Site_Count (Chosen), 1 .. D);
         begin
            for S in 1 .. Chosen loop
               for C in 1 .. D loop
                  Used (Site_Index (S), Dim_Index (C)) :=
                    Result (Site_Index (S), Dim_Index (C));
               end loop;
            end loop;
            W := Compute_D2_Weights (Data, Used);
         end;
         Best := W'First;
         Best_W := W (Best);
         for I in W'Range loop
            if W (I) > Best_W then
               Best_W := W (I);
               Best := I;
            end if;
         end loop;
         Chosen := Chosen + 1;
         Copy_Point_To_Center (Data, Best, Result, Site_Index (Chosen));
      end loop;

      return Result;
   end Init_Centers_Farthest_Point;

   -------------------------------------------------------------------------
   -- Init_Centers_From_Indices
   -------------------------------------------------------------------------

   function Init_Centers_From_Indices
     (Data : Dataset; Idx : Labels) return Centers
   is
      K      : constant Site_Count := Site_Count (Idx'Length);
      D      : constant Dim_Count := Data'Length (2);
      Result : Centers (1 .. K, 1 .. D);
      P      : Point_Index;
      Slot   : Site_Index := 1;
   begin
      if Data'Length (1) < 1 or else D < 1 or else K < 1 then
         raise Invalid_Argument with "Init_Centers_From_Indices: empty";
      end if;
      --  Capacity enforced by Site_Count / Dim_Count subtypes.
      for I in Idx'Range loop
         if Idx (I) < Natural (Data'First (1))
           or else Idx (I) > Natural (Data'Last (1))
         then
            raise Invalid_Argument with
              "Init_Centers_From_Indices: bad index";
         end if;
         P := Point_Index (Idx (I));
         Copy_Point_To_Center (Data, P, Result, Slot);
         if Natural (Slot) < Natural (K) then
            Slot := Site_Index (Natural (Slot) + 1);
         end if;
      end loop;
      return Result;
   end Init_Centers_From_Indices;

   -------------------------------------------------------------------------
   -- Max displacement
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

   -------------------------------------------------------------------------
   -- Run_Lloyd
   -------------------------------------------------------------------------

   function Run_Lloyd
     (Data   : Dataset;
      Init   : Centers;
      Params : Parameters := Default_Parameters) return Result
   is
      N      : constant Point_Count := Data'Length (1);
      D      : constant Dim_Count := Data'Length (2);
      K      : constant Site_Count := Params.K;
      Out_R  : Result (N => N, K => K, D => D);
      Prev   : Centers (1 .. K, 1 .. D);
      Disp   : Real;
      Lab_Tmp : Labels (Data'Range (1));
      S_Off1 : constant Integer := Init'First (1) - 1;
      S_Off2 : constant Integer := Init'First (2) - 1;
   begin
      if N < 1 or else D < 1 or else K < 1 then
         raise Invalid_Argument with "Run_Lloyd: empty data/K";
      end if;
      --  Capacity enforced by Point_Count / Dim_Count / Site_Count subtypes.
      if Init'Length (1) /= K or else Init'Length (2) /= D then
         raise Invalid_Argument with "Run_Lloyd: Init extent mismatch";
      end if;

      for J in 1 .. K loop
         for C in 1 .. D loop
            Out_R.Centroids (Site_Index (J), Dim_Index (C)) :=
              Init
                (Site_Index (J + S_Off1),
                 Dim_Index (C + S_Off2));
         end loop;
      end loop;

      Out_R.Empty := [others => False];
      Out_R.Iters := 0;
      Out_R.Converged := False;

      for Iter in 1 .. Params.Max_Iters loop
         Prev := Out_R.Centroids;
         Lab_Tmp := Assign_Labels (Data, Out_R.Centroids);
         declare
            P_Off : constant Integer := Data'First (1) - 1;
         begin
            for P in Data'Range (1) loop
               Out_R.Lab (Point_Index (Integer (P) - P_Off)) := Lab_Tmp (P);
            end loop;
         end;
         Compute_Centroids (Data, Lab_Tmp, Out_R.Centroids, Out_R.Empty);
         Out_R.Iters := Iter;
         Disp := Max_Center_Displacement (Prev, Out_R.Centroids);
         if Disp < Params.Tol then
            Out_R.Converged := True;
            exit;
         end if;
      end loop;

      Out_R.Inertia := Within_Cluster_SSE (Data, Out_R.Centroids, Lab_Tmp);
      return Out_R;
   end Run_Lloyd;

   -------------------------------------------------------------------------
   -- Run_KMeansPP
   -------------------------------------------------------------------------

   function Run_KMeansPP
     (Data   : Dataset;
      Params : Parameters := Default_Parameters) return Result
   is
      Init : constant Centers :=
        Init_Centers_KMeansPP (Data, Params.K, Params.Seed);
   begin
      return Run_Lloyd (Data, Init, Params);
   end Run_KMeansPP;

end K_Means_Plus_Plus;
