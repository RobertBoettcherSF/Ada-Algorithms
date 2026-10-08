pragma SPARK_Mode (On);

package Interleaving_String is
   subtype Length is Natural range 0 .. 4;
   subtype Symbol is Natural range 0 .. 25;
   type Word is array (Positive range 1 .. 4) of Symbol;

   function Is_Interleaving
     (A, B, C : Word; NA, NB, NC : Length) return Boolean
     with Global => null;
end Interleaving_String;
