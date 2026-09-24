pragma Ada_2022;
package Logger_Rate_Limiter_Lite with SPARK_Mode => On is
   Capacity : constant := 8;
   subtype Count is Natural range 0 .. Capacity;
   type Limiter is private;
   function Create return Limiter with Global => null;
   function Used (L : Limiter) return Count with Global => null;
   procedure Allow (L : in out Limiter) with Global => null, Pre => Used (L) < Capacity;
   procedure Reset (L : in out Limiter) with Global => null;
private
   type Limiter is record Requests : Count := 0; end record;
end Logger_Rate_Limiter_Lite;
