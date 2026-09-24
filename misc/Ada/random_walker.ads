-- random_walker.ads
package Random_Walker is

   -- Basic types for the algorithm
   type Node_Id is new Positive;
   type Label_Id is new Natural; -- 0 represents an unlabeled node

   type Edge is record
      Node_A : Node_Id;
      Node_B : Node_Id;
   end record;

   -- Arrays representing graph data
   type Edge_Array is array (Positive range <>) of Edge;
   type Intensity_Array is array (Node_Id range <>) of Float;
   type Label_Array is array (Node_Id range <>) of Label_Id;

   -- Matrix for prior probabilities (Node_Id, Label_Id)
   type Prior_Matrix is array (Node_Id range <>, Label_Id range <>) of Float;

   -- Custom Exceptions
   Invalid_Graph_Error      : exception;
   Invalid_Parameters_Error : exception;

   -- Variant 1: Standard Random Walker Algorithm (Preemptive calculation via iterative solver)
   -- Solves the Dirichlet problem using Jacobi iterations.
   procedure Random_Walker_Segmentation
     (Edges         : in Edge_Array;
      Intensities   : in Intensity_Array;
      Seeds         : in Label_Array;
      Beta          : in Float;
      Max_Iter      : in Positive;
      Tolerance     : in Float;
      Result_Labels : out Label_Array);

   -- Variant 2: Random Walker Algorithm with Priors
   -- Incorporates prior probability models (e.g., intensity priors) into the energy function.
   procedure Random_Walker_With_Priors
     (Edges         : in Edge_Array;
      Intensities   : in Intensity_Array;
      Seeds         : in Label_Array;
      Priors        : in Prior_Matrix;
      Gamma         : in Float; -- Weight of the prior term
      Beta          : in Float;
      Max_Iter      : in Positive;
      Tolerance     : in Float;
      Result_Labels : out Label_Array);

end Random_Walker;
