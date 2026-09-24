pragma Ada_2022;

--  Sequential bounded circular buffer. SPARK Level-2 core used by the
--  protected Channel. No tasking here.
package Bounded_Buffer
  with SPARK_Mode => On
is
   Capacity : constant Positive := 8;

   type Element is new Integer;
   type Buffer is private;

   function Length (B : Buffer) return Natural
     with Global => null,
          Post   => Length'Result <= Capacity;

   function Is_Empty (B : Buffer) return Boolean
     with Global => null,
          Post   => Is_Empty'Result = (Length (B) = 0);

   function Is_Full (B : Buffer) return Boolean
     with Global => null,
          Post   => Is_Full'Result = (Length (B) = Capacity);

   procedure Clear (B : out Buffer)
     with Global => null,
          Post   => Is_Empty (B) and then Length (B) = 0;

   procedure Put (B : in out Buffer; Item : Element)
     with Global => null,
          Pre    => not Is_Full (B),
          Post   => Length (B) = Length (B)'Old + 1
            and then not Is_Empty (B);

   procedure Get (B : in out Buffer; Item : out Element)
     with Global => null,
          Pre    => not Is_Empty (B),
          Post   => Length (B) = Length (B)'Old - 1
            and then not Is_Full (B);

private
   subtype Index is Natural range 0 .. Capacity - 1;
   subtype Count_Range is Natural range 0 .. Capacity;

   type Data_Array is array (Index) of Element;

   type Buffer is record
      Data  : Data_Array := [others => 0];
      Head  : Index := 0;
      Tail  : Index := 0;
      Count : Count_Range := 0;
   end record;

   function Length (B : Buffer) return Natural is (Natural (B.Count));
end Bounded_Buffer;
