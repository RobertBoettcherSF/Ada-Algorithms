--  Implementation of Fuzzy_C_Means (Dunn 1973 / Bezdek 1981 FCM).

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Fuzzy_C_Means
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
     (C : Centers; J : Cluster_Index) return Point
   is
      D      : constant Dim_Count := C'Length (2);
      Result : Point (1 .. D);
      Off    : constant Integer := C'First (2) - 1;
   begin
      if J not in C'Range (1) or else D < 1 then
         raise Invalid_Argument with "Extract_Center: bad index/dims";
      end if;
      for K in 1 .. D loop
         Result (K) := C (J, Dim_Index (K + Off));
      end loop;
      return Result;
   end Extract_Center;

   -------------------------------------------------------------------------
   -- Power helper: X^M via Exp(M * Log(X)); X >= 0
   -------------------------------------------------------------------------

   function Real_Pow (Base, Expn : Real) return Real is
   begin
      if Base = 0.0 then
         if Expn > 0.0 then
            return 0.0;
         elsif Expn = 0.0 then
            return 1.0;
         else
            raise Invalid_Argument with "Real_Pow: 0^negative";
         end if;
      end if;
      if Base < 0.0 then
         raise Invalid_Argument with "Real_Pow: negative base";
      end if;
      if Expn = 0.0 then
         return 1.0;
      end if;
      if Expn = 1.0 then
         return Base;
      end if;
      if Expn = 2.0 then
         return Base * Base;
      end if;
      return Real
        (Math.Exp (Long_Float (Expn) * Math.Log (Long_Float (Base))));
   end Real_Pow;

   -------------------------------------------------------------------------
   -- Init_Memberships_Random
   -------------------------------------------------------------------------

   function Init_Memberships_Random
     (N    : Point_Count;
      C    : Cluster_Count;
      Seed : Natural) return Membership_Matrix
   is
      W     : Membership_Matrix (1 .. N, 1 .. C);
      State : RNG_State;
      Row_Sum : Real;
      U     : Unit_Interval;
   begin
      if N < 1 or else C < 2 then
         raise Invalid_Argument with
           "Init_Memberships_Random: need N>=1 and C>=2";
      end if;
      Seed_RNG (State, Seed);
      for I in 1 .. N loop
         Row_Sum := 0.0;
         for J in 1 .. C loop
            --  Draw in (0,1] by adding a tiny floor so zero weight is avoided.
            U := Draw_Unit (State);
            W (I, J) := Real (U) + 1.0E-6;
            Row_Sum := Row_Sum + W (I, J);
         end loop;
         for J in 1 .. C loop
            W (I, J) := W (I, J) / Row_Sum;
         end loop;
      end loop;
      return W;
   end Init_Memberships_Random;

   -------------------------------------------------------------------------
   -- Update_Centers
   -------------------------------------------------------------------------

   procedure Update_Centers
     (Data : Dataset;
      W    : Membership_Matrix;
      M    : Fuzzifier;
      Ctr  : in out Centers)
   is
      N      : constant Point_Count := Data'Length (1);
      D      : constant Dim_Count := Data'Length (2);
      C_Num  : constant Cluster_Count := Ctr'Length (1);
      Weight : Real;
      Denom  : Real;
      Acc    : array (1 .. Max_Dims) of Real;
      Pt     : Point (1 .. D);
   begin
      if M <= 1.0 then
         raise Invalid_Argument with "Update_Centers: m must be > 1";
      end if;
      if W'Length (1) /= N or else W'Length (2) /= C_Num
        or else Ctr'Length (2) /= D
      then
         raise Invalid_Argument with "Update_Centers: shape mismatch";
      end if;

      for J_Rel in 1 .. C_Num loop
         declare
            J : constant Cluster_Index :=
              Cluster_Index (Integer (Ctr'First (1)) + J_Rel - 1);
            W_Col : constant Cluster_Index :=
              Cluster_Index (Integer (W'First (2)) + J_Rel - 1);
         begin
            Denom := 0.0;
            for K in 1 .. D loop
               Acc (K) := 0.0;
            end loop;

            for I_Rel in 1 .. N loop
               declare
                  I : constant Point_Index :=
                    Point_Index (Integer (Data'First (1)) + I_Rel - 1);
                  WI : constant Point_Index :=
                    Point_Index (Integer (W'First (1)) + I_Rel - 1);
               begin
                  Weight := Real_Pow (W (WI, W_Col), M);
                  Denom := Denom + Weight;
                  Pt := Extract_Point (Data, I);
                  for K in 1 .. D loop
                     Acc (K) := Acc (K) + Weight * Pt (K);
                  end loop;
               end;
            end loop;

            if Denom > Distance_Eps then
               for K in 1 .. D loop
                  Ctr (J, Dim_Index (Integer (Ctr'First (2)) + K - 1)) :=
                    Acc (K) / Denom;
               end loop;
            end if;
            --  else: keep previous center (degenerate empty fuzzy cluster)
         end;
      end loop;
   end Update_Centers;

   -------------------------------------------------------------------------
   -- Update_Memberships
   -------------------------------------------------------------------------

   procedure Update_Memberships
     (Data : Dataset;
      Ctr  : Centers;
      M    : Fuzzifier;
      W    : in out Membership_Matrix)
   is
      N     : constant Point_Count := Data'Length (1);
      D     : constant Dim_Count := Data'Length (2);
      C_Num : constant Cluster_Count := Ctr'Length (1);
      Expn  : constant Real := 2.0 / (M - 1.0);
      Dist  : array (1 .. Max_Clusters) of Real;
      Pt    : Point (1 .. D);
      Cj    : Point (1 .. D);
      Sq    : Real;
      Sum_Inv : Real;
      Zero_Hit : Boolean;
      Zero_J   : Cluster_Index;
   begin
      if M <= 1.0 then
         raise Invalid_Argument with "Update_Memberships: m must be > 1";
      end if;
      if W'Length (1) /= N or else W'Length (2) /= C_Num
        or else Ctr'Length (2) /= D
      then
         raise Invalid_Argument with "Update_Memberships: shape mismatch";
      end if;

      for I_Rel in 1 .. N loop
         declare
            I : constant Point_Index :=
              Point_Index (Integer (Data'First (1)) + I_Rel - 1);
            WI : constant Point_Index :=
              Point_Index (Integer (W'First (1)) + I_Rel - 1);
         begin
            Pt := Extract_Point (Data, I);
            Zero_Hit := False;
            Zero_J := Ctr'First (1);

            for J_Rel in 1 .. C_Num loop
               declare
                  J : constant Cluster_Index :=
                    Cluster_Index (Integer (Ctr'First (1)) + J_Rel - 1);
               begin
                  Cj := Extract_Center (Ctr, J);
                  Sq := Squared_Distance (Pt, Cj);
                  if Sq <= Distance_Eps then
                     Zero_Hit := True;
                     Zero_J := J;
                     Dist (J_Rel) := 0.0;
                  else
                     Dist (J_Rel) :=
                       Real (Math.Sqrt (Long_Float (Sq)));
                  end if;
               end;
            end loop;

            if Zero_Hit then
               --  Point coincides with a center: crisp membership there.
               for J_Rel in 1 .. C_Num loop
                  declare
                     WJ : constant Cluster_Index :=
                       Cluster_Index (Integer (W'First (2)) + J_Rel - 1);
                     J : constant Cluster_Index :=
                       Cluster_Index (Integer (Ctr'First (1)) + J_Rel - 1);
                  begin
                     if J = Zero_J then
                        W (WI, WJ) := 1.0;
                     else
                        W (WI, WJ) := 0.0;
                     end if;
                  end;
               end loop;
            else
               --  Standard Bezdek update using distances.
               for J_Rel in 1 .. C_Num loop
                  declare
                     WJ : constant Cluster_Index :=
                       Cluster_Index (Integer (W'First (2)) + J_Rel - 1);
                     Dj : constant Real := Dist (J_Rel);
                  begin
                     Sum_Inv := 0.0;
                     for K_Rel in 1 .. C_Num loop
                        declare
                           Dk : constant Real := Dist (K_Rel);
                           Ratio : Real;
                        begin
                           Ratio := Dj / Dk;
                           Sum_Inv := Sum_Inv + Real_Pow (Ratio, Expn);
                        end;
                     end loop;
                     W (WI, WJ) := 1.0 / Sum_Inv;
                  end;
               end loop;
            end if;
         end;
      end loop;
   end Update_Memberships;

   -------------------------------------------------------------------------
   -- Objective_J
   -------------------------------------------------------------------------

   function Objective_J
     (Data : Dataset;
      Ctr  : Centers;
      W    : Membership_Matrix;
      M    : Fuzzifier) return Non_Negative
   is
      N     : constant Point_Count := Data'Length (1);
      D     : constant Dim_Count := Data'Length (2);
      C_Num : constant Cluster_Count := Ctr'Length (1);
      Acc   : Real := 0.0;
      Pt    : Point (1 .. D);
      Cj    : Point (1 .. D);
      Wpow  : Real;
   begin
      if M <= 1.0 then
         raise Invalid_Argument with "Objective_J: m must be > 1";
      end if;
      if W'Length (1) /= N or else W'Length (2) /= C_Num
        or else Ctr'Length (2) /= D
      then
         raise Invalid_Argument with "Objective_J: shape mismatch";
      end if;

      for I_Rel in 1 .. N loop
         declare
            I : constant Point_Index :=
              Point_Index (Integer (Data'First (1)) + I_Rel - 1);
            WI : constant Point_Index :=
              Point_Index (Integer (W'First (1)) + I_Rel - 1);
         begin
            Pt := Extract_Point (Data, I);
            for J_Rel in 1 .. C_Num loop
               declare
                  J : constant Cluster_Index :=
                    Cluster_Index (Integer (Ctr'First (1)) + J_Rel - 1);
                  WJ : constant Cluster_Index :=
                    Cluster_Index (Integer (W'First (2)) + J_Rel - 1);
               begin
                  Cj := Extract_Center (Ctr, J);
                  Wpow := Real_Pow (W (WI, WJ), M);
                  Acc := Acc + Wpow * Squared_Distance (Pt, Cj);
               end;
            end loop;
         end;
      end loop;
      return Acc;
   end Objective_J;

   -------------------------------------------------------------------------
   -- Max_Membership_Delta
   -------------------------------------------------------------------------

   function Max_Membership_Delta
     (A, B : Membership_Matrix) return Non_Negative
   is
      Max_D : Real := 0.0;
      Diff  : Real;
   begin
      if A'Length (1) /= B'Length (1) or else A'Length (2) /= B'Length (2)
      then
         raise Invalid_Argument with "Max_Membership_Delta: shape mismatch";
      end if;
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            Diff := abs (A (I, J) - B (I, J));
            if Diff > Max_D then
               Max_D := Diff;
            end if;
         end loop;
      end loop;
      return Max_D;
   end Max_Membership_Delta;

   -------------------------------------------------------------------------
   -- Hard_Labels_From_Memberships
   -------------------------------------------------------------------------

   function Hard_Labels_From_Memberships
     (W : Membership_Matrix) return Hard_Labels
   is
      N      : constant Point_Count := W'Length (1);
      Labels : Hard_Labels (1 .. N);
      Best_J : Cluster_Index;
      Best_W : Real;
   begin
      if W'Length (1) < 1 or else W'Length (2) < 1 then
         raise Invalid_Argument with "Hard_Labels: empty matrix";
      end if;
      for I_Rel in 1 .. N loop
         declare
            WI : constant Point_Index :=
              Point_Index (Integer (W'First (1)) + I_Rel - 1);
         begin
            Best_J := W'First (2);
            Best_W := W (WI, Best_J);
            for J in W'Range (2) loop
               if W (WI, J) > Best_W then
                  Best_W := W (WI, J);
                  Best_J := J;
               end if;
            end loop;
            Labels (I_Rel) := Natural (Best_J);
         end;
      end loop;
      return Labels;
   end Hard_Labels_From_Memberships;

   -------------------------------------------------------------------------
   -- Partition_Coefficient
   -------------------------------------------------------------------------

   function Partition_Coefficient
     (W : Membership_Matrix) return Non_Negative
   is
      N   : constant Point_Count := W'Length (1);
      Acc : Real := 0.0;
   begin
      if N < 1 or else W'Length (2) < 1 then
         raise Invalid_Argument with "Partition_Coefficient: empty";
      end if;
      for I in W'Range (1) loop
         for J in W'Range (2) loop
            Acc := Acc + W (I, J) * W (I, J);
         end loop;
      end loop;
      return Acc / Real (N);
   end Partition_Coefficient;

   -------------------------------------------------------------------------
   -- Run_Fuzzy_C_Means
   -------------------------------------------------------------------------

   function Run_Fuzzy_C_Means
     (Data   : Dataset;
      Params : Parameters := Default_Parameters) return Result
   is
      N : constant Point_Count := Data'Length (1);
      D : constant Dim_Count := Data'Length (2);
      C : constant Cluster_Count := Params.C;
      M : constant Fuzzifier := Params.Fuzzifier_M;

      W_Cur  : Membership_Matrix (1 .. N, 1 .. C);
      W_Prev : Membership_Matrix (1 .. N, 1 .. C);
      Ctr    : Centers (1 .. C, 1 .. D) := [others => [others => 0.0]];
      Out_R  : Result (N => N, C => C, D => D);
      Max_Dw : Real;
      Iter   : Natural := 0;
   begin
      if N < 1 or else D < 1 then
         raise Invalid_Argument with "Run_FCM: empty data";
      end if;
      if C < 2 then
         raise Invalid_Argument with "Run_FCM: C must be >= 2";
      end if;
      if C > N then
         raise Invalid_Argument with "Run_FCM: C must be <= N";
      end if;
      if M <= 1.0 then
         raise Invalid_Argument with "Run_FCM: Fuzzifier_M must be > 1";
      end if;

      --  1. Random memberships (seeded), row-stochastic.
      W_Cur := Init_Memberships_Random (N, C, Params.Seed);

      --  Initial centers from W.
      Update_Centers (Data, W_Cur, M, Ctr);

      Out_R.Converged := False;
      loop
         Iter := Iter + 1;
         W_Prev := W_Cur;

         --  2. Update centers from W.
         Update_Centers (Data, W_Cur, M, Ctr);

         --  3. Update memberships from centers.
         Update_Memberships (Data, Ctr, M, W_Cur);

         Max_Dw := Max_Membership_Delta (W_Cur, W_Prev);
         if Max_Dw < Params.Eps then
            Out_R.Converged := True;
            exit;
         end if;
         exit when Iter >= Params.Max_Iters;
      end loop;

      Out_R.Centers := Ctr;
      Out_R.Memberships := W_Cur;
      Out_R.Objective_J := Objective_J (Data, Ctr, W_Cur, M);
      Out_R.Iters := Iter;
      return Out_R;
   end Run_Fuzzy_C_Means;

end Fuzzy_C_Means;
