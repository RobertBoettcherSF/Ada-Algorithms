pragma Ada_2022;

package Repeated_Substring_Pattern with SPARK_Mode => On is
   Max_Length : constant := 100_000;
   subtype Index is Positive range 1 .. Max_Length;
   type Text_Array is array (Index range <>) of Character;

   --  Input has period P: every character equals the one P places earlier.
   function Has_Period (Input : Text_Array; P : Positive) return Boolean is
     (for all I in Input'Range =>
        (if I - Input'First >= P then Input (I) = Input (I - P)))
     with Ghost;

   --  Input is its first P characters repeated Input'Length / P times.
   function Repeats_Unit (Input : Text_Array; P : Positive) return Boolean is
     (Input'Length mod P = 0 and then Has_Period (Input, P))
     with Ghost;

   --  True when Input is a unit of length P < Input'Length repeated at
   --  least twice (P = Input'Length, the whole text once, does not count;
   --  texts shorter than 2 are never repeated).
   function Is_Repeated (Input : Text_Array) return Boolean
     with Global => null,
          Post   => Is_Repeated'Result =
                      (for some P in 1 .. Input'Length / 2 => Repeats_Unit (Input, P));
end Repeated_Substring_Pattern;
