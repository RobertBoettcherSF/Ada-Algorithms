pragma Ada_2022;
package body Stack_Bounded with SPARK_Mode => On is
   procedure Initialize (S : out Stack) is
   begin for I in Index loop S.Data (I) := 0; end loop; S.Count := 0; end Initialize;
   function Is_Empty (S : Stack) return Boolean is begin return S.Count = 0; end Is_Empty;
   function Is_Full (S : Stack) return Boolean is begin return S.Count = Capacity; end Is_Full;
   function Depth (S : Stack) return Natural is begin return S.Count; end Depth;
   procedure Push (S : in out Stack; Value : Integer) is
   begin if S.Count < Capacity then S.Count := S.Count + 1; S.Data (S.Count) := Value; end if; end Push;
   procedure Pop (S : in out Stack; Value : out Integer) is
   begin if S.Count > 0 then Value := S.Data (S.Count); S.Count := S.Count - 1; else Value := 0; end if; end Pop;
   function Top (S : Stack) return Integer is begin if S.Count > 0 then return S.Data (S.Count); else return 0; end if; end Top;
end Stack_Bounded;
