pragma Ada_2022;
package body Time_Based_Key_Value_Store with SPARK_Mode => On is
   procedure Initialize is begin for K in Key_Type loop Store (K).Value := 0; Store (K).Stamp := 0; Store (K).Valid := False; end loop; end Initialize;
   procedure Put (Key : Key_Type; Value : Integer; At_Time : Time_Type) is begin Store (Key).Value := Value; Store (Key).Stamp := At_Time; Store (Key).Valid := True; end Put;
   function Get (Key : Key_Type; At_Time : Time_Type) return Integer is
   begin if Store (Key).Valid and then Store (Key).Stamp <= At_Time then return Store (Key).Value; end if; return 0; end Get;
end Time_Based_Key_Value_Store;
