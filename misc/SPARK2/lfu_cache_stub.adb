pragma SPARK_Mode (On);

package body Lfu_Cache_Stub is
   function Empty return Cache is
   begin
      return (U1 => False, U2 => False, U3 => False, U4 => False, K1 => 0, K2 => 0, K3 => 0, K4 => 0,
              V1 => 0, V2 => 0, V3 => 0, V4 => 0, F1 => 0, F2 => 0, F3 => 0, F4 => 0);
   end Empty;

   function Contains (C : Cache; K : Key) return Boolean is
   begin
      return (C.U1 and then C.K1 = K) or else (C.U2 and then C.K2 = K)
        or else (C.U3 and then C.K3 = K) or else (C.U4 and then C.K4 = K);
   end Contains;

   function Next (F : Frequency) return Frequency is
   begin
      if F = Frequency'Last then return F; else return F + 1; end if;
   end Next;

   function Put (C : Cache; K : Key; V : Value) return Cache is
      R : Cache := C;
   begin
      if C.U1 and then C.K1 = K then R.V1 := V; R.F1 := Next (C.F1); return R; end if;
      if C.U2 and then C.K2 = K then R.V2 := V; R.F2 := Next (C.F2); return R; end if;
      if C.U3 and then C.K3 = K then R.V3 := V; R.F3 := Next (C.F3); return R; end if;
      if C.U4 and then C.K4 = K then R.V4 := V; R.F4 := Next (C.F4); return R; end if;
      if not C.U1 then R.U1 := True; R.K1 := K; R.V1 := V; R.F1 := 1; return R; end if;
      if not C.U2 then R.U2 := True; R.K2 := K; R.V2 := V; R.F2 := 1; return R; end if;
      if not C.U3 then R.U3 := True; R.K3 := K; R.V3 := V; R.F3 := 1; return R; end if;
      if not C.U4 then R.U4 := True; R.K4 := K; R.V4 := V; R.F4 := 1; return R; end if;
      if C.F1 <= C.F2 and then C.F1 <= C.F3 and then C.F1 <= C.F4 then
         R.K1 := K; R.V1 := V; R.F1 := 1;
      elsif C.F2 <= C.F3 and then C.F2 <= C.F4 then
         R.K2 := K; R.V2 := V; R.F2 := 1;
      elsif C.F3 <= C.F4 then
         R.K3 := K; R.V3 := V; R.F3 := 1;
      else
         R.K4 := K; R.V4 := V; R.F4 := 1;
      end if;
      return R;
   end Put;

   function Lookup (C : Cache; K : Key; Default : Value) return Value is
   begin
      if C.U1 and then C.K1 = K then return C.V1; end if;
      if C.U2 and then C.K2 = K then return C.V2; end if;
      if C.U3 and then C.K3 = K then return C.V3; end if;
      if C.U4 and then C.K4 = K then return C.V4; end if;
      return Default;
   end Lookup;
end Lfu_Cache_Stub;
