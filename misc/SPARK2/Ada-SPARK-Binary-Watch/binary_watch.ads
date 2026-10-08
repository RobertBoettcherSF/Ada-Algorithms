pragma Ada_2022;
package Binary_Watch with SPARK_Mode => On is
   subtype Hour is Integer range 0 .. 11;
   subtype Minute is Integer range 0 .. 59;
   subtype Watch_Value is Integer range 0 .. 719;
   function To_Minutes (H : Hour; M : Minute) return Watch_Value
     with Global => null;
   function Is_Valid (H : Hour; M : Minute) return Boolean
     with Global => null;
end Binary_Watch;
