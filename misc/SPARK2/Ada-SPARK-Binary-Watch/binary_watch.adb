pragma Ada_2022;
package body Binary_Watch with SPARK_Mode => On is
   function To_Minutes (H : Hour; M : Minute) return Watch_Value is
   begin
      return H * 60 + M;
   end To_Minutes;
   function Is_Valid (H : Hour; M : Minute) return Boolean is
   begin
      return To_Minutes (H, M) <= 719;
   end Is_Valid;
end Binary_Watch;
