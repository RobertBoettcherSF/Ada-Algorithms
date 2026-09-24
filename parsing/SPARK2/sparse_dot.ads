pragma Ada_2022;

package Sparse_Dot with SPARK_Mode => On is
   Dimension : constant := 5;
   Nonzero_Count : constant := 3;
   subtype Index is Positive range 1 .. Dimension;
   subtype Nonzero_Index is Positive range 1 .. Nonzero_Count;
   subtype Component is Integer range -10 .. 10;
   type Dense_Vector is array (Index) of Component;
   type Sparse_Indices is array (Nonzero_Index) of Index;
   type Sparse_Values is array (Nonzero_Index) of Component;

   function Dot (Values : Sparse_Values; Indices : Sparse_Indices;
                 Dense : Dense_Vector) return Integer with Global => null;
end Sparse_Dot;
