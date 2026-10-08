pragma Ada_2022;
pragma SPARK_Mode (On);

package LRU_Cache_Lite is
   pragma Assertion_Policy (Pre => Check);
   subtype Count is Natural range 0 .. 16;
   subtype Position is Count range 1 .. 16;
   subtype Key is Integer range 0 .. 100;
   subtype Value is Integer range -100 .. 100;
   type Cache is private;

   function Empty return Cache;
   function Length (C : Cache) return Count;
   function Contains (C : Cache; K : Key) return Boolean;

   --  Store V under K and make K the most recently used key. A new key on a
   --  full cache first evicts the least recently used entry.
   procedure Put (C : in out Cache; K : Key; V : Value);

   --  The value under K; counts as a use (K becomes the most recently used).
   procedure Get (C : in out Cache; K : Key; V : out Value)
     with Pre => Contains (C, K);

   --  The value under K without changing the recency order.
   function Lookup (C : Cache; K : Key) return Value
     with Pre => Contains (C, K);
private
   type Key_Array is array (Position) of Key;
   type Value_Array is array (Position) of Value;
   --  Entries 1 .. Size in recency order: 1 is the least recently used.
   type Cache is record
      Keys : Key_Array := [others => 0];
      Values : Value_Array := [others => 0];
      Size : Count := 0;
   end record;

   function Contains (C : Cache; K : Key) return Boolean is
     (for some I in Position => I <= C.Size and then C.Keys (I) = K);
end LRU_Cache_Lite;
