pragma SPARK_Mode (On);

package Design_HashMap_Stub is
   Capacity : constant := 4;
   subtype Key is Positive range 1 .. 16;
   subtype Value is Natural range 0 .. 100;
   subtype Slot is Positive range 1 .. Capacity;
   type Map_Entry is record
      Present : Boolean;
      Key_Value : Key;
      Stored_Value : Value;
   end record;
   type Table is array (Slot) of Map_Entry;

   function Lookup (Map : Table; Search : Key) return Value
     with Global => null;
end Design_HashMap_Stub;
