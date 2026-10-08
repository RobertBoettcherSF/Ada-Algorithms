pragma Ada_2022;
package Randomized_Collection with SPARK_Mode => On is
   Capacity : constant := 8;
   subtype Count is Natural range 0 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   subtype Seed is Natural range 0 .. 10000;
   type Collection is private;
   function Empty return Collection with Global => null;
   function Size (C : Collection) return Count with Global => null;
   procedure Add (C : in out Collection; V : Value)
     with Global => null, Pre => Size (C) < Capacity;
   function Contains (C : Collection; V : Value) return Boolean with Global => null;
   procedure Next (S : in out Seed; V : out Value) with Global => null;
private
   subtype Slot is Positive range 1 .. Capacity;
   type Value_Array is array (Slot) of Value;
   type Collection is record
      Data : Value_Array := (others => 0);
      Count_Stored : Count := 0;
   end record;
end Randomized_Collection;
