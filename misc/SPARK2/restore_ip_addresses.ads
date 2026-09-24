pragma Ada_2022;

package Restore_IP_Addresses with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 12;
   subtype Start_Index is Positive range 1 .. 10;
   subtype Segment_Length is Positive range 1 .. 3;
   subtype Digit is Natural range 0 .. 9;
   type Digit_Sequence is array (Index) of Digit;
   function Valid_Segment
     (D : Digit_Sequence; Start : Start_Index; Length : Segment_Length)
      return Boolean with Global => null;
   function Count_Valid_Segments (D : Digit_Sequence) return Natural with Global => null;
end Restore_IP_Addresses;
