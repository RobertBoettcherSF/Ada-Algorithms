package body Lbg_Algorithm is

   -----------------------------------------------------------------------------
   -- Helper: Squared Euclidean Distance
   -----------------------------------------------------------------------------
   function Squared_Distance (V1, V2 : Vector) return Real is
      Sum  : Real := 0.0;
      Diff : Real;
   begin
      for I in 1 .. Dimension loop
         Diff := V1 (I) - V2 (I);
         Sum := Sum + Diff * Diff;
      end loop;
      return Sum;
   end Squared_Distance;

   -----------------------------------------------------------------------------
   -- Helper: Find Nearest Codebook Vector Index
   -----------------------------------------------------------------------------
   function Nearest_Index (V : Vector; Codebook : Vector_Array) return Positive is
      Best_Index : Positive := Codebook'First;
      Best_Dist  : Real := Squared_Distance (V, Codebook (Best_Index));
      Dist       : Real;
   begin
      -- Iterate through remaining codebook vectors to find closer matches
      for I in Codebook'First + 1 .. Codebook'Last loop
         Dist := Squared_Distance (V, Codebook (I));
         if Dist < Best_Dist then
            Best_Dist := Dist;
            Best_Index := I;
         end if;
      end loop;
      return Best_Index;
   end Nearest_Index;

   -----------------------------------------------------------------------------
   -- Average Distortion (MSE)
   -----------------------------------------------------------------------------
   function Average_Distortion
     (Training_Data : Vector_Array;
      Codebook      : Vector_Array) return Real
   is
      Total_Distortion : Real := 0.0;
   begin
      for I in Training_Data'Range loop
         Total_Distortion := Total_Distortion +
           Squared_Distance (Training_Data (I),
                             Codebook (Nearest_Index (Training_Data (I), Codebook)));
      end loop;
      return Total_Distortion / Real (Training_Data'Length);
   end Average_Distortion;

   -----------------------------------------------------------------------------
   -- Variant 1: Lloyd's Algorithm Optimization
   -----------------------------------------------------------------------------
   function Optimize_Codebook_Lloyd
     (Training_Data    : Vector_Array;
      Initial_Codebook : Vector_Array;
      Epsilon          : Real := 0.001;
      Max_Iterations   : Positive := 100) return Vector_Array
   is
      -- Normalize indices to 1 .. Length for internal manipulation
      Current_Codebook : Vector_Array (1 .. Initial_Codebook'Length);
      Next_Codebook    : Vector_Array (1 .. Initial_Codebook'Length);
      Counts           : array (1 .. Initial_Codebook'Length) of Natural;
      Prev_Distortion  : Real := Real'Last;
      Curr_Distortion  : Real;
      Nearest          : Positive;
      Improvement      : Real;
      Idx              : Positive := 1;
   begin
      if Initial_Codebook'Length > Training_Data'Length then
         raise Invalid_Input with "Initial Codebook size cannot exceed Training Data size.";
      end if;

      -- Copy initial codebook into normalized index space
      for I in Initial_Codebook'Range loop
         Current_Codebook (Idx) := Initial_Codebook (I);
         Idx := Idx + 1;
      end loop;

      for Iter in 1 .. Max_Iterations loop
         pragma Unreferenced (Iter); -- Prevent "unused loop variable" warning
         
         -- Reset accumulators
         for I in Next_Codebook'Range loop
            for D in 1 .. Dimension loop
               Next_Codebook (I)(D) := 0.0;
            end loop;
            Counts (I) := 0;
         end loop;

         -- Assignment step: assign each vector to the nearest centroid
         for I in Training_Data'Range loop
            Nearest := Nearest_Index (Training_Data (I), Current_Codebook);
            for D in 1 .. Dimension loop
               Next_Codebook (Nearest)(D) := Next_Codebook (Nearest)(D) + Training_Data (I)(D);
            end loop;
            Counts (Nearest) := Counts (Nearest) + 1;
         end loop;

         -- Update step: compute new centroids
         for I in Next_Codebook'Range loop
            if Counts (I) > 0 then
               for D in 1 .. Dimension loop
                  Next_Codebook (I)(D) := Next_Codebook (I)(D) / Real (Counts (I));
               end loop;
            else
               -- Edge case: Empty cell. Retain previous centroid to avoid NaN
               Next_Codebook (I) := Current_Codebook (I);
            end if;
         end loop;

         -- Convergence check
         Curr_Distortion := Average_Distortion (Training_Data, Next_Codebook);
         if Prev_Distortion = 0.0 then
            exit; -- Prevent division by zero if already perfect
         end if;

         Improvement := (Prev_Distortion - Curr_Distortion) / Prev_Distortion;
         
         Current_Codebook := Next_Codebook;
         Prev_Distortion  := Curr_Distortion;

         -- Stop if fractional improvement is below the epsilon threshold
         if abs Improvement < Epsilon then
            exit;
         end if;
      end loop;

      return Current_Codebook;
   end Optimize_Codebook_Lloyd;

   -----------------------------------------------------------------------------
   -- Variant 2: Standard Linde-Buzo-Gray Algorithm (Splitting)
   -----------------------------------------------------------------------------
   function Generate_Codebook_Lbg
     (Training_Data   : Vector_Array;
      Target_Size     : Positive;
      Epsilon         : Real := 0.001;
      Split_Factor    : Real := 0.01;
      Max_Iterations  : Positive := 100) return Vector_Array
   is
      Centroid : Vector;

      -- Recursive inner helper to manage the iteratively growing codebook array size
      function Lbg_Step (Current_Codebook : Vector_Array) return Vector_Array is
         Current_Size : constant Positive := Current_Codebook'Length;
      begin
         if Current_Size >= Target_Size then
            return Current_Codebook;
         end if;

         declare
            -- Calculate growth: Double size if possible, otherwise scale precisely to Target
            Next_Size     : constant Positive := Integer'Min (Current_Size * 2, Target_Size);
            Num_To_Split  : constant Positive := Next_Size - Current_Size;
            Next_Codebook : Vector_Array (1 .. Next_Size);
            Index         : Positive := 1;
         begin
            -- Split a subset of the vectors to achieve exact Target_Size
            for I in 1 .. Num_To_Split loop
               for D in 1 .. Dimension loop
                  Next_Codebook (Index)(D)     := Current_Codebook (Current_Codebook'First + I - 1)(D) + Split_Factor;
                  Next_Codebook (Index + 1)(D) := Current_Codebook (Current_Codebook'First + I - 1)(D) - Split_Factor;
               end loop;
               Index := Index + 2;
            end loop;

            -- Carry over the remaining vectors unaltered
            for I in Num_To_Split + 1 .. Current_Size loop
               Next_Codebook (Index) := Current_Codebook (Current_Codebook'First + I - 1);
               Index := Index + 1;
            end loop;

            -- Optimize the newly split codebook, then recurse
            return Lbg_Step (Optimize_Codebook_Lloyd (Training_Data, Next_Codebook, Epsilon, Max_Iterations));
         end;
      end Lbg_Step;

   begin
      if Target_Size > Training_Data'Length then
         raise Invalid_Input with "Target size cannot exceed available training samples.";
      end if;

      -- Base Case: Calculate the global centroid of the entire training dataset
      for D in 1 .. Dimension loop
         Centroid (D) := 0.0;
      end loop;
      for I in Training_Data'Range loop
         for D in 1 .. Dimension loop
            Centroid (D) := Centroid (D) + Training_Data (I)(D);
         end loop;
      end loop;
      for D in 1 .. Dimension loop
         Centroid (D) := Centroid (D) / Real (Training_Data'Length);
      end loop;

      -- Kick off the splitting recursion from the global centroid
      declare
         Initial_Codebook : constant Vector_Array (1 .. 1) := [1 => Centroid];
      begin
         return Lbg_Step (Initial_Codebook);
      end;
   end Generate_Codebook_Lbg;

end Lbg_Algorithm;
