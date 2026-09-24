with Ada.Numerics.Generic_Elementary_Functions;

package body Cluster_Analysis is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Long_Float);

   ------------------------
   -- Euclidean_Distance --
   ------------------------
   function Euclidean_Distance (P1, P2 : Point) return Coordinate is
      Sum_Squares : Coordinate := 0.0;
      Diff        : Coordinate;
   begin
      for I in Dimension_Index loop
         Diff := P1(I) - P2(I);
         Sum_Squares := Sum_Squares + (Diff * Diff);
      end loop;
      return Coordinate (Math.Sqrt (Long_Float (Sum_Squares)));
   end Euclidean_Distance;

   ------------------------
   -- Manhattan_Distance --
   ------------------------
   function Manhattan_Distance (P1, P2 : Point) return Coordinate is
      Sum_Abs : Coordinate := 0.0;
      Diff    : Coordinate;
   begin
      for I in Dimension_Index loop
         Diff := P1(I) - P2(I);
         if Diff < 0.0 then
            Sum_Abs := Sum_Abs - Diff;
         else
            Sum_Abs := Sum_Abs + Diff;
         end if;
      end loop;
      return Sum_Abs;
   end Manhattan_Distance;

   -----------------------
   -- Calculate_Inertia --
   -----------------------
   function Calculate_Inertia
     (Data          : Point_Array;
      Assignments   : Cluster_Assignment;
      Centroids     : Point_Array;
      Use_Manhattan : Boolean := False) return Coordinate
   is
      Total_Inertia     : Coordinate := 0.0;
      Assigned_Centroid : Point;
      C_Idx             : Positive;
   begin
      for I in Data'Range loop
         C_Idx := Centroids'First + Positive (Assignments (Assignments'First + (I - Data'First))) - 1;
         Assigned_Centroid := Centroids (C_Idx);
         
         if Use_Manhattan then
            Total_Inertia := Total_Inertia + Manhattan_Distance (Data (I), Assigned_Centroid);
         else
            Total_Inertia := Total_Inertia + Euclidean_Distance (Data (I), Assigned_Centroid);
         end if;
      end loop;
      return Total_Inertia;
   end Calculate_Inertia;

   -------------
   -- K_Means --
   -------------
   procedure K_Means
     (Data           : in  Point_Array;
      K              : in  Positive;
      Max_Iterations : in  Positive;
      Assignments    : out Cluster_Assignment;
      Centroids      : out Point_Array)
   is
      Local_Assignments : Cluster_Assignment (Assignments'Range) := [others => 1];
      Local_Centroids   : Point_Array (Centroids'Range);
      
      Changed    : Boolean := True;
      Iterations : Natural := 0;
      Counts     : array (1 .. K) of Natural;
      Sums       : array (1 .. K) of Point;
      Min_Dist   : Coordinate;
      Dist       : Coordinate;
      Best_C     : Cluster_ID;
      Data_Idx   : Positive;
      Assign_Idx : Positive;
   begin
      -- Initialize centroids using the Forgy method (first K data points).
      for C in 1 .. K loop
         Local_Centroids (Local_Centroids'First + C - 1) := Data (Data'First + C - 1);
      end loop;

      while Changed and Iterations < Max_Iterations loop
         Changed := False;
         Iterations := Iterations + 1;

         -- Step 1: Assign each point to the nearest centroid.
         for I in 0 .. Data'Length - 1 loop
            Data_Idx := Data'First + I;
            Assign_Idx := Local_Assignments'First + I;

            Min_Dist := Coordinate'Last;
            Best_C   := 1;

            for C in 1 .. K loop
               Dist := Euclidean_Distance (Data (Data_Idx), Local_Centroids (Local_Centroids'First + C - 1));
               if Dist < Min_Dist then
                  Min_Dist := Dist;
                  Best_C   := Cluster_ID (C);
               end if;
            end loop;

            if Local_Assignments (Assign_Idx) /= Best_C then
               Local_Assignments (Assign_Idx) := Best_C;
               Changed := True;
            end if;
         end loop;

         -- Step 2: Update centroids to the mean of assigned points.
         if Changed or Iterations = 1 then
            Counts := [others => 0];
            Sums := [others => [others => 0.0]];

            for I in 0 .. Data'Length - 1 loop
               Data_Idx := Data'First + I;
               Assign_Idx := Local_Assignments'First + I;
               Best_C := Local_Assignments (Assign_Idx);

               Counts (Positive (Best_C)) := Counts (Positive (Best_C)) + 1;
               for D in Dimension_Index loop
                  Sums (Positive (Best_C))(D) := Sums (Positive (Best_C))(D) + Data (Data_Idx)(D);
               end loop;
            end loop;

            for C in 1 .. K loop
               if Counts (C) > 0 then
                  for D in Dimension_Index loop
                     Local_Centroids (Local_Centroids'First + C - 1)(D) := Sums (C)(D) / Coordinate (Counts (C));
                  end loop;
               end if;
            end loop;
         end if;
      end loop;

      -- Commit local state to out parameters.
      Assignments := Local_Assignments;
      Centroids   := Local_Centroids;
   end K_Means;

   ---------------
   -- K_Medians --
   ---------------
   procedure K_Medians
     (Data           : in  Point_Array;
      K              : in  Positive;
      Max_Iterations : in  Positive;
      Assignments    : out Cluster_Assignment;
      Centroids      : out Point_Array)
   is
      Local_Assignments : Cluster_Assignment (Assignments'Range) := [others => 1];
      Local_Centroids   : Point_Array (Centroids'Range);
      
      Changed    : Boolean := True;
      Iterations : Natural := 0;
      Counts     : array (1 .. K) of Natural;
      Min_Dist   : Coordinate;
      Dist       : Coordinate;
      Best_C     : Cluster_ID;
      Data_Idx   : Positive;
      Assign_Idx : Positive;

      type Coordinate_Array is array (Positive range <>) of Coordinate;

      -- Internal helper to sort coordinates for median computation.
      procedure Selection_Sort (A : in out Coordinate_Array) is
         Min_Idx : Positive;
         Temp    : Coordinate;
      begin
         if A'Length <= 1 then 
            return; 
         end if;
         for I in A'First .. A'Last - 1 loop
            Min_Idx := I;
            for J in I + 1 .. A'Last loop
               if A (J) < A (Min_Idx) then
                  Min_Idx := J;
               end if;
            end loop;
            Temp := A (I);
            A (I) := A (Min_Idx);
            A (Min_Idx) := Temp;
         end loop;
      end Selection_Sort;

   begin
      -- Initialize centroids using the Forgy method.
      for C in 1 .. K loop
         Local_Centroids (Local_Centroids'First + C - 1) := Data (Data'First + C - 1);
      end loop;

      while Changed and Iterations < Max_Iterations loop
         Changed := False;
         Iterations := Iterations + 1;

         -- Step 1: Assign each point to the nearest centroid.
         for I in 0 .. Data'Length - 1 loop
            Data_Idx := Data'First + I;
            Assign_Idx := Local_Assignments'First + I;

            Min_Dist := Coordinate'Last;
            Best_C   := 1;

            for C in 1 .. K loop
               Dist := Manhattan_Distance (Data (Data_Idx), Local_Centroids (Local_Centroids'First + C - 1));
               if Dist < Min_Dist then
                  Min_Dist := Dist;
                  Best_C   := Cluster_ID (C);
               end if;
            end loop;

            if Local_Assignments (Assign_Idx) /= Best_C then
               Local_Assignments (Assign_Idx) := Best_C;
               Changed := True;
            end if;
         end loop;

         -- Step 2: Update centroids to the geometric median of assigned points.
         if Changed or Iterations = 1 then
            Counts := [others => 0];

            for I in 0 .. Data'Length - 1 loop
               Assign_Idx := Local_Assignments'First + I;
               Best_C := Local_Assignments (Assign_Idx);
               Counts (Positive (Best_C)) := Counts (Positive (Best_C)) + 1;
            end loop;

            for C in 1 .. K loop
               if Counts (C) > 0 then
                  declare
                     Cluster_Coords : Coordinate_Array (1 .. Counts (C));
                     Idx            : Positive;
                  begin
                     for D in Dimension_Index loop
                        Idx := 1;
                        for I in 0 .. Data'Length - 1 loop
                           if Local_Assignments (Local_Assignments'First + I) = Cluster_ID (C) then
                              Cluster_Coords (Idx) := Data (Data'First + I)(D);
                              Idx := Idx + 1;
                           end if;
                        end loop;

                        Selection_Sort (Cluster_Coords);

                        -- Calculate Median depending on array sizing parity.
                        if Counts (C) mod 2 = 1 then
                           Local_Centroids (Local_Centroids'First + C - 1)(D) := Cluster_Coords (1 + Counts (C) / 2);
                        else
                           Local_Centroids (Local_Centroids'First + C - 1)(D) :=
                             (Cluster_Coords (Counts (C) / 2) + Cluster_Coords (1 + Counts (C) / 2)) / 2.0;
                        end if;
                     end loop;
                  end;
               end if;
            end loop;
         end if;
      end loop;

      -- Commit local state to out parameters.
      Assignments := Local_Assignments;
      Centroids   := Local_Centroids;
   end K_Medians;

end Cluster_Analysis;
