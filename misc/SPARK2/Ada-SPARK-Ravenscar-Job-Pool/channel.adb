pragma Ada_2022;

package body Channel
  with SPARK_Mode => On
is

   procedure Put (B : in out Buffer; Item : Integer) is
   begin
      Bounded_Buffer.Put (B, Bounded_Buffer.Element (Item));
   end Put;

   procedure Get (B : in out Buffer; Item : out Integer) is
      E : Bounded_Buffer.Element;
   begin
      Bounded_Buffer.Get (B, E);
      Item := Integer (E);
   end Get;

end Channel;
