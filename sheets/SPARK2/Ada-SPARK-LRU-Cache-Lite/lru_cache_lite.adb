pragma SPARK_Mode (On);

package body LRU_Cache_Lite is
   function Empty return Cache is
   begin
      return (Keys => (others => 0), Values => (others => 0), Size => 0);
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
      end if;
   end Put;

   function Length (C : Cache) return Count is
   begin
      return C.Size;
   end Length;

   function Lookup (C : Cache; K : Key) return Value is
      Answer : Value := 0;
   begin
      for I in Position loop
         if I <= C.Size and then C.Keys (I) = K then
            Answer := C.Values (I);
         end if;
      end loop;
      return Answer;
   end Lookup;

   function Contains (C : Cache; K : Key) return Boolean is
      Seen : Boolean := False;
   begin
      for I in Position loop
         if I <= C.Size and then C.Keys (I) = K then
            Seen := True;
         end if;
      end loop;
      return Seen;
   end Contains;
end LRU_Cache_Lite;
