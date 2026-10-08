pragma Ada_2022;

package body Bounded_Buffer
  with SPARK_Mode => On
is

   procedure Clear (B : out Buffer) is
   begin
      B := (Data => [others => 0], Head => 0, Tail => 0, Count => 0);
   end Clear;

   procedure Put (B : in out Buffer; Item : Element) is
   begin
      B.Data (B.Tail) := Item;
      B.Tail := (B.Tail + 1) mod Capacity;
      B.Count := B.Count + 1;
   end Put;

   procedure Get (B : in out Buffer; Item : out Element) is
   begin
      Item := B.Data (B.Head);
      B.Head := (B.Head + 1) mod Capacity;
      B.Count := B.Count - 1;
   end Get;

   function Is_Empty (B : Buffer) return Boolean is (B.Count = 0);

   function Is_Full (B : Buffer) return Boolean is (B.Count = Capacity);

end Bounded_Buffer;
