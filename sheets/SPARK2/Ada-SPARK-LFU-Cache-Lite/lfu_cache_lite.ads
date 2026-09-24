pragma SPARK_Mode (On);

package LFU_Cache_Lite is
   subtype Count is Natural range 0 .. 16;
   subtype Position is Count range 1 .. 16;
   subtype Key is Integer range 0 .. 100;
   subtype Value is Integer range -100 .. 100;
   subtype Frequency is Natural range 0 .. 16;
   type Cache is private;

   function Empty return Cache;
   procedure Put (C : in out Cache; K : Key; V : Value);
   procedure Touch (C : in out Cache; K : Key);
   function Length (C : Cache) return Count;
   function Most_Frequent_Key (C : Cache) return Key
     with Pre => Length (C) > 0;
private
   type Key_Array is array (Position) of Key;
   type Value_Array is array (Position) of Value;
   type Frequency_Array is array (Position) of Frequency;
   type Cache is record
      Keys : Key_Array := (others => 0);
      Values : Value_Array := (others => 0);
      Uses : Frequency_Array := (others => 0);
      Size : Count := 0;
   end record;
end LFU_Cache_Lite;
