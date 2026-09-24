pragma SPARK_Mode (On);

package body Valid_IP_Address_Stub is
   function Is_Valid (Value : Address) return Boolean is
      pragma Unreferenced (Value);
   begin
      return True;
   end Is_Valid;

   function Is_Loopback (Value : Address) return Boolean is
   begin
      return Value.First = 127 and then Value.Second = 0
        and then Value.Third = 0 and then Value.Fourth = 1;
   end Is_Loopback;
end Valid_IP_Address_Stub;
