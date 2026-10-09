pragma Ada_2022;

package Search_2D_Matrix with SPARK_Mode => On is
   Rows : constant := 8;
   Cols : constant := 8;
   subtype Row is Positive range 1 .. Rows;
   subtype Column is Positive range 1 .. Cols;
   subtype Value is Integer range 0 .. 99;
   type Matrix is array (Row, Column) of Value;

   subtype Probe_Count is Natural range 0 .. Rows * Cols;
   type Search_Result is record
      Found  : Boolean;       --  some cell equals Target
      Probes : Probe_Count;   --  comparisons with cells
   end record;

   function Contains (Input : Matrix; Target : Value) return Search_Result
     with Global => null;
end Search_2D_Matrix;
