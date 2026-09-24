pragma SPARK_Mode (On);

package body LFU_Cache_Lite is
   function Empty return Cache is
   begin
      return (Keys => (others => 0), Values => (others => 0),
              Uses => (others => 0), Size => 0);
   end Empty;

   procedure Put (C : in out Cache; K : Key; V : Value) is
      Seen : Boolean := False;
   begin
      for I in Position loop
         if I <= C.Size and then not Seen and then C.Keys (I) = K then
            C.Values (I) := V;
            Seen := True;
         end if;
      end loop;
      if not Seen and then C.Size < Count'Last then
         C.Size := C.Size + 1;
         C.Keys (C.Size) := K;
         C.Values (C.Size) := V;
         C.Uses (C.Size) := 1;
      end if;
   end Put;

   procedure Touch (C : in out Cache; K : Key) is
   begin
      for I in Position loop
         if I <= C.Size and then C.Keys (I) = K and then C.Uses (I) < Frequency'Last then
            C.Uses (I) := C.Uses (I) + 1;
         end if;
      end loop;
   end Touch;

   function Length (C : Cache) return Count is
   begin
      return C.Size;
   end Length;

   function Most_Frequent_Key (C : Cache) return Key is
      Best : Position := 1;
   begin
      for I in Position loop
         if I <= C.Size and then C.Uses (I) > C.Uses (Best) then
            Best := I;
         end if;
      end loop;
      return C.Keys (Best);
   end Most_Frequent_Key;
end LFU_Cache_Lite;
