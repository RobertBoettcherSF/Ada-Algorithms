pragma SPARK_Mode (On);

package Sequence_Reconstruction with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Length is Natural range 0 .. Capacity;
   subtype Value is Natural range 0 .. Capacity;
   type Sequence is array (Positive range 1 .. Capacity) of Value;

   function Matches (Expected, Candidate : Sequence; N : Length) return Boolean
     with Global => null;
end Sequence_Reconstruction;
