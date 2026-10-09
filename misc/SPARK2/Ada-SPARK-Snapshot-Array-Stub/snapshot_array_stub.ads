--  PLACEHOLDER: bounded stub (the folder name ends in -Stub), not a full Snapshot-Array implementation; see PROOFS.csv stub
pragma SPARK_Mode (On);

package Snapshot_Array_Stub is
   Array_Size : constant := 4;
   subtype Array_Index is Positive range 1 .. Array_Size;
   subtype Used_Count is Natural range 0 .. Array_Size;
   subtype Element is Natural range 0 .. 1000;
   type Value_Array is array (Array_Index) of Element;

   function Snapshot_Total
     (Values : Value_Array; Used : Used_Count) return Natural;
end Snapshot_Array_Stub;
