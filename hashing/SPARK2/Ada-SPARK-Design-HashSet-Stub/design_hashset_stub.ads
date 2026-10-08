pragma SPARK_Mode (On);

package Design_Hashset_Stub is
   Capacity : constant := 4;
   subtype Count is Natural range 0 .. Capacity;
   subtype Key is Integer range -100 .. 100;

   type Set is record
      Size : Count := 0;
      K1, K2, K3, K4 : Key := 0;
   end record;

   function Empty return Set;
   function Contains (S : Set; K : Key) return Boolean;
   function Insert (S : Set; K : Key) return Set;
end Design_Hashset_Stub;
