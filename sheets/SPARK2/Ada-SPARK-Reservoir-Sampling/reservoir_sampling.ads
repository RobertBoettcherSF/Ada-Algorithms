pragma Ada_2022;

package Reservoir_Sampling with SPARK_Mode => On is
   Stream_Length : constant := 6;
   Capacity : constant := 3;
   subtype Stream_Index is Positive range 1 .. Stream_Length;
   subtype Slot is Positive range 1 .. Capacity;
   subtype Item is Integer range -100 .. 100;
   type Stream is array (Stream_Index) of Item;
   type Reservoir is array (Slot) of Item;
   subtype Selection is Integer range 0 .. Capacity;
   type Choices is array (Stream_Index) of Selection;

   procedure Sample (Input : Stream; Choice : Choices; Result : out Reservoir);
end Reservoir_Sampling;
