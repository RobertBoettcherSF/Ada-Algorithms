--  Ada SPARK teaching sheet: Huffman-related frequency analysis (bounded).
pragma Ada_2022;
package Huffman_Coding
  with SPARK_Mode => On
is
   Max_Len : constant := 32;
   subtype Symbol is Character range 'a' .. 'z';
   type Symbol_Array is array (Positive range <>) of Symbol;
   type Freq_Map is array (Symbol) of Natural;

   function Count_Frequencies (Data : Symbol_Array) return Freq_Map
     with
       Global => null,
       Pre    => Data'First = 1 and then Data'Last <= Max_Len,
       Post   => (for all S in Symbol =>
                    Count_Frequencies'Result (S) <= Data'Length);

   function Distinct_Count (F : Freq_Map) return Natural
     with
       Global => null,
       Post   => Distinct_Count'Result <= 26;

   function Most_Frequent (F : Freq_Map) return Symbol
     with
       Global => null,
       Pre    => Distinct_Count (F) >= 1;

end Huffman_Coding;
