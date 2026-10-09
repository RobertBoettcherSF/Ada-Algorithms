pragma Ada_2022;
pragma SPARK_Mode (On);
package body LFU_Cache_Lite is
   function Empty return Cache is
   begin
      return (Keys => [others => 0], Values => [others => 0],
              Uses => [others => 0], Size => 0);
   end Empty;

   function Length (C : Cache) return Count is (C.Size);

   --  Position of K, 0 if absent.
   function Find (C : Cache; K : Key) return Count
     with Post => (if Contains (C, K) then Find'Result in 1 .. C.Size and then C.Keys (Find'Result) = K
                   else Find'Result = 0)
   is
   begin
      for I in Position loop
         if I <= C.Size and then C.Keys (I) = K then
            return I;
         end if;
         pragma Loop_Invariant (for all J in 1 .. I => not (J <= C.Size and then C.Keys (J) = K));
      end loop;
      return 0;
   end Find;

   --  Move entry P to the most recently used end.
   procedure Move_To_End (C : in out Cache; P : Position)
     with Pre => P <= C.Size, Post => C.Size = C.Size'Old
   is
      K : constant Key := C.Keys (P);
      V : constant Value := C.Values (P);
      U : constant Frequency := C.Uses (P);
   begin
      for I in P .. C.Size - 1 loop
         C.Keys (I) := C.Keys (I + 1);
         C.Values (I) := C.Values (I + 1);
         C.Uses (I) := C.Uses (I + 1);
      end loop;
      C.Keys (C.Size) := K;
      C.Values (C.Size) := V;
      C.Uses (C.Size) := U;
   end Move_To_End;

   procedure Use_Entry (C : in out Cache; P : Position)
     with Pre => P <= C.Size, Post => C.Size = C.Size'Old
   is
   begin
      if C.Uses (P) < Frequency'Last then
         C.Uses (P) := C.Uses (P) + 1;
      end if;
      Move_To_End (C, P);
   end Use_Entry;

   procedure Put (C : in out Cache; K : Key; V : Value) is
      P : constant Count := Find (C, K);
      Low : Position := 1;
   begin
      if P in 1 .. C.Size then
         C.Values (P) := V;
         Use_Entry (C, P);
      else
         if C.Size = Count'Last then
            --  evict: fewest uses; scanning from the least recent keeps the oldest on ties
            for I in 2 .. C.Size loop
               if C.Uses (I) < C.Uses (Low) then
                  Low := I;
               end if;
            end loop;
            Move_To_End (C, Low);
            C.Size := C.Size - 1;
         end if;
         C.Size := C.Size + 1;
         C.Keys (C.Size) := K;
         C.Values (C.Size) := V;
         C.Uses (C.Size) := 1;
      end if;
   end Put;

   procedure Touch (C : in out Cache; K : Key) is
   begin
      Use_Entry (C, Find (C, K));   --  in 1 .. Size by Pre => Contains (C, K) and the Post of Find
   end Touch;

   function Get (C : Cache; K : Key) return Value is
     (C.Values (Find (C, K)));   --  in 1 .. Size by Pre => Contains (C, K) and the Post of Find

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
