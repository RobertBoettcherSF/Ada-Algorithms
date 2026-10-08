pragma Ada_2022;

package CSR_Row_Sum with SPARK_Mode => On is
   Row_Count : constant := 3;
   Entry_Count : constant := 6;
   subtype Row_Index is Positive range 1 .. Row_Count;
   subtype Entry_Index is Positive range 1 .. Entry_Count;
   subtype Component is Integer range 0 .. 10;
   subtype Pointer is Positive range 1 .. Entry_Count + 1;
   type Value_Array is array (Entry_Index) of Component;
   type Pointer_Array is array (Row_Index) of Pointer;

   function Row_Sum (Values : Value_Array; Row : Row_Index) return Integer
     with Global => null;
end CSR_Row_Sum;
