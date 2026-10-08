--  Own tests for Count_Primes (see tests/SOURCES.txt).
--  Is_Prime (V) is primality; Below (V) = number of primes p < V.
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
begin
   for V in Limit loop
      Report (Is_Prime (V) = Prime (V), "Is_Prime" & V'Image);
      Report (Below (V) = Below_Ref (V), "Below" & V'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own trial-division reference, exhaustive)");
end Own_Checks;
