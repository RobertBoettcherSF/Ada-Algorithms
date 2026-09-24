-- vector_quantization.ads
-- Specification for Vector Quantization (VQ)
-- Implements Static (Encoding/Decoding) and Dynamic (LBG Training) Variants.

package Vector_Quantization is

   -- Strong typing for VQ specific data structures
   type Vector is array (Positive range <>) of Float;
   
   -- 2D Array representing a collection of vectors (Dataset or Codebook)
   -- Index 1 corresponds to the Vector Index, Index 2 corresponds to Dimension
   type Matrix is array (Positive range <>, Positive range <>) of Float;

   -- Exceptions for robust error handling
   Dimension_Mismatch : exception;
   Empty_Dataset      : exception;
   Invalid_Codebook   : exception;

   -- Variant 1: Static Vector Encoding (Find Nearest Neighbor)
   -- Maps a target vector to the index of the closest centroid in the codebook.
   function Encode (Target : Vector; Book : Matrix) return Positive;

   -- Variant 2: Static Vector Decoding
   -- Retrieves the centroid vector associated with a given index.
   function Decode (Index : Positive; Book : Matrix) return Vector;

   -- Variant 3: Dynamic Vector Quantization Training (LBG/GLA Algorithm)
   -- Iteratively optimizes a codebook of size `Codebook_Size` to minimize MSE 
   -- against the training `Data`. Supports convergence thresholds and max iterations.
   function Train_LBG
     (Data          : Matrix;
      Codebook_Size : Positive;
      Epsilon       : Float := 0.001;
      Max_Iter      : Positive := 100) return Matrix;

   -- Helper: Calculate Squared Euclidean distance between two vectors
   function Distance_Squared (V1, V2 : Vector) return Float;

   -- Helper: Calculate Mean Squared Error (MSE) of a dataset against a codebook
   function Calculate_MSE (Data : Matrix; Book : Matrix) return Float;

end Vector_Quantization;
