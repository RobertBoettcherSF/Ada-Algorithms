pragma Ada_2022;

--  Concurrent Channel: protected object wrapping Channel.Buffer.
--  SPARK_Mode Off (tasking / PO on host without forcing Ravenscar RTS).
--  Pattern remains Ravenscar-compatible: simple barriers, no select.
package Channel.Sync
  with SPARK_Mode => Off
is
   protected PO is
      entry Enqueue (Item : Integer);
      entry Dequeue (Item : out Integer);
      function Length return Natural;
      procedure Reset;
   private
      Buf : Buffer;
   end PO;
end Channel.Sync;
