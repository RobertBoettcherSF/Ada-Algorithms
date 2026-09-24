pragma Ada_2022;

package Matchsticks_To_Square_Lite with SPARK_Mode => On is
   subtype Count is Positive range 4 .. 12;
   subtype Length is Positive range 1 .. 12;
   subtype Index is Positive range 1 .. 12;
   type Stick_List is array (Index) of Length;
   function Can_Form_Square (Sticks : Stick_List; N : Count) return Boolean with Global => null;
end Matchsticks_To_Square_Lite;
