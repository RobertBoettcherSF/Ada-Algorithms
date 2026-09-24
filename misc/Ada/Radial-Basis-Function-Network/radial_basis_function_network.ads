package Radial_Basis_Function_Network is

   --  Fundamental floating-point type for high precision calculations
   type Real is digits 15;

   --  Custom index types to ensure strong typing for dimensions and counts
   type Dimension_Index is new Positive;
   type Center_Index is new Positive;

   --  Domain-specific subtypes to enforce valid ranges
   subtype Distance is Real range 0.0 .. Real'Last;
   subtype Shape_Parameter is Real range 0.000_000_001 .. Real'Last;

   --  Core array structures
   type Feature_Vector is array (Dimension_Index range <>) of Real;
   type Center_Matrix is array (Center_Index range <>, Dimension_Index range <>) of Real;
   type Weight_Vector is array (Center_Index range <>) of Real;

   --  Supported Radial Basis Functions
   type RBF_Type is
     (Gaussian,
      Multiquadric,
      Inverse_Quadratic,
      Inverse_Multiquadric);

   --  Exceptions for invalid operations
   Dimension_Mismatch_Error : exception;
   Normalization_Error      : exception;

   --  The primary RBF Network data structure
   type RBF_Network (Num_Centers : Center_Index; Num_Features : Dimension_Index) is private;

   --  Creates and initializes a new RBF Network
   function Create_Network
     (Centers       : Center_Matrix;
      Weights       : Weight_Vector;
      Bias          : Real;
      Shape         : Shape_Parameter;
      Function_Type : RBF_Type;
      Is_Normalized : Boolean) return RBF_Network
     with Global => null,
          Pre    => Centers'Length (1) > 0 and then
                    Centers'Length (2) > 0 and then
                    Centers'Length (1) = Weights'Length,
          Post   => Create_Network'Result.Num_Centers = Center_Index (Centers'Length (1)) and then
                    Create_Network'Result.Num_Features = Dimension_Index (Centers'Length (2));

   --  Evaluates the network output for a given input feature vector
   function Evaluate
     (Net   : RBF_Network;
      Input : Feature_Vector) return Real
     with Global => null,
          Pre    => Input'Length = Net.Num_Features;

   --  Computes the Euclidean distance between two vectors of equal length
   function Euclidean_Distance (A, B : Feature_Vector) return Distance
     with Global => null,
          Pre    => A'Length = B'Length;

   --  Computes the activation value given a distance and shape parameter
   function Calculate_Activation
     (Dist   : Distance;
      Shape  : Shape_Parameter;
      F_Type : RBF_Type) return Real
     with Global => null;

private

   --  Hidden implementation of the network record
   type RBF_Network (Num_Centers : Center_Index; Num_Features : Dimension_Index) is record
      Centers       : Center_Matrix (1 .. Num_Centers, 1 .. Num_Features);
      Weights       : Weight_Vector (1 .. Num_Centers);
      Bias          : Real;
      Shape         : Shape_Parameter;
      Function_Type : RBF_Type;
      Is_Normalized : Boolean;
   end record;

end Radial_Basis_Function_Network;
