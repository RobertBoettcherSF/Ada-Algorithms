generic
   Dimension : Positive;
package Lbg_Algorithm is

   -- Custom floating-point type for vector components to enforce strong typing.
   type Real is digits 6;

   -- Core vector and dataset types.
   type Vector is array (1 .. Dimension) of Real;
   type Vector_Array is array (Positive range <>) of Vector;

   -- Exception raised when structural or logic constraints are violated at runtime.
   Invalid_Input : exception;

   -- Computes the squared Euclidean distance between two vectors.
   function Squared_Distance (V1, V2 : Vector) return Real;

   -- Calculates the average distortion (Mean Squared Error) for a given dataset and codebook.
   function Average_Distortion
     (Training_Data : Vector_Array;
      Codebook      : Vector_Array) return Real
   with Pre => Training_Data'Length > 0 and then Codebook'Length > 0;

   -- Variant 1: Lloyd's Algorithm (K-Means)
   -- Iteratively optimizes an existing initial codebook without splitting.
   function Optimize_Codebook_Lloyd
     (Training_Data    : Vector_Array;
      Initial_Codebook : Vector_Array;
      Epsilon          : Real := 0.001;
      Max_Iterations   : Positive := 100) return Vector_Array
   with Pre => Training_Data'Length > 0 
               and then Initial_Codebook'Length > 0
               and then Initial_Codebook'Length <= Training_Data'Length
               and then Epsilon >= 0.0;

   -- Variant 2: Standard Linde-Buzo-Gray (LBG) Algorithm
   -- Generates a codebook of Target_Size from scratch using centroid splitting.
   function Generate_Codebook_Lbg
     (Training_Data   : Vector_Array;
      Target_Size     : Positive;
      Epsilon         : Real := 0.001;
      Split_Factor    : Real := 0.01;
      Max_Iterations  : Positive := 100) return Vector_Array
   with Pre => Training_Data'Length > 0 
               and then Target_Size <= Training_Data'Length
               and then Epsilon >= 0.0
               and then Split_Factor > 0.0;

end Lbg_Algorithm;
