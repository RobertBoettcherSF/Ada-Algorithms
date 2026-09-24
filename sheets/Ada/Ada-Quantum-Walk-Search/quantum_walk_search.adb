with Ada.Numerics.Generic_Elementary_Functions;

package body Quantum_Walk_Search is

   package Prob_Functions is new Ada.Numerics.Generic_Elementary_Functions (Probability);
   use Prob_Functions;

   function Is_Valid_Graph (Graph : Adjacency_Matrix) return Boolean is
   begin
      -- Check symmetry for undirected graph representation
      for I in Vertex_Index loop
         for J in Vertex_Index loop
            if Graph (I, J) /= Graph (J, I) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Valid_Graph;

   function Is_Valid_Marked (Marked : Marked_Set) return Boolean is
      Has_Marked : Boolean := False;
   begin
      for I in Marked'Range loop
         if Marked (I) then
            Has_Marked := True;
            exit;
         end if;
      end loop;
      return Has_Marked;
   end Is_Valid_Marked;

   function Count_Marked_Vertices (Marked : Marked_Set) return Natural is
      Count : Natural := 0;
   begin
      for I in Marked'Range loop
         if Marked (I) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Marked_Vertices;

   -- Discrete-Time Quantum Walk Search Simulation
   function Discrete_Time_Search_Simulation
     (Graph         : Adjacency_Matrix;
      Marked        : Marked_Set;
      Start_Vertex  : Vertex_Index;
      Steps         : Step_Count) return Success_Probability
   is
      pragma Unreferenced (Start_Vertex);
      N : constant Positive := Vertex_Index'Pos (Vertex_Index'Last) - Vertex_Index'Pos (Vertex_Index'First) + 1;
      
      type Amplitude_Array is array (Vertex_Index) of Probability;
      Amplitudes      : Amplitude_Array;
      Next_Amplitudes : Amplitude_Array;
      Initial_Val     : constant Probability := 1.0 / Sqrt (Probability (N));
      Sum_Sq          : Probability;
   begin
      if not Is_Valid_Graph (Graph) then
         raise Invalid_Graph_Error;
      end if;
      if not Is_Valid_Marked (Marked) then
         raise No_Marked_Vertex_Error;
      end if;

      -- Step 1: Initialize uniform superposition
      for I in Vertex_Index loop
         Amplitudes (I) := Initial_Val;
      end loop;

      -- Step 2: Iterate quantum walk steps (Oracle reflection + Graph mixing diffusion)
      for Step in 1 .. Steps loop
         -- 2a. Oracle reflection (phase inversion on marked vertices)
         for I in Vertex_Index loop
            if Marked (I) then
               Amplitudes (I) := -Amplitudes (I);
            end if;
         end loop;

         -- 2b. Diffusion / Coined Quantum Walk mixing operator over graph adjacency
         for I in Vertex_Index loop
            declare
               Neighbor_Sum : Probability := 0.0;
               Degree       : Natural := 0;
            begin
               for J in Vertex_Index loop
                  if Graph (I, J) then
                     Neighbor_Sum := Neighbor_Sum + Amplitudes (J);
                     Degree := Degree + 1;
                  end if;
               end loop;
               
               if Degree > 0 then
                  Next_Amplitudes (I) := 0.5 * Amplitudes (I) + 0.5 * (Neighbor_Sum / Probability (Degree));
               else
                  Next_Amplitudes (I) := Amplitudes (I);
               end if;
            end;
         end loop;

         -- Normalize amplitudes to maintain total probability = 1.0
         Sum_Sq := 0.0;
         for I in Vertex_Index loop
            Sum_Sq := Sum_Sq + Next_Amplitudes (I) * Next_Amplitudes (I);
         end loop;

         if Sum_Sq > 0.0 then
            declare
               Norm_Factor : constant Probability := Sqrt (Sum_Sq);
            begin
               for I in Vertex_Index loop
                  Amplitudes (I) := Next_Amplitudes (I) / Norm_Factor;
               end loop;
            end;
         else
            Amplitudes := Next_Amplitudes;
         end if;
      end loop;

      -- Step 3: Calculate success probability (sum of squared amplitudes of marked vertices)
      Sum_Sq := 0.0;
      for I in Vertex_Index loop
         if Marked (I) then
            Sum_Sq := Sum_Sq + Amplitudes (I) * Amplitudes (I);
         end if;
      end loop;

      if Sum_Sq < 0.0 then
         return 0.0;
      elsif Sum_Sq > 1.0 then
         return 1.0;
      else
         return Success_Probability (Sum_Sq);
      end if;
   end Discrete_Time_Search_Simulation;

   -- Continuous-Time Quantum Walk Search Simulation
   function Continuous_Time_Search_Simulation
     (Graph         : Adjacency_Matrix;
      Marked        : Marked_Set;
      Evolution_Time : Probability;
      Steps         : Step_Count) return Success_Probability
   is
      N           : constant Positive := Vertex_Index'Pos (Vertex_Index'Last) - Vertex_Index'Pos (Vertex_Index'First) + 1;
      type Amplitude_Array is array (Vertex_Index) of Probability;
      Amplitudes  : Amplitude_Array;
      Initial_Val : constant Probability := 1.0 / Sqrt (Probability (N));
      Sum_Sq      : Probability;
      Time_Step   : constant Probability := Evolution_Time / Probability (Integer'Max (1, Step_Count'Pos (Steps)));
   begin
      if not Is_Valid_Graph (Graph) then
         raise Invalid_Graph_Error;
      end if;
      if not Is_Valid_Marked (Marked) then
         raise No_Marked_Vertex_Error;
      end if;

      -- Initialize uniform superposition
      for I in Vertex_Index loop
         Amplitudes (I) := Initial_Val;
      end loop;

      -- Simulate Schrödinger-like continuous time evolution using Hamiltonian adjacency matrix
      for Step in 1 .. Steps loop
         declare
            Next_Amp : Amplitude_Array := Amplitudes;
         begin
            for I in Vertex_Index loop
               declare
                  Interaction : Probability := 0.0;
               begin
                  for J in Vertex_Index loop
                     if Graph (I, J) then
                        Interaction := Interaction + (Amplitudes (J) - Amplitudes (I));
                     end if;
                  end loop;
                  
                  if Marked (I) then
                     Interaction := Interaction + 2.0 * Amplitudes (I);
                  end if;

                  Next_Amp (I) := Amplitudes (I) + Time_Step * Interaction;
               end;
            end loop;
            Amplitudes := Next_Amp;
         end;
      end loop;

      -- Normalize and compute probability
      Sum_Sq := 0.0;
      for I in Vertex_Index loop
         Sum_Sq := Sum_Sq + Amplitudes (I) * Amplitudes (I);
      end loop;

      if Sum_Sq > 0.0 then
         declare
            Norm_Factor : constant Probability := Sqrt (Sum_Sq);
         begin
            for I in Vertex_Index loop
               Amplitudes (I) := Amplitudes (I) / Norm_Factor;
            end loop;
         end;
      end if;

      Sum_Sq := 0.0;
      for I in Vertex_Index loop
         if Marked (I) then
            Sum_Sq := Sum_Sq + Amplitudes (I) * Amplitudes (I);
         end if;
      end loop;

      if Sum_Sq < 0.0 then
         return 0.0;
      elsif Sum_Sq > 1.0 then
         return 1.0;
      else
         return Success_Probability (Sum_Sq);
      end if;
   end Continuous_Time_Search_Simulation;

   -- Classical Random Walk Search
   function Classical_Random_Walk_Search
     (Graph         : Adjacency_Matrix;
      Marked        : Marked_Set;
      Start_Vertex  : Vertex_Index;
      Max_Steps     : Step_Count;
      Seed          : Natural) return Step_Count
   is
      Current      : Vertex_Index := Start_Vertex;
      Current_Seed : Natural := Seed;
      
      function Next_Random return Natural is
      begin
         Current_Seed := Natural ((Long_Long_Integer (Current_Seed) * 1103515245 + 12345) mod 2147483647);
         return Current_Seed;
      end Next_Random;
   begin
      if not Is_Valid_Graph (Graph) then
         raise Invalid_Graph_Error;
      end if;
      if not Is_Valid_Marked (Marked) then
         raise No_Marked_Vertex_Error;
      end if;

      if Marked (Current) then
         return 0;
      end if;

      for Step in 1 .. Max_Steps loop
         declare
            type Neighbor_Array is array (1 .. 64) of Vertex_Index;
            Neighbors : Neighbor_Array;
            Count     : Natural := 0;
         begin
            for J in Vertex_Index loop
               if Graph (Current, J) then
                  Count := Count + 1;
                  Neighbors (Count) := J;
               end if;
            end loop;

            if Count > 0 then
               declare
                  Chosen_Index : constant Natural := (Next_Random mod Count) + 1;
               begin
                  Current := Neighbors (Chosen_Index);
               end;
            end if;
         end;

         if Marked (Current) then
            return Step;
         end if;
      end loop;

      return Max_Steps;
   end Classical_Random_Walk_Search;

end Quantum_Walk_Search;
