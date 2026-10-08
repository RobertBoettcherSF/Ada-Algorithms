pragma Ada_2022;

package body Channel.Sync
  with SPARK_Mode => Off
is
   protected body PO is
      entry Enqueue (Item : Integer) when Length < Capacity is
      begin
         Put (Buf, Item);
      end Enqueue;

      entry Dequeue (Item : out Integer) when Length > 0 is
      begin
         Get (Buf, Item);
      end Dequeue;

      function Length return Natural is
      begin
         return Channel.Length (Buf);
      end Length;

      procedure Reset is
      begin
         Clear (Buf);
      end Reset;
   end PO;
end Channel.Sync;
