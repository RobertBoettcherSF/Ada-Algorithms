pragma SPARK_Mode (On);

package Lfu_Cache_Stub is
   Capacity : constant := 4;
   subtype Key is Integer range -100 .. 100;
   subtype Value is Integer range -1000 .. 1000;
   subtype Frequency is Natural range 0 .. 100;

   type Cache is record
      U1, U2, U3, U4 : Boolean := False;
      K1, K2, K3, K4 : Key := 0;
      V1, V2, V3, V4 : Value := 0;
      F1, F2, F3, F4 : Frequency := 0;
   end record;

   function Empty return Cache;
   function Contains (C : Cache; K : Key) return Boolean;
   function Put (C : Cache; K : Key; V : Value) return Cache;
   function Lookup (C : Cache; K : Key; Default : Value) return Value;
end Lfu_Cache_Stub;
