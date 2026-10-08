pragma SPARK_Mode (On);

package body Design_Hashset_Stub is
   function Empty return Set is
   begin
      return (Size => 0, K1 => 0, K2 => 0, K3 => 0, K4 => 0);
   end Empty;

   function Contains (S : Set; K : Key) return Boolean is
   begin
      return (S.Size >= 1 and then S.K1 = K)
        or else (S.Size >= 2 and then S.K2 = K)
        or else (S.Size >= 3 and then S.K3 = K)
        or else (S.Size >= 4 and then S.K4 = K);
   end Contains;

   function Insert (S : Set; K : Key) return Set is
      R : Set := S;
   begin
      if Contains (S, K) then
         return R;
      end if;
      case S.Size is
         when 0 => R.K1 := K; R.Size := 1;
         when 1 => R.K2 := K; R.Size := 2;
         when 2 => R.K3 := K; R.Size := 3;
         when 3 => R.K4 := K; R.Size := 4;
         when 4 => null;
      end case;
      return R;
   end Insert;
end Design_Hashset_Stub;
