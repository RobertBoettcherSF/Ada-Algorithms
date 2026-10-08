pragma SPARK_Mode (On);

package Alien_Dictionary with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Length is Natural range 0 .. Capacity;
   subtype Letter is Character range 'a' .. 'z';
   subtype Rank_Value is Natural range 0 .. 25;
   type Word is array (Positive range 1 .. Capacity) of Letter;
   type Alphabet_Order is array (Letter) of Rank_Value;

   function Is_Ordered
     (First, Second : Word; First_Length, Second_Length : Length;
      Order : Alphabet_Order) return Boolean
     with Global => null;
end Alien_Dictionary;
