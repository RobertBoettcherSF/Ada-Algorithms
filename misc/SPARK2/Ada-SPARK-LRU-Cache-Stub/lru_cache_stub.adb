pragma SPARK_Mode (On);

package body Lru_Cache_Stub is
   function Empty return Cache is
   begin
      return (Clock => 0, U1 => False, U2 => False, U3 => False, U4 => False,
              K1 => 0, K2 => 0, K3 => 0, K4 => 0, V1 => 0, V2 => 0, V3 => 0, V4 => 0,
              T1 => 0, T2 => 0, T3 => 0, T4 => 0);
   end Empty;

   function Contains (C : Cache; K : Key) return Boolean is
   begin
      return (C.U1 and then C.K1 = K) or else (C.U2 and then C.K2 = K)
        or else (C.U3 and then C.K3 = K) or else (C.U4 and then C.K4 = K);
   end Contains;

   function Next (S : Stamp) return Stamp is
   begin
      if S = Stamp'Last then return S; else return S + 1; end if;
   end Next;

   function Put (C : Cache; K : Key; V : Value) return Cache is
      R : Cache := C;
      Now : constant Stamp := Next (C.Clock);
   begin
      R.Clock := Now;
      if C.U1 and then C.K1 = K then R.V1 := V; R.T1 := Now; return R; end if;
      if C.U2 and then C.K2 = K then R.V2 := V; R.T2 := Now; return R; end if;
      if C.U3 and then C.K3 = K then R.V3 := V; R.T3 := Now; return R; end if;
      if C.U4 and then C.K4 = K then R.V4 := V; R.T4 := Now; return R; end if;
      if not C.U1 then R.U1 := True; R.K1 := K; R.V1 := V; R.T1 := Now; return R; end if;
      if not C.U2 then R.U2 := True; R.K2 := K; R.V2 := V; R.T2 := Now; return R; end if;
      if not C.U3 then R.U3 := True; R.K3 := K; R.V3 := V; R.T3 := Now; return R; end if;
      if not C.U4 then R.U4 := True; R.K4 := K; R.V4 := V; R.T4 := Now; return R; end if;
      if C.T1 <= C.T2 and then C.T1 <= C.T3 and then C.T1 <= C.T4 then
         R.K1 := K; R.V1 := V; R.T1 := Now;
      elsif C.T2 <= C.T3 and then C.T2 <= C.T4 then
         R.K2 := K; R.V2 := V; R.T2 := Now;
      elsif C.T3 <= C.T4 then
         R.K3 := K; R.V3 := V; R.T3 := Now;
      else
         R.K4 := K; R.V4 := V; R.T4 := Now;
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
end Lru_Cache_Stub;
