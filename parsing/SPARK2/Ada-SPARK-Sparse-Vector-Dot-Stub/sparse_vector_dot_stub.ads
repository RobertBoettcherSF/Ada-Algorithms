--  PLACEHOLDER: bounded stub (the folder name ends in -Stub), not a full Sparse-Vector-Dot implementation; see PROOFS.csv stub
pragma SPARK_Mode (On);

package Sparse_Vector_Dot_Stub is
   Capacity : constant := 8;
   subtype Component_Index is Positive range 1 .. Capacity;
   subtype Component is Integer range -100 .. 100;
   type Vector is array (Component_Index) of Component;

   function Dot (Left, Right : Vector) return Integer with Global => null;
end Sparse_Vector_Dot_Stub;
