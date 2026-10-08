pragma Ada_2022;
pragma SPARK_Mode (On);

package LFU_Cache_Lite is
   pragma Assertion_Policy (Pre => Check);
   subtype Count is Natural range 0 .. 16;
   subtype Position is Count range 1 .. 16;
   subtype Key is Integer range 0 .. 100;
   subtype Value is Integer range -100 .. 100;
   subtype Frequency is Natural;   --  use counts stop at Natural'Last (about 2**31 uses)
   type Cache is private;

   function Empty return Cache;
   function Length (C : Cache) return Count;
   function Contains (C : Cache; K : Key) return Boolean;

   --  Store V under K; counts as a use and makes K the most recently used.
   --  A new key on a full cache first evicts the entry with the fewest uses,
   --  the least recently used among ties.
   procedure Put (C : in out Cache; K : Key; V : Value);

   --  Count a use of K and make it the most recently used.
   procedure Touch (C : in out Cache; K : Key)
     with Pre => Contains (C, K);

   --  The key with the most uses, the least recently used among ties.
   function Most_Frequent_Key (C : Cache) return Key
     with Pre => Length (C) > 0;
private
   type Key_Array is array (Position) of Key;
   type Value_Array is array (Position) of Value;
   type Frequency_Array is array (Position) of Frequency;
   --  Entries 1 .. Size in recency order: 1 is the least recently used.
   type Cache is record
      Keys : Key_Array := [others => 0];
      Values : Value_Array := [others => 0];
      Uses : Frequency_Array := [others => 0];
      Size : Count := 0;
   end record;

   function Contains (C : Cache; K : Key) return Boolean is
     (for some I in Position => I <= C.Size and then C.Keys (I) = K);
end LFU_Cache_Lite;
