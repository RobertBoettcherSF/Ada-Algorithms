pragma SPARK_Mode (On);
package Design_HashMap is
   Capacity : constant := 4;
   subtype Key is Positive range 1 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   type Map is private;
   function Empty return Map with Global => null;
   procedure Put (M : in out Map; K : Key; V : Value) with Global => null;
   function Contains (M : Map; K : Key) return Boolean with Global => null;
   function Get (M : Map; K : Key) return Value with Global => null,
     Pre => Contains (M, K);
private
   type Value_Array is array (Key) of Value;
   type Used_Array is array (Key) of Boolean;
   type Map is record
      Values : Value_Array := (others => 0);
      Used : Used_Array := (others => False);
   end record;
end Design_HashMap;
