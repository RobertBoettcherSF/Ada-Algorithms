-- random_walker.adb
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Random_Walker is

   -- Helper function to compute the edge weight based on intensity differences.
   -- Uses standard Gaussian weighting: w_ij = exp(-beta * (I_i - I_j)^2)
   function Compute_Weight (Intensity_A, Intensity_B : Float; Beta : Float) return Float is
      Diff : constant Float := Intensity_A - Intensity_B;
   begin
      return Exp (-Beta * (Diff * Diff));
   end Compute_Weight;

   -- Variant 1: Standard Random Walker
   procedure Random_Walker_Segmentation
     (Edges         : in Edge_Array;
      Intensities   : in Intensity_Array;
      Seeds         : in Label_Array;
      Beta          : in Float;
      Max_Iter      : in Positive;
      Tolerance     : in Float;
      Result_Labels : out Label_Array)
   is
      -- Dummy priors matrix (empty) and Gamma = 0.0 to reuse the generalized logic
      Dummy_Priors : constant Prior_Matrix (1 .. 0, 1 .. 0) := (others => (others => 0.0));
   begin
      Random_Walker_With_Priors
        (Edges         => Edges,
         Intensities   => Intensities,
         Seeds         => Seeds,
         Priors        => Dummy_Priors,
         Gamma         => 0.0,
         Beta          => Beta,
         Max_Iter      => Max_Iter,
         Tolerance     => Tolerance,
         Result_Labels => Result_Labels);
   end Random_Walker_Segmentation;

   -- Variant 2: Random Walker with Priors (also acts as core engine for Variant 1)
   procedure Random_Walker_With_Priors
     (Edges         : in Edge_Array;
      Intensities   : in Intensity_Array;
      Seeds         : in Label_Array;
      Priors        : in Prior_Matrix;
      Gamma         : in Float;
      Beta          : in Float;
      Max_Iter      : in Positive;
      Tolerance     : in Float;
      Result_Labels : out Label_Array)
   is
      Max_Label : Label_Id := 0;
   begin
      -- Data Validation
      if Intensities'First /= Seeds'First or Intensities'Last /= Seeds'Last then
         raise Invalid_Parameters_Error with "Intensities and Seeds arrays must have matching bounds.";
      end if;

      if Gamma > 0.0 and then 
         (Priors'First(1) /= Intensities'First or Priors'Last(1) /= Intensities'Last) then
         raise Invalid_Parameters_Error with "Priors matrix must match Intensities bounds.";
      end if;

      -- Determine maximum label from the Seeds array
      for I in Seeds'Range loop
         if Seeds (I) > Max_Label then
            Max_Label := Seeds (I);
         end if;
      end loop;

      if Max_Label = 0 then
         raise Invalid_Parameters_Error with "No seeds provided. At least one labeled node is required.";
      end if;

      -- Validate Priors matrix labels if Gamma is active
      if Gamma > 0.0 and then Natural(Priors'Last(2)) < Natural(Max_Label) then
         raise Invalid_Parameters_Error with "Priors matrix does not cover all labels.";
      end if;

      declare
         -- Probability matrix P(Node, Label)
         type Prob_Matrix is array (Intensities'Range, 1 .. Max_Label) of Float;
         P, P_Next : Prob_Matrix := (others => (others => 0.0));
         
         Max_Diff : Float;
         Iter     : Positive := 1;
         
         Weight : Float;
         Denom  : Float;
         Sum    : Float;
      begin
         -- Initialization
         for I in Intensities'Range loop
            if Seeds (I) > 0 then
               P (I, Seeds (I)) := 1.0;
            else
               -- Unlabeled nodes initialized to uniform distribution
               for L in 1 .. Max_Label loop
                  P (I, L) := 1.0 / Float (Max_Label);
               end loop;
            end if;
         end loop;
         P_Next := P;

         -- Jacobi Iterative Solver for the Dirichlet problem
         loop
            Max_Diff := 0.0;
            
            for I in Intensities'Range loop
               if Seeds (I) = 0 then -- Only update unlabeled nodes
                  for L in 1 .. Max_Label loop
                     Sum   := 0.0;
                     Denom := 0.0;

                     -- Iterate over edges to find neighbors (Adjacency List would be faster for large graphs, 
                     -- but array iteration is sufficient for this reference implementation)
                     for E in Edges'Range loop
                        if Edges (E).Node_A = I or Edges (E).Node_B = I then
                           declare
                              Neighbor : constant Node_Id := 
                                (if Edges (E).Node_A = I then Edges (E).Node_B else Edges (E).Node_A);
                           begin
                              Weight := Compute_Weight (Intensities (I), Intensities (Neighbor), Beta);
                              Sum    := Sum + Weight * P (Neighbor, L);
                              Denom  := Denom + Weight;
                           end;
                        end if;
                     end loop;

                     -- Add Priors if Gamma > 0
                     if Gamma > 0.0 then
                        Sum   := Sum + Gamma * Priors (I, L);
                        Denom := Denom + Gamma;
                     end if;

                     -- Update Rule
                     if Denom > 0.0 then
                        P_Next (I, L) := Sum / Denom;
                     end if;

                     -- Track Convergence
                     if abs (P_Next (I, L) - P (I, L)) > Max_Diff then
                        Max_Diff := abs (P_Next (I, L) - P (I, L));
                     end if;
                  end loop;
               end if;
            end loop;

            P := P_Next;
            exit when Max_Diff <= Tolerance or Iter >= Max_Iter;
            Iter := Iter + 1;
         end loop;

         -- Final Label Assignment (Argmax)
         for I in Intensities'Range loop
            if Seeds (I) > 0 then
               Result_Labels (I) := Seeds (I);
            else
               declare
                  Best_L : Label_Id := 1;
                  Best_P : Float    := P (I, 1);
               begin
                  for L in 2 .. Max_Label loop
                     if P (I, L) > Best_P then
                        Best_P := P (I, L);
                        Best_L := L;
                     end if;
                  end loop;
                  Result_Labels (I) := Best_L;
               end;
            end if;
         end loop;
      end;
   end Random_Walker_With_Priors;

end Random_Walker;
