pragma Ada_2022;
pragma SPARK_Mode (On);
package body LRU_Cache_Lite is
   function Empty return Cache is
   begin
      return (Keys => [others => 0], Values => [others => 0], Size => 0);
   end Empty;

   function Length (C : Cache) return Count is (C.Size);

   --  Position of K, 0 if absent.
   function Find (C : Cache; K : Key) return Count is
   begin
      for I in Position loop
         if I <= C.Size and then C.Keys (I) = K then
            return I;
         end if;
      end loop;
      return 0;
   end Find;

   --  Move entry P to the most recently used end.
   procedure Move_To_End (C : in out Cache; P : Position)
     with Pre => P <= C.Size, Post => C.Size = C.Size'Old
   is
      K : constant Key := C.Keys (P);
      V : constant Value := C.Values (P);
   begin
      for I in P .. C.Size - 1 loop
         C.Keys (I) := C.Keys (I + 1);
         C.Values (I) := C.Values (I + 1);
      end loop;
      C.Keys (C.Size) := K;
      C.Values (C.Size) := V;
   end Move_To_End;

   procedure Put (C : in out Cache; K : Key; V : Value) is
      P : constant Count := Find (C, K);
   begin
      if P in 1 .. C.Size then
         C.Values (P) := V;
         Move_To_End (C, P);
      elsif C.Size < Count'Last then
         C.Size := C.Size + 1;
         C.Keys (C.Size) := K;
         C.Values (C.Size) := V;
      else
         Move_To_End (C, 1);        --  the least recently used entry is reused
         C.Keys (C.Size) := K;
         C.Values (C.Size) := V;
      end if;
   end Put;

   procedure Get (C : in out Cache; K : Key; V : out Value) is
      P : constant Count := Find (C, K);
   begin
      if P in 1 .. C.Size then
         V := C.Values (P);
         Move_To_End (C, P);
      else
         V := 0;   --  excluded by Pre => Contains (C, K)
      end if;
   end Get;

   function Lookup (C : Cache; K : Key) return Value is
      P : constant Count := Find (C, K);
   begin
      return (if P in 1 .. C.Size then C.Values (P) else 0);   --  else excluded by Pre
   end Lookup;
end LRU_Cache_Lite;
