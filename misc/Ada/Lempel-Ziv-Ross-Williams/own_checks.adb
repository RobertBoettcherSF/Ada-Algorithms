--  Own checks (see tests/SOURCES.txt): Decompress (Compress (X)) = X for random inputs,
--  including inputs whose index range starts at Stream_Element_Offset'First (what a
--  positional aggregate such as (65, 66, 67) gets) or ends at Stream_Element_Offset'Last.
with Ada.Streams; use Ada.Streams;
with Ada.Text_IO;
with LZRW; use LZRW;

procedure Own_Checks is
   Seed : Long_Long_Integer := 20261008;
   function Next (Bound : Positive) return Natural is
   begin
      Seed := (Seed * 16807) mod 2147483647;
      return Natural (Seed mod Long_Long_Integer (Bound));
   end Next;
   Runs : Natural := 0;
   procedure Round_Trip (X : Stream_Element_Array; Label : String) is
      C : Stream_Element_Array (1 .. Stream_Element_Offset (Max_Compressed_Size (X'Length)) + 16);
      D : Stream_Element_Array (1 .. X'Length + 16);
      CS, DS : Natural;
   begin
      Compress (X, C, CS);
      Decompress (C (1 .. Stream_Element_Offset (CS)), D, DS);
      if DS /= X'Length or else D (1 .. Stream_Element_Offset (DS)) /= X then
         Ada.Text_IO.Put_Line ("FAIL own check: round trip changed the data (" & Label & ")");
         raise Program_Error;
      end if;
      Runs := Runs + 1;
   exception
      when Constraint_Error =>
         Ada.Text_IO.Put_Line ("FAIL own check: Constraint_Error on a valid input (" & Label & ")");
         raise;
   end Round_Trip;
begin
   for Run in 1 .. 2000 loop
      declare
         N : constant Natural := Next (300);
         Alpha : constant Positive := (if Run mod 2 = 0 then 3 else 256);
         X : Stream_Element_Array (1 .. Stream_Element_Offset (N));
      begin
         for I in X'Range loop X (I) := Stream_Element (Next (Alpha)); end loop;
         Round_Trip (X, "index 1 ..");
         if N > 0 then   --  an empty range at the limits cannot be written without overflow
         declare
            Low : Stream_Element_Array (Stream_Element_Offset'First .. Stream_Element_Offset'First + X'Length - 1);
            High : Stream_Element_Array (Stream_Element_Offset'Last - X'Length + 1 .. Stream_Element_Offset'Last);
         begin
            Low := X; High := X;
            Round_Trip (Low, "index from Stream_Element_Offset'First");
            Round_Trip (High, "index up to Stream_Element_Offset'Last");
         end;
         end if;
      end;
   end loop;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Natural'Image (Runs) & " round trips (own property)");
end Own_Checks;
