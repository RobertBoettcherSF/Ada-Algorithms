--  PLACEHOLDER: has no word list; only counts splits of a 4-symbol word into single symbols; see H122
pragma SPARK_Mode (On);

package Word_Break_II is
   subtype Length is Natural range 0 .. 4;
   subtype Symbol is Natural range 0 .. 25;
   subtype Count is Natural range 0 .. 100;
   type Word is array (Positive range 1 .. 4) of Symbol;

   function Segmentations (A : Word; N : Length) return Count
     with Global => null;
end Word_Break_II;
