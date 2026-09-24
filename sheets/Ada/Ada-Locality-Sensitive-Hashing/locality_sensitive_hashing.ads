pragma Ada_2022;

--  Locality_Sensitive_Hashing (LSH) reduces the dimensionality of high-dimensional
--  data. This package implements three common LSH families:
--  1. Bit Sampling for Hamming distance
--  2. MinHash for Jaccard similarity of sets
--  3. Random Projection for Cosine distance of dense vectors

package Locality_Sensitive_Hashing is

   --  Fundamental Data Types
   type Bit_Vector is array (Positive range <>) of Boolean;
   type Index_Array is array (Positive range <>) of Positive;
   
   type Hash_Value is mod 2**32;
   type Hash_Array is array (Positive range <>) of Hash_Value;
   
   type Integer_Array is array (Positive range <>) of Integer;
   
   type Float_Vector is array (Positive range <>) of Long_Float;
   type Float_Matrix is array (Positive range <>, Positive range <>) of Long_Float;

   --  Exceptions for invalid usage and edge cases
   Dimension_Mismatch : exception;
   Empty_Input        : exception;
   Invalid_Index      : exception;

   -----------------------------------------------------------------------------
   --  Variant 1: Bit Sampling LSH (Hamming Distance)
   -----------------------------------------------------------------------------
   
   --  Extracts bits from `Data` at the specified `Indices` and packs them 
   --  into a 32-bit Hash_Value.
   function Bit_Sampling_Hash
     (Data    : Bit_Vector;
      Indices : Index_Array) return Hash_Value;

   -----------------------------------------------------------------------------
   --  Variant 2: MinHash LSH (Jaccard Similarity)
   -----------------------------------------------------------------------------
   
   --  Computes the MinHash of a set of integers using a specific Seed.
   function Min_Hash
     (Data : Integer_Array;
      Seed : Hash_Value) return Hash_Value;

   --  Computes a MinHash signature using an array of seeds to represent 
   --  multiple independent hash functions.
   function Min_Hash_Signature
     (Data  : Integer_Array;
      Seeds : Hash_Array) return Hash_Array;

   --  Estimates the Jaccard similarity between two sets given their MinHash signatures.
   function Estimate_Jaccard_Similarity
     (Sig_A, Sig_B : Hash_Array) return Long_Float;

   -----------------------------------------------------------------------------
   --  Variant 3: Random Projection LSH (Cosine Distance)
   -----------------------------------------------------------------------------
   
   --  Hashes a real-valued vector by projecting it onto a random hyperplane.
   --  Returns True if the dot product is positive, False otherwise.
   function Random_Projection_Hash
     (Data       : Float_Vector;
      Hyperplane : Float_Vector) return Boolean;

   --  Computes a full Cosine signature by evaluating Random_Projection_Hash
   --  against a matrix of hyperplanes (each row is a hyperplane).
   function Cosine_Signature
     (Data        : Float_Vector;
      Hyperplanes : Float_Matrix) return Bit_Vector;

end Locality_Sensitive_Hashing;
