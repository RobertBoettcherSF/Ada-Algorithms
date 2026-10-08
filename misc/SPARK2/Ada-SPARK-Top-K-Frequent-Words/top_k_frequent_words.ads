pragma Ada_2022;
package Top_K_Frequent_Words with SPARK_Mode => On is
   Capacity : constant := 32;
   subtype Size is Positive range 1 .. Capacity;
   subtype Word_Id is Positive range 1 .. Capacity;
   subtype Frequency is Natural range 0 .. Capacity;
   type Word_Array is array (Size) of Word_Id;
   function Kth_Frequency (Words : Word_Array; N : Size; K : Size) return Frequency
     with Pre => K <= N;
end Top_K_Frequent_Words;
