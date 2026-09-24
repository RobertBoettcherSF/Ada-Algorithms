pragma Ada_2022;
package Design_Skiplist_Lite with SPARK_Mode => On is
   Capacity : constant := 8;
   subtype Count is Natural range 0 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   subtype Level is Natural range 0 .. 4;
   type Skiplist is private;
   function Empty return Skiplist with Global => null;
   function Size (S : Skiplist) return Count with Global => null;
   function Height (V : Value) return Level with Global => null;
   procedure Insert (S : in out Skiplist; V : Value)
     with Global => null, Pre => Size (S) < Capacity;
   function First (S : Skiplist) return Value with Global => null, Pre => Size (S) > 0;
private
   subtype Slot is Positive range 1 .. Capacity;
   type Value_Array is array (Slot) of Value;
   type Skiplist is record Data : Value_Array := (others => 0); Count_Stored : Count := 0; end record;
end Design_Skiplist_Lite;
