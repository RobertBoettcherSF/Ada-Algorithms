pragma Ada_2022;
package Validate_Stack_Sequences with SPARK_Mode => On is
   Capacity : constant := 4;
   subtype Length is Natural range 0 .. Capacity;
   subtype Slot is Positive range 1 .. Capacity;
   subtype Value is Integer range 0 .. 9;
   type Sequence is array (Slot) of Value;
   function Valid (Pushed : Sequence; Popped : Sequence; N : Length) return Boolean with Global => null;
end Validate_Stack_Sequences;
