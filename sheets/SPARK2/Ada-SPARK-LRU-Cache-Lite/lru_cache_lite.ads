pragma SPARK_Mode (On);

package LRU_Cache_Lite is
   subtype Count is Natural range 0 .. 16;
   subtype Position is Count range 1 .. 16;
   subtype Key is Integer range 0 .. 100;
   subtype Value is Integer range -100 .. 100;
   type Cache is private;

   function Empty return Cache;
   procedure Put (C : in out Cache; K : Key; V : Value);
   function Length (C : Cache) return Count;
   function Lookup (C : Cache; K : Key) return Value;
   function Contains (C : Cache; K : Key) return Boolean;
private
   type Key_Array is array (Position) of Key;
   type Value_Array is array (Position) of Value;
   type Cache is record
      Keys : Key_Array := (others => 0);
      Values : Value_Array := (others => 0);
      Size : Count := 0;
   end record;
end LRU_Cache_Lite;
