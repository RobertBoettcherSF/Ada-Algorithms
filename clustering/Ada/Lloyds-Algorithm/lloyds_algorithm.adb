--  Implementation of Lloyds_Algorithm (discrete k-means form + 2-D grid CVT).

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Lloyds_Algorithm
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

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
      Sum : Real := 0.0;
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
      D : constant Dim_Count := Data'Length (2);
      Result : Point (1 .. D);
      Off : constant Integer := Data'First (2) - 1;
   begin
      if P not in Data'Range (1) or else D < 1 then
         raise Invalid_Argument with "Extract_Point: bad index/dims";
      end if;
      for J in 1 .. D loop
         Result (J) := Data (P, Dim_Index (J + Off));
      end loop;
      return Result;
   end Extract_Point;

   function Extract_Site
     (S : Sites; K : Site_Index) return Point
   is
      D : constant Dim_Count := S'Length (2);
      Result : Point (1 .. D);
      Off : constant Integer := S'First (2) - 1;
   begin
      if K not in S'Range (1) or else D < 1 then
         raise Invalid_Argument with "Extract_Site: bad index/dims";
      end if;
      for J in 1 .. D loop
         Result (J) := S (K, Dim_Index (J + Off));
      end loop;
      return Result;
   end Extract_Site;

   -------------------------------------------------------------------------
   -- Nearest_Site / Assign_Labels
   -------------------------------------------------------------------------

   function Nearest_Site
     (Query : Point; S : Sites) return Site_Index
   is
      Best : Site_Index := S'First (1);
      Best_Sq : Real := 0.0;
      Cand_Sq : Real := 0.0;
      D : constant Dim_Count := S'Length (2);
      Q : Point (1 .. D);
      Off_Q : constant Integer := Query'First - 1;
      Site_Pt : Point (1 .. D);
      First_Site : Boolean := True;
   begin
      if S'Length (1) < 1 or else D < 1 or else Query'Length /= D then
         raise Invalid_Argument with "Nearest_Site: empty or dim mismatch";
      end if;
      for J in 1 .. D loop
         Q (J) := Query (Dim_Index (J + Off_Q));
      end loop;
      for K in S'Range (1) loop
         Site_Pt := Extract_Site (S, K);
         Cand_Sq := Squared_Distance (Q, Site_Pt);
         if First_Site or else Cand_Sq < Best_Sq then
            Best_Sq := Cand_Sq;
            Best := K;
            First_Site := False;
         end if;
      end loop;
      return Best;
   end Nearest_Site;

   function Assign_Labels
     (Data : Dataset; S : Sites) return Labels
   is
      N : constant Point_Count := Data'Length (1);
      Result : Labels (Data'Range (1));
      Pt : Point (1 .. Data'Length (2));
   begin
      if N < 1 or else S'Length (1) < 1
        or else S'Length (2) /= Data'Length (2)
      then
         raise Invalid_Argument with "Assign_Labels: bad extents";
      end if;
      --  Capacity enforced by Point_Count / Sites index subtypes.
      for P in Data'Range (1) loop
         Pt := Extract_Point (Data, P);
         Result (P) := Natural (Nearest_Site (Pt, S));
      end loop;
      return Result;
   end Assign_Labels;

   -------------------------------------------------------------------------
   -- Compute_Centroids
   -------------------------------------------------------------------------

   procedure Compute_Centroids
     (Data        : Dataset;
      Lab         : Labels;
      S           : in out Sites;
      Empty       : out Empty_Flags;
      Raise_Empty : Boolean := False)
   is
      K_Count : constant Site_Count := S'Length (1);
      D       : constant Dim_Count := S'Length (2);
      Counts  : array (S'Range (1)) of Natural := [others => 0];
      Sums    : array (S'Range (1), 1 .. D) of Real := [others => [others => 0.0]];
      Lab_K   : Site_Index;
      Any_Empty : Boolean := False;
      Dim_Off : constant Integer := Data'First (2) - 1;
      Site_Off : constant Integer := S'First (2) - 1;
   begin
      if Lab'Length /= Data'Length (1)
        or else Lab'First /= Data'First (1)
        or else Empty'Length /= K_Count
        or else Empty'First /= S'First (1)
        or else D /= Data'Length (2)
      then
         raise Invalid_Argument with "Compute_Centroids: extent mismatch";
      end if;

      for P in Data'Range (1) loop
         if Lab (P) < Natural (S'First (1))
           or else Lab (P) > Natural (S'Last (1))
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

      for K in S'Range (1) loop
         if Counts (K) = 0 then
            Empty (K) := True;
            Any_Empty := True;
            --  Keep previous site coordinates (documented empty policy).
         else
            Empty (K) := False;
            for J in 1 .. D loop
               S (K, Dim_Index (J + Site_Off)) :=
                 Sums (K, J) / Real (Counts (K));
            end loop;
         end if;
      end loop;

      if Raise_Empty and then Any_Empty then
         raise Degenerate_Cluster with "Compute_Centroids: empty cluster";
      end if;
   end Compute_Centroids;

   -------------------------------------------------------------------------
   -- Within_Cluster_SSE
   -------------------------------------------------------------------------

   function Within_Cluster_SSE
     (Data : Dataset; S : Sites; Lab : Labels) return Non_Negative
   is
      Total : Real := 0.0;
      Pt : Point (1 .. Data'Length (2));
      Mu : Point (1 .. Data'Length (2));
      K_Id : Site_Index;
   begin
      if Lab'Length /= Data'Length (1)
        or else S'Length (2) /= Data'Length (2)
        or else S'Length (1) < 1
      then
         raise Invalid_Argument with "Within_Cluster_SSE: extent mismatch";
      end if;
      for P in Data'Range (1) loop
         if Lab (P) < Natural (S'First (1))
           or else Lab (P) > Natural (S'Last (1))
         then
            raise Invalid_Argument with "Within_Cluster_SSE: bad label";
         end if;
         K_Id := Site_Index (Lab (P));
         Pt := Extract_Point (Data, P);
         Mu := Extract_Site (S, K_Id);
         Total := Total + Squared_Distance (Pt, Mu);
      end loop;
      return Total;
   end Within_Cluster_SSE;

   -------------------------------------------------------------------------
   -- Init_Sites_From_Data
   -------------------------------------------------------------------------

   function Init_Sites_From_Data
     (Data : Dataset; K : Site_Count) return Sites
   is
      N : constant Point_Count := Data'Length (1);
      D : constant Dim_Count := Data'Length (2);
      Result : Sites (1 .. K, 1 .. D);
      Idx : Point_Index;
      Span : Integer;
      Dim_Off : constant Integer := Data'First (2) - 1;
   begin
      if N < 1 or else D < 1 or else K < 1 then
         raise Invalid_Argument with "Init_Sites_From_Data: empty/K";
      end if;
      --  Capacity enforced by Point_Count / Dim_Count / Site_Count subtypes.
      if K > N then
         raise Invalid_Argument with "Init_Sites_From_Data: K > N";
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
   end Init_Sites_From_Data;

   -------------------------------------------------------------------------
   -- Max displacement between two Sites matrices
   -------------------------------------------------------------------------

   function Max_Site_Displacement (A, B : Sites) return Non_Negative is
      Max_D : Real := 0.0;
      PA, PB : Point (1 .. A'Length (2));
      Dist : Real;
   begin
      for K in A'Range (1) loop
         PA := Extract_Site (A, K);
         PB := Extract_Site (B, K);
         Dist := Distance (PA, PB);
         if Dist > Max_D then
            Max_D := Dist;
         end if;
      end loop;
      return Max_D;
   end Max_Site_Displacement;

   -------------------------------------------------------------------------
   -- Run_Lloyd (with explicit Init)
   -------------------------------------------------------------------------

   function Run_Lloyd
     (Data   : Dataset;
      Init   : Sites;
      Params : Parameters := Default_Parameters) return Lloyd_Result
   is
      N : constant Point_Count := Data'Length (1);
      D : constant Dim_Count := Data'Length (2);
      K : constant Site_Count := Params.K;
      Result : Lloyd_Result (N => N, K => K, D => D);
      Prev : Sites (1 .. K, 1 .. D);
      Disp : Real;
      Lab_Tmp : Labels (Data'Range (1));
   begin
      if N < 1 or else D < 1 or else K < 1 then
         raise Invalid_Argument with "Run_Lloyd: empty data/K";
      end if;
      --  Capacity enforced by Point_Count / Dim_Count / Site_Count subtypes.
      if Init'Length (1) /= K or else Init'Length (2) /= D then
         raise Invalid_Argument with "Run_Lloyd: Init extent mismatch";
      end if;
      --  Tol subtype Non_Negative; nonnegativity enforced by type.

      --  Copy Init into Result.Centroids (normalize index bases to 1 ..).
      declare
         S_Off1 : constant Integer := Init'First (1) - 1;
         S_Off2 : constant Integer := Init'First (2) - 1;
      begin
         for J in 1 .. K loop
            for C in 1 .. D loop
               Result.Centroids (Site_Index (J), Dim_Index (C)) :=
                 Init
                   (Site_Index (J + S_Off1),
                    Dim_Index (C + S_Off2));
            end loop;
         end loop;
      end;

      Result.Empty := [others => False];
      Result.Iters := 0;
      Result.Converged := False;

      for Iter in 1 .. Params.Max_Iters loop
         Prev := Result.Centroids;
         Lab_Tmp := Assign_Labels (Data, Result.Centroids);
         --  Remap labels into Result.Lab with 1-based point indices.
         declare
            P_Off : constant Integer := Data'First (1) - 1;
         begin
            for P in Data'Range (1) loop
               Result.Lab (Point_Index (Integer (P) - P_Off)) := Lab_Tmp (P);
            end loop;
         end;
         Compute_Centroids
           (Data, Lab_Tmp, Result.Centroids, Result.Empty,
            Raise_Empty => False);
         Result.Iters := Iter;
         Disp := Max_Site_Displacement (Prev, Result.Centroids);
         if Disp < Params.Tol then
            Result.Converged := True;
            exit;
         end if;
      end loop;

      Result.Inertia :=
        Within_Cluster_SSE (Data, Result.Centroids, Lab_Tmp);
      return Result;
   end Run_Lloyd;

   -------------------------------------------------------------------------
   -- Run_Lloyd (auto-init)
   -------------------------------------------------------------------------

   function Run_Lloyd
     (Data   : Dataset;
      Params : Parameters) return Lloyd_Result
   is
      Init : constant Sites := Init_Sites_From_Data (Data, Params.K);
   begin
      return Run_Lloyd (Data, Init, Params);
   end Run_Lloyd;

   -------------------------------------------------------------------------
   -- Run_Lloyd_Grid_2D
   -------------------------------------------------------------------------

   function Run_Lloyd_Grid_2D
     (Box        : BBox_2D;
      Resolution : Positive;
      Init       : Sites;
      Max_Iters  : Positive := 50;
      Tol        : Non_Negative := 1.0E-6) return Sites
   is
      K : constant Site_Count := Init'Length (1);
      Current : Sites (1 .. K, 1 .. 2);
      Prev : Sites (1 .. K, 1 .. 2);
      Counts : array (1 .. K) of Natural;
      Sum_X, Sum_Y : array (1 .. K) of Real;
      DX, DY : Real;
      X, Y : Real;
      Best : Site_Index;
      Best_Sq, Cand_Sq, Diff_X, Diff_Y : Real;
      Disp : Real;
      S_Off1 : constant Integer := Init'First (1) - 1;
      S_Off2 : constant Integer := Init'First (2) - 1;
   begin
      if K < 1 or else Init'Length (2) /= 2 then
         raise Invalid_Argument with "Run_Lloyd_Grid_2D: need K sites in 2-D";
      end if;
      if Box.X_Max <= Box.X_Min or else Box.Y_Max <= Box.Y_Min then
         raise Invalid_Argument with "Run_Lloyd_Grid_2D: degenerate bbox";
      end if;
      if Resolution < 2 or else Resolution > 128 then
         raise Invalid_Argument with "Run_Lloyd_Grid_2D: bad resolution";
      end if;
      --  Capacity enforced by Site_Count / Sites'Length subtypes.

      for J in 1 .. K loop
         Current (Site_Index (J), 1) :=
           Init (Site_Index (J + S_Off1), Dim_Index (1 + S_Off2));
         Current (Site_Index (J), 2) :=
           Init (Site_Index (J + S_Off1), Dim_Index (2 + S_Off2));
      end loop;

      DX := (Box.X_Max - Box.X_Min) / Real (Resolution - 1);
      DY := (Box.Y_Max - Box.Y_Min) / Real (Resolution - 1);

      for Iter in 1 .. Max_Iters loop
         Prev := Current;
         Counts := [others => 0];
         Sum_X := [others => 0.0];
         Sum_Y := [others => 0.0];

         for IX in 0 .. Resolution - 1 loop
            X := Box.X_Min + Real (IX) * DX;
            for IY in 0 .. Resolution - 1 loop
               Y := Box.Y_Min + Real (IY) * DY;
               --  Nearest site among Current.
               Best := 1;
               Diff_X := X - Current (1, 1);
               Diff_Y := Y - Current (1, 2);
               Best_Sq := Diff_X * Diff_X + Diff_Y * Diff_Y;
               for Sk in 2 .. K loop
                  Diff_X := X - Current (Site_Index (Sk), 1);
                  Diff_Y := Y - Current (Site_Index (Sk), 2);
                  Cand_Sq := Diff_X * Diff_X + Diff_Y * Diff_Y;
                  if Cand_Sq < Best_Sq then
                     Best_Sq := Cand_Sq;
                     Best := Site_Index (Sk);
                  end if;
               end loop;
               Counts (Best) := Counts (Best) + 1;
               Sum_X (Best) := Sum_X (Best) + X;
               Sum_Y (Best) := Sum_Y (Best) + Y;
            end loop;
         end loop;

         for Sk in 1 .. K loop
            if Counts (Site_Index (Sk)) > 0 then
               Current (Site_Index (Sk), 1) :=
                 Sum_X (Site_Index (Sk)) / Real (Counts (Site_Index (Sk)));
               Current (Site_Index (Sk), 2) :=
                 Sum_Y (Site_Index (Sk)) / Real (Counts (Site_Index (Sk)));
            end if;
            --  else keep previous (empty cell policy).
         end loop;

         Disp := Max_Site_Displacement (Prev, Current);
         exit when Disp < Tol;
      end loop;

      return Current;
   end Run_Lloyd_Grid_2D;

end Lloyds_Algorithm;
