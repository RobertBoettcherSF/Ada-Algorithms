pragma Ada_2022;

--  Generic fixed-capacity string builder (Wikibooks Ada Programming/Generics,
--  RM 12): reusable algorithm parameterized by a formal object Capacity.
--  Formal objects are never static — use subtype/array ranges of Capacity;
--  do not write `mod Capacity` or other illegal static type defs.
generic
   Capacity : Positive;  --  formal object, mode in (default)
package Bounded_String_Builder
  with SPARK_Mode => On
is
   pragma Unevaluated_Use_Of_Old (Allow);

   --  Derived from the formal object (legal); Capacity is not a static value.
   subtype Length_Type is Natural range 0 .. Capacity;
   subtype Index_Type  is Positive range 1 .. Capacity;

   type Builder is private;

   function Length (B : Builder) return Length_Type
     with Global => null;

   function Max_Capacity return Positive
     with Global => null,
          Post   => Max_Capacity'Result = Capacity;

   function Element (B : Builder; Position : Index_Type) return Character
     with Global => null,
          Pre    => Position <= Length (B);

   procedure Clear (B : out Builder)
     with Global => null,
          Post   => Length (B) = 0;

   --  Builder UX: Status fails cleanly when full; length unchanged on failure.
   procedure Append
     (B      : in out Builder;
      Item   : Character;
      Status : out Boolean)
     with Global => null,
          Post   =>
            Status = (Length (B)'Old < Capacity)
              and then
            (if Status then
               Length (B) = Length (B)'Old + 1
                 and then Element (B, Length (B)) = Item
             else
               Length (B) = Length (B)'Old);

   procedure Append
     (B      : in out Builder;
      Item   : String;
      Status : out Boolean)
     with Global => null,
          Post   =>
            Status = (Item'Length <= Capacity - Length (B)'Old)
              and then
            (if Status then
               Length (B) = Length (B)'Old + Item'Length
             else
               Length (B) = Length (B)'Old);

   procedure Append_Integer
     (B      : in out Builder;
      Value  : Integer;
      Status : out Boolean)
     with Global => null,
          Post   =>
            (if Status then Length (B) >= Length (B)'Old + 1
             else Length (B) = Length (B)'Old);

   --  Classic Ada out-String + Last; empty => Last < Target'First.
   --  Avoids returning String (secondary stack).
   procedure To_String
     (B      : Builder;
      Target : out String;
      Last   : out Natural)
     with Global => null,
          Pre    => Target'First = 1
                      and then Target'Last >= Length (B),
          Post   =>
            (if Length (B) = 0 then Last = 0
             else Last = Length (B));

   procedure Slice
     (B      : Builder;
      Low    : Positive;
      High   : Natural;
      Target : out String;
      Last   : out Natural)
     with Global => null,
          Pre    =>
            Target'First = 1
              and then High <= Length (B)
              and then Low <= High + 1
              and then (if High >= Low then
                          Target'Last >= High - Low + 1
                        else
                          True),
          Post   =>
            (if High < Low then Last = 0
             else Last = High - Low + 1);

   function Equals (Left : Builder; Right : String) return Boolean
     with Global => null,
          Pre    => Right'First = 1;

private
   type Data_Array is array (Index_Type) of Character;

   type Builder is record
      Data : Data_Array := [others => Character'First];
      Len  : Length_Type := 0;
   end record;

   function Length (B : Builder) return Length_Type is (B.Len);

   function Max_Capacity return Positive is (Capacity);

   function Element (B : Builder; Position : Index_Type) return Character is
     (B.Data (Position));
end Bounded_String_Builder;
