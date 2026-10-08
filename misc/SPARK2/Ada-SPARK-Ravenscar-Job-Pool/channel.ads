pragma Ada_2022;

with Bounded_Buffer;

--  Bounded Channel (capacity N). Put/Get carry Pre/Post over Length.
--  Sequential view is SPARK_Mode On and Level-2 proved.
--  Concurrent PO lives in Channel.Sync (SPARK Off) — same capacity,
--  Ravenscar-shaped entries (simple barriers, no select).
package Channel
  with SPARK_Mode => On
is
   Capacity : constant Positive := Bounded_Buffer.Capacity;

   subtype Buffer is Bounded_Buffer.Buffer;

   function Length (B : Buffer) return Natural
     renames Bounded_Buffer.Length;

   function Is_Empty (B : Buffer) return Boolean
     renames Bounded_Buffer.Is_Empty;

   function Is_Full (B : Buffer) return Boolean
     renames Bounded_Buffer.Is_Full;

   procedure Clear (B : out Buffer)
     renames Bounded_Buffer.Clear;

   procedure Put (B : in out Buffer; Item : Integer)
     with Global => null,
          Pre    => not Is_Full (B),
          Post   => Length (B) = Length (B)'Old + 1;

   procedure Get (B : in out Buffer; Item : out Integer)
     with Global => null,
          Pre    => not Is_Empty (B),
          Post   => Length (B) = Length (B)'Old - 1;

end Channel;
