--  PLACEHOLDER: bounded stub (the folder name ends in -Stub), not a full Valid-IP-Address implementation; see PROOFS.csv stub
pragma SPARK_Mode (On);

package Valid_IP_Address_Stub is
   subtype Octet is Natural range 0 .. 255;
   type Address is record
      First, Second, Third, Fourth : Octet;
   end record;

   function Is_Valid (Value : Address) return Boolean
     with Global => null;
   function Is_Loopback (Value : Address) return Boolean
     with Global => null;
end Valid_IP_Address_Stub;
