--  Own tests for Count_Primes (see tests/SOURCES.txt).
--  Count_Primes_Below (N) = number of primes p < N.
pragma Ada_2022;
with Ada.Text_IO;
with Count_Primes; use Count_Primes;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;


   --  Own reference: trial division.
   function Prime (V : Natural) return Boolean is
   begin
      if V < 2 then
         return False;
      end if;
      for D in 2 .. V - 1 loop
         if V mod D = 0 then
            return False;
         end if;
      end loop;
      return True;
   end Prime;
   function Below_Ref (V : Natural) return Natural is
      C : Natural := 0;
   begin
      for X in 0 .. V - 1 loop
         if Prime (X) then
            C := C + 1;
         end if;
      end loop;
      return C;
   end Below_Ref;
   --  Count for any N in 0 .. 1000 (-1 when N is rejected).
   function Count_Of (V : Natural) return Integer is
   begin
      return Integer (Count_Primes_Below (V));
   exception
      when Constraint_Error =>
         return -1;
   end Count_Of;
begin
   --  H119: a real count for every N up to 1000 (a sieve), not only the
   --  0 .. 30 of the old case table.
   for V in 0 .. 1000 loop
      Report (Count_Of (V) = Below_Ref (V), "N =" & V'Image);
   end loop;
   Report (Count_Of (1000) = 168, "pi (999) = 168 (known value)");
   --  Published values of pi (x) at the bounds (10**6 and 10**7 are not
   --  prime, so "below" and "up to" agree).
   Report (Count_Of (10**6) = 78_498, "pi (10**6) = 78,498 (known value)");
   Report (Count_Of (10**7) = 664_579, "pi (10**7) = 664,579 (known value)");
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own trial-division reference, exhaustive 0 .. 1000)");
end Own_Checks;
