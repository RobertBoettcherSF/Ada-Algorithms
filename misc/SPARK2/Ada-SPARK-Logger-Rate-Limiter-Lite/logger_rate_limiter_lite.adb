pragma Ada_2022;
package body Logger_Rate_Limiter_Lite with SPARK_Mode => On is
   function Create return Limiter is
   begin return (Requests => 0); end Create;
   function Used (L : Limiter) return Count is
   begin return L.Requests; end Used;
   procedure Allow (L : in out Limiter) is
   begin if L.Requests < Capacity then L.Requests := L.Requests + 1; end if; end Allow;
   procedure Reset (L : in out Limiter) is
   begin if L.Requests > 0 then L.Requests := 0; else L.Requests := 0; end if; end Reset;
end Logger_Rate_Limiter_Lite;
